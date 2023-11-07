// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/************************************************
Record Source that publishes records to a queue
*************************************************/

// event: generate records to the queue
event eRecordSourceDNSWeightedQueueGenerateRecords: (name: string, region: int, batch: int, invoker: machine);
// event: generate records to the queue
event eRecordSourceDNSWeightedQueueGenerateRecordsNotification: (name: string, region: int, batch: int, count: int, success: bool);

/******************************************************************
Record Source as a State Machine that publishes records to a Queue
*******************************************************************/
machine RecordSourceDNSWeightedQueue {

  var name: string;
  var region: int;
  var dnsName: string;
  var dns: Route53DNSWeightedQueue;
  var records: seq[seq[tRecord]];

  start state Init {

    entry (input: (name: string, region: int, dnsName: string, dns: Route53DNSWeightedQueue, records: seq[seq[tRecord]])) {

       name = input.name;
       region = input.region;
       dnsName = input.dnsName;
       dns = input.dns;
       records = input.records;
    }

    on eRecordSourceDNSWeightedQueueGenerateRecords do (input1: (name: string, region: int, batch: int, invoker: machine)) {

			var record: tRecord;
			var count: int;

      foreach(record in records[input1.batch - 1]) {

				count = count + 1;

        send dns, eRoute53DNSWeightedQueueSendRecord, (name = dnsName, record = record, invoker = this);
        receive {
          case eRoute53DNSWeightedQueueSendRecordCompleted: (input2: (name: string, record: tRecord, success: bool)) {
            if (input2.success == false) {
              send input1.invoker, eRecordSourceDNSWeightedQueueGenerateRecordsNotification, (name = name, region = region, batch = input1.batch, count = count, success = false);
              return;
            }
          }
        }
      }

			send input1.invoker, eRecordSourceDNSWeightedQueueGenerateRecordsNotification, (name = name, region = region, batch = input1.batch, count = sizeof(records[input1.batch - 1]), success = true);
    }
  }
}
