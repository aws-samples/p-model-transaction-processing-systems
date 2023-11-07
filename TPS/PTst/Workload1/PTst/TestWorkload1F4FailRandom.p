// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/***************************************************************
This file contains test case for workload1 active-active scenario
****************************************************************/

test tcWorkload1F4 [main=TestWorkload1F4FailRandom]:
  assert Workload1IsSafeAndLive in
  (union Workload1, { TestWorkload1F4FailRandom });

//
// Test driver that checks the system with workload1 fail-container scenario
//
// There are 8 components (kafka, container & databases) across 3 micro services that can potentially fail
// It randomly fails a subset of these 8 components using following logic:
// STEP 1: DETERMINE HOW MANY COMPONENTS TO FAIL OUT OF THE 8 COMPONENTS THAT MAY FAIL
// STEP 2: DETERMINE WHICH OF THE 8 COMPONENTS TO FAIL
// STEP 3: PUBLISH 50 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION
// STEP 4: FAIL THE COMPONENTS THAT WERE IDENTIFIED TO BE FAILED IN STEP 1 AND 2
// STEP 5: PUBLISH 50 RECORDS AND CONFIRM THAT THEY WERE PUBLISHED BY RECORD SOURCE
// STEP 6: RECOVER THE COMPONENTS THAT WERE FAILED IN STEP 4
// STEP 7: PUBLISH 50 RECORDS AND CONFIRM THAT ALL 150 RECORDS WERE DELIVERED TO RECORD DESTINATION
//
// The various components are assigned the following serial number during the randomization process
// 1. receiver container
// 2. receiver database
// 3. validator container
// 4. validator database
// 5. inbound kafka
// 6. processor container
// 7. process database
// 8. outbound kafka
//

machine TestWorkload1F4FailRandom {

	var systemConstants: tWorkload1Constants;

	var recordSet1: seq[tRecord];
	var recordSet2: seq[tRecord];
	var recordSet3: seq[tRecord];
	var records: seq[seq[tRecord]];

	var sizes: seq[int];
	
	var system: Workload1;

	var failCount: int;
	var failIndex: int;
	var failIndexes: seq[int];
	var i: int;
	var foundNew: bool;
	var publishingSuccessful: bool;

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

			// ***** STEP 1: DETERMINE HOW MANY COMPONENTS TO FAIL OUT OF THE 8 COMPONENTS THAT MAY FAIL

			// determine how many components to fail out of the 8 components that may fail
			failCount = choose(8) + 1;
//      failCount = 3;

			// ***** STEP 2: DETERMINE WHICH OF THE 8 COMPONENTS TO FAIL

			// once it decides how many components to fail, it randomly determines which of the 8 components to fail
			print format ("Fail Count: {0}", failCount);
			i = 0;
			while(i < failCount) {

				foundNew = false;
				while (!foundNew) {
					failIndex = choose(8) + 1;
					print format ("Fail Index: {0}", failIndex);
					if (failIndex in failIndexes) {
						print format ("Fail Index: False");
						foundNew = false;
					}
					else {
						print format ("Fail Index: True");
						foundNew = true;
						failIndexes += (i, failIndex);
						i = i + 1;
					}
				}
			}

			// ***** STEP 3: PUBLISH 50 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION

			// sign up to receive notification from record destination when it receives 50 records
     	send system, eRecordDestinationDNSWeightedKafkaReceiveNotification, (name = systemConstants.recordDestinationDNSName, region = 1, count = 50, invoker = this);

			// publish 50 records, 25 region 1 and 25 to region 2
			send system, eRecordSourceDNSWeightedAPIGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 1, invoker = this);

			// wait for notification from record source that it has generated 50 records that are part of 1st batch
			receive {
				case eRecordSourceDNSWeightedAPIGenerateRecordsNotification: (input: (name: string, region: int, batch: int, count: int, success: bool)) {
					print format ("Record source published 50 records");
				}
			}

			// wait for notification from record destination that it has received 50 records
			receive {
				case eRecordDestinationDNSWeightedKafkaReceiveNotificationResponse: (input: (name: string, region: int, count: int)) {
					print format ("Record destination received 50 records");
				}
			}

			// ***** STEP 4: FAIL THE COMPONENTS THAT WERE IDENTIFIED TO BE FAILED IN STEP 1 AND 2

			i = 1;
			while(i <= 8) {
				if (i in failIndexes) {
					print format ("Fail Index: {0}", i);
					if (i == 1) {
						send system, eAPIMongoAPIContainerFail, (name = systemConstants.receiverContainerName,  region = 1);
					}
					else if (i == 2) {
						send system, eMongoFail, (name = systemConstants.receiverDatabaseName, );
					}
					else if (i == 3) {
						send system, eAPIMongoKafkaContainerFail, (name = systemConstants.validatorContainerName,  region = 1);
          }
          else if (i == 4) {
          	send system, eMongoFail, (name = systemConstants.validatorDatabaseName, );
          }
					else if (i == 5) {
						send system, eKafkaFail, (name = systemConstants.inboundKafkaName,  region = 1, invoker = this);
            receive {
              case eKafkaFailCompleted: (input: (name: string, region: int)) {
                print format ("Inbound kafka fail completed");
              }
            }
					}
					else if (i == 6) {
						send system, eKafkaMongoKafkaContainerFail, (name = systemConstants.processorContainerName,  region = 1);
          }
          else if (i == 7) {
          	send system, eMongoFail, (name = systemConstants.processorDatabaseName, );
          }
          else if (i == 8) {
						send system, eKafkaFail, (name = systemConstants.outboundKafkaName,  region = 1, invoker = this);
            receive {
              case eKafkaFailCompleted: (input: (name: string, region: int)) {
                print format ("Outbound kafka fail completed");
              }
            }
          }
				}
				i= i + 1;
			}

			// ***** STEP 5: PUBLISH 50 RECORDS AND CONFIRM THAT THEY WERE PUBLISHED BY RECORD SOURCE

			// publish 50 records, 25 to region 1 and 25 to region 2
			send system, eRecordSourceDNSWeightedAPIGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 2, invoker = this);

      publishingSuccessful = false;
			// wait for notification from record source that it has generated 50 records that are part of 2nd batch
			receive {
				case eRecordSourceDNSWeightedAPIGenerateRecordsNotification: (input: (name: string, region: int, batch: int, count: int, success: bool)) {
				  publishingSuccessful = input.success;
					print format ("Record source published 100 records");
				}
			}

			// ***** STEP 6: RECOVER THE COMPONENTS THAT WERE FAILED IN STEP 4

			// recover queues and databases
			i = 1;
			while(i <= 8) {
				if (i in failIndexes) {
					print format ("Fail Index: {0}", i);
					if (i == 1) {
						send system, eAPIMongoAPIContainerRecover, (name = systemConstants.receiverContainerName,  region = 1);
					}
					else if (i == 2) {
						send system, eMongoRecover, (name = systemConstants.receiverDatabaseName, );
					}
					else if (i == 3) {
						send system, eAPIMongoKafkaContainerRecover, (name = systemConstants.validatorContainerName,  region = 1);
          }
          else if (i == 4) {
          	send system, eMongoRecover, (name = systemConstants.validatorDatabaseName, );
          }
					else if (i == 5) {
						send system, eKafkaRecover, (name = systemConstants.inboundKafkaName,  region = 1);
					}
					else if (i == 6) {
						send system, eKafkaMongoKafkaContainerRecover, (name = systemConstants.processorContainerName,  region = 1);
          }
          else if (i == 7) {
          	send system, eMongoRecover, (name = systemConstants.processorDatabaseName, );
          }
          else if (i == 8) {
						send system, eKafkaRecover, (name = systemConstants.outboundKafkaName,  region = 1);
          }
				}
				i= i + 1;
			}

			// recover containers
			send system, eAPIMongoAPIContainerRecover, (name = systemConstants.receiverContainerName,  region = 1);
			send system, eAPIMongoKafkaContainerRecover, (name = systemConstants.validatorContainerName,  region = 1);
			send system, eKafkaMongoKafkaContainerRecover, (name = systemConstants.processorContainerName,  region = 1);
			send system, eKafkaMongoKafkaContainerRecover, (name = systemConstants.processorContainerName,  region = 2);


			// complete publication from record source in case it was interrupted when inbound queue was failed
			if (publishingSuccessful == false) {
				send system, eRecordSourceDNSWeightedAPIGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 2, invoker = this);
			}

			// ***** STEP 7: PUBLISH 50 RECORDS AND CONFIRM THAT ALL 150 RECORDS WERE DELIVERED TO RECORD DESTINATION

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
