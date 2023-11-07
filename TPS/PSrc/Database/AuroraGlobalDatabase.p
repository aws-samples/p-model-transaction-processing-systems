// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/********************************************************
Events used to communicate with Aurora Global Database
*********************************************************/

// event: insert record into the database
event eAuroraInsertRecord: (name: string, record: tRecord, invoker:machine);
// event: insert record into the database completed
event eAuroraInsertRecordCompleted: (name: string, record: tRecord, success: bool);
// event: update record in the database
event eAuroraUpdateRecord: (name: string, record: tRecord, invoker:machine);
// event: update record in the database completed
event eAuroraUpdateRecordCompleted: (name: string, record: tRecord, success: bool);
// event: delete record from the database
event eAuroraDeleteRecord: (name: string, recordId: int, invoker:machine);
// event: delete record from the database completed
event eAuroraDeleteRecordCompleted: (name: string, recordId: int, success: bool);
// event: read record from the database
event eAuroraReadRecord: (name: string, recordId: int, invoker: machine);
// event: read record response from the database
event eAuroraReadRecordResponse: (name: string, record: tRecord, success: bool);
// event: read records from the database
event eAuroraReadRecords: (name: string, recordIds: seq[int], invoker: machine);
// event: read records response from the database
event eAuroraReadRecordsResponse: (name: string, records: seq[tRecord], success: bool);
// event: get record count from the database
event eAuroraGetRecordCount: (name: string, invoker: machine);
// event: get record count response from the database
event eAuroraGetRecordCountResponse: (name: string, recordCount: int, success: bool);
// event: switch active and passive region
event eAuroraSwitchRegions: (name: string, invoker: machine);
// event: switch active and passive region
event eAuroraSwitchRegionsCompleted: (name: string, success: bool);
// event: fail the database
event eAuroraFail: (name: string, invoker: machine);
// event: fail the database completed
event eAuroraFailCompleted: (name: string);
// event: recover the database
event eAuroraRecover: (name: string, invoker: machine);
// event: recover the database completed
event eAuroraRecoverCompleted: (name: string, success: bool);
// event: kill the database
event eAuroraKill: (name: string);
// event: fail the database replication
event eAuroraFailReplication: (name: string, invoker: machine);
// event: fail the database replication completed
event eAuroraFailReplicationCompleted: (name: string);
// event: recover the database replication
event eAuroraRecoverReplication: (name: string);
// event: create the database replication
event eAuroraCreateReplication: (name: string);
// event: kill the database replication
event eAuroraKillReplication: (name: string);

/*************************************************************
 Aurora Global Database as a State Machine
**************************************************************/
machine AuroraGlobalDatabase {

  var name: string;
  var database1: AuroraRegionalDatabase;
  var database2: AuroraRegionalDatabase;
  var replicator: AuroraReplicator;
  var activeRegion: int;

  start state Init {

    entry (input: (name: string)) {

      name = input.name;
      database1 = new AuroraRegionalDatabase((name = format ("{0}-{1}", input.name, "1"), region = 1, active = true));
      database2 = new AuroraRegionalDatabase((name = format ("{0}-{1}", input.name, "2"), region = 2, active = false));
      replicator = new AuroraReplicator((name = format ("{0}-replicator", input.name), database1Name = format ("{0}-{1}", input.name, "1"), database2Name = format ("{0}-{1}", input.name, "2"), database1 = database1, database2 = database2));
      goto Region1Active;
    }
  }

  state Region1Active {

    entry {

    	activeRegion = 1;
    }

    on eAuroraInsertRecord do (input: (name: string, record: tRecord, invoker: machine)) {

      send database1, eAuroraInsertRecord, (name = format("{0}-{1}", name, "1"), record = input.record, invoker = input.invoker);
      send replicator, eAuroraInsertRecord, (name = format("{0}-replicator", input.name), record = input.record, invoker = input.invoker);
    }

    on eAuroraUpdateRecord do (input: (name: string, record: tRecord, invoker: machine)) {

      send database1, eAuroraUpdateRecord, (name = format("{0}-{1}", name, "1"), record = input.record, invoker = input.invoker);
      send replicator, eAuroraUpdateRecord, (name = format("{0}-replicator", input.name), record = input.record, invoker = input.invoker);
    }

    on eAuroraDeleteRecord do (input: (name: string, recordId: int, invoker: machine)) {

      send database1, eAuroraDeleteRecord, (name = format("{0}-{1}", name, "1"), recordId = input.recordId, invoker = input.invoker);
      send replicator, eAuroraDeleteRecord, (name = format("{0}-replicator", input.name), recordId = input.recordId, invoker = input.invoker);
    }

    on eAuroraReadRecord do (input: (name: string, recordId: int, invoker: machine)) {

      send database1, eAuroraReadRecord, (name = format("{0}-{1}", name, "1"), recordId = input.recordId, invoker = input.invoker);
    }

    on eAuroraReadRecords do (input: (name: string, recordIds: seq[int], invoker: machine)) {

      send database1, eAuroraReadRecords, (name = format("{0}-{1}", name, "1"), recordIds = input.recordIds, invoker = input.invoker);
    }

    on eAuroraGetRecordCount do (input: (name: string, invoker: machine)) {

      send database1, eAuroraGetRecordCount, (name = format("{0}-{1}", name, "1"), invoker = input.invoker);
    }

    on eAuroraSwitchRegions do (input: (name: string, invoker: machine)) {

			var database1Switch: bool;
			var database2Switch: bool;
			var database3Switch: bool;

			send database1, eAuroraSwitchRegions, (name = format("{0}-{1}", name, "1"), invoker = this);
			receive {
				case eAuroraSwitchRegionsCompleted: (input: (name: string, success: bool)) {
					database1Switch = input.success;
					print format ("{0} switch regions completed", input.name);
				}
			}

			send database2, eAuroraSwitchRegions, (name = format("{0}-{1}", name, "2"), invoker = this);
			receive {
				case eAuroraSwitchRegionsCompleted: (input: (name: string, success: bool)) {
					database2Switch = input.success;
					print format ("{0} switch regions completed", input.name);
				}
			}

			send replicator, eAuroraSwitchRegions, (name = format("{0}-replicator", name), invoker = this);
			receive {
				case eAuroraSwitchRegionsCompleted: (input: (name: string, success: bool)) {
					database3Switch= input.success;
					print format ("{0} switch regions completed", input.name);
				}
			}

			if (database1Switch && database2Switch && database3Switch) {
				send input.invoker, eAuroraSwitchRegionsCompleted, (name = input.name, success = true);
				goto Region2Active;
			}
			else {
				send input.invoker, eAuroraSwitchRegionsCompleted, (name = input.name, success = false);
			}
    }

    on eAuroraFail do (input: (name: string, invoker: machine)) {

			send database1, eAuroraFail, input;
			send database2, eAuroraFail, input;
			send replicator, eAuroraFail, input;

			send input.invoker, eAuroraFailCompleted, (name = input.name, );

			goto FailedProcessing;
		}

		ignore eAuroraRecover;

    on eAuroraKill do (input: (name: string)) {

			send database1, eAuroraKill, input;
			send database2, eAuroraKill, input;
			send replicator, eAuroraKill, input;
			raise halt;
		}

    on eAuroraRecoverReplication do (input: (name: string)) {

			send replicator, eAuroraRecover, (name = input.name, invoker = this);
			receive {
				case eAuroraRecoverCompleted: (input: (name: string, success: bool)) {
				}
			}
		}

    on eAuroraFailReplication do (input: (name: string, invoker: machine)) {

			send replicator, eAuroraFail, input;

			send input.invoker, eAuroraFailReplicationCompleted, (name = input.name, );
		}

    on eAuroraCreateReplication do (input: (name: string)) {

			replicator = new AuroraReplicator((name = format ("{0}-replicator", input.name), database1Name = format ("{0}-{1}", input.name, "1"), database2Name = format ("{0}-{1}", input.name, "2"), database1 = database1, database2 = database2));
		}

    on eAuroraKillReplication do (input: (name: string)) {

			send replicator, eAuroraKill, input;
		}
  }

  state Region2Active {

    entry {

    	activeRegion = 2;
    }

    on eAuroraInsertRecord do (input: (name: string, record: tRecord, invoker: machine)) {

      send database2, eAuroraInsertRecord, (name = format("{0}-{1}", name, "2"), record = input.record, invoker = input.invoker);
      send replicator, eAuroraInsertRecord, (name = format("{0}-replicator", input.name), record = input.record, invoker = input.invoker);
    }

    on eAuroraUpdateRecord do (input: (name: string, record: tRecord, invoker: machine)) {

      send database2, eAuroraUpdateRecord, (name = format("{0}-{1}", name, "2"), record = input.record, invoker = input.invoker);
      send replicator, eAuroraUpdateRecord, (name = format("{0}-replicator", input.name), record = input.record, invoker = input.invoker);
    }

    on eAuroraDeleteRecord do (input: (name: string, recordId: int, invoker: machine)) {

      send database2, eAuroraDeleteRecord, (name = format("{0}-{1}", name, "2"), recordId = input.recordId, invoker = input.invoker);
      send replicator, eAuroraDeleteRecord, (name = format("{0}-replicator", input.name), recordId = input.recordId, invoker = input.invoker);
    }

    on eAuroraReadRecord do (input: (name: string, recordId: int, invoker: machine)) {

      send database2, eAuroraReadRecord, (name = format("{0}-{1}", name, "2"), recordId = input.recordId, invoker = input.invoker);
    }

    on eAuroraReadRecords do (input: (name: string, recordIds: seq[int], invoker: machine)) {

      send database2, eAuroraReadRecords, (name = format("{0}-{1}", name, "2"), recordIds = input.recordIds, invoker = input.invoker);
    }

    on eAuroraGetRecordCount do (input: (name: string, invoker: machine)) {

      send database2, eAuroraGetRecordCount, (name = format("{0}-{1}", name, "2"), invoker = input.invoker);
    }

    on eAuroraSwitchRegions do (input: (name: string, invoker: machine)) {

			var database1Switch: bool;
			var database2Switch: bool;
			var database3Switch: bool;

			send database1, eAuroraSwitchRegions, (name = format("{0}-{1}", name, "1"), invoker = input.invoker);
			receive {
				case eAuroraSwitchRegionsCompleted: (input: (name: string, success: bool)) {
					database1Switch = input.success;
					print format ("{0} switch regions completed", input.name);
				}
			}

			send database2, eAuroraSwitchRegions, (name = format("{0}-{1}", name, "2"), invoker = input.invoker);
			receive {
				case eAuroraSwitchRegionsCompleted: (input: (name: string, success: bool)) {
					database2Switch = input.success;
					print format ("{0} switch regions completed", input.name);
				}
			}

			send replicator, eAuroraSwitchRegions, (name = format("{0}-replicator", name), invoker = input.invoker);
			receive {
				case eAuroraSwitchRegionsCompleted: (input: (name: string, success: bool)) {
					database3Switch = input.success;
					print format ("{0} switch regions completed", input.name);
				}
			}

			if (database1Switch && database2Switch && database3Switch) {
				send input.invoker, eAuroraSwitchRegionsCompleted, (name = input.name, success = true);
				goto Region2Active;
			}
			else {
				send input.invoker, eAuroraSwitchRegionsCompleted, (name = input.name, success = false);
			}
		}

		on eAuroraFail do (input: (name: string, invoker: machine)) {

			send database1, eAuroraFail, (name = format("{0}-{1}", name, "1"), invoker = input.invoker);
			send database2, eAuroraFail, (name = format("{0}-{1}", name, "2"), invoker = input.invoker);
			send replicator, eAuroraFail, (name = format("{0}-replicator", name), invoker = input.invoker);

			send input.invoker, eAuroraFailCompleted, (name = input.name, );

			goto FailedProcessing;
		}

		ignore eAuroraRecover;

		on eAuroraKill do (input: (name: string)) {

			send database1, eAuroraKill, (name = format("{0}-{1}", name, "1"), );
			send database2, eAuroraKill, (name = format("{0}-{1}", name, "2"), );
			send replicator, eAuroraKill, (name = format("{0}-replicator", name), );
			raise halt;
		}

    on eAuroraRecoverReplication do (input: (name: string)) {

			send replicator, eAuroraRecover, (name = input.name, invoker = this);
			receive {
				case eAuroraRecoverCompleted: (input: (name: string, success: bool)) {
				}
			}
		}

		on eAuroraFailReplication do (input: (name: string, invoker: machine)) {

			send replicator, eAuroraFail, input;

			send input.invoker, eAuroraFailReplicationCompleted, (name = input.name, );
		}

    on eAuroraCreateReplication do (input: (name: string)) {

			replicator = new AuroraReplicator((name = format ("{0}-replicator", input.name), database1Name = format ("{0}-{1}", input.name, "1"), database2Name = format ("{0}-{1}", input.name, "2"), database1 = database1, database2 = database2));
		}

		on eAuroraKillReplication do (input: (name: string)) {

			send replicator, eAuroraKill, input;
		}
  }

  state FailedProcessing {

		on eAuroraInsertRecord do (input: (name: string, record: tRecord, invoker: machine)) {

      send input.invoker, eAuroraInsertRecordCompleted, (name = input.name, record = input.record, success = false);
    }

    on eAuroraUpdateRecord do (input: (name: string, record: tRecord, invoker: machine)) {

      send input.invoker, eAuroraUpdateRecordCompleted, (name = input.name, record = input.record, success = false);
    }

    on eAuroraDeleteRecord do (input: (name: string, recordId: int, invoker: machine)) {

      send input.invoker, eAuroraDeleteRecordCompleted, (name = input.name, recordId = input.recordId, success = false);
    }

    on eAuroraReadRecord do (input: (name: string, recordId: int, invoker: machine)) {

      send input.invoker, eAuroraReadRecordResponse, (name = name, record = (recordId = 0, recordValue = 0), success = false);
    }

    on eAuroraReadRecords do (input: (name: string, recordIds: seq[int], invoker: machine)) {

			var records: seq[tRecord];
			records += (0, (recordId = 0, recordValue = 0));
      send input.invoker, eAuroraReadRecordsResponse, (name = name, records = records, success = false);
    }

    on eAuroraGetRecordCount do (input: (name: string, invoker: machine)) {

      send input.invoker, eAuroraGetRecordCountResponse, (name = name, recordCount = 0, success = false);
    }

    on eAuroraSwitchRegions do (input: (name: string, invoker: machine)) {

			send input.invoker, eAuroraSwitchRegionsCompleted, (name = input.name, success = false);
		}

		ignore eAuroraFail;

		on eAuroraRecover do (input: (name: string, invoker: machine)) {

			send database1, eAuroraRecover, (name = format("{0}-{1}", name, "1"), invoker = this);
			receive {
				case eAuroraRecoverCompleted: (input: (name: string, success: bool)) {
				}
			}

			send database2, eAuroraRecover, (name = format("{0}-{1}", name, "2"), invoker = this);
			receive {
				case eAuroraRecoverCompleted: (input: (name: string, success: bool)) {
				}
			}

			send replicator, eAuroraRecover, (name = format("{0}-replicator", name), invoker = this);
			receive {
				case eAuroraRecoverCompleted: (input: (name: string, success: bool)) {
				}
			}

      send input.invoker, eAuroraRecoverCompleted, (name = input.name, success = true);

			if (activeRegion == 1) {
				goto Region1Active;
			}
			else {
				goto Region2Active;
			}
		}

		on eAuroraKill do (input: (name: string)) {

			send database1, eAuroraKill, (name = format ("{0}-{1}", name, "1"), );
			send database2, eAuroraKill, (name = format("{0}-{1}", name, "2"), );
			send replicator, eAuroraKill, (name = format("{0}-replicator", name), );
			raise halt;
		}
	}
}

machine AuroraRegionalDatabase {

  var name: string;
  var region: int;
  var records: seq[tRecord];
  var active: bool;

  start state Init {

    entry (input: (name: string, region: int, active: bool)) {

      name = input.name;
      region = input.region;
      active = input.active;
      goto ProcessRecords;
    }
	}

 	state ProcessRecords {

    on eAuroraInsertRecord do (input: (name: string, record: tRecord, invoker: machine)) {

      records += (sizeof(records), input.record);

			if (active) {
        send input.invoker, eAuroraInsertRecordCompleted, (name = input.name, record = input.record, success = true);
      }
    }

    on eAuroraUpdateRecord do (input: (name: string, record: tRecord, invoker: machine)) {

      var record: tRecord;
      foreach(record in records)
      {
        if (record.recordId == input.record.recordId) {
          record.recordValue = input.record.recordValue;
          break;
        }
      }

			if (active) {
      	send input.invoker, eAuroraUpdateRecordCompleted, (name = input.name, record = input.record, success = true);
      }
    }

    on eAuroraDeleteRecord do (input: (name: string, recordId: int, invoker: machine)) {

      var record: tRecord;
      var counter: int;
      foreach(record in records)
      {
        if (record.recordId == input.recordId) {
          records -= counter;
          break;
        }
        counter = counter + 1;
      }

			if (active) {
      	send input.invoker, eAuroraDeleteRecordCompleted, (name = input.name, recordId = input.recordId, success = true);
      }
    }

    on eAuroraReadRecord do (input: (name: string, recordId: int, invoker: machine)) {

      var item: tRecord;
      foreach(item in records)
      {
        if (item.recordId == input.recordId) {
          send input.invoker, eAuroraReadRecordResponse, (name = name, record = item, success = true);
        }
      }
    }

    on eAuroraReadRecords do (input: (name: string, recordIds: seq[int], invoker: machine)) {

      var recordId: int;
      var record: tRecord;
      var responseRecords: seq[tRecord];
      foreach(recordId in input.recordIds) {
        foreach(record in records)
        {
          if (record.recordId == recordId) {
            responseRecords += (sizeof(responseRecords), record);
            break;
          }
        }
      }

      send input.invoker, eAuroraReadRecordsResponse, (name = name, records = responseRecords, success = true);
    }

    on eAuroraGetRecordCount do (input: (name: string, invoker: machine)) {

      send input.invoker, eAuroraGetRecordCountResponse, (name = name, recordCount = sizeof(records), success = true);
    }

		on eAuroraSwitchRegions do (input: (name: string, invoker: machine)) {

			active = !active;
			send input.invoker, eAuroraSwitchRegionsCompleted, (name = input.name, success = true);
		}

    on eAuroraFail do (input: (name: string, invoker: machine)) {

			goto FailedProcessing;
		}

		ignore eAuroraRecover;

    on eAuroraKill do (input: (name: string)) {

			raise halt;
		}
  }

	state FailedProcessing {

		defer eAuroraInsertRecord;
		defer eAuroraUpdateRecord;
		defer eAuroraDeleteRecord;
		defer eAuroraReadRecord;
		defer eAuroraReadRecords;
		defer eAuroraGetRecordCount;

		ignore eAuroraFail;

		on eAuroraRecover do (input: (name: string, invoker: machine)) {

      send input.invoker, eAuroraRecoverCompleted, (name = input.name, success = true);
			goto ProcessRecords;
		}

    on eAuroraKill do (input: (name: string)) {

			raise halt;
		}
	}
}

machine AuroraReplicator {

	var name: string;
	var database1Name: string;
	var database2Name: string;
  var database1: AuroraRegionalDatabase;
  var database2: AuroraRegionalDatabase;
  var activeRegion: int;

  start state Init {

    entry (input: (name: string, database1Name: string, database2Name: string, database1: AuroraRegionalDatabase, database2: AuroraRegionalDatabase)) {

    	name = input.name;
    	database1Name = input.database1Name;
      database1 = input.database1;
      database2Name = input.database2Name;
      database2 = input.database2;
      goto Region1Active;
    }
  }

  state Region1Active {

    entry {

    	activeRegion = 1;
    }

    on eAuroraInsertRecord do (input: (name: string, record: tRecord, invoker: machine)) {

      send database2, eAuroraInsertRecord, (name = database2Name, record = input.record, invoker =  input.invoker);
    }

    on eAuroraUpdateRecord do (input: (name: string, record: tRecord, invoker: machine)) {

      send database2, eAuroraUpdateRecord, (name = database2Name, record = input.record, invoker =  input.invoker);
    }

    on eAuroraDeleteRecord do (input: (name: string, recordId: int, invoker: machine)) {

      send database2, eAuroraDeleteRecord, (name = database2Name, recordId = input.recordId, invoker =  input.invoker);
    }

    on eAuroraSwitchRegions do (input: (name: string, invoker: machine)) {

			send input.invoker, eAuroraSwitchRegionsCompleted, (name = input.name, success = true);
      goto Region2Active;
    }

    on eAuroraFail do (input: (name: string, invoker: machine)) {

			goto FailedProcessing;
		}

		ignore eAuroraRecover;

    on eAuroraKill do (input: (name: string)) {

			raise halt;
		}
  }

  state Region2Active {

    entry {

    	activeRegion = 2;
    }

    on eAuroraInsertRecord do (input: (name: string, record: tRecord, invoker: machine)) {

      send database1, eAuroraInsertRecord, (name = database1Name, record = input.record, invoker =  input.invoker);
    }

    on eAuroraUpdateRecord do (input: (name: string, record: tRecord, invoker: machine)) {

      send database1, eAuroraUpdateRecord, (name = database1Name, record = input.record, invoker =  input.invoker);
    }

    on eAuroraDeleteRecord do (input: (name: string, recordId: int, invoker: machine)) {

      send database1, eAuroraDeleteRecord, (name = database1Name, recordId = input.recordId, invoker =  input.invoker);
    }

    on eAuroraSwitchRegions do (input: (name: string, invoker: machine)) {

			send input.invoker, eAuroraSwitchRegionsCompleted, (name = input.name, success = true);
      goto Region1Active;
    }

    on eAuroraFail do (input: (name: string, invoker: machine)) {

			goto FailedProcessing;
		}

		ignore eAuroraRecover;

    on eAuroraKill do (input: (name: string)) {

			raise halt;
		}
  }

  state FailedProcessing {

		defer eAuroraInsertRecord;
		defer eAuroraUpdateRecord;
		defer eAuroraDeleteRecord;
		defer eAuroraReadRecord;
		defer eAuroraReadRecords;
		defer eAuroraGetRecordCount;
		defer eAuroraSwitchRegions;

		ignore eAuroraFail;

		on eAuroraRecover do (input: (name: string, invoker: machine)) {

      send input.invoker, eAuroraRecoverCompleted, (name = input.name, success = true);

			if (activeRegion == 1) {
				goto Region1Active;
			}
			else {
				goto Region2Active;
			}
		}

    on eAuroraKill do (input: (name: string)) {

			raise halt;
		}
	}
}

