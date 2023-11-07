// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/************************************************
Record Source that publishes records to a queue
*************************************************/

// event: generate records to the queue
event eRecordSourceQueueGenerateRecords;

/******************************************************************
Record Source as a State Machine that publishes records to a Queue
*******************************************************************/
machine RecordSourceQueue {

  var name: string;
  var region: int;
  var outQueueName: string;
  var outQueue: Queue;
  var records: seq[tRecord];

  start state Init {

    entry (input: (name: string, region: int, outQueueName: string, outQueue: Queue, records: seq[tRecord])) {

       name = input.name;
       region = input.region;
       outQueueName = input.outQueueName;
       outQueue = input.outQueue;
       records = input.records;
    }

    on eRecordSourceQueueGenerateRecords do {

      var record: tRecord;
      foreach(record in records) {
        send outQueue, eQueueSendRecord, (name = outQueueName, region = region, record = record, invoker = this);
				receive {
					case eQueueSendRecordCompleted: (input: (name: string, region: int, record: tRecord, success: bool)) {
					}
				}
      }
    }
  }
}
