// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/****************************************************************
This file contains test case for standard active-passive scenario
*****************************************************************/

test tcActivePassive [main=TestActivePassive]:
  assert ActivePassiveIsSafeAndLive in
  (union ActivePassive, { TestActivePassive });

//
// Test driver that checks the system with standard active-passive scenario
//
// STEP 1: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION
//

machine TestActivePassive {

	var systemConstants: tActivePassiveConstants;

	var recordSet: seq[tRecord];
	var records: seq[seq[tRecord]];

	var system: ActivePassive;

  start state Init {

    entry {

			systemConstants = getActivePassiveConstants();

			recordSet = CreateRecords(10, 1);
			records += (0, recordSet);

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
					print format ("Record destination received 10 records");
				}
			}
    }

    ignore eRecordSourceDNSFailoverQueueGenerateRecordsNotification;
  }
}
