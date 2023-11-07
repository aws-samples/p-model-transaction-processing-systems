// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/********************************************************
Events used to communicate with MongoDB Atlas
*********************************************************/

// event: insert record into the database
event eMongoInsertRecord: (name: string, region: int, record: tRecord, invoker: machine);
// event: insert record into the database completed
event eMongoInsertRecordCompleted: (name: string, region: int, record: tRecord, success: bool);
// event: update record in the database
event eMongoUpdateRecord: (name: string, region: int, record: tRecord, invoker: machine);
// event: update record in the database completed
event eMongoUpdateRecordCompleted: (name: string, region: int, record: tRecord, success: bool);
// event: delete record from the database
event eMongoDeleteRecord: (name: string, region: int, recordId: int, invoker: machine);
// event: delete record from the database completed
event eMongoDeleteRecordCompleted: (name: string, region: int, recordId: int, success: bool);
// event: read record from the database
event eMongoReadRecord: (name: string, region: int, recordId: int, invoker: machine);
// event: read record response from the database
event eMongoReadRecordResponse: (name: string, region: int, record: tRecord, success: bool);
// event: read records from the database
event eMongoReadRecords: (name: string, region: int, recordIds: seq[int], invoker: machine);
// event: read records response from the database
event eMongoReadRecordsResponse: (name: string, region: int, records: seq[tRecord], success: bool);
// event: get record count from the database
event eMongoGetRecordCount: (name: string, region: int, invoker: machine);
// event: get record count response from the database
event eMongoGetRecordCountResponse: (name: string, region: int, recordCount: int, success: bool);
// event: switch active and passive region
event eMongoSwitchRegions: (name: string, invoker: machine);
// event: switch active and passive region
event eMongoSwitchRegionsCompleted: (name: string, success: bool);
// event: fail the database
event eMongoFail: (name: string);
// event: recover the database
event eMongoRecover: (name: string);
// event: kill the database
event eMongoKill: (name: string);

/*************************************************************
 Mongo Global Table as a State Machine
**************************************************************/
machine MongoDBAtlas {

  var name: string;
  var database1: MongoRegionalDatabase;  // primary
  var database2: MongoRegionalDatabase;  // secondary
  var database3: MongoRegionalDatabase;  // tertiary
  var activeRegion: int;

  start state Init {

    entry (input: (name: string)) {

      name = input.name;
      database1 = new MongoRegionalDatabase((name = format ("{0}-{1}", input.name, "1"), region = 1));
      database2 = new MongoRegionalDatabase((name = format ("{0}-{1}", input.name, "2"), region = 2));
      database3 = new MongoRegionalDatabase((name = format ("{0}-{1}", input.name, "3"), region = 3));
      goto Region1Active;
    }
  }

  state Region1Active {

    entry {

    	activeRegion = 1;
    }

    on eMongoInsertRecord do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      var database1Success: bool;
      var database2Success: bool;

      // primary insert
      send database1, eMongoInsertRecord, (name = format("{0}-{1}", name, "1"), region = 1, record = input.record, invoker = this);
      receive {
        case eMongoInsertRecordCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
          database1Success = input2.success;
        }
      }

      // synchronous replication
      send database2, eMongoInsertRecord, (name = format("{0}-{1}", name, "2"), region = 2, record = input.record, invoker = this);
      receive {
        case eMongoInsertRecordCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
          database2Success = input2.success;
        }
      }

      // asynchronous replication
      send database3, eMongoInsertRecord, (name = format("{0}-{1}", name, "3"), region = 3, record = input.record, invoker = this);

      send input.invoker, eMongoInsertRecordCompleted, (name = input.name, region = input.region, record = input.record, success = database1Success && database2Success);
    }

    on eMongoUpdateRecord do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      var database1Success: bool;
      var database2Success: bool;
      var replicationTarget: int;

      // primary update
      send database1, eMongoUpdateRecord, (name = format("{0}-{1}", name, "1"), region = 1, record = input.record, invoker = this);
      receive {
        case eMongoUpdateRecordCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
          database1Success = input2.success;
        }
      }

      // synchronous write
      send database2, eMongoUpdateRecord, (name = format("{0}-{1}", name, "2"), region = 2, record = input.record, invoker = this);
      receive {
        case eMongoUpdateRecordCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
          database2Success = input2.success;
        }
      }

      // asynchronous write
      send database3, eMongoUpdateRecord, (name = format("{0}-{1}", name, "3"), region = 3, record = input.record, invoker = this);

      send input.invoker, eMongoUpdateRecordCompleted, (name = input.name, region = input.region, record = input.record, success = database1Success && database2Success);
    }

    on eMongoDeleteRecord do (input: (name: string, region: int, recordId: int, invoker: machine)) {

      var database1Success: bool;
      var database2Success: bool;
      var replicationTarget: int;

      // primary delete
      send database1, eMongoDeleteRecord, (name = format("{0}-{1}", name, "1"), region = 1, recordId = input.recordId, invoker = this);
      receive {
        case eMongoDeleteRecordCompleted: (input2: (name: string, region: int, recordId: int, success: bool)) {
          database1Success = input2.success;
        }
      }

      // synchronous write
      send database2, eMongoDeleteRecord, (name = format("{0}-{1}", name, "2"), region = 2, recordId = input.recordId, invoker = this);
      receive {
        case eMongoDeleteRecordCompleted: (input2: (name: string, region: int, recordId: int, success: bool)) {
          database2Success = input2.success;
        }
      }

      // asynchronous write
      send database3, eMongoDeleteRecord, (name = format("{0}-{1}", name, "3"), region = 3, recordId = input.recordId, invoker = this);

      send input.invoker, eMongoDeleteRecordCompleted, (name = input.name, region = input.region, recordId = input.recordId, success = database1Success && database2Success);
    }

    on eMongoReadRecord do (input: (name: string, region: int, recordId: int, invoker: machine)) {

			if (input.region == 1) {
      	send database1, eMongoReadRecord, (name = format("{0}-{1}", name, "1"), region = input.region, recordId = input.recordId, invoker = input.invoker);
      }
      else {
      	send database2, eMongoReadRecord, (name = format("{0}-{1}", name, "2"), region = input.region, recordId = input.recordId, invoker = input.invoker);
      }
    }

    on eMongoReadRecords do (input: (name: string, region: int, recordIds: seq[int], invoker: machine)) {

			if (input.region == 1) {
      	send database1, eMongoReadRecords, (name = format("{0}-{1}", name, "1"), region = input.region, recordIds = input.recordIds, invoker = input.invoker);
      }
      else {
      	send database2, eMongoReadRecords, (name = format("{0}-{1}", name, "2"), region = input.region, recordIds = input.recordIds, invoker = input.invoker);
      }
    }

    on eMongoGetRecordCount do (input: (name: string, region: int, invoker: machine)) {

			if (input.region == 1) {
      	send database1, eMongoGetRecordCount, (name = format("{0}-{1}", name, "1"), region = input.region, invoker = input.invoker);
      }
      else {
      	send database2, eMongoGetRecordCount, (name = format("{0}-{1}", name, "2"), region = input.region, invoker = input.invoker);
      }
    }

    on eMongoSwitchRegions do (input: (name: string, invoker: machine)) {

      send input.invoker, eMongoSwitchRegionsCompleted, (name = input.name, success = true);
			goto Region2Active;
    }

    on eMongoFail do (input: (name: string)) {

			send database1, eMongoFail, input;
			send database2, eMongoFail, input;
			send database3, eMongoFail, input;
			goto FailedProcessing;
		}

		ignore eMongoRecover;

    on eMongoKill do (input: (name: string)) {

			send database1, eMongoKill, input;
			send database2, eMongoKill, input;
			send database3, eMongoKill, input;
			raise halt;
		}

		ignore eMongoInsertRecordCompleted;
  }

  state Region2Active {

    entry {

      activeRegion = 2;
    }

    on eMongoInsertRecord do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      var database1Success: bool;
      var database2Success: bool;

      // primary insert
      send database2, eMongoInsertRecord, (name = format("{0}-{1}", name, "2"), region = 2, record = input.record, invoker = this);
      receive {
        case eMongoInsertRecordCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
          database1Success = input2.success;
        }
      }

      // synchronous replication
      send database3, eMongoInsertRecord, (name = format("{0}-{1}", name, "3"), region = 3, record = input.record, invoker = this);
      receive {
        case eMongoInsertRecordCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
          database2Success = input2.success;
        }
      }

      // asynchronous replication
      send database1, eMongoInsertRecord, (name = format("{0}-{1}", name, "1"), region = 1, record = input.record, invoker = this);

      send input.invoker, eMongoInsertRecordCompleted, (name = input.name, region = input.region, record = input.record, success = database1Success && database2Success);
    }

    on eMongoUpdateRecord do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      var database1Success: bool;
      var database2Success: bool;
      var replicationTarget: int;

      // primary update
      send database2, eMongoUpdateRecord, (name = format("{0}-{1}", name, "2"), region = 2, record = input.record, invoker = this);
      receive {
        case eMongoUpdateRecordCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
          database1Success = input2.success;
        }
      }

      // synchronous write
      send database3, eMongoUpdateRecord, (name = format("{0}-{1}", name, "3"), region = 3, record = input.record, invoker = this);
      receive {
        case eMongoUpdateRecordCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
          database2Success = input2.success;
        }
      }

      // asynchronous write
      send database1, eMongoUpdateRecord, (name = format("{0}-{1}", name, "1"), region = 1, record = input.record, invoker = this);

      send input.invoker, eMongoUpdateRecordCompleted, (name = input.name, region = input.region, record = input.record, success = database1Success && database2Success);
    }

    on eMongoDeleteRecord do (input: (name: string, region: int, recordId: int, invoker: machine)) {

      var database1Success: bool;
      var database2Success: bool;
      var replicationTarget: int;

      // primary delete
      send database2, eMongoDeleteRecord, (name = format("{0}-{1}", name, "2"), region = 2, recordId = input.recordId, invoker = this);
      receive {
        case eMongoDeleteRecordCompleted: (input2: (name: string, region: int, recordId: int, success: bool)) {
          database1Success = input2.success;
        }
      }

      // synchronous write
      send database3, eMongoDeleteRecord, (name = format("{0}-{1}", name, "3"), region = 3, recordId = input.recordId, invoker = this);
      receive {
        case eMongoDeleteRecordCompleted: (input2: (name: string, region: int, recordId: int, success: bool)) {
          database2Success = input2.success;
        }
      }

      // asynchronous write
      send database1, eMongoDeleteRecord, (name = format("{0}-{1}", name, "1"), region = 1, recordId = input.recordId, invoker = this);

      send input.invoker, eMongoDeleteRecordCompleted, (name = input.name, region = input.region, recordId = input.recordId, success = database1Success && database2Success);
    }

    on eMongoReadRecord do (input: (name: string, region: int, recordId: int, invoker: machine)) {

      if (input.region == 1) {
        send database3, eMongoReadRecord, (name = format("{0}-{1}", name, "3"), region = input.region, recordId = input.recordId, invoker = input.invoker);
      }
      else {
        send database2, eMongoReadRecord, (name = format("{0}-{1}", name, "2"), region = input.region, recordId = input.recordId, invoker = input.invoker);
      }
    }

    on eMongoReadRecords do (input: (name: string, region: int, recordIds: seq[int], invoker: machine)) {

      if (input.region == 1) {
        send database3, eMongoReadRecords, (name = format("{0}-{1}", name, "3"), region = input.region, recordIds = input.recordIds, invoker = input.invoker);
      }
      else {
        send database2, eMongoReadRecords, (name = format("{0}-{1}", name, "2"), region = input.region, recordIds = input.recordIds, invoker = input.invoker);
      }
    }

    on eMongoGetRecordCount do (input: (name: string, region: int, invoker: machine)) {

      if (input.region == 1) {
        send database3, eMongoGetRecordCount, (name = format("{0}-{1}", name, "3"), region = input.region, invoker = input.invoker);
      }
      else {
        send database2, eMongoGetRecordCount, (name = format("{0}-{1}", name, "2"), region = input.region, invoker = input.invoker);
      }
    }

    on eMongoSwitchRegions do (input: (name: string, invoker: machine)) {

      send input.invoker, eMongoSwitchRegionsCompleted, (name = input.name, success = true);
			goto Region1Active;
    }

    on eMongoFail do (input: (name: string)) {

      send database1, eMongoFail, input;
      send database2, eMongoFail, input;
      send database3, eMongoFail, input;
      goto FailedProcessing;
    }

    ignore eMongoRecover;

    on eMongoKill do (input: (name: string)) {

      send database1, eMongoKill, input;
      send database2, eMongoKill, input;
      send database3, eMongoKill, input;
      raise halt;
    }

    ignore eMongoInsertRecordCompleted;
  }

  state FailedProcessing {

		defer eMongoUpdateRecord;
		defer eMongoDeleteRecord;
		defer eMongoReadRecord;
		defer eMongoReadRecords;
		defer eMongoGetRecordCount;
    ignore eMongoInsertRecordCompleted;
		ignore eMongoFail;

    on eMongoInsertRecord do (input: (name: string, region: int, record: tRecord, invoker: machine)) {
      send input.invoker, eMongoInsertRecordCompleted, (name = input.name, region = input.region, record = input.record, success = false);
    }

		on eMongoRecover do (input: (name: string)) {

			send database1, eMongoRecover, input;
			send database2, eMongoRecover, input;
			send database3, eMongoRecover, input;
			if (activeRegion == 1){
			  goto Region1Active;
			}
			else {
			  goto Region2Active;
			}
		}

    on eMongoKill do (input: (name: string)) {

			send database1, eMongoKill, input;
			send database2, eMongoKill, input;
			send database3, eMongoKill, input;
			raise halt;
		}
	}
}

machine MongoRegionalDatabase {

  var name: string;
  var region: int;
  var records: seq[tRecord];

  start state Init {

    entry (input: (name: string, region: int)) {

      name = input.name;
      region = input.region;
      goto ProcessRecords;
    }
  }

	state ProcessRecords {

    on eMongoInsertRecord do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      records += (sizeof(records), input.record);
      send input.invoker, eMongoInsertRecordCompleted, (name = input.name, region = input.region, record = input.record, success = true);
    }

    on eMongoUpdateRecord do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      var record: tRecord;
      foreach(record in records) {
        if (record.recordId == input.record.recordId) {
          record.recordValue = input.record.recordValue;
        }
      }

      send input.invoker, eMongoUpdateRecordCompleted, (name = input.name, region = input.region, record = input.record, success = true);
    }

    on eMongoDeleteRecord do (input: (name: string, region: int, recordId: int, invoker: machine)) {

      var record: tRecord;
      var counter: int;
      foreach(record in records) {
        if (record.recordId == input.recordId) {
          records -= counter;
        }
        counter = counter + 1;
      }

      send input.invoker, eMongoDeleteRecordCompleted, (name = input.name, region = input.region, recordId = input.recordId, success = true);
    }

    on eMongoReadRecord do (input: (name: string, region: int, recordId: int, invoker: machine)) {

      var item: tRecord;
      foreach(item in records) {
        if (item.recordId == input.recordId) {
          send input.invoker, eMongoReadRecordResponse, (name = input.name, region = input.region, record = item, success = true);
        }
      }
    }

    on eMongoReadRecords do (input: (name: string, region: int, recordIds: seq[int], invoker: machine)) {

      var recordId: int;
      var record: tRecord;
      var responseRecords: seq[tRecord];
      foreach(recordId in input.recordIds) {
        foreach(record in records) {
          if (record.recordId == recordId) {
            responseRecords += (sizeof(responseRecords), record);
            break;
          }
        }
      }

      send input.invoker, eMongoReadRecordsResponse, (name = input.name, region = input.region, records = responseRecords, success = true);
    }

    on eMongoGetRecordCount do (input: (name: string, region: int, invoker: machine)) {

      send input.invoker, eMongoGetRecordCountResponse, (name = input.name, region = input.region, recordCount = sizeof(records), success = true);
    }

    on eMongoFail do (input: (name: string)) {

			goto FailedProcessing;
		}

		ignore eMongoRecover;

    on eMongoKill do (input: (name: string)) {

			raise halt;
		}
  }

	state FailedProcessing {

		defer eMongoInsertRecord;
		defer eMongoUpdateRecord;
		defer eMongoDeleteRecord;
		defer eMongoReadRecord;
		defer eMongoReadRecords;
		defer eMongoGetRecordCount;

		ignore eMongoFail;

		on eMongoRecover do (input: (name: string)) {

			goto ProcessRecords;
		}

    on eMongoKill do (input: (name: string)) {

			raise halt;
		}
	}
}



