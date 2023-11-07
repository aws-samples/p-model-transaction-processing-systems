// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/*********************************************************************
This file contains test case for active-passive-fail-replication scenario
**********************************************************************/

test tcActivePassiveF4 [main=TestActivePassiveF4FailReplication]:
  assert ActivePassiveIsSafeAndLive in
  (union ActivePassive, { TestActivePassiveF4FailReplication });

//
// Test driver that checks the system with active-passive-fail-replication scenario
//
// STEP 1: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION
// STEP 2: FAIL DATABASE REPLICATION IN ALL DATABASES
// STEP 3: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION
// STEP 4: RECOVER DATABASE REPLICATION IN ALL DATABASES
// STEP 5: PUBLISH 10 RECORDS AND CONFIRM THAT ALL 30 RECORDS WERE DELIVERED TO RECORD DESTINATION
//

machine TestActivePassiveF4FailReplication {

	var systemConstants: tActivePassiveConstants;

	var recordSet1: seq[tRecord];
	var recordSet2: seq[tRecord];
	var recordSet3: seq[tRecord];
	var records: seq[seq[tRecord]];

	var system: ActivePassive;

  start state Init {

    entry {

      systemConstants = getActivePassiveConstants();

			recordSet1 = CreateRecords(10, 1);
			records += (0, recordSet1);
			recordSet2 = CreateRecords(10, 11);
			records += (1, recordSet2);
			recordSet3 = CreateRecords(10, 21);
			records += (2, recordSet3);

			system = new ActivePassive((systemConstants = systemConstants, records = records));

			announce eSpec_ActivePassive_Init, records;

			// ***** STEP 1: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION

			// sign up to receive notification from record destination when it receives 10 records
			send system, eRecordDestinationDNSFailoverQueueReceiveNotification, (name = systemConstants.recordDestinationDNSName, region = 1, count = 10, invoker = this);

			// publish 10 records
			send system, eRecordSourceDNSFailoverQueueGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 1, invoker = this);

			// wait for notification from record destination that it has received 10 records
			receive {
				case eRecordDestinationDNSFailoverQueueReceiveNotificationResponse: (input: (name: string, region: int, count: int)) {
					print format ("Destination received 10 records");
				}
			}

			// ***** STEP 2: FAIL DATABASE REPLICATION IN ALL DATABASES

			// fail database replication in inbound, preprocess, core, postprocess and outbound databases
			send system, eAuroraFailReplication, (name = systemConstants.inboundDatabaseName,  invoker = this);
			receive {
				case eAuroraFailReplicationCompleted: (input: (name: string)) {
					print format ("Inbound database fail completed");
				}
			}
			send system, eAuroraFailReplication, (name = systemConstants.preprocessDatabaseName, invoker = this);
			receive {
				case eAuroraFailReplicationCompleted: (input: (name: string)) {
					print format ("Preprocess database fail completed");
				}
			}
			send system, eAuroraFailReplication, (name = systemConstants.coreDatabaseName, invoker = this);
			receive {
				case eAuroraFailReplicationCompleted: (input: (name: string)) {
					print format ("Core database fail completed");
				}
			}
			send system, eAuroraFailReplication, (name = systemConstants.postprocessDatabaseName, invoker = this);
			receive {
				case eAuroraFailReplicationCompleted: (input: (name: string)) {
					print format ("Postprocess database fail completed");
				}
			}
			send system, eAuroraFailReplication, (name = systemConstants.outboundDatabaseName, invoker = this);
			receive {
				case eAuroraFailReplicationCompleted: (input: (name: string)) {
					print format ("Outbound database fail completed");
				}
			}

			// ***** STEP 3: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION

			// sign up to receive notification from record destination when it receives 20 records
			send system, eRecordDestinationDNSFailoverQueueReceiveNotification, (name = systemConstants.recordDestinationDNSName, region = 1, count = 20, invoker = this);

			// publish 10 records
			send system, eRecordSourceDNSFailoverQueueGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 2, invoker = this);

			// wait for notification from record destination that it has received 20 records
			receive {
				case eRecordDestinationDNSFailoverQueueReceiveNotificationResponse: (input: (name: string, region: int, count: int)) {
					print format ("Destination received 20 records");
				}
			}

			// ***** STEP 4: RECOVER DATABASE REPLICATION IN ALL DATABASES

			// recover database replication in inbound, preprocess, core, postprocess and outbound databases
			send system, eAuroraRecoverReplication, (name = systemConstants.inboundDatabaseName,  );
			send system, eAuroraRecoverReplication, (name = systemConstants.preprocessDatabaseName,  );
			send system, eAuroraRecoverReplication, (name = systemConstants.coreDatabaseName,  );
			send system, eAuroraRecoverReplication, (name = systemConstants.postprocessDatabaseName,  );
			send system, eAuroraRecoverReplication, (name = systemConstants.outboundDatabaseName,  );

			// ***** STEP 5: PUBLISH 10 RECORDS AND CONFIRM THAT ALL 30 RECORDS WERE DELIVERED TO RECORD DESTINATION

			// sign up to receive notification from record destination when it receives 30 records
			send system, eRecordDestinationDNSFailoverQueueReceiveNotification, (name = systemConstants.recordDestinationDNSName, region = 1, count = 30, invoker = this);

			// publish 10 records
			send system, eRecordSourceDNSFailoverQueueGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 3, invoker = this);

			// wait for notification from record destination that it has received 30 records
			receive {
				case eRecordDestinationDNSFailoverQueueReceiveNotificationResponse: (input: (name: string, region: int, count: int)) {
					print format ("Destination received 30 records");
				}
			}
    }

    ignore eRecordSourceDNSFailoverQueueGenerateRecordsNotification;
  }
}