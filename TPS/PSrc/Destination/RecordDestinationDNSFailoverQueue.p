// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/*********************************************************
Events used to communicate with a Record Destination
**********************************************************/

// event: send receive notification event to destination
event eRecordDestinationDNSFailoverQueueReceiveNotification: (name: string, region: int, count: int, invoker: machine);
// event: send receive notification response event to invoker
event eRecordDestinationDNSFailoverQueueReceiveNotificationResponse: (name: string, region: int, count: int);
// event: send receive notification event to destination
event eRecordDestinationDNSFailoverQueueResume: (name: string);

/**********************************************************************
Record Destination as a State Machine that reads messages from a DNS
***********************************************************************/
machine RecordDestinationDNSFailoverQueue {

  var name: string;
  var region: int;
  var dnsName: string;
  var dns: Route53DNSFailoverQueue;
  var records: seq[tRecord];
  var count: int;
  var invoker: machine;

  start state Init {

    entry (input: (name: string, region: int, dnsName: string, dns: Route53DNSFailoverQueue)) {

      name = input.name;
      region = input.region;
      dnsName = input.dnsName;
      dns = input.dns;
      send dns, eRoute53DNSFailoverQueueReceiveRecord, (name = dnsName, invoker = this);
      goto ProcessRecords;
    }
  }

  state ProcessRecords {

    on eQueueReceiveRecordResponse do (input: (name: string, region: int, record: tRecord, queueDepth: int, success: bool)) {

			if (input.success) {

				records += (sizeof(records), input.record);
				send dns, eRoute53DNSFailoverQueueRemoveRecord, (name = dnsName, record = input.record, invoker = this);
				receive {
					case eRoute53DNSFailoverQueueRemoveRecordCompleted: (input: (name: string, record: tRecord, success: bool)) {
					}
				}

				if (sizeof(records) == count) {
					send invoker, eRecordDestinationDNSFailoverQueueReceiveNotificationResponse, (name = name, region = region, count = count);
				}
      }

      send dns, eRoute53DNSFailoverQueueReceiveRecord, (name = dnsName, invoker = this);
    }

    on eRecordDestinationDNSFailoverQueueReceiveNotification do (input: (name: string, region: int, count: int, invoker: machine)) {

			count = input.count;
			invoker = input.invoker;
		}

		on eRecordDestinationDNSFailoverQueueResume do (input: (name: string)) {

			send dns, eRoute53DNSFailoverQueueReceiveRecord, (name = dnsName, invoker = this);
		}
  }
}
