// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/**********************************************************************
Record Destination as a State Machine that reads messages from a queue
***********************************************************************/
machine RecordDestinationQueue {

  var name: string;
  var region: int;
  var inQueueName: string;
  var inQueue: Queue;
  var records: seq[tRecord];

  start state Init {

    entry (input: (name: string, region: int, inQueueName: string, inQueue: Queue)) {

      name = input.name;
      region = input.region;
      inQueueName = input.inQueueName;
      inQueue = input.inQueue;
      goto ProcessRecords;
    }
  }

  state ProcessRecords {

    entry {
      send inQueue, eQueueReceiveRecord, (name = inQueueName, region = region, invoker = this);
    }

    on eQueueReceiveRecordResponse do (input: (name: string, region: int, record: tRecord, queueDepth: int, success: bool)) {

      records += (sizeof(records), input.record);
      send inQueue, eQueueRemoveRecord, (name = inQueueName, region = region, record = input.record, invoker = this);
      receive {
				case eQueueRemoveRecordCompleted: (input: (name: string, region: int, record: tRecord, success: bool)) {
				}
			}
      goto ProcessRecords;
    }
  }
}
