// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/*********************************************************
Events used to communicate with a Kafka-Mongo-Kafka container
**********************************************************/

// event: receive notification from the queue
event eKafkaMongoKafkaContainerReceiveNotification: (name: string, region: int, count: int, invoker: machine);
// event: receive notification response from the queue
event eKafkaMongoKafkaContainerReceiveNotificationResponse: (name: string, region: int, count: int, success: bool);
// event: set the in queue
event eKafkaMongoKafkaContainerSetInKafka: (name: string, region: int, inKafka: Kafka, invoker: machine);
// event: set the in queue completed
event eKafkaMongoKafkaContainerSetInKafkaCompleted: (name: string, region: int, inKafka: Kafka, success: bool);
// event: set the database
event eKafkaMongoKafkaContainerSetDatabase: (name: string, region: int, database: MongoDBAtlas, invoker: machine);
// event: set the database completed
event eKafkaMongoKafkaContainerSetDatabaseCompleted: (name: string, region: int, database: MongoDBAtlas, success: bool);
// event: set the out queue
event eKafkaMongoKafkaContainerSetOutKafka: (name: string, region: int, outKafka: Kafka, invoker: machine);
// event: set the out queue completed
event eKafkaMongoKafkaContainerSetOutKafkaCompleted: (name: string, region: int, outKafka: Kafka, success: bool);
// event: fail the container
event eKafkaMongoKafkaContainerFail: (name: string, region: int);
// event: recover the container
event eKafkaMongoKafkaContainerRecover: (name: string, region: int);
// event: kill the container
event eKafkaMongoKafkaContainerKill: (name: string, region: int);

/****************************************************************************************************************************
A Container as a State Machine that reads from a Kafka stream, writes to a Mongo Atlas database and writes to a Kafka stream
*****************************************************************************************************************************/
machine KafkaMongoKafkaContainer {

 	var name: string;
 	var region: int;
 	var inKafkaName: string;
 	var inKafka: Kafka;
 	var databaseName: string;
 	var database: MongoDBAtlas;
 	var outKafkaName: string;
 	var outKafka: Kafka;
 	var count: int;
	var notificationCount: int;
	var notificationInvoker: machine;

 	start state Init {

   	entry (input: (name: string, region: int, inKafkaName: string, inKafka: Kafka, databaseName: string, database: MongoDBAtlas, outKafkaName: string, outKafka: Kafka)) {

     	name = input.name;
     	region = input.region;
     	inKafkaName = input.inKafkaName;
     	inKafka = input.inKafka;
     	databaseName = input.databaseName;
     	database = input.database;
     	outKafkaName = input.outKafkaName;
     	outKafka = input.outKafka;
     	send inKafka, eKafkaReceiveRecords, (name = inKafkaName, region = region, invoker = this);
     	goto ProcessRecords;
   	}
 	}

 	state ProcessRecords {

   	on eKafkaReceiveRecordsResponse do (input: (name: string, region: int, records: seq[tRecord], kafkaDepth: int, success: bool)) {

			var inKafkaSuccess: bool;
			var databaseSuccess: bool;
			var outKafkaSuccess: bool;
			var failure: bool;
      var record: tRecord;

			if (input.success) {

				count = count + 1;
				failure = false;

        databaseSuccess = true;
        foreach (record in input.records) {
          send database, eMongoInsertRecord, (name = databaseName, region = input.region, record = record, invoker = this);
          receive {
            case eMongoInsertRecordCompleted: (input1: (name: string, region: int, record: tRecord, success: bool)) {
               databaseSuccess = input1.success;
            }
          }

          if (databaseSuccess == false) {
            break;
          }
        }

				if (databaseSuccess) {

					send outKafka, eKafkaSendRecords, (name= outKafkaName, region = region, records = input.records, invoker = this);
					receive {
						case eKafkaSendRecordsCompleted: (input2: (name: string, region: int, records: seq[tRecord], success: bool)) {
							outKafkaSuccess = input2.success;
						}
					}

					if (outKafkaSuccess) {

						send inKafka, eKafkaRemoveRecords, (name = inKafkaName, region = region, records = input.records, invoker = this);
						receive {
							case eKafkaRemoveRecordsCompleted: (input3: (name: string, region: int, records: seq[tRecord], success: bool)) {
								inKafkaSuccess = input3.success;

								if (inKafkaSuccess) {

									if (count == notificationCount) {
										send notificationInvoker, eKafkaMongoKafkaContainerReceiveNotificationResponse, (name = name, region = region, count = count, success = true);
									}

									send inKafka, eKafkaReceiveRecords, (name = inKafkaName, region = region, invoker = this);
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

		on eKafkaMongoKafkaContainerReceiveNotification do (input: (name: string, region: int, count: int, invoker: machine)) {

			notificationCount = input.count;
			notificationInvoker = input.invoker;
		}

		on eKafkaMongoKafkaContainerSetInKafka do (input: (name: string, region: int, inKafka: Kafka, invoker: machine)) {

			inKafka = input.inKafka;
			send input.invoker, eKafkaMongoKafkaContainerSetInKafkaCompleted, (name = name, region = region, inKafka = inKafka, success = true);
		}

		on eKafkaMongoKafkaContainerSetDatabase do (input: (name: string, region: int, database: MongoDBAtlas, invoker: machine)) {

			database = input.database;
			send input.invoker, eKafkaMongoKafkaContainerSetDatabaseCompleted, (name = name, region = region, database = database, success = true);
		}

		on eKafkaMongoKafkaContainerSetOutKafka do (input: (name: string, region: int, outKafka: Kafka, invoker: machine)) {

			outKafka = input.outKafka;
			send input.invoker, eKafkaMongoKafkaContainerSetOutKafkaCompleted, (name = name, region = region, outKafka = outKafka, success = true);
		}

		on eKafkaMongoKafkaContainerFail do (input: (name: string, region: int)) {

			goto FailedProcessing;
		}

		ignore eKafkaMongoKafkaContainerRecover;

		on eKafkaMongoKafkaContainerKill do (input: (name: string, region: int)) {

			raise halt;
		}
 	}

 	state FailedDependency {

		defer eKafkaReceiveRecordsResponse;
		defer eKafkaMongoKafkaContainerReceiveNotification;
		ignore eKafkaMongoKafkaContainerFail;

		on eKafkaMongoKafkaContainerRecover do (input: (name: string, region: int)) {

			send inKafka, eKafkaReceiveRecords, (name = inKafkaName, region = input.region, invoker = this);

			goto ProcessRecords;
		}

		on eKafkaMongoKafkaContainerKill do (input: (name: string, region: int)) {

			raise halt;
		}
 	}

 	state FailedProcessing {

		defer eKafkaReceiveRecordsResponse;
		defer eKafkaMongoKafkaContainerReceiveNotification;
		ignore eKafkaMongoKafkaContainerFail;

		on eKafkaMongoKafkaContainerRecover do (input: (name: string, region: int)) {

			goto ProcessRecords;
		}

		on eKafkaMongoKafkaContainerKill do (input: (name: string, region: int)) {

			raise halt;
		}
 	}
}
