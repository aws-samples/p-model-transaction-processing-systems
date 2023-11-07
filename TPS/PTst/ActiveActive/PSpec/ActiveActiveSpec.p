// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/*****************************************************
Active-Active Standard Specification.
*****************************************************/

// event: initialize the monitor with the initial records when the system starts
event eSpec_ActiveActive_Init: (initialRecords: seq[seq[tRecord]], size1: int, size2: int);

/***********************************************************************************************************************
Active-Active standard specification.
It verifies that all the records published by record source are delivered to record destination.
It does not guarantee ordering, as records sent to regions are likely to be delivered out of order to record destination.
************************************************************************************************************************/

spec ActiveActiveIsSafeAndLive observes eQueueSendRecord,  eQueueSendRecordCompleted, eQueueReceiveRecordResponse, eQueueRemoveRecord, eDynamoInsertRecord, eSpec_ActiveActive_Init {

  // records
  var records: seq[tRecord];

  // sent records
  var recordsSentToQueue: map[string, seq[tRecord]];

  // sent records completed
  var recordsSentToQueueCompleted: map[string, seq[tRecord]];

  // received records
  var recordsReceivedFromQueue: map[string, seq[tRecord]];

  // removed records
  var recordsRemovedFromQueue: map[string, seq[tRecord]];

  // stored records
  var recordsStoredInTable: map[string, seq[tRecord]];

  // region 1 max
  var region1Size: int;

  // region 2 max
  var region2Size: int;

  start state Init {

    on eSpec_ActiveActive_Init goto WaitForRecords with (input: (initialRecords: seq[seq[tRecord]], size1: int, size2: int)) {

      records = CombineRecords(input.initialRecords);
      region1Size = input.size1;
      region2Size = input.size2;
    }
  }

  hot state WaitForRecords {

    on eQueueSendRecord do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      var key: string;

      key = format("{0}-{1}", input.name, input.region);

      recordsSentToQueue = addEntryIfDoesNotExist(recordsSentToQueue, key);

      // last record may be sent to queue again if it was not processed successfully
      if (sizeof(recordsSentToQueue[key]) == 0 || recordsSentToQueue[key][sizeof(recordsSentToQueue[key]) - 1].recordId != input.record.recordId) {

				recordsSentToQueue[key] += (sizeof(recordsSentToQueue[key]), input.record);
      }

      PrintAllRecords2(region1Size, region2Size, "recordsSentToQueue", recordsSentToQueue, recordsSentToQueueCompleted, recordsReceivedFromQueue, recordsRemovedFromQueue, recordsStoredInTable);
      if (AllRecordsProcessed2(region1Size, region2Size, "recordsSentToQueue", recordsSentToQueue, recordsSentToQueueCompleted, recordsReceivedFromQueue, recordsRemovedFromQueue, recordsStoredInTable)) {
        goto FinishedProcessingAllRecords;
      }
    }

    on eQueueSendRecordCompleted do (input: (name: string, region: int, record: tRecord, success: bool)) {

      var key: string;

      key = format("{0}-{1}", input.name, input.region);

      recordsSentToQueueCompleted = addEntryIfDoesNotExist(recordsSentToQueueCompleted, key);

      // last record may be sent to queue again if it was not processed successfully
      if (sizeof(recordsSentToQueueCompleted[key]) == 0 || recordsSentToQueueCompleted[key][sizeof(recordsSentToQueueCompleted[key]) - 1].recordId != input.record.recordId) {

				recordsSentToQueueCompleted[key] += (sizeof(recordsSentToQueueCompleted[key]), input.record);
      }

      PrintAllRecords2(region1Size, region2Size, "recordsSentToQueue", recordsSentToQueue, recordsSentToQueueCompleted, recordsReceivedFromQueue, recordsRemovedFromQueue, recordsStoredInTable);
      if (AllRecordsProcessed2(region1Size, region2Size, "recordsSentToQueue", recordsSentToQueue, recordsSentToQueueCompleted, recordsReceivedFromQueue, recordsRemovedFromQueue, recordsStoredInTable)) {
        goto FinishedProcessingAllRecords;
      }
    }

    on eQueueReceiveRecordResponse do (input: (name: string, region: int, record: tRecord, queueDepth: int, success: bool)) {

      var key: string;

      key = format("{0}-{1}", input.name, input.region);

			if (input.success) {

        recordsReceivedFromQueue = addEntryIfDoesNotExist(recordsReceivedFromQueue, key);

        // last record may be sent to queue again if it was not processed successfully
        if (sizeof(recordsReceivedFromQueue[key]) == 0 || recordsReceivedFromQueue[key][sizeof(recordsReceivedFromQueue[key]) - 1].recordId != input.record.recordId) {

			    recordsReceivedFromQueue[key] += (sizeof(recordsReceivedFromQueue[key]), input.record);
			  }

				PrintAllRecords2(region1Size, region2Size, "recordsReceivedFromQueue", recordsSentToQueue, recordsSentToQueueCompleted, recordsReceivedFromQueue, recordsRemovedFromQueue, recordsStoredInTable);
				if (AllRecordsProcessed2(region1Size, region2Size, "recordsReceivedFromQueue", recordsSentToQueue, recordsSentToQueueCompleted, recordsReceivedFromQueue, recordsRemovedFromQueue, recordsStoredInTable)) {
				  goto FinishedProcessingAllRecords;
				}
      }
    }

    on eQueueRemoveRecord do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      var key: string;

      key = format("{0}-{1}", input.name, input.region);

      recordsRemovedFromQueue = addEntryIfDoesNotExist(recordsRemovedFromQueue, key);

      // last record may be sent to queue again if it was not processed successfully
      if (sizeof(recordsRemovedFromQueue[key]) == 0 || recordsRemovedFromQueue[key][sizeof(recordsRemovedFromQueue[key]) - 1].recordId != input.record.recordId) {

				recordsRemovedFromQueue[key] += (sizeof(recordsRemovedFromQueue[key]), input.record);
      }

      PrintAllRecords2(region1Size, region2Size, "recordsRemovedFromQueue", recordsSentToQueue, recordsSentToQueueCompleted, recordsReceivedFromQueue, recordsRemovedFromQueue, recordsStoredInTable);
      if (AllRecordsProcessed2(region1Size, region2Size, "recordsRemovedFromQueue", recordsSentToQueue, recordsSentToQueueCompleted, recordsReceivedFromQueue, recordsRemovedFromQueue, recordsStoredInTable)) {
        goto FinishedProcessingAllRecords;
      }
    }

    on eDynamoInsertRecord do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      var key: string;

      key = format("{0}-{1}", input.name, input.region);

      recordsStoredInTable = addEntryIfDoesNotExist(recordsStoredInTable, key);

      // last record may be sent to database again if it was not processed successfully
      if (sizeof(recordsStoredInTable[key]) == 0 || recordsStoredInTable[key][sizeof(recordsStoredInTable[key]) - 1].recordId != input.record.recordId) {

				recordsStoredInTable[key] += (sizeof(recordsStoredInTable[key]), input.record);
			}

      PrintAllRecords2(region1Size, region2Size, "recordsStoredInTable", recordsSentToQueue, recordsSentToQueueCompleted, recordsReceivedFromQueue, recordsRemovedFromQueue, recordsStoredInTable);
      if (AllRecordsProcessed2(region1Size, region2Size, "recordsStoredInTable", recordsSentToQueue, recordsSentToQueueCompleted, recordsReceivedFromQueue, recordsRemovedFromQueue, recordsStoredInTable)) {
        goto FinishedProcessingAllRecords;
			}
    }
  }

  state FinishedProcessingAllRecords {

			ignore eQueueSendRecord;
			ignore eQueueReceiveRecord;
			ignore eQueueReceiveRecordResponse;
			ignore eQueueRemoveRecord;
  }
}

// compare two records
fun AllRecordsProcessed2(size1: int,
                         size2: int,
                         name: string,
                         recordsSentToQueue: map[string, seq[tRecord]],
                         recordsSentToQueueCompleted: map[string, seq[tRecord]],
                         recordsReceivedFromQueue: map[string, seq[tRecord]],
                         recordsRemovedFromQueue: map[string, seq[tRecord]],
                         recordsStoredInDatabase: map[string, seq[tRecord]]) : bool {

  if (AllRecordsProcessedInMap2(size1, size2, "recordsSentToQueue", recordsSentToQueue) &&
      AllRecordsProcessedInMap2(size1, size2, "recordsSentToQueueCompleted", recordsSentToQueueCompleted) &&
      AllRecordsProcessedInMap2(size1, size2, "recordsReceivedFromQueue", recordsReceivedFromQueue) &&
      AllRecordsProcessedInMap2(size1, size2, "recordsRemovedFromQueue", recordsRemovedFromQueue) &&
      AllRecordsProcessedInMap2(size1, size2, "recordsStoredInDatabase", recordsStoredInDatabase)) {
    return true;
  } else {
    return false;
  }
}

fun AllRecordsProcessedInMap2(size1: int,
                              size2: int,
                              name: string,
                              input: map[string, seq[tRecord]]) : bool {

  var key: string;
  var countSize1: int;
  var countSize2: int;

  if (size1 == size2) {
    foreach (key in keys(input)) {
      if (sizeof(input[key]) != size1) {
        return false;
      }
    }
  }
  else {
    foreach (key in keys(input)) {
      if (sizeof(input[key]) != size1 && sizeof(input[key]) != size2) {
        return false;
      }
      else if (sizeof(input[key]) == size1) {
        countSize1 = countSize1 + 1;
      }
      else if (sizeof(input[key]) == size2) {
        countSize2 = countSize2 + 1;
      }
    }

    if (countSize1 != countSize2) {
      return false;
    }
  }

  return true;
}

// print all records
fun PrintAllRecords2(size1: int,
                     size2: int,
                     name: string,
                     recordsSentToQueue: map[string, seq[tRecord]],
                     recordsSentToQueueCompleted: map[string, seq[tRecord]],
                     recordsReceivedFromQueue: map[string, seq[tRecord]],
                     recordsRemovedFromQueue: map[string, seq[tRecord]],
                     recordsStoredInDatabase: map[string, seq[tRecord]]){

  PrintRecordsInMap2(size1, size2, "recordsSentToQueue", recordsSentToQueue);
  PrintRecordsInMap2(size1, size2, "recordsSentToQueueCompleted", recordsSentToQueueCompleted);
  PrintRecordsInMap2(size1, size2, "recordsReceivedFromQueue", recordsReceivedFromQueue);
  PrintRecordsInMap2(size1, size2, "recordsRemovedFromQueue", recordsRemovedFromQueue);
  PrintRecordsInMap2(size1, size2, "recordsStoredInDatabase", recordsStoredInDatabase);
}

fun PrintRecordsInMap2(size1: int, size2: int, name: string, input: map[string, seq[tRecord]]){

  var key: string;
  foreach (key in keys(input)) {
      if (sizeof(input[key]) <= size1) {
        print format ("Total records = {0}, The number of records in map {1} for key {2} = {3},  yet to be processed = {4}", size1, name, key, sizeof(input[key]), size1 - sizeof(input[key]));
      }
      else {
        print format ("Total records = {0}, The number of records in map {1} for key {2} = {3},  yet to be processed = {4}", size2, name, key, sizeof(input[key]), size2 - sizeof(input[key]));
      }
  }
}


