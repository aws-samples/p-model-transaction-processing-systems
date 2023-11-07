// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/*****************************************************
Active-Passive Standard Specification.
*****************************************************/

// event: initialize the monitor with the initial records when the system starts
event eSpec_ActivePassive_Init: seq[seq[tRecord]];

/****************************************************************************************************************************
Active-Passive standard specification.
It verifies that all the records published by record source are delivered to each components and finally to record destination.
It also verifies that the records are delivered to each component and finally to record destination in order they are published by record source.
*****************************************************************************************************************************/

spec ActivePassiveIsSafeAndLive observes eQueueSendRecord,  eQueueSendRecordCompleted, eQueueReceiveRecordResponse, eQueueRemoveRecord, eAuroraInsertRecord, eSpec_ActivePassive_Init {

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
  var recordsStoredInDatabase: map[string, seq[tRecord]];

  start state Init {

    on eSpec_ActivePassive_Init goto WaitForRecords with (initialRecords: seq[seq[tRecord]]) {

      records = CombineRecords(initialRecords);
    }
  }

  hot state WaitForRecords {

    on eQueueSendRecord do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      recordsSentToQueue = addEntryIfDoesNotExist(recordsSentToQueue, input.name);

      // last record may be sent to queue again if it was not processed successfully
      if (sizeof(recordsSentToQueue[input.name]) == 0 || records[sizeof(recordsSentToQueue[input.name]) -1].recordId != input.record.recordId) {

        assert CompareRecords(records[sizeof(recordsSentToQueue[input.name])], input.record),
          format ("Unexpected record sent to {0} queue: [{1}, {2}], expected: [{3}, {4}]", input.name, input.record.recordId, input.record.recordValue, records[sizeof(recordsSentToQueue[input.name])].recordId, records[sizeof(recordsSentToQueue[input.name])].recordValue);

        recordsSentToQueue[input.name] += (sizeof(recordsSentToQueue[input.name]), input.record);
      }

      PrintAllRecords(sizeof(records), "recordsSentToQueue", recordsSentToQueue, recordsSentToQueueCompleted, recordsReceivedFromQueue, recordsRemovedFromQueue, recordsStoredInDatabase);
      if (AllRecordsProcessed(sizeof(records), "recordsSentToQueue", recordsSentToQueue, recordsSentToQueueCompleted, recordsReceivedFromQueue, recordsRemovedFromQueue, recordsStoredInDatabase)) {
        goto FinishedProcessingAllRecords;
      }
    }

    on eQueueSendRecordCompleted do (input: (name: string, region: int, record: tRecord, success: bool)) {

      if (input.success == true) {

        recordsSentToQueueCompleted = addEntryIfDoesNotExist(recordsSentToQueueCompleted, input.name);

        assert CompareRecords(records[sizeof(recordsSentToQueueCompleted[input.name])], input.record),
          format ("Unexpected record sent to {0} queue: [{1}, {2}], expected: [{3}, {4}]", input.name, input.record.recordId, input.record.recordValue, records[sizeof(recordsSentToQueueCompleted[input.name])].recordId, records[sizeof(recordsSentToQueueCompleted[input.name])].recordValue);

        recordsSentToQueueCompleted[input.name] += (sizeof(recordsSentToQueueCompleted[input.name]), input.record);

        PrintAllRecords(sizeof(records), "recordsSentToQueue", recordsSentToQueue, recordsSentToQueueCompleted, recordsReceivedFromQueue, recordsRemovedFromQueue, recordsStoredInDatabase);
        if (AllRecordsProcessed(sizeof(records), "recordsSentToQueue", recordsSentToQueue, recordsSentToQueueCompleted, recordsReceivedFromQueue, recordsRemovedFromQueue, recordsStoredInDatabase)) {
          goto FinishedProcessingAllRecords;
        }
      }
    }

    on eQueueReceiveRecordResponse do (input: (name: string, region: int, record: tRecord, queueDepth: int, success: bool)) {

			if (input.success) {

        recordsReceivedFromQueue = addEntryIfDoesNotExist(recordsReceivedFromQueue, input.name);
        recordsRemovedFromQueue = addEntryIfDoesNotExist(recordsRemovedFromQueue, input.name);

        if (sizeof(recordsReceivedFromQueue[input.name]) == 0 || records[sizeof(recordsReceivedFromQueue[input.name]) -1].recordId != input.record.recordId) {
          assert (records[sizeof(recordsRemovedFromQueue[input.name])].recordId == input.record.recordId),
            format ("Unexpected record received from {0} queue: [{1}, {2}], expected: [{3}, {4}]", input.name, input.record.recordId, input.record.recordValue, records[sizeof(recordsRemovedFromQueue[input.name])].recordId, records[sizeof(recordsRemovedFromQueue[input.name])].recordValue);

          recordsReceivedFromQueue[input.name] += (sizeof(recordsReceivedFromQueue[input.name]), input.record);
        }

        PrintAllRecords(sizeof(records), "recordsReceivedFromQueue", recordsSentToQueue, recordsSentToQueueCompleted, recordsReceivedFromQueue, recordsRemovedFromQueue, recordsStoredInDatabase);
        if (AllRecordsProcessed(sizeof(records), "recordsReceivedFromQueue", recordsSentToQueue, recordsSentToQueueCompleted, recordsReceivedFromQueue, recordsRemovedFromQueue, recordsStoredInDatabase)) {
          goto FinishedProcessingAllRecords;
        }
      }
    }

    on eQueueRemoveRecord do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      recordsRemovedFromQueue = addEntryIfDoesNotExist(recordsRemovedFromQueue, input.name);

      assert CompareRecords(records[sizeof(recordsRemovedFromQueue[input.name])], input.record),
        format ("Unexpected record removed from {0} queue: [{1}, {2}], expected: [{3}, {4}]", input.name, input.record.recordId, input.record.recordValue, records[sizeof(recordsRemovedFromQueue[input.name])].recordId, records[sizeof(recordsRemovedFromQueue[input.name])].recordValue);
      recordsRemovedFromQueue[input.name] += (sizeof(recordsRemovedFromQueue[input.name]), input.record);

      print format ("Removed record: {0} from queue: {1}", input.name, input.record.recordId);

      PrintAllRecords(sizeof(records), "recordsRemovedFromQueue", recordsSentToQueue, recordsSentToQueueCompleted, recordsReceivedFromQueue, recordsRemovedFromQueue, recordsStoredInDatabase);
      if (AllRecordsProcessed(sizeof(records), "recordsRemovedFromQueue", recordsSentToQueue, recordsSentToQueueCompleted, recordsReceivedFromQueue, recordsRemovedFromQueue, recordsStoredInDatabase)) {
        goto FinishedProcessingAllRecords;
      }
    }

    on eAuroraInsertRecord do (input: (name: string, record: tRecord, invoker: machine)) {

      recordsStoredInDatabase = addEntryIfDoesNotExist(recordsStoredInDatabase, input.name);

      // last record may be sent to database again if it was not processed successfully
      if (sizeof(recordsStoredInDatabase[input.name]) == 0 || records[sizeof(recordsStoredInDatabase[input.name]) -1].recordId != input.record.recordId) {
        assert CompareRecords(records[sizeof(recordsStoredInDatabase[input.name])], input.record),
          format ("Unexpected record sent to {0} database: [{1}, {2}], expected: [{3}, {4}]", input.name, input.record.recordId, input.record.recordValue, records[sizeof(recordsStoredInDatabase[input.name])].recordId, records[sizeof(recordsStoredInDatabase[input.name])].recordValue);

        recordsStoredInDatabase[input.name] += (sizeof(recordsStoredInDatabase[input.name]), input.record);
      }

      PrintAllRecords(sizeof(records), "recordsStoredInDatabase", recordsSentToQueue, recordsSentToQueueCompleted, recordsReceivedFromQueue, recordsRemovedFromQueue, recordsStoredInDatabase);
      if (AllRecordsProcessed(sizeof(records), "recordsStoredInDatabase", recordsSentToQueue, recordsSentToQueueCompleted, recordsReceivedFromQueue, recordsRemovedFromQueue, recordsStoredInDatabase)) {
        goto FinishedProcessingAllRecords;
      }
    }
  }

  state FinishedProcessingAllRecords {

			ignore eQueueSendRecord;
			ignore eQueueSendRecordCompleted;
			ignore eQueueReceiveRecord;
			ignore eQueueReceiveRecordResponse;
			ignore eQueueRemoveRecord;
			ignore eAuroraInsertRecord;
  }
}

// compare two records
fun AllRecordsProcessed(size: int,
                        name: string,
                        recordsSentToQueue: map[string, seq[tRecord]],
                        recordsSentToQueueCompleted: map[string, seq[tRecord]],
                        recordsReceivedFromQueue: map[string, seq[tRecord]],
                        recordsRemovedFromQueue: map[string, seq[tRecord]],
                        recordsStoredInDatabase: map[string, seq[tRecord]]) : bool {

  if (AllRecordsProcessedInMap(size, "recordsSentToQueue", recordsSentToQueue) &&
      AllRecordsProcessedInMap(size, "recordsSentToQueueCompleted", recordsSentToQueueCompleted) &&
      AllRecordsProcessedInMap(size, "recordsReceivedFromQueue", recordsReceivedFromQueue) &&
      AllRecordsProcessedInMap(size, "recordsRemovedFromQueue", recordsRemovedFromQueue) &&
      AllRecordsProcessedInMap(size, "recordsStoredInDatabase", recordsStoredInDatabase)) {
    return true;
  } else {
    return false;
  }
}

fun AllRecordsProcessedInMap(size: int, name: string, input: map[string, seq[tRecord]]) : bool {

  var key: string;
  foreach (key in keys(input)) {
    if (sizeof(input[key]) != size) {
      return false;
    }
  }

  return true;
}

// print all records
fun PrintAllRecords(size: int,
                    name: string,
                    recordsSentToQueue: map[string, seq[tRecord]],
                    recordsSentToQueueCompleted: map[string, seq[tRecord]],
                    recordsReceivedFromQueue: map[string, seq[tRecord]],
                    recordsRemovedFromQueue: map[string, seq[tRecord]],
                    recordsStoredInDatabase: map[string, seq[tRecord]]){

  PrintRecordsInMap(size, "recordsSentToQueue", recordsSentToQueue);
  PrintRecordsInMap(size, "recordsSentToQueueCompleted", recordsSentToQueueCompleted);
  PrintRecordsInMap(size, "recordsReceivedFromQueue", recordsReceivedFromQueue);
  PrintRecordsInMap(size, "recordsRemovedFromQueue", recordsRemovedFromQueue);
  PrintRecordsInMap(size, "recordsStoredInDatabase", recordsStoredInDatabase);
}

fun PrintRecordsInMap(size: int, name: string, input: map[string, seq[tRecord]]){

  var key: string;
  foreach (key in keys(input)) {
      print format ("Total records = {0}, The number of records in map {1} for key {2} = {3},  yet to be processed = {4}", size, name, key, sizeof(input[key]), size - sizeof(input[key]));
  }
}

