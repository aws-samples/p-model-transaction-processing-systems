// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/***********************************************************************
This file contains test case for active-active-fail-replication scenario
************************************************************************/

test tcActiveActiveF4 [main=TestActiveActiveF4FailReplication]:
  assert ActiveActiveIsSafeAndLive in
  (union ActiveActive, { TestActiveActiveF4FailReplication });

//
// Test driver that checks the system with active-active-fail-replication scenario
//
// STEP 1: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION
// STEP 2: FAIL DATABASE REPLICATION IN ALL DATABASES
// STEP 3: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION
// STEP 4: RECOVER DATABASE REPLICATION IN ALL DATABASES
// STEP 5: PUBLISH 10 RECORDS AND CONFIRM THAT ALL 30 RECORDS WERE DELIVERED TO RECORD DESTINATION
//

machine TestActiveActiveF4FailReplication {

	var systemConstants: tActiveActiveConstants;

	var recordSet1: seq[tRecord];
	var recordSet2: seq[tRecord];
	var recordSet3: seq[tRecord];
	var records: seq[seq[tRecord]];

	var system: ActiveActive;

  start state Init {

    entry {

			systemConstants = getActiveActiveConstants();

			recordSet1 = CreateRecords(10, 1);
			records += (0, recordSet1);
			recordSet2 = CreateRecords(10, 11);
			records += (1, recordSet2);
			recordSet3 = CreateRecords(10, 21);
			records += (2, recordSet3);

			system = new ActiveActive((systemConstants = systemConstants, records = records));

			announce eSpec_ActiveActive_Init, (initialRecords = records, size1 = 15, size2 = 15);

			// ***** STEP 1: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION

			// sign up to receive notification from record destination when it receives 10 records
			send system, eRecordDestinationDNSWeightedQueueReceiveNotification, (name = systemConstants.recordDestinationDNSName, region = 1, count = 10, invoker = this);

			// publish 10 records, 5 to region 1 and 5 region 2
			send system, eRecordSourceDNSWeightedQueueGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 1, invoker = this);

			// wait for notification from record destination that it has received 10 records
			receive {
				case eRecordDestinationDNSWeightedQueueReceiveNotificationResponse: (input: (name: string, region: int, count: int)) {
					print format ("Record destination received 10 records");
				}
			}

			// ***** STEP 2: FAIL DATABASE REPLICATION IN ALL DATABASES

			// fail database replication in inbound, preprocess, core, postprocess and outbound databases
			send system, eDynamoFailReplication, (name = systemConstants.inboundTableName,  );
			send system, eDynamoFailReplication, (name = systemConstants.preprocessTableName,  );
			send system, eDynamoFailReplication, (name = systemConstants.coreTableName,  );
			send system, eDynamoFailReplication, (name = systemConstants.postprocessTableName,  );
			send system, eDynamoFailReplication, (name = systemConstants.outboundTableName,  );

			// ***** STEP 3: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION

			// sign up to receive notification from record destination when it receives 20 records
			send system, eRecordDestinationDNSWeightedQueueReceiveNotification, (name = systemConstants.recordDestinationDNSName, region = 1, count = 20, invoker = this);

			// publish 10 records, 5 to region 1 and 5 region 2
			send system, eRecordSourceDNSWeightedQueueGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 2, invoker = this);

			// wait for notification from record destination that it has received 20 records
			receive {
				case eRecordDestinationDNSWeightedQueueReceiveNotificationResponse: (input: (name: string, region: int, count: int)) {
					print format ("Record destination received 10 records");
				}
			}

			// ***** STEP 4: RECOVER DATABASE REPLICATION IN ALL DATABASES

			// recover database replication in inbound, preprocess, core, postprocess and outbound databases
			send system, eDynamoRecoverReplication, (name = systemConstants.inboundTableName,  );
			send system, eDynamoRecoverReplication, (name = systemConstants.preprocessTableName,  );
			send system, eDynamoRecoverReplication, (name = systemConstants.coreTableName,  );
			send system, eDynamoRecoverReplication, (name = systemConstants.postprocessTableName,  );
			send system, eDynamoRecoverReplication, (name = systemConstants.outboundTableName,  );

			// ***** STEP 5: PUBLISH 10 RECORDS AND CONFIRM THAT ALL 30 RECORDS WERE DELIVERED TO RECORD DESTINATION

			// sign up to receive notification from record destination when it receives 30 records
			send system, eRecordDestinationDNSWeightedQueueReceiveNotification, (name = systemConstants.recordDestinationDNSName, region = 1, count = 30, invoker = this);

			// publish 10 records, 5 to region 1 and 5 region 2
			send system, eRecordSourceDNSWeightedQueueGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 3, invoker = this);

			// wait for notification from record destination that it has received 30 records
			receive {
				case eRecordDestinationDNSWeightedQueueReceiveNotificationResponse: (input: (name: string, region: int, count: int)) {
					print format ("Record destination received 10 records");
				}
			}
    }

    ignore eRecordSourceDNSWeightedQueueGenerateRecordsNotification;
  }
}