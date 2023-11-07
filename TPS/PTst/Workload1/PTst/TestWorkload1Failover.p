// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/***************************************************************
This file contains test case for workload1 active-active scenario
****************************************************************/

test tcWorkload1Failover [main=TestWorkload1Failover]:
  assert Workload1IsSafeAndLive in
  (union Workload1, { TestWorkload1Failover });

//
// Test driver that checks the system with standard active-active scenario
//
// STEP 1: PUBLISH 50 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION
// STEP 2: TAKE REGION 1 OFFLINE SO THAT ALL TRAFFIC IS ROUTED TO REGION 2
// STEP 3: PUBLISH 50 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION
// STEP 4: PUBLISH 50 RECORDS AND CONFIRM THAT ALL 150 RECORDS WERE DELIVERED TO RECORD DESTINATION
//

machine TestWorkload1Failover {

	var systemConstants: tWorkload1Constants;

	var recordSet1: seq[tRecord];
	var recordSet2: seq[tRecord];
	var recordSet3: seq[tRecord];
	var records: seq[seq[tRecord]];

	var sizes: seq[int];
	
	var system: Workload1;

  start state Init {

    entry {

      systemConstants = getWorkload1Constants();

			recordSet1 = CreateRecords(50, 1);
			records += (0, recordSet1);
			recordSet2 = CreateRecords(50, 51);
			records += (1, recordSet2);
			recordSet3 = CreateRecords(50, 101);
			records += (2, recordSet3);

      sizes += (0, 25);
      sizes += (1, 50);
      sizes += (2, 125);
      sizes += (3, 250);

			system = new Workload1((systemConstants = systemConstants, records = records, sizes = sizes));

			announce eSpec_Workload1_Init, (initialRecords = records, sizes = sizes);

			// ***** STEP 1: PUBLISH 50 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION

			// sign up to receive notification from record destination when it receives 50 records
			send system, eRecordDestinationDNSWeightedKafkaReceiveNotification, (name = systemConstants.recordDestinationDNSName, region = 1, count = 50, invoker = this);

			// publish 50 records, 25 to region 1 and 25 to region 2
			send system, eRecordSourceDNSWeightedAPIGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 1, invoker = this);

			// wait for notification from record destination that it has received 50 records
			receive {
				case eRecordDestinationDNSWeightedKafkaReceiveNotificationResponse: (input: (name: string, region: int, count: int)) {
					print format ("Record destination received 50 records");
				}
			}

			// ***** STEP 2: TAKE REGION 1 OFFLINE SO THAT ALL TRAFFIC IS ROUTED TO REGION 2

			// take region 1 offline for inbound dns
			send system, eRoute53DNSWeightedAPISwitchRegionOffline, (name = systemConstants.inDNSName, region = 1);

			// take region 1 offline for outbound dns
			send system, eRoute53DNSWeightedKafkaSwitchRegionOffline, (name = systemConstants.outDNSName, region = 1);

      // switch receiver database
      send system, eMongoSwitchRegions, (name = systemConstants.receiverDatabaseName, invoker=this);
      receive {
        case eMongoSwitchRegionsCompleted: (input: (name: string, success: bool)) {
          print format ("Receiver database switched");
        }
      }

      // switch validator database
      send system, eMongoSwitchRegions, (name = systemConstants.validatorDatabaseName, invoker=this);
      receive {
        case eMongoSwitchRegionsCompleted: (input: (name: string, success: bool)) {
          print format ("Validator database switched");
        }
      }

      // switch processor database
      send system, eMongoSwitchRegions, (name = systemConstants.processorDatabaseName, invoker=this);
      receive {
        case eMongoSwitchRegionsCompleted: (input: (name: string, success: bool)) {
          print format ("Processor database switched");
        }
      }

			// ***** STEP 3: PUBLISH 50 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION

			// sign up to receive notification from record destination when it receives 100 records
      send system, eRecordDestinationDNSWeightedKafkaReceiveNotification, (name = systemConstants.recordDestinationDNSName, region = 1, count = 100, invoker = this);

			// publish 50 records, 25 to region 1 and 25 to region 2
			send system, eRecordSourceDNSWeightedAPIGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 2, invoker = this);

			// wait for notification from record destination that it has received 100 records
			receive {
				case eRecordDestinationDNSWeightedKafkaReceiveNotificationResponse: (input: (name: string, region: int, count: int)) {
					print format ("Record destination received 100 records");
				}
			}

			// ***** STEP 4: PUBLISH 50 RECORDS AND CONFIRM THAT ALL 150 RECORDS WERE DELIVERED TO RECORD DESTINATION

			// sign up to receive notification from record destination when it receives 150 records
      send system, eRecordDestinationDNSWeightedKafkaReceiveNotification, (name = systemConstants.recordDestinationDNSName, region = 1, count = 150, invoker = this);

			// publish 50 records, 25 to region 1 and 25 to region 2
			send system, eRecordSourceDNSWeightedAPIGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 3, invoker = this);

			// wait for notification from record destination that it has received 150 records
			receive {
				case eRecordDestinationDNSWeightedKafkaReceiveNotificationResponse: (input: (name: string, region: int, count: int)) {
					print format ("Record destination received 150 records");
				}
			}
    }

    ignore eRecordSourceDNSWeightedAPIGenerateRecordsNotification;
  }
}
