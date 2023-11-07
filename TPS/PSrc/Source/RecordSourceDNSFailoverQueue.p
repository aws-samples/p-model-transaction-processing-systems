// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/************************************************
Record Source that publishes records to a queue
*************************************************/

// event: generate records to the queue
event eRecordSourceDNSFailoverQueueGenerateRecords: (name: string, region: int, batch: int, invoker: machine);
// event: generate records to the queue
event eRecordSourceDNSFailoverQueueGenerateRecordsNotification: (name: string, region: int, batch: int, count: int, success: bool);

/******************************************************************
Record Source as a State Machine that publishes records to a Queue
*******************************************************************/
machine RecordSourceDNSFailoverQueue {

  var name: string;
  var region: int;
  var dnsName: string;
  var dns: Route53DNSFailoverQueue;
  var records: seq[seq[tRecord]];

  start state Init {

    entry (input: (name: string, region: int, dnsName: string, dns: Route53DNSFailoverQueue, records: seq[seq[tRecord]])) {

       name = input.name;
       region = input.region;
       dnsName = input.dnsName;
       dns = input.dns;
       records = input.records;
    }

    on eRecordSourceDNSFailoverQueueGenerateRecords do (input1: (name: string, region: int, batch: int, invoker: machine)) {

			var record: tRecord;
			var count: int;

      count = 0;
      foreach(record in records[input1.batch-1]) {

        count = count + 1;

        send dns, eRoute53DNSFailoverQueueSendRecord, (name = dnsName, record = record, invoker = this);
        receive {
          case eRoute53DNSFailoverQueueSendRecordCompleted: (input2: (name: string, record: tRecord, success: bool)) {
            if (input2.success == false) {
              send input1.invoker, eRecordSourceDNSFailoverQueueGenerateRecordsNotification, (name = name, region = region, batch = input1.batch, count = count, success = false);
              return;
            }
          }
        }
      }

			send input1.invoker, eRecordSourceDNSFailoverQueueGenerateRecordsNotification, (name = name, region = region, batch = input1.batch, count = sizeof(records[input1.batch-1]), success = true);
    }
  }
}
