// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/*****************************************************************
This file contains test case for active-active-failover scenario
******************************************************************/

test tcActiveActiveFailover [main=TestActiveActiveFailover]:
  assert ActiveActiveIsSafeAndLive in
  (union ActiveActive, { TestActiveActiveFailover });

//
// Test driver that checks the system with active-active-failover scenario
//
// STEP 1: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION
// STEP 2: TAKE REGION 1 OFFLINE SO THAT ALL TRAFFIC IS ROUTED TO REGION 2
// STEP 3: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION
// STEP 4: PUBLISH 10 RECORDS AND CONFIRM THAT ALL 30 RECORDS WERE DELIVERED TO RECORD DESTINATION
//

machine TestActiveActiveFailover {

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

			announce eSpec_ActiveActive_Init, (initialRecords = records, size1 = 5, size2 = 25);

			// ***** STEP 1: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION

			// sign up to receive notification from record destination when it receives 10 records
			send system, eRecordDestinationDNSWeightedQueueReceiveNotification, (name = systemConstants.recordDestinationDNSName, region = 1, count = 10, invoker = this);

			// publish 10 records, 5 to region 1 and 5 to region 2
			send system, eRecordSourceDNSWeightedQueueGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 1, invoker = this);

			// wait for notification from record destination that it has received 10 records
			receive {
				case eRecordDestinationDNSWeightedQueueReceiveNotificationResponse: (input: (name: string, region: int, count: int)) {
					print format ("Record destination received 10 records");
				}
			}

			// ***** STEP 2: TAKE REGION 1 OFFLINE SO THAT ALL TRAFFIC IS ROUTED TO REGION 2

			// take region 1 offline for inbound dns
			send system, eRoute53DNSWeightedQueueSwitchRegionOffline, (name = systemConstants.inDNSName, region = 1);

			// take region 1 offline for outbound dns
			send system, eRoute53DNSWeightedQueueSwitchRegionOffline, (name = systemConstants.outDNSName, region = 1);

			// ***** STEP 3: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION

			// sign up to receive notification from record destination when it receives 20 records
      send system, eRecordDestinationDNSWeightedQueueReceiveNotification, (name = systemConstants.recordDestinationDNSName, region = 1, count = 20, invoker = this);

			// publish 10 records, 5 to region 1 and 5 to region 2
			send system, eRecordSourceDNSWeightedQueueGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 2, invoker = this);

			// wait for notification from record destination that it has received 10 records
			receive {
				case eRecordDestinationDNSWeightedQueueReceiveNotificationResponse: (input: (name: string, region: int, count: int)) {
					print format ("Record destination received 20 records");
				}
			}

			// ***** STEP 4: PUBLISH 10 RECORDS AND CONFIRM THAT ALL 30 RECORDS WERE DELIVERED TO RECORD DESTINATION

			// sign up to receive notification from record destination when it receives 30 records
      send system, eRecordDestinationDNSWeightedQueueReceiveNotification, (name = systemConstants.recordDestinationDNSName, region = 1, count = 30, invoker = this);

			// publish 10 records, 5 to region 1 and 5 to region 2
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