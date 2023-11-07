// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/*****************************************************************
This file contains test case for active-passive-failover scenarios
******************************************************************/

test tcActivePassiveFailover [main=TestActivePassiveFailover]:
  assert ActivePassiveIsSafeAndLive in
  (union ActivePassive, { TestActivePassiveFailover });

//
// Test driver that checks the system with active-passive-failover scenario
//
// STEP 1: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO INBOUND PREPROCESS QUEUE
// STEP 2: SWITCH REGIONS
// STEP 3: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION
// STEP 4: PUBLISH 10 RECORDS AND CONFIRM THAT ALL 30 RECORDS WERE DELIVERED TO RECORD DESTINATION
//

machine TestActivePassiveFailover {

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

			// ***** STEP 1: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO INBOUND PREPROCESS QUEUE

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

			// ***** STEP 2: SWITCH REGIONS

			// switch regions for inbound DNS
			send system, eRoute53DNSFailoverQueueSwitchRegions, (name = systemConstants.inDNSName, );

			// switch regions for inbound database
			send system, eAuroraSwitchRegions, (name = systemConstants.inboundDatabaseName, invoker = this);
			receive {
				case eAuroraSwitchRegionsCompleted: (input: (name: string, success: bool)) {
					print format ("{0} switch regions completed", input.name);
				}
			}

			// switch regions for preprocess database
			send system, eAuroraSwitchRegions, (name = systemConstants.preprocessDatabaseName, invoker = this);
			receive {
				case eAuroraSwitchRegionsCompleted: (input: (name: string, success: bool)) {
					print format ("{0} switch regions completed", input.name);
				}
			}

			// switch regions for core database
			send system, eAuroraSwitchRegions, (name = systemConstants.coreDatabaseName, invoker = this);
			receive {
				case eAuroraSwitchRegionsCompleted: (input: (name: string, success: bool)) {
					print format ("{0} switch regions completed", input.name);
				}
			}

			// switch regions for post process database
			send system, eAuroraSwitchRegions, (name = systemConstants.postprocessDatabaseName, invoker = this);
			receive {
				case eAuroraSwitchRegionsCompleted: (input: (name: string, success: bool)) {
					print format ("{0} switch regions completed", input.name);
				}
			}

			// switch regions for outbound database
			send system, eAuroraSwitchRegions, (name = systemConstants.outboundDatabaseName, invoker = this);
			receive {
				case eAuroraSwitchRegionsCompleted: (input: (name: string, success: bool)) {
					print format ("{0} switch regions completed", input.name);
				}
			}

			// switch regions for outbound DNS
			send system, eRoute53DNSFailoverQueueSwitchRegions, (name = systemConstants.outDNSName, );

			// ***** STEP 3: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION

			// sign up to receive notification from record destination when it receives 20 records
      send system, eRecordDestinationDNSFailoverQueueReceiveNotification, (name = systemConstants.recordDestinationDNSName, region = 1, count = 20, invoker = this);

      // publish 10 records
			send system, eRecordSourceDNSFailoverQueueGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 2, invoker = this);

			// wait for notification from record destination that it has received 10 records
			receive {
				case eRecordDestinationDNSFailoverQueueReceiveNotificationResponse: (input: (name: string, region: int, count: int)) {
					print format ("Record destination received 20 records");
				}
			}

			// ***** STEP 4: PUBLISH 10 RECORDS AND CONFIRM THAT ALL 30 RECORDS WERE DELIVERED TO RECORD DESTINATION

			// sign up to receive notification from record destination when it receives 30 records
      send system, eRecordDestinationDNSFailoverQueueReceiveNotification, (name = systemConstants.recordDestinationDNSName, region = 1, count = 30, invoker = this);

			// publish 10 records
			send system, eRecordSourceDNSFailoverQueueGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 3, invoker = this);

			// wait for notification from record destination that it has received 30 records
			receive {
				case eRecordDestinationDNSFailoverQueueReceiveNotificationResponse: (input: (name: string, region: int, count: int)) {
					print format ("Record destination received 30 records");
				}
			}
    }

    ignore eRecordSourceDNSFailoverQueueGenerateRecordsNotification;
  }
}