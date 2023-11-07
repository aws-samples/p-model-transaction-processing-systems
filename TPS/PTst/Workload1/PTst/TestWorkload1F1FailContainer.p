// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/***************************************************************
This file contains test case for workload1 active-active scenario
****************************************************************/

test tcWorkload1F1 [main=TestWorkload1F1FailContainer]:
  assert Workload1IsSafeAndLive in
  (union Workload1, { TestWorkload1F1FailContainer });

//
// Test driver that checks the system with workload1 fail-container scenario
//
// STEP 1: PUBLISH 50 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION
// STEP 2: FAIL PROCESSOR CONTAINER
// STEP 3: PUBLISH 50 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO INBOUND KAFKA
// STEP 4: RECOVER PREPROCESS CONTAINER
// STEP 5: PUBLISH 50 RECORDS AND CONFIRM THAT ALL 150 RECORDS WERE DELIVERED TO RECORD DESTINATION
//

machine TestWorkload1F1FailContainer {

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

      sizes += (0, 75);
      sizes += (1, 150);

			system = new Workload1((systemConstants = systemConstants, records = records, sizes = sizes));

			announce eSpec_Workload1_Init, (initialRecords = records, sizes = sizes);

			// ***** STEP 1: PUBLISH 50 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION

			// sign up to receive notification from record destination when it receives 50 records
			send system, eRecordDestinationDNSWeightedKafkaReceiveNotification, (name = systemConstants.recordDestinationDNSName, region = 1, count = 50, invoker = this);

			// publish 50 records, 25 to region 1 and 25 region 2
			send system, eRecordSourceDNSWeightedAPIGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 1, invoker = this);

			// wait for notification from record destination that it has received 50 records
			receive {
				case eRecordDestinationDNSWeightedKafkaReceiveNotificationResponse: (input: (name: string, region: int, count: int)) {
					print format ("Record destination received 50 records");
				}
			}

			// ***** STEP 2: FAIL PROCESSOR CONTAINER

			// fail processor container
			send system, eKafkaMongoKafkaContainerFail, (name = systemConstants.processorContainerName, region = 1);

			// ***** STEP 3: PUBLISH 50 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO INBOUND KAFKA

			// sign up to receive notification from inbound Kafka in region 1 when it receives 50 records (other 50 were delivered to region 2)
			send system, eKafkaReceiveNotification, (name = systemConstants.inboundKafkaName, region = 1, count = 50, invoker = this);

			// publish 50 records, 25 to region 1 and 25 region 2
			send system, eRecordSourceDNSWeightedAPIGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 2, invoker = this);

			// wait for notification from inbound kafka in region 1 that it has received 50 records (other 50 were delivered to region 2)
			receive {
				case eKafkaReceiveNotificationResponse: (input: (name: string, region: int, count: int, success: bool)) {
					print format ("Inbound Kafka received 50 records");
				}
			}

			// ***** STEP 4: RECOVER PREPROCESS CONTAINER

			// recover inbound preprocess container
			send system, eKafkaMongoKafkaContainerRecover, (name = systemConstants.processorContainerName, region = 1);

			// ***** STEP 5: PUBLISH 50 RECORDS AND CONFIRM THAT ALL 150 RECORDS WERE DELIVERED TO RECORD DESTINATION

			// sign up to receive notification from record destination when it receives 30 records
			send system, eRecordDestinationDNSWeightedKafkaReceiveNotification, (name = systemConstants.recordDestinationDNSName, region = 1, count = 150, invoker = this);

			// publish 50 records, 25 to region 1 and 25 region 2
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
