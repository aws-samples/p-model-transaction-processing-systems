// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/***************************************************************
This file contains test case for standard active-active scenario
****************************************************************/

test tcActiveActive [main=TestActiveActive]:
  assert ActiveActiveIsSafeAndLive in
  (union ActiveActive, { TestActiveActive });

//
// Test driver that checks the system with standard active-active scenario
//
// STEP 1: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION
//

machine TestActiveActive {

	var systemConstants: tActiveActiveConstants;

	var recordSet: seq[tRecord];
	var records: seq[seq[tRecord]];

	var system: ActiveActive;

  start state Init {

    entry {

			systemConstants = getActiveActiveConstants();

			recordSet = CreateRecords(10, 1);
			records += (0, recordSet);

			system = new ActiveActive((systemConstants = systemConstants, records = records));
			
			announce eSpec_ActiveActive_Init, (initialRecords = records, size1 = 5, size2 = 5);

			// ***** STEP 1: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION

			// sign up to receive notification from record destination when it receives 10 records
			send system, eRecordDestinationDNSWeightedQueueReceiveNotification, (name = systemConstants.recordDestinationDNSName, region = 1, count = 10, invoker = this);

			// publish 10 records
			send system, eRecordSourceDNSWeightedQueueGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 1, invoker = this);

			// wait for notification from record destination that it has received 10 records
			receive {
				case eRecordDestinationDNSWeightedQueueReceiveNotificationResponse: (input: (name: string, region: int, count: int)) {
					print format ("Record destination received 10 records");
				}
			}
    }

    ignore eRecordSourceDNSWeightedQueueGenerateRecordsNotification;
  }
}
