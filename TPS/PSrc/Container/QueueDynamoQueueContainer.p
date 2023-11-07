// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/*********************************************************
Events used to communicate with a QueueDynamoQueue container
**********************************************************/

// event: receive notification from the queue
event eQueueDynamoQueueContainerReceiveNotification: (name: string, region: int, count: int, invoker: machine);
// event: receive notification response from the queue
event eQueueDynamoQueueContainerReceiveNotificationResponse: (name: string, region: int, count: int, success: bool);
// event: set the in queue
event eQueueDynamoQueueContainerSetInQueue: (name: string, region: int, inQueue: Queue, invoker: machine);
// event: set the in queue completed
event eQueueDynamoQueueContainerSetInQueueCompleted: (name: string, region: int, inQueue: Queue, success: bool);
// event: set the table
event eQueueDynamoQueueContainerSetTable: (name: string, region: int, table: DynamoGlobalTable, invoker: machine);
// event: set the table completed
event eQueueDynamoQueueContainerSetTableCompleted: (name: string, region: int, table: DynamoGlobalTable, success: bool);
// event: set the out queue
event eQueueDynamoQueueContainerSetOutQueue: (name: string, region: int, outQueue: Queue, invoker: machine);
// event: set the out queue completed
event eQueueDynamoQueueContainerSetOutQueueCompleted: (name: string, region: int, outQueue: Queue, success: bool);
// event: fail the container
event eQueueDynamoQueueContainerFail: (name: string, region: int);
// event: recover the container
event eQueueDynamoQueueContainerRecover: (name: string, region: int);
// event: kill the container
event eQueueDynamoQueueContainerKill: (name: string, region: int);

/*************************************************************************************************
A Container as a State Machine that reads from a queue, writes to a DynamoDB table and writes to a queue
**************************************************************************************************/
machine QueueDynamoQueueContainer {

 	var name: string;
 	var region: int;
 	var inQueueName: string;
 	var inQueue: Queue;
 	var tableName: string;
 	var table: DynamoGlobalTable;
 	var outQueueName: string;
 	var outQueue: Queue;
 	var count: int;
	var notificationCount: int;
	var notificationInvoker: machine;

 	start state Init {

   	entry (input: (name: string, region: int, inQueueName: string, inQueue: Queue, tableName: string, table: DynamoGlobalTable, outQueueName: string, outQueue: Queue)) {

     	name = input.name;
     	region = input.region;
     	inQueueName = input.inQueueName;
     	inQueue = input.inQueue;
     	tableName = input.tableName;
     	table = input.table;
     	outQueueName = input.outQueueName;
     	outQueue = input.outQueue;
     	send inQueue, eQueueReceiveRecord, (name = inQueueName, region = region, invoker = this);
     	goto ProcessRecords;
   	}
 	}

 	state ProcessRecords {

   	on eQueueReceiveRecordResponse do (input: (name: string, region: int, record: tRecord, queueDepth: int, success: bool)) {

			var inQueueSuccess: bool;
			var tableSuccess: bool;
			var outQueueSuccess: bool;
			var failure: bool;

			if (input.success) {

				count = count + 1;
				failure = false;

				send table, eDynamoInsertRecord, (name = tableName, region = region, record = input.record, invoker = this);
				receive {
					case eDynamoInsertRecordCompleted: (input1: (name: string, region: int, record: tRecord, success: bool)) {
						tableSuccess = input1.success;
					}
				}

				if (tableSuccess) {

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
										send notificationInvoker, eQueueDynamoQueueContainerReceiveNotificationResponse, (name = name, region = region, count = count, success = true);
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

		on eQueueDynamoQueueContainerReceiveNotification do (input: (name: string, region: int, count: int, invoker: machine)) {

			notificationCount = input.count;
			notificationInvoker = input.invoker;
		}

		on eQueueDynamoQueueContainerSetInQueue do (input: (name: string, region: int, inQueue: Queue, invoker: machine)) {

			inQueue = input.inQueue;
			send input.invoker, eQueueDynamoQueueContainerSetInQueueCompleted, (name = name, region = region, inQueue = inQueue, success = true);
			send inQueue, eQueueReceiveRecord, (name = inQueueName, region = region, invoker = this);
		}

		on eQueueDynamoQueueContainerSetTable do (input: (name: string, region: int, table: DynamoGlobalTable, invoker: machine)) {

			table = input.table;
			send input.invoker, eQueueDynamoQueueContainerSetTableCompleted, (name = name, region = region, table = table, success = true);
		}

		on eQueueDynamoQueueContainerSetOutQueue do (input: (name: string, region: int, outQueue: Queue, invoker: machine)) {

			outQueue = input.outQueue;
			send input.invoker, eQueueDynamoQueueContainerSetOutQueueCompleted, (name = name, region = region, outQueue = outQueue, success = true);
		}

		on eQueueDynamoQueueContainerFail do (input: (name: string, region: int)) {

			goto FailedProcessing;
		}

		ignore eQueueDynamoQueueContainerRecover;

		on eQueueDynamoQueueContainerKill do (input: (name: string, region: int)) {

			raise halt;
		}
 	}

 	state FailedDependency {

		defer eQueueReceiveRecordResponse;
		defer eQueueDynamoQueueContainerReceiveNotification;
		ignore eQueueDynamoQueueContainerFail;

		on eQueueDynamoQueueContainerRecover do (input: (name: string, region: int)) {

			send inQueue, eQueueReceiveRecord, (name = inQueueName, region = region, invoker = this);

			goto ProcessRecords;
		}

		on eQueueDynamoQueueContainerKill do (input: (name: string, region: int)) {

			raise halt;
		}
 	}

 	state FailedProcessing {

		defer eQueueReceiveRecordResponse;
		defer eQueueDynamoQueueContainerReceiveNotification;
		ignore eQueueDynamoQueueContainerFail;

		on eQueueDynamoQueueContainerRecover do (input: (name: string, region: int)) {

			goto ProcessRecords;
		}

		on eQueueDynamoQueueContainerKill do (input: (name: string, region: int)) {

			raise halt;
		}
 	}
}
