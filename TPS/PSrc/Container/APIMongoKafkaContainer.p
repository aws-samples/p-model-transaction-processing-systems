// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/*********************************************************
Events used to communicate with a API-Mongo-Kafka container
**********************************************************/

// event: invoke the API
event eAPIMongoKafkaContainerInvoke: (name: string, region: int, record: tRecord, invoker: machine);
// event: invoke the API completed
event eAPIMongoKafkaContainerInvokeCompleted: (name: string, region: int, record: tRecord, success: bool);
// event: receive notification from the container
event eAPIMongoKafkaContainerReceiveNotification: (name: string, region: int, count: int, invoker: machine);
// event: receive notification response from the container
event eAPIMongoKafkaContainerReceiveNotificationResponse: (name: string, region: int, count: int, success: bool);
// event: set the database
event eAPIMongoKafkaContainerSetDatabase: (name: string, region: int, database: MongoDBAtlas, invoker: machine);
// event: set the database completed
event eAPIMongoKafkaContainerSetDatabaseCompleted: (name: string, region: int, database: MongoDBAtlas, success: bool);
// event: set the out queue
event eAPIMongoKafkaContainerSetOutKafka: (name: string, region: int, outKafka: Kafka, invoker: machine);
// event: set the out queue completed
event eAPIMongoKafkaContainerSetOutKafkaCompleted: (name: string, region: int, outKafka: Kafka, success: bool);
// event: fail the container
event eAPIMongoKafkaContainerFail: (name: string, region: int);
// event: recover the container
event eAPIMongoKafkaContainerRecover: (name: string, region: int);
// event: kill the container
event eAPIMongoKafkaContainerKill: (name: string, region: int);

/****************************************************************************************************************************
A Container as a State Machine that receives an API invocation, writes to a Mongo Atlas database and writes to a Kafka stream
*****************************************************************************************************************************/
machine APIMongoKafkaContainer {

 	var name: string;
 	var region: int;
 	var databaseName: string;
 	var database: MongoDBAtlas;
 	var outKafkaName: string;
 	var outKafka: Kafka;
 	var count: int;
	var notificationCount: int;
	var notificationInvoker: machine;

 	start state Init {

   	entry (input: (name: string, region: int, databaseName: string, database: MongoDBAtlas, outKafkaName: string, outKafka: Kafka)) {

     	name = input.name;
     	region = input.region;
     	databaseName = input.databaseName;
     	database = input.database;
     	outKafkaName = input.outKafkaName;
     	outKafka = input.outKafka;
     	goto ProcessRecords;
   	}
 	}

 	state ProcessRecords {

   	on eAPIMongoKafkaContainerInvoke do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      var recordsToSend: seq[tRecord];
			var databaseSuccess: bool;
			var outKafkaSuccess: bool;
			var failure: bool;

      recordsToSend += (0, input.record);

      count = count + 1;
      failure = false;

      send database, eMongoInsertRecord, (name = databaseName, region = input.region, record = input.record, invoker = this);
      receive {
        case eMongoInsertRecordCompleted: (input1: (name: string, region: int, record: tRecord, success: bool)) {
           databaseSuccess = input1.success;
        }
      }

      if (databaseSuccess) {

        send outKafka, eKafkaSendRecords, (name= outKafkaName, region = region, records = recordsToSend, invoker = this);
        receive {
          case eKafkaSendRecordsCompleted: (input2: (name: string, region: int, records: seq[tRecord], success: bool)) {
            outKafkaSuccess = input2.success;
          }
        }

        failure = !outKafkaSuccess;
      }
      else {
        failure = true;
      }

      send input.invoker, eAPIMongoKafkaContainerInvokeCompleted, (name = input.name, region = input.region, record = input.record, success = !failure);

      if (failure == false && count == notificationCount) {
        send notificationInvoker, eAPIMongoKafkaContainerReceiveNotificationResponse, (name = name, region = region, count = count, success = true);
      }

      if (failure == true) {
        goto FailedDependency;
      }
   	}

		on eAPIMongoKafkaContainerReceiveNotification do (input: (name: string, region: int, count: int, invoker: machine)) {

			notificationCount = input.count;
			notificationInvoker = input.invoker;
		}

		on eAPIMongoKafkaContainerSetDatabase do (input: (name: string, region: int, database: MongoDBAtlas, invoker: machine)) {

			database = input.database;
			send input.invoker, eAPIMongoKafkaContainerSetDatabaseCompleted, (name = name, region = region, database = database, success = true);
		}

		on eAPIMongoKafkaContainerSetOutKafka do (input: (name: string, region: int, outKafka: Kafka, invoker: machine)) {

			outKafka = input.outKafka;
			send input.invoker, eAPIMongoKafkaContainerSetOutKafkaCompleted, (name = name, region = region, outKafka = outKafka, success = true);
		}

		on eAPIMongoKafkaContainerFail do (input: (name: string, region: int)) {

			goto FailedProcessing;
		}

		ignore eAPIMongoKafkaContainerRecover;

		on eAPIMongoKafkaContainerKill do (input: (name: string, region: int)) {

			raise halt;
		}
 	}

 	state FailedDependency {

		defer eAPIMongoKafkaContainerReceiveNotification;
		ignore eAPIMongoKafkaContainerFail;

    on eAPIMongoKafkaContainerInvoke do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      send input.invoker, eAPIMongoKafkaContainerInvokeCompleted, (name = input.name, region = input.region, record = input.record, success = false);
    }

		on eAPIMongoKafkaContainerRecover do (input: (name: string, region: int)) {

			goto ProcessRecords;
		}

		on eAPIMongoKafkaContainerKill do (input: (name: string, region: int)) {

			raise halt;
		}
 	}

 	state FailedProcessing {

		defer eAPIMongoKafkaContainerReceiveNotification;
		ignore eAPIMongoKafkaContainerFail;

    on eAPIMongoKafkaContainerInvoke do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      send input.invoker, eAPIMongoKafkaContainerInvokeCompleted, (name = input.name, region = input.region, record = input.record, success = false);
    }

		on eAPIMongoKafkaContainerRecover do (input: (name: string, region: int)) {

			goto ProcessRecords;
		}

		on eAPIMongoKafkaContainerKill do (input: (name: string, region: int)) {

			raise halt;
		}
 	}
}
