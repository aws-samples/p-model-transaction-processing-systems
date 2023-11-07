// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/***************************************************************
This file contains test case for workload1 active-active scenario
****************************************************************/

test tcWorkload1 [main=TestWorkload1]:
  assert Workload1IsSafeAndLive in
  (union Workload1, { TestWorkload1 });

//
// Test driver that checks the system with standard active-active scenario
//
// STEP 1: PUBLISH 50 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION
//

machine TestWorkload1 {

	var systemConstants: tWorkload1Constants;

	var recordSet: seq[tRecord];
	var records: seq[seq[tRecord]];

	var sizes: seq[int];
	
	var system: Workload1;

  start state Init {

    entry {

			systemConstants = getWorkload1Constants();

			recordSet = CreateRecords(50, 1);
			records += (0, recordSet);

      sizes += (0, 25);
      sizes += (1, 50);

			system = new Workload1((systemConstants = systemConstants, records = records, sizes = sizes));

			announce eSpec_Workload1_Init, (initialRecords = records, sizes = sizes);

			// ***** STEP 1: PUBLISH 50 RECORDS AND CONFIRM THAT THEY WERE DELIVERED TO RECORD DESTINATION

			// sign up to receive notification from record destination when it receives 50 records
			send system, eRecordDestinationDNSWeightedKafkaReceiveNotification, (name = systemConstants.recordDestinationDNSName, region = 1, count = 50, invoker = this);

			// publish 50 records
			send system, eRecordSourceDNSWeightedAPIGenerateRecords, (name = systemConstants.recordSourceDNSName, region = 1, batch = 1, invoker = this);

			// wait for notification from record destination that it has received 50 records
			receive {
				case eRecordDestinationDNSWeightedKafkaReceiveNotificationResponse: (input: (name: string, region: int, count: int)) {
					print format ("Record destination received 50 records");
				}
			}
    }

    ignore eRecordSourceDNSWeightedAPIGenerateRecordsNotification;
  }
}
