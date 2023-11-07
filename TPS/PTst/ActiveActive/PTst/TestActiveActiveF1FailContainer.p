// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/*********************************************************************
This file contains test driver for active-active-fail-container scenario
**********************************************************************/

test tcActiveActiveF1 [main=TestActiveActiveF1FailContainer]:
  assert ActiveActiveIsSafeAndLive in
  (union ActiveActive, { TestActiveActiveF1FailContainer });

//
// Test driver that checks the system with active-active-fail-container scenario
//
// STEP 1: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION
// STEP 2: FAIL PREPROCESS CONTAINER
// STEP 3: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO INBOUND-PREPROCESS QUEUE
// STEP 4: RECOVER PREPROCESS CONTAINER
// STEP 5: PUBLISH 10 RECORDS AND CONFIRM THAT ALL 30 RECORDS WERE DELIVERED TO RECORD DESTINATION
//

machine TestActiveActiveF1FailContainer {

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

			// ***** STEP 2: FAIL PREPROCESS CONTAINER

			// fail preprocess container
			send system, eQueueDynamoQueueContainerFail, (name = systemConstants.preprocessContainerName, region = 1);

			// ***** STEP 3: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO INBOUND-PREPROCESS QUEUE

			// sign up to receive notification from inbound-preprocess queue in region 1 when it receives 10 records (other 10 were delivered to region 2)
			send system, eQueueReceiveNotification, (name = systemConstants.inboundPreprocessQueueName, region = 1, count = 10, invoker = this);

			// publish 10 records, 5 to region 1 and 5 region 2
			send system, eRecordSourceDNSWeightedQueueGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 2, invoker = this);

			// wait for notification from inbound-preprocess queue in region 1 that it has received 10 records (other 10 were delivered to region 2)
			receive {
				case eQueueReceiveNotificationResponse: (input: (name: string, region: int, count: int, success: bool)) {
					print format ("Inbound-Preprocess queue received 10 records");
				}
			}

			// ***** STEP 4: RECOVER PREPROCESS CONTAINER

			// recover inbound preprocess container
			send system, eQueueDynamoQueueContainerRecover, (name = systemConstants.preprocessContainerName, region = 1);

			// ***** STEP 5: PUBLISH 10 RECORDS AND CONFIRM THAT ALL 30 RECORDS WERE DELIVERED TO RECORD DESTINATION

			// sign up to receive notification from record destination when it receives 30 records
			send system, eRecordDestinationDNSWeightedQueueReceiveNotification, (name = systemConstants.recordDestinationDNSName, region = 1, count = 30, invoker = this);

			// publish 10 records, 5 to region 1 and 5 region 2
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