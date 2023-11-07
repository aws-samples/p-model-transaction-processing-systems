// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/********************************************************
Events used to communicate with Dynamo Global Table
*********************************************************/

// event: insert record into the database
event eDynamoInsertRecord: (name: string, region: int, record: tRecord, invoker: machine);
// event: insert record into the database completed
event eDynamoInsertRecordCompleted: (name: string, region: int, record: tRecord, success: bool);
// event: update record in the database
event eDynamoUpdateRecord: (name: string, region: int, record: tRecord, invoker: machine);
// event: update record in the database completed
event eDynamoUpdateRecordCompleted: (name: string, region: int, record: tRecord, success: bool);
// event: delete record from the database
event eDynamoDeleteRecord: (name: string, region: int, recordId: int, invoker: machine);
// event: delete record from the database completed
event eDynamoDeleteRecordCompleted: (name: string, region: int, recordId: int, success: bool);
// event: read record from the database
event eDynamoReadRecord: (name: string, region: int, recordId: int, invoker: machine);
// event: read record response from the database
event eDynamoReadRecordResponse: (name: string, region: int, record: tRecord, success: bool);
// event: read records from the database
event eDynamoReadRecords: (name: string, region: int, recordIds: seq[int], invoker: machine);
// event: read records response from the database
event eDynamoReadRecordsResponse: (name: string, region: int, records: seq[tRecord], success: bool);
// event: get record count from the database
event eDynamoGetRecordCount: (name: string, region: int, invoker: machine);
// event: get record count response from the database
event eDynamoGetRecordCountResponse: (name: string, region: int, recordCount: int, success: bool);
// event: fail the database
event eDynamoFail: (name: string);
// event: recover the database
event eDynamoRecover: (name: string);
// event: kill the database
event eDynamoKill: (name: string);
// event: fail the database replication
event eDynamoFailReplication: (name: string);
// event: recover the database replication
event eDynamoRecoverReplication: (name: string);
// event: create the database replication
event eDynamoCreateReplication: (name: string);
// event: kill the database replication
event eDynamoKillReplication: (name: string);

/*************************************************************
 Dynamo Global Table as a State Machine
**************************************************************/
machine DynamoGlobalTable {

  var name: string;
  var table1: DynamoRegionalTable;
  var table2: DynamoRegionalTable;
  var replicator: DynamoReplicator;

  start state Init {

    entry (input: (name: string)) {

      name = input.name;
      table1 = new DynamoRegionalTable((name = format ("{0}-{1}", input.name, "1"), region = 1));
      table2 = new DynamoRegionalTable((name = format ("{0}-{1}", input.name, "2"), region = 2));
      replicator = new DynamoReplicator((name = format ("{0}-replicator", input.name), table1Name = format ("{0}-{1}", input.name, "1"), table2Name = format ("{0}-{1}", input.name, "2"), table1 = table1, table2 = table2));
      goto ProcessRecords;
    }
  }

  state ProcessRecords {

    on eDynamoInsertRecord do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

			if (input.region == 1) {
      	send table1, eDynamoInsertRecord, (name = format("{0}-{1}", name, "1"), region = input.region, record = input.record, invoker = input.invoker);
      	send replicator, eDynamoInsertRecord, (name = format("{0}-replicator", input.name), region = input.region, record = input.record, invoker = input.invoker);
    	}
    	else {
    		send table2, eDynamoInsertRecord, (name = format("{0}-{1}", name, "2"), region = input.region, record = input.record, invoker = input.invoker);
        send replicator, eDynamoInsertRecord, (name = format("{0}-replicator", input.name), region = input.region, record = input.record, invoker = input.invoker);
    	}
    }

    on eDynamoUpdateRecord do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

			if (input.region == 1) {
      	send table1, eDynamoUpdateRecord, (name = format("{0}-{1}", name, "1"), region = input.region, record = input.record, invoker = input.invoker);
      	send replicator, eDynamoUpdateRecord, (name = format("{0}-replicator", input.name), region = input.region, record = input.record, invoker = input.invoker);
      }
      else {
      	send table2, eDynamoUpdateRecord, (name = format("{0}-{1}", name, "2"), region = input.region, record = input.record, invoker = input.invoker);
        send replicator, eDynamoUpdateRecord, (name = format("{0}-replicator", input.name), region = input.region, record = input.record, invoker = input.invoker);
      }
    }

    on eDynamoDeleteRecord do (input: (name: string, region: int, recordId: int, invoker: machine)) {

			if (input.region == 1) {
      	send table1, eDynamoDeleteRecord, (name = format("{0}-{1}", name, "1"), region = input.region, recordId = input.recordId, invoker = input.invoker);
      	send replicator, eDynamoDeleteRecord, (name = format("{0}-replicator", input.name), region = input.region, recordId = input.recordId, invoker = input.invoker);
      }
      else {
      	send table2, eDynamoDeleteRecord, (name = format("{0}-{1}", name, "2"), region = input.region, recordId = input.recordId, invoker = input.invoker);
        send replicator, eDynamoDeleteRecord, (name = format("{0}-replicator", input.name), region = input.region, recordId = input.recordId, invoker = input.invoker);
      }
    }

    on eDynamoReadRecord do (input: (name: string, region: int, recordId: int, invoker: machine)) {

			if (input.region == 1) {
      	send table1, eDynamoReadRecord, (name = format("{0}-{1}", name, "1"), region = input.region, recordId = input.recordId, invoker = input.invoker);
      }
      else {
      	send table2, eDynamoReadRecord, (name = format("{0}-{1}", name, "2"), region = input.region, recordId = input.recordId, invoker = input.invoker);
      }
    }

    on eDynamoReadRecords do (input: (name: string, region: int, recordIds: seq[int], invoker: machine)) {

			if (input.region == 1) {
      	send table1, eDynamoReadRecords, (name = format("{0}-{1}", name, "1"), region = input.region, recordIds = input.recordIds, invoker = input.invoker);
      }
      else {
      	send table2, eDynamoReadRecords, (name = format("{0}-{1}", name, "2"), region = input.region, recordIds = input.recordIds, invoker = input.invoker);
      }
    }

    on eDynamoGetRecordCount do (input: (name: string, region: int, invoker: machine)) {

			if (input.region == 1) {
      	send table1, eDynamoGetRecordCount, (name = format("{0}-{1}", name, "1"), region = input.region, invoker = input.invoker);
      }
      else {
      	send table2, eDynamoGetRecordCount, (name = format("{0}-{1}", name, "2"), region = input.region, invoker = input.invoker);
      }
    }

    on eDynamoFail do (input: (name: string)) {

			send table1, eDynamoFail, input;
			send table2, eDynamoFail, input;
			send replicator, eDynamoFail, input;
			goto FailedProcessing;
		}

		ignore eDynamoRecover;

    on eDynamoKill do (input: (name: string)) {

			send table1, eDynamoKill, input;
			send table2, eDynamoKill, input;
			send replicator, eDynamoKill, input;
			raise halt;
		}

    on eDynamoFailReplication do (input: (name: string)) {

			send replicator, eDynamoFail, input;
		}

    on eDynamoRecoverReplication do (input: (name: string)) {

			send replicator, eDynamoRecover, input;
		}

    on eDynamoCreateReplication do (input: (name: string)) {

			replicator = new DynamoReplicator((name = format ("{0}-replicator", input.name), table1Name = format ("{0}-{1}", input.name, "1"), table2Name = format ("{0}-{1}", input.name, "2"), table1 = table1, table2 = table2));
		}

    on eDynamoKillReplication do (input: (name: string)) {

			send replicator, eDynamoKill, input;
		}
  }

  state FailedProcessing {

		defer eDynamoInsertRecord;
		defer eDynamoUpdateRecord;
		defer eDynamoDeleteRecord;
		defer eDynamoReadRecord;
		defer eDynamoReadRecords;
		defer eDynamoGetRecordCount;

		ignore eDynamoFail;

		on eDynamoRecover do (input: (name: string)) {

			send table1, eDynamoRecover, input;
			send table2, eDynamoRecover, input;
			send replicator, eDynamoRecover, input;
			goto ProcessRecords;
		}

    on eDynamoKill do (input: (name: string)) {

			send table1, eDynamoKill, input;
			send table2, eDynamoKill, input;
			send replicator, eDynamoKill, input;
			raise halt;
		}
	}
}

machine DynamoRegionalTable {

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

    on eDynamoInsertRecord do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      records += (sizeof(records), input.record);
      if (region == input.region) {
      	send input.invoker, eDynamoInsertRecordCompleted, (name = input.name, region = input.region, record = input.record, success = true);
      }
    }

    on eDynamoUpdateRecord do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      var record: tRecord;
      foreach(record in records) {
        if (record.recordId == input.record.recordId) {
          record.recordValue = input.record.recordValue;
        }
      }
      if (region == input.region) {
      	send input.invoker, eDynamoUpdateRecordCompleted, (name = input.name, region = input.region, record = input.record, success = true);
      }
    }

    on eDynamoDeleteRecord do (input: (name: string, region: int, recordId: int, invoker: machine)) {

      var record: tRecord;
      var counter: int;
      foreach(record in records) {
        if (record.recordId == input.recordId) {
          records -= counter;
        }
        counter = counter + 1;
      }

			if (region == input.region) {
      	send input.invoker, eDynamoDeleteRecordCompleted, (name = input.name, region = input.region, recordId = input.recordId, success = true);
      }
    }

    on eDynamoReadRecord do (input: (name: string, region: int, recordId: int, invoker: machine)) {

      var item: tRecord;
      foreach(item in records) {
        if (item.recordId == input.recordId) {
          send input.invoker, eDynamoReadRecordResponse, (name = input.name, region = input.region, record = item, success = true);
        }
      }
    }

    on eDynamoReadRecords do (input: (name: string, region: int, recordIds: seq[int], invoker: machine)) {

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

      send input.invoker, eDynamoReadRecordsResponse, (name = input.name, region = input.region, records = responseRecords, success = true);
    }

    on eDynamoGetRecordCount do (input: (name: string, region: int, invoker: machine)) {

      send input.invoker, eDynamoGetRecordCountResponse, (name = input.name, region = input.region, recordCount = sizeof(records), success = true);
    }

    on eDynamoFail do (input: (name: string)) {

			goto FailedProcessing;
		}

		ignore eDynamoRecover;

    on eDynamoKill do (input: (name: string)) {

			raise halt;
		}
  }

	state FailedProcessing {

		defer eDynamoInsertRecord;
		defer eDynamoUpdateRecord;
		defer eDynamoDeleteRecord;
		defer eDynamoReadRecord;
		defer eDynamoReadRecords;
		defer eDynamoGetRecordCount;

		ignore eDynamoFail;

		on eDynamoRecover do (input: (name: string)) {

			goto ProcessRecords;
		}

    on eDynamoKill do (input: (name: string)) {

			raise halt;
		}
	}
}

machine DynamoReplicator {

	var name: string;
	var table1Name: string;
	var table2Name: string;
  var table1: DynamoRegionalTable;
  var table2: DynamoRegionalTable;

  start state Init {

    entry (input: (name: string, table1Name: string, table2Name: string, table1: DynamoRegionalTable, table2: DynamoRegionalTable)) {

    	name = input.name;
    	table1Name = input.table1Name;
      table1 = input.table1;
      table2Name = input.table2Name;
      table2 = input.table2;
      goto ProcessRecords;
    }
  }

  state ProcessRecords {

    entry {
    }

    on eDynamoInsertRecord do (input: (name: string, region: int,  record: tRecord, invoker: machine)) {

			if (input.region == 1) {
      	send table2, eDynamoInsertRecord, (name = table2Name, region = input.region, record = input.record, invoker = input.invoker);
      }
      else {
      	send table1, eDynamoInsertRecord, (name = table1Name, region = input.region, record = input.record, invoker = input.invoker);
      }
    }

    on eDynamoUpdateRecord do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

			if (input.region == 1) {
      	send table2, eDynamoUpdateRecord, (name = table2Name, region = input.region, record = input.record, invoker = input.invoker);
     	}
     	else {
     		send table1, eDynamoUpdateRecord, (name = table1Name, region = input.region, record = input.record, invoker = input.invoker);
     	}
    }

    on eDynamoDeleteRecord do (input: (name: string, region: int, recordId: int, invoker: machine)) {

			if (input.region == 1) {
				send table2, eDynamoDeleteRecord, (name = table2Name, region = input.region, recordId = input.recordId, invoker = input.invoker);
			}
			else {
				send table1, eDynamoDeleteRecord, (name = table1Name, region = input.region, recordId = input.recordId, invoker = input.invoker);
			}
  	}

    on eDynamoFail do (input: (name: string)) {

			goto FailedProcessing;
		}

		ignore eDynamoRecover;

    on eDynamoKill do (input: (name: string)) {

			raise halt;
		}
  }

	state FailedProcessing {

		defer eDynamoInsertRecord;
		defer eDynamoUpdateRecord;
		defer eDynamoDeleteRecord;
		defer eDynamoReadRecord;
		defer eDynamoReadRecords;
		defer eDynamoGetRecordCount;

		ignore eDynamoFail;

		on eDynamoRecover do (input: (name: string)) {

			goto ProcessRecords;
		}

    on eDynamoKill do (input: (name: string)) {

			raise halt;
		}
	}
}

