// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/***********************************************************************
This file contains test case for active-active-fail-database scenario
************************************************************************/

test tcActiveActiveF2 [main=TestActiveActiveF2FailDatabase]:
  assert ActiveActiveIsSafeAndLive in
  (union ActiveActive, { TestActiveActiveF2FailDatabase });

//
// Test driver that checks the system with active-active-fail-database scenario
//
// STEP 1: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION
// STEP 2: FAIL PREPROCESS DATABASE
// STEP 3: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO INBOUND-PREPROCESS QUEUE
// STEP 4: RECOVER PREPROCESS DATABASE
// STEP 5: RESUME PREPROCESS CONTAINER AS IT MIGHT HAVE GONE DOWN WHEN DATABASE RETURNED AN ERROR MESSAGE WHILE TRYING TO INSERT A RECORD
// STEP 6: PUBLISH 10 RECORDS AND CONFIRM THAT ALL 30 RECORDS WERE DELIVERED TO RECORD DESTINATION
//

machine TestActiveActiveF2FailDatabase {

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

			// publish 10 records, 5 region 1 and 5 to region 2
			send system, eRecordSourceDNSWeightedQueueGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 1, invoker = this);

			// wait for notification from record destination that it has received 10 records
			receive {
				case eRecordDestinationDNSWeightedQueueReceiveNotificationResponse: (input: (name: string, region: int, count: int)) {
					print format ("Record destination received 10 records");
				}
			}

			// ***** STEP 2: FAIL PREPROCESS DATABASE

			// fail preprocess database
			send system, eDynamoFail, (name = systemConstants.preprocessTableName,  );

			// ***** STEP 3: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO INBOUND-PREPROCESS QUEUE

			// sign up to receive notification from inbound-preprocess queue when it receives 10 records (checking that inbound-preprocess queue got 10 records as preprocess container will go down before processing 10 records, when database returns failure when trying to insert records) (other 10 were delivered to region 2)
			send system, eQueueReceiveNotification, (name = systemConstants.inboundPreprocessQueueName, region = 1, count = 10, invoker = this);

			// publish 10 records, 5 region 1 and 5 to region 2
			send system, eRecordSourceDNSWeightedQueueGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 2, invoker = this);

			// wait for notification from inbound-preprocess queue that it has received 10 records (other 10 were delivered to region 2)
			receive {
				case eQueueReceiveNotificationResponse: (input: (name: string, region: int, count: int, success: bool)) {
					print format ("Inbound-Preprocess queue1 received 10 records");
				}
			}

			// ***** STEP 4: RECOVER PREPROCESS DATABASE

			// recover preprocess database
			send system, eDynamoRecover, (name = systemConstants.preprocessTableName, );

			// ***** STEP 5: RESUME PREPROCESS CONTAINER AS IT MIGHT HAVE GONE DOWN WHEN DATABASE RETURNED AN ERROR MESSAGE WHILE TRYING TO INSERT A RECORD

			// recover preprocess container
			send system, eQueueDynamoQueueContainerRecover, (name = systemConstants.preprocessContainerName, region = 1);

			// ***** STEP 6: PUBLISH 10 RECORDS AND CONFIRM THAT ALL 30 RECORDS WERE DELIVERED TO RECORD DESTINATION

			// sign up to receive notification from record destination when it receives 30 records
			send system, eRecordDestinationDNSWeightedQueueReceiveNotification, (name = systemConstants.recordDestinationDNSName, region = 1, count = 30, invoker = this);

			// publish 10 records
			send system, eRecordSourceDNSWeightedQueueGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 3, invoker = this);

			// wait for notification from record destination that it has received 30 records
			receive {
				case eRecordDestinationDNSWeightedQueueReceiveNotificationResponse: (input: (name: string, region: int, count: int)) {
					print format ("Record destination received 30 records");
				}
			}
    }

    ignore eRecordSourceDNSWeightedQueueGenerateRecordsNotification;
  }
}