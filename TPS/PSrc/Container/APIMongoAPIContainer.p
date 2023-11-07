// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/*********************************************************
Events used to communicate with a API-Mongo-API container
**********************************************************/

// event: invoke the API
event eAPIMongoAPIContainerInvoke: (name: string, region: int, record: tRecord, invoker: machine);
// event: invoke the API completed
event eAPIMongoAPIContainerInvokeCompleted: (name: string, region: int, record: tRecord, success: bool);
// event: receive notification from the container
event eAPIMongoAPIContainerReceiveNotification: (name: string, region: int, count: int, invoker: machine);
// event: receive notification response from the container
event eAPIMongoAPIContainerReceiveNotificationResponse: (name: string, region: int, count: int, success: bool);
// event: set the database
event eAPIMongoAPIContainerSetDatabase: (name: string, region: int, database: MongoDBAtlas, invoker: machine);
// event: set the database completed
event eAPIMongoAPIContainerSetDatabaseCompleted: (name: string, region: int, database: MongoDBAtlas, success: bool);
// event: set the out queue
event eAPIMongoAPIContainerSetOutAPI: (name: string, region: int, outAPI: APIMongoKafkaContainer, invoker: machine);
// event: set the out queue completed
event eAPIMongoAPIContainerSetOutAPICompleted: (name: string, region: int, outAPI: APIMongoKafkaContainer, success: bool);
// event: fail the container
event eAPIMongoAPIContainerFail: (name: string, region: int);
// event: recover the container
event eAPIMongoAPIContainerRecover: (name: string, region: int);
// event: kill the container
event eAPIMongoAPIContainerKill: (name: string, region: int);

/****************************************************************************************************************************
A Container as a State Machine that receives an API invocation, writes to a Mongo Atlas database and Invokes an API
*****************************************************************************************************************************/
machine APIMongoAPIContainer {

 	var name: string;
 	var region: int;
 	var databaseName: string;
 	var database: MongoDBAtlas;
 	var outAPIName: string;
 	var outAPI: APIMongoKafkaContainer;
 	var count: int;
	var notificationCount: int;
	var notificationInvoker: machine;

 	start state Init {

   	entry (input: (name: string, region: int, databaseName: string, database: MongoDBAtlas, outAPIName: string, outAPI: APIMongoKafkaContainer)) {

     	name = input.name;
     	region = input.region;
     	databaseName = input.databaseName;
     	database = input.database;
     	outAPIName = input.outAPIName;
     	outAPI = input.outAPI;
     	goto ProcessRecords;
   	}
 	}

 	state ProcessRecords {

   	on eAPIMongoAPIContainerInvoke do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      var recordsToSend: seq[tRecord];
			var databaseSuccess: bool;
			var outAPISuccess: bool;
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

        send outAPI, eAPIMongoKafkaContainerInvoke, (name= outAPIName, region = region, record = input.record, invoker = this);
        receive {
          case eAPIMongoKafkaContainerInvokeCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
            outAPISuccess = input2.success;
          }
        }

        failure = !outAPISuccess;
      }
      else {
        failure = true;
      }

      send input.invoker, eAPIMongoAPIContainerInvokeCompleted, (name = input.name, region = input.region, record = input.record, success = !failure);

      if (failure == false && count == notificationCount) {
        send notificationInvoker, eAPIMongoAPIContainerReceiveNotificationResponse, (name = name, region = region, count = count, success = true);
      }

      if (failure == true) {
        goto FailedDependency;
      }
   	}

		on eAPIMongoAPIContainerReceiveNotification do (input: (name: string, region: int, count: int, invoker: machine)) {

			notificationCount = input.count;
			notificationInvoker = input.invoker;
		}

		on eAPIMongoAPIContainerSetDatabase do (input: (name: string, region: int, database: MongoDBAtlas, invoker: machine)) {

			database = input.database;
			send input.invoker, eAPIMongoAPIContainerSetDatabaseCompleted, (name = name, region = region, database = database, success = true);
		}

		on eAPIMongoAPIContainerSetOutAPI do (input: (name: string, region: int, outAPI: APIMongoKafkaContainer, invoker: machine)) {

			outAPI = input.outAPI;
			send input.invoker, eAPIMongoAPIContainerSetOutAPICompleted, (name = name, region = region, outAPI = outAPI, success = true);
		}

		on eAPIMongoAPIContainerFail do (input: (name: string, region: int)) {

			goto FailedProcessing;
		}

		ignore eAPIMongoAPIContainerRecover;

		on eAPIMongoAPIContainerKill do (input: (name: string, region: int)) {

			raise halt;
		}
 	}

 	state FailedDependency {

		defer eAPIMongoAPIContainerReceiveNotification;
		ignore eAPIMongoAPIContainerFail;

    on eAPIMongoAPIContainerInvoke do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      send input.invoker, eAPIMongoAPIContainerInvokeCompleted, (name = input.name, region = input.region, record = input.record, success = false);
    }

		on eAPIMongoAPIContainerRecover do (input: (name: string, region: int)) {

			goto ProcessRecords;
		}

		on eAPIMongoAPIContainerKill do (input: (name: string, region: int)) {

			raise halt;
		}
 	}

 	state FailedProcessing {

		defer eAPIMongoAPIContainerReceiveNotification;
		ignore eAPIMongoAPIContainerFail;

    on eAPIMongoAPIContainerInvoke do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      send input.invoker, eAPIMongoAPIContainerInvokeCompleted, (name = input.name, region = input.region, record = input.record, success = false);
    }

		on eAPIMongoAPIContainerRecover do (input: (name: string, region: int)) {

			goto ProcessRecords;
		}

		on eAPIMongoAPIContainerKill do (input: (name: string, region: int)) {

			raise halt;
		}
 	}
}
