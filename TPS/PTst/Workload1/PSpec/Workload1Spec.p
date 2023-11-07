// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/*****************************************************
Workload1 Standard Specification.
*****************************************************/

// event: initialize the monitor with the initial records when the system starts
event eSpec_Workload1_Init: (initialRecords: seq[seq[tRecord]], sizes: seq[int]);

/****************************************************************************************************************************
Active-Passive standard specification.
It verifies that all the records published by record source are delivered to each components and finally to record destination.
It also verifies that the records are delivered to each component and finally to record destination in order they are published by record source.
*****************************************************************************************************************************/

spec Workload1IsSafeAndLive observes eAPIMongoAPIContainerInvoke,  eAPIMongoKafkaContainerInvoke, eKafkaSendRecords, eKafkaReceiveRecordsResponse, eKafkaRemoveRecords, eMongoInsertRecord, eSpec_Workload1_Init {

  // records
  var records: seq[tRecord];

  // api invocations
  var apiInvocations: map[string, seq[tRecord]];

  // sent records
  var recordsSentToKafka: map[string, seq[tRecord]];

  // received records
  var recordsReceivedFromKafka: map[string, seq[tRecord]];

  // removed records
  var recordsRemovedFromKafka: map[string, seq[tRecord]];

  // stored records
  var recordsStoredInDatabase: map[string, seq[tRecord]];

  // sizes of records in various components
  var sizes : seq[int];

  start state Init {

    on eSpec_Workload1_Init goto WaitForRecords with (input: (initialRecords: seq[seq[tRecord]], sizes: seq[int])) {

      records = CombineRecords(input.initialRecords);
      sizes = input.sizes;
    }
  }

  hot state WaitForRecords {

    on eAPIMongoAPIContainerInvoke do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      var key: string;

      key = format("{0}-{1}", input.name, input.region);

      apiInvocations = addEntryIfDoesNotExist(apiInvocations, key);

      // last record may be sent again if it was not processed successfully
      if (sizeof(apiInvocations[key]) == 0 || apiInvocations[key][sizeof(apiInvocations[key]) - 1].recordId != input.record.recordId) {

				apiInvocations[key] += (sizeof(apiInvocations[key]), input.record);
      }

      PrintAllRecordsWorkload1(sizes, "receiverAPIInvocation", apiInvocations, recordsSentToKafka, recordsReceivedFromKafka, recordsRemovedFromKafka, recordsStoredInDatabase);
      if (AllRecordsProcessedWorkload1(sizes, "receiverAPIInvocation", apiInvocations, recordsSentToKafka, recordsReceivedFromKafka, recordsRemovedFromKafka, recordsStoredInDatabase)) {
        goto FinishedProcessingAllRecords;
			}
    }

    on eAPIMongoKafkaContainerInvoke do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      var key: string;

      key = format("{0}-{1}", input.name, input.region);

      apiInvocations = addEntryIfDoesNotExist(apiInvocations, key);

      // last record may be sent again if it was not processed successfully
			if (sizeof(apiInvocations[key]) == 0 || apiInvocations[key][sizeof(apiInvocations[key]) - 1].recordId != input.record.recordId) {

				apiInvocations[key] += (sizeof(apiInvocations[key]), input.record);
      }

      PrintAllRecordsWorkload1(sizes, "validatorAPIInvocation", apiInvocations, recordsSentToKafka, recordsReceivedFromKafka, recordsRemovedFromKafka, recordsStoredInDatabase);
      if (AllRecordsProcessedWorkload1(sizes, "validatorAPIInvocation", apiInvocations, recordsSentToKafka, recordsReceivedFromKafka, recordsRemovedFromKafka, recordsStoredInDatabase)) {
        goto FinishedProcessingAllRecords;
      }
    }

    on eKafkaSendRecords do (input: (name: string, region: int, records: seq[tRecord], invoker: machine)) {

      var record: tRecord;
      var key: string;

      key = format("{0}-{1}", input.name, input.region);

      recordsSentToKafka = addEntryIfDoesNotExist(recordsSentToKafka, key);

      foreach (record in input.records) {

        // last record may be sent again if it was not processed successfully
        if (sizeof(recordsSentToKafka[key]) < sizeof(input.records) || (sizeof(recordsSentToKafka[key]) >= sizeof(input.records) && recordsSentToKafka[key][sizeof(recordsSentToKafka[key]) - sizeof(input.records)].recordId != record.recordId)) {

          recordsSentToKafka[key] += (sizeof(recordsSentToKafka[key]), record);
        }
        else {
          print format ("Received Duplicate: Unexpected record received from {0} queue: [{1}, {2}], expected: [{3}, {4}]", key, record.recordId, record.recordValue, records[sizeof(recordsSentToKafka[key])].recordId, records[sizeof(recordsSentToKafka[key])].recordValue);
          break;
        }

        PrintAllRecordsWorkload1(sizes, "recordsSentToKafka", apiInvocations, recordsSentToKafka, recordsReceivedFromKafka, recordsRemovedFromKafka, recordsStoredInDatabase);
        if (AllRecordsProcessedWorkload1(sizes, "recordsSentToKafka", apiInvocations, recordsSentToKafka, recordsReceivedFromKafka, recordsRemovedFromKafka, recordsStoredInDatabase)) {
          goto FinishedProcessingAllRecords;
        }
      }
    }

    on eKafkaReceiveRecordsResponse do (input: (name: string, region: int, records: seq[tRecord], kafkaDepth: int, success: bool)) {

      var record: tRecord;
      var key: string;

      key = format("{0}-{1}", input.name, input.region);

      recordsReceivedFromKafka = addEntryIfDoesNotExist(recordsReceivedFromKafka, key);

      foreach (record in input.records) {
        if (input.success) {

          // last record may be sent again if it was not processed successfully
          if (sizeof(recordsReceivedFromKafka[key]) < sizeof(input.records) || (sizeof(recordsReceivedFromKafka[key]) >= sizeof(input.records) && recordsReceivedFromKafka[key][sizeof(recordsReceivedFromKafka[key]) - sizeof(input.records)].recordId != record.recordId)) {

              recordsReceivedFromKafka[key] += (sizeof(recordsReceivedFromKafka[key]), record);
          }
          else {
            print format ("Received Duplicate: Unexpected record received from {0} queue: [{1}, {2}], expected: [{3}, {4}]", key, record.recordId, record.recordValue, records[sizeof(recordsReceivedFromKafka[key])].recordId, records[sizeof(recordsReceivedFromKafka[key])].recordValue);
            break;
          }
        }

        PrintAllRecordsWorkload1(sizes, "recordsReceivedFromKafka", apiInvocations, recordsSentToKafka, recordsReceivedFromKafka, recordsRemovedFromKafka, recordsStoredInDatabase);
        if (AllRecordsProcessedWorkload1(sizes, "recordsReceivedFromKafka", apiInvocations, recordsSentToKafka, recordsReceivedFromKafka, recordsRemovedFromKafka, recordsStoredInDatabase)) {
          goto FinishedProcessingAllRecords;
        }
      }
    }

    on eKafkaRemoveRecords do (input: (name: string, region: int, records: seq[tRecord], invoker: machine)) {

      var record: tRecord;
      var key: string;

      key = format("{0}-{1}", input.name, input.region);

      recordsRemovedFromKafka = addEntryIfDoesNotExist(recordsRemovedFromKafka, key);

      foreach (record in input.records) {

        // last record may be sent again if it was not processed successfully
        if (sizeof(recordsRemovedFromKafka[key]) < sizeof(input.records) || (sizeof(recordsRemovedFromKafka[key]) >= sizeof(input.records) && recordsRemovedFromKafka[key][sizeof(recordsRemovedFromKafka[key]) - sizeof(input.records)].recordId != record.recordId)) {

          recordsRemovedFromKafka[key] += (sizeof(recordsRemovedFromKafka[key]), record);
        }
        else {
            print format ("Received Duplicate: Unexpected record received from {0} queue: [{1}, {2}], expected: [{3}, {4}]", key, record.recordId, record.recordValue, records[sizeof(recordsRemovedFromKafka[key])].recordId, records[sizeof(recordsRemovedFromKafka[key])].recordValue);
            break;
        }

        PrintAllRecordsWorkload1(sizes, "recordsRemovedFromKafka", apiInvocations, recordsSentToKafka, recordsReceivedFromKafka, recordsRemovedFromKafka, recordsStoredInDatabase);
        if (AllRecordsProcessedWorkload1(sizes, "recordsRemovedFromKafka", apiInvocations, recordsSentToKafka, recordsReceivedFromKafka, recordsRemovedFromKafka, recordsStoredInDatabase)) {
          goto FinishedProcessingAllRecords;
        }
      }
    }

    on eMongoInsertRecord do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      var key: string;

      key = format("{0}-{1}", input.name, input.region);

      recordsStoredInDatabase = addEntryIfDoesNotExist(recordsStoredInDatabase, key);

      if (!RecordInList(recordsStoredInDatabase[key], input.record)) {

        recordsStoredInDatabase[key] += (sizeof(recordsStoredInDatabase[key]), input.record);
      }

      PrintAllRecordsWorkload1(sizes, "recordsStoredInDatabase", apiInvocations, recordsSentToKafka, recordsReceivedFromKafka, recordsRemovedFromKafka, recordsStoredInDatabase);
      if (AllRecordsProcessedWorkload1(sizes, "recordsStoredInDatabase", apiInvocations, recordsSentToKafka, recordsReceivedFromKafka, recordsRemovedFromKafka, recordsStoredInDatabase)) {
        goto FinishedProcessingAllRecords;
      }
    }
  }

  state FinishedProcessingAllRecords {

      ignore eAPIMongoAPIContainerInvoke;
      ignore eAPIMongoKafkaContainerInvoke;
			ignore eKafkaSendRecords;
			ignore eKafkaReceiveRecords;
			ignore eKafkaReceiveRecordsResponse;
			ignore eKafkaRemoveRecords;
			ignore eMongoInsertRecord;
  }
}

// compare two records
fun AllRecordsProcessedWorkload1(sizes: seq[int],
                                 name: string,
                                 apiInvocations: map[string, seq[tRecord]],
                                 recordsSentToKafka: map[string, seq[tRecord]],
                                 recordsReceivedFromKafka: map[string, seq[tRecord]],
                                 recordsRemovedFromKafka: map[string, seq[tRecord]],
                                 recordsStoredInDatabase: map[string, seq[tRecord]]) : bool {

  if (AllRecordsProcessedInMapWorkload1(sizes, "apiInvocations", apiInvocations) &&
      AllRecordsProcessedInMapWorkload1(sizes, "recordsSentToKafka", recordsSentToKafka) &&
      AllRecordsProcessedInMapWorkload1(sizes, "recordsReceivedFromKafka", recordsReceivedFromKafka) &&
      AllRecordsProcessedInMapWorkload1(sizes, "recordsRemovedFromKafka", recordsRemovedFromKafka) &&
      AllRecordsProcessedInMapWorkload1(sizes, "recordsStoredInDatabase", recordsStoredInDatabase)) {
    return true;
  } else {
    return false;
  }
}

fun AllRecordsProcessedInMapWorkload1(sizes: seq[int],
                                      name: string,
                                      input: map[string, seq[tRecord]]) : bool {

  var key: string;
  var size: int;
  var sizeMatched: bool;

  foreach (key in keys(input)) {
    sizeMatched = false;
    foreach (size in sizes) {
      if (sizeof(input[key]) == size) {
        sizeMatched = true;
      }
    }
    if (sizeMatched == false) {
      return false;
    }
  }

  return true;
}

// print all records
fun PrintAllRecordsWorkload1(sizes: seq[int],
                             name: string,
                             apiInvocations: map[string, seq[tRecord]],
                             recordsSentToKafka: map[string, seq[tRecord]],
                             recordsReceivedFromKafka: map[string, seq[tRecord]],
                             recordsRemovedFromKafka: map[string, seq[tRecord]],
                             recordsStoredInDatabase: map[string, seq[tRecord]]){

  PrintRecordsInMapWorkload1(sizes, "apiInvocations", apiInvocations);
  PrintRecordsInMapWorkload1(sizes, "recordsSentToKafka", recordsSentToKafka);
  PrintRecordsInMapWorkload1(sizes, "recordsReceivedFromKafka", recordsReceivedFromKafka);
  PrintRecordsInMapWorkload1(sizes, "recordsRemovedFromKafka", recordsRemovedFromKafka);
  PrintRecordsInMapWorkload1(sizes, "recordsStoredInDatabase", recordsStoredInDatabase);
}

fun PrintRecordsInMapWorkload1(sizes: seq[int], name: string, input: map[string, seq[tRecord]]) {

  var key: string;
  var size: int;
  var targetSize: int;

  foreach (key in keys(input)) {

      targetSize = 0;
      foreach (size in sizes) {
        if (size >= sizeof(input[key])) {
          targetSize = size;
          break;
        }
      }

      print format ("Total records = {0}, The number of records in map {1} for key {2} = {3},  yet to be processed = {4}", targetSize, name, key, sizeof(input[key]), targetSize - sizeof(input[key]));
  }
}

