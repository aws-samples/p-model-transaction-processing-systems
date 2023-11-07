// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/***************************************************************
This file contains test case for workload1 active-active scenario
****************************************************************/

test tcWorkload1F2 [main=TestWorkload1F2FailDatabase]:
  assert Workload1IsSafeAndLive in
  (union Workload1, { TestWorkload1F2FailDatabase });

//
// Test driver that checks the system with workload1 fail-container scenario
//
// STEP 1: PUBLISH 50 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION
// STEP 2: FAIL PROCESSOR DATABASE
// STEP 3: PUBLISH 50 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO INBOUND KAFKA
// STEP 4: RECOVER PROCESSOR DATABASE
// STEP 5: RECOVER PROCESSOR CONTAINER AS IT MIGHT HAVE GONE DOWN WHEN DATABASE RETURNED AN ERROR MESSAGE WHILE TRYING TO INSERT A RECORD
// STEP 6: PUBLISH 50 RECORDS AND CONFIRM THAT ALL 150 RECORDS WERE DELIVERED TO RECORD DESTINATION
//

machine TestWorkload1F2FailDatabase {

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

			// publish 50 records, 25 region 1 and 25 to region 2
			send system, eRecordSourceDNSWeightedAPIGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 1, invoker = this);

			// wait for notification from record destination that it has received 50 records
			receive {
				case eRecordDestinationDNSWeightedKafkaReceiveNotificationResponse: (input: (name: string, region: int, count: int)) {
					print format ("Record destination received 50 records");
				}
			}

			// ***** STEP 2: FAIL PROCESSOR DATABASE

			// fail processor database
			send system, eMongoFail, (name = systemConstants.processorDatabaseName,  );

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

			// ***** STEP 4: RECOVER PROCESSOR DATABASE

			// recover processor database
			send system, eMongoRecover, (name = systemConstants.processorDatabaseName, );

			// ***** STEP 5: RECOVER PROCESSOR CONTAINER AS IT MIGHT HAVE GONE DOWN WHEN DATABASE RETURNED AN ERROR MESSAGE WHILE TRYING TO INSERT A RECORD

			// recover processor container
			send system, eKafkaMongoKafkaContainerRecover, (name = systemConstants.processorContainerName, region = 1);
			send system, eKafkaMongoKafkaContainerRecover, (name = systemConstants.processorContainerName, region = 2);

			// ***** STEP 6: PUBLISH 50 RECORDS AND CONFIRM THAT ALL 150 RECORDS WERE DELIVERED TO RECORD DESTINATION

			// sign up to receive notification from record destination when it receives 150 records
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
