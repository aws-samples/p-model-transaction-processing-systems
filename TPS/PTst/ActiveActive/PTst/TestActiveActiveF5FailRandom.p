// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/********************************************************************
This file contains test case for active-active-fail-random scenario
*********************************************************************/

test tcActiveActiveF5 [main=TestActiveActiveF5FailRandom]:
  assert ActiveActiveIsSafeAndLive in
  (union ActiveActive, { TestActiveActiveF5FailRandom });

// Test driver that checks the system with active-active-fail-random scenario
// There are 16 components (queue, container & databases) across 5 micro services that can potentially fail
// It randomly fails a subset of these 16 components using following logic:
// STEP 1: DETERMINE HOW MANY COMPONENTS TO FAIL OUT OF THE 16 COMPONENTS THAT MAY FAIL
// STEP 2: DETERMINE WHICH OF THE 16 COMPONENTS TO FAIL
// STEP 3: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION
// STEP 4: FAIL THE COMPONENTS THAT WERE IDENTIFIED TO BE FAILED IN STEP 1 AND 2
// STEP 5: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE PUBLISHED BY RECORD SOURCE
// STEP 6: RECOVER THE COMPONENTS THAT WERE FAILED IN STEP 4
// STEP 7: PUBLISH 10 RECORDS AND CONFIRM THAT ALL 30 RECORDS WERE DELIVERED TO RECORD DESTINATION
//
// The various components are assigned the following serial number during the randomization process
// 1. inbound queue
// 2. inbound container
// 3. inbound database
// 4. inbound preprocess queue
// 5. preprocess container
// 6. preprocess database
// 7. preprocess core queue
// 8. core container
// 9. core database
// 10. core postprocess queue
// 11. postprocess container
// 12. postprocess database
// 13. postprocess outbound queue
// 14. outbound container
// 15. outbound database
// 16. outbound queue
machine TestActiveActiveF5FailRandom {

	var systemConstants: tActiveActiveConstants;

	var recordSet1: seq[tRecord];
	var recordSet2: seq[tRecord];
	var recordSet3: seq[tRecord];
	var records: seq[seq[tRecord]];

	var system: ActiveActive;

	var failCount: int;
	var failIndex: int;
	var failIndexes: seq[int];
	var i: int;
	var foundNew: bool;
	var publishingSuccessful: bool;
	
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

			// ***** STEP 1: DETERMINE HOW MANY COMPONENTS TO FAIL OUT OF THE 16 COMPONENTS THAT MAY FAIL

			// determine how many components to fail out of the 16 components that may fail
			failCount = choose(16) + 1;

			// ***** STEP 2: DETERMINE WHICH OF THE 16 COMPONENTS TO FAIL

			// once it decides how many components to fail, it randomly determines which of the 16 components to fail
			print format ("Fail Count: {0}", failCount);
			i = 0;
			while(i < failCount) {

				foundNew = false;
				while (!foundNew) {
					failIndex = choose(16) + 1;
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

			// ***** STEP 3: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION

			// sign up to receive notification from record destination when it receives 10 records
			send system, eRecordDestinationDNSWeightedQueueReceiveNotification, (name = systemConstants.recordDestinationDNSName, region = 1, count = 10, invoker = this);

			// publish 10 records, 5 to region 1 and 5 to region 2
			send system, eRecordSourceDNSWeightedQueueGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 1, invoker = this);

			// wait for notification from record source that it has generated 10 records that are part of 1st batch
			receive {
				case eRecordSourceDNSWeightedQueueGenerateRecordsNotification: (input: (name: string, region: int, batch: int, count: int, success: bool)) {
					print format ("Record source published 10 records");
				}
			}

			// wait for notification from record destination that it has received 10 records
			receive {
				case eRecordDestinationDNSWeightedQueueReceiveNotificationResponse: (input: (name: string, region: int, count: int)) {
					print format ("Record destination received 10 records");
				}
			}

			// ***** STEP 4: FAIL THE COMPONENTS THAT WERE IDENTIFIED TO BE FAILED IN STEP 1 AND 2

			i = 1;
			while(i <= 16) {
				if (i in failIndexes) {
					print format ("Fail Index: {0}", i);
					if (i == 1) {
						send system, eQueueFail, (name = systemConstants.inboundQueueName,  region = 1, invoker = this);
						receive {
							case eQueueFailCompleted: (input: (name: string, region: int)) {
								print format ("Inbound fail queue completed");
							}
						}
					}
					else if (i == 2) {
						send system, eQueueDynamoQueueContainerFail, (name = systemConstants.inboundContainerName, region = 1);
					}
					else if (i == 3) {
						send system, eDynamoFail, (name = systemConstants.inboundTableName,  );
          }
          else if (i == 4) {
          	send system, eQueueFail, (name = systemConstants.inboundPreprocessQueueName,  region = 1, invoker = this);
						receive {
							case eQueueFailCompleted: (input: (name: string, region: int)) {
								print format ("Inbound-Preprocess fail queue completed");
							}
						}
          }
					else if (i == 5) {
						send system, eQueueDynamoQueueContainerFail, (name = systemConstants.preprocessContainerName, region = 1);
					}
					else if (i == 6) {
						send system, eDynamoFail, (name = systemConstants.preprocessTableName,  );
          }
          else if (i == 7) {
          	send system, eQueueFail, (name = systemConstants.preprocessCoreQueueName,  region = 1, invoker = this);
						receive {
							case eQueueFailCompleted: (input: (name: string, region: int)) {
								print format ("Preprocess-Core fail queue completed");
							}
						}
          }
					else if (i == 8) {
						send system, eQueueDynamoQueueContainerFail, (name = systemConstants.coreContainerName, region = 1);
					}
					else if (i == 9) {
						send system, eDynamoFail, (name = systemConstants.coreTableName,  );
          }
          else if (i == 10) {
          	send system, eQueueFail, (name = systemConstants.corePostprocessQueueName,  region = 1, invoker = this);
						receive {
							case eQueueFailCompleted: (input: (name: string, region: int)) {
								print format ("Core-Postprocess fail queue completed");
							}
						}
          }
					else if (i == 11) {
						send system, eQueueDynamoQueueContainerFail, (name = systemConstants.postprocessContainerName, region = 1);
					}
					else if (i == 12) {
						send system, eDynamoFail, (name = systemConstants.postprocessTableName,  );
          }
          else if (i == 13) {
          	send system, eQueueFail, (name = systemConstants.postprocessOutboundQueueName,  region = 1, invoker = this);
						receive {
							case eQueueFailCompleted: (input: (name: string, region: int)) {
								print format ("Postprocess-Outbound fail queue completed");
							}
						}
          }
					else if (i == 14) {
						send system, eQueueDynamoQueueContainerFail, (name = systemConstants.outboundContainerName, region = 1);
					}
					else if (i == 15) {
						send system, eDynamoFail, (name = systemConstants.outboundTableName,  );
          }
          else if (i == 16) {
          	send system, eQueueFail, (name = systemConstants.outboundQueueName,  region = 1, invoker = this);
						receive {
							case eQueueFailCompleted: (input: (name: string, region: int)) {
								print format ("Outbound fail queue completed");
							}
						}
          }
				}
				i= i + 1;
			}

			// ***** STEP 5: PUBLISH 10 RECORDS AND CONFIRM THAT THEY WERE PUBLISHED BY RECORD SOURCE

			// publish 10 records, 5 to region 1 and 5 to region 2
			send system, eRecordSourceDNSWeightedQueueGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 2, invoker = this);

      publishingSuccessful = false;
			// wait for notification from record source that it has generated 10 records that are part of 2nd batch
			receive {
				case eRecordSourceDNSWeightedQueueGenerateRecordsNotification: (input: (name: string, region: int, batch: int, count: int, success: bool)) {
				  publishingSuccessful = input.success;
					print format ("Record source published 20 records");
				}
			}

			// ***** STEP 6: RECOVER THE COMPONENTS THAT WERE FAILED IN STEP 4

			// recover queues and databases
			i = 1;
			while(i <= 16) {
				if (i in failIndexes) {
					print format ("Recover Index: {0}", i);
					if (i == 1) {
						send system, eQueueRecover, (name = systemConstants.inboundQueueName,  region = 1);
					}
					else if (i == 3) {
						send system, eDynamoRecover, (name = systemConstants.inboundTableName,  );
					}
					else if (i == 4) {
						send system, eQueueRecover, (name = systemConstants.inboundPreprocessQueueName,  region = 1);
					}
					else if (i == 6) {
						send system, eDynamoRecover, (name = systemConstants.preprocessTableName,  );
					}
					else if (i == 7) {
						send system, eQueueRecover, (name = systemConstants.preprocessCoreQueueName,  region = 1);
					}
					else if (i == 9) {
						send system, eDynamoRecover, (name = systemConstants.coreTableName,  );
					}
					else if (i == 10) {
						send system, eQueueRecover, (name = systemConstants.corePostprocessQueueName,  region = 1);
					}
					else if (i == 12) {
						send system, eDynamoRecover, (name = systemConstants.postprocessTableName,  );
					}
					else if (i == 13) {
						send system, eQueueRecover, (name = systemConstants.postprocessOutboundQueueName,  region = 1);
					}
					else if (i == 15) {
						send system, eDynamoRecover, (name = systemConstants.outboundTableName,  );
					}
					else if (i == 16) {
						send system, eQueueRecover, (name = systemConstants.outboundQueueName,  region = 1);
					}
				}
				i = i + 1;
			}

			// recover containers
			send system, eQueueDynamoQueueContainerRecover, (name = systemConstants.inboundContainerName, region = 1);
			send system, eQueueDynamoQueueContainerRecover, (name = systemConstants.preprocessContainerName, region = 1);
			send system, eQueueDynamoQueueContainerRecover, (name = systemConstants.coreContainerName, region = 1);
			send system, eQueueDynamoQueueContainerRecover, (name = systemConstants.postprocessContainerName, region = 1);
			send system, eQueueDynamoQueueContainerRecover, (name = systemConstants.outboundContainerName, region = 1);

			// complete publication from record source in case it was interrupted when inbound queue was failed
			if (publishingSuccessful == false) {
				send system, eRecordSourceDNSWeightedQueueGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 2, invoker = this);
			}

			// ***** STEP 7: PUBLISH 10 RECORDS AND CONFIRM THAT ALL 30 RECORDS WERE DELIVERED TO RECORD DESTINATION

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