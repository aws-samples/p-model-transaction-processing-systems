// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/*************************************************************
Events used to communicate with a Queue-Aurora-Queue Container
**************************************************************/

// event: receive notification from the queue
event eQueueAuroraQueueContainerReceiveNotification: (name: string, region: int, count: int, invoker: machine);
// event: receive notification response from the queue
event eQueueAuroraQueueContainerReceiveNotificationResponse: (name: string, region: int, count: int, success: bool);
// event: set the in queue
event eQueueAuroraQueueContainerSetInQueue: (name: string, region: int, inQueue: Queue, invoker: machine);
// event: set the in queue completed
event eQueueAuroraQueueContainerSetInQueueCompleted: (name: string, region: int, inQueue: Queue, success: bool);
// event: set the database
event eQueueAuroraQueueContainerSetDatabase: (name: string, region: int, database: AuroraGlobalDatabase, invoker: machine);
// event: set the database completed
event eQueueAuroraQueueContainerSetDatabaseCompleted: (name: string, region: int, database: AuroraGlobalDatabase, success: bool);
// event: set the out queue
event eQueueAuroraQueueContainerSetOutQueue: (name: string, region: int, outQueue: Queue, invoker: machine);
// event: set the out queue completed
event eQueueAuroraQueueContainerSetOutQueueCompleted: (name: string, region: int, outQueue: Queue, success: bool);
// event: fail the container
event eQueueAuroraQueueContainerFail: (name: string, region: int);
// event: recover the container
event eQueueAuroraQueueContainerRecover: (name: string, region: int);
// event: kill the container
event eQueueAuroraQueueContainerKill: (name: string, region: int);

/*************************************************************************************************************************
A Container as a State Machine that reads from an input queue, writes to an Aurora database and writes to an output queue
**************************************************************************************************************************/
machine QueueAuroraQueueContainer {

 	var name: string;
 	var region: int;
 	var inQueueName: string;
 	var inQueue: Queue;
 	var databaseName: string;
 	var database: AuroraGlobalDatabase;
 	var outQueueName: string;
 	var outQueue: Queue;
 	var count: int;
	var notificationCount: int;
	var notificationInvoker: machine;

 	start state Init {

   	entry (input: (name: string, region: int, inQueueName: string, inQueue: Queue, databaseName: string, database: AuroraGlobalDatabase, outQueueName: string, outQueue: Queue)) {

     	name = input.name;
     	region = input.region;
     	inQueueName = input.inQueueName;
     	inQueue = input.inQueue;
     	databaseName = input.databaseName;
     	database = input.database;
     	outQueueName = input.outQueueName;
     	outQueue = input.outQueue;
     	send inQueue, eQueueReceiveRecord, (name = inQueueName, region = region, invoker = this);
     	goto ProcessRecords;
   	}
 	}

 	state ProcessRecords {

   	on eQueueReceiveRecordResponse do (input: (name: string, region: int, record: tRecord, queueDepth: int, success: bool)) {

			var inQueueSuccess: bool;
			var databaseSuccess: bool;
			var outQueueSuccess: bool;
			var failure: bool;

			if (input.success) {

				count = count + 1;
				failure = false;

				send database, eAuroraInsertRecord, (name = databaseName, record = input.record, invoker = this);
				receive {
					case eAuroraInsertRecordCompleted: (input1: (name: string, record: tRecord, success: bool)) {
						databaseSuccess = input1.success;
					}
				}

				if (databaseSuccess) {

					send outQueue, eQueueSendRecord, (name= outQueueName, region = region, record = input.record, invoker = this);
					receive {
						case eQueueSendRecordCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
							outQueueSuccess = input2.success;
						}
					}

					if (outQueueSuccess) {

						send inQueue, eQueueRemoveRecord, (name = inQueueName, region = region, record = input.record, invoker = this);
						receive {
							case eQueueRemoveRecordCompleted: (input3: (name: string, region: int, record: tRecord, success: bool)) {
								inQueueSuccess = input3.success;

								if (inQueueSuccess) {

									if (count == notificationCount) {
										send notificationInvoker, eQueueAuroraQueueContainerReceiveNotificationResponse, (name = name, region = region, count = count, success = true);
									}

									send inQueue, eQueueReceiveRecord, (name = inQueueName, region = region, invoker = this);
								}
								else {
									failure = true;
								}
							}
						}
					}
					else {
						failure = true;
					}
				}
				else {
					failure = true;
				}

				if (failure == true) {
					goto FailedDependency;
				}
			}
			else {
				goto FailedDependency;
			}
   	}

		on eQueueAuroraQueueContainerReceiveNotification do (input: (name: string, region: int, count: int, invoker: machine)) {

			notificationCount = input.count;
			notificationInvoker = input.invoker;
		}

		on eQueueAuroraQueueContainerSetInQueue do (input: (name: string, region: int, inQueue: Queue, invoker: machine)) {

			inQueue = input.inQueue;
			send input.invoker, eQueueAuroraQueueContainerSetInQueueCompleted, (name = name, region = region, inQueue = inQueue, success = true);
		}

		on eQueueAuroraQueueContainerSetDatabase do (input: (name: string, region: int, database: AuroraGlobalDatabase, invoker: machine)) {

			database = input.database;
			send input.invoker, eQueueAuroraQueueContainerSetDatabaseCompleted, (name = name, region = region, database = database, success = true);
		}

		on eQueueAuroraQueueContainerSetOutQueue do (input: (name: string, region: int, outQueue: Queue, invoker: machine)) {

			outQueue = input.outQueue;
			send input.invoker, eQueueAuroraQueueContainerSetOutQueueCompleted, (name = name, region = region, outQueue = outQueue, success = true);
		}

		on eQueueAuroraQueueContainerFail do (input: (name: string, region: int)) {

			goto FailedProcessing;
		}

		ignore eQueueAuroraQueueContainerRecover;

		on eQueueAuroraQueueContainerKill do (input: (name: string, region: int)) {

			raise halt;
		}
 	}

 	state FailedDependency {

		defer eQueueReceiveRecordResponse;
		defer eQueueAuroraQueueContainerReceiveNotification;
		ignore eQueueAuroraQueueContainerFail;

		on eQueueAuroraQueueContainerRecover do (input: (name: string, region: int)) {

			send inQueue, eQueueReceiveRecord, (name = inQueueName, region = region, invoker = this);

			goto ProcessRecords;
		}

		on eQueueAuroraQueueContainerKill do (input: (name: string, region: int)) {

			raise halt;
		}
 	}

 	state FailedProcessing {

		defer eQueueReceiveRecordResponse;
		defer eQueueAuroraQueueContainerReceiveNotification;
		ignore eQueueAuroraQueueContainerFail;

		on eQueueAuroraQueueContainerRecover do (input: (name: string, region: int)) {

			goto ProcessRecords;
		}

		on eQueueAuroraQueueContainerKill do (input: (name: string, region: int)) {

			raise halt;
		}
 	}
}
