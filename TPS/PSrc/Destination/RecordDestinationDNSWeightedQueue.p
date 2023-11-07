// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/*********************************************************
Events used to communicate with a Record Destination
**********************************************************/

// event: send receive notification event to destination
event eRecordDestinationDNSWeightedQueueReceiveNotification: (name: string, region: int, count: int, invoker: machine);
// event: send receive notification response event to invoker
event eRecordDestinationDNSWeightedQueueReceiveNotificationResponse: (name: string, region: int, count: int);
// event: send receive notification event to destination
event eRecordDestinationDNSWeightedQueueResume: (name: string);

/**********************************************************************
Record Destination as a State Machine that reads messages from a DNS
***********************************************************************/
machine RecordDestinationDNSWeightedQueue {

  var name: string;
  var region: int;
  var dnsName: string;
  var dns: Route53DNSWeightedQueue;
  var records: seq[tRecord];
  var count: int;
  var invoker: machine;

  start state Init {

    entry (input: (name: string, region: int, dnsName: string, dns: Route53DNSWeightedQueue)) {

      name = input.name;
      region = input.region;
      dnsName = input.dnsName;
      dns = input.dns;
      send dns, eRoute53DNSWeightedQueueReceiveRecord, (name = dnsName, region = 1, invoker = this);
      send dns, eRoute53DNSWeightedQueueReceiveRecord, (name = dnsName, region = 2, invoker = this);
      goto ProcessRecords;
    }
  }

  state ProcessRecords {

    on eQueueReceiveRecordResponse do (input: (name: string, region: int, record: tRecord, queueDepth: int, success: bool)) {

			if (input.success) {

				records += (sizeof(records), input.record);
				send dns, eRoute53DNSWeightedQueueRemoveRecord, (name = dnsName, region = input.region, record = input.record, invoker = this);
				receive {
					case eRoute53DNSWeightedQueueRemoveRecordCompleted: (input: (name: string, region: int, record: tRecord, success: bool)) {
					}
				}

				if (sizeof(records) == count) {
					send invoker, eRecordDestinationDNSWeightedQueueReceiveNotificationResponse, (name = name, region = region, count = count);
				}
			}

			send dns, eRoute53DNSWeightedQueueReceiveRecord, (name = dnsName, region = input.region, invoker = this);
    }

    on eRecordDestinationDNSWeightedQueueReceiveNotification do (input: (name: string, region: int, count: int, invoker: machine)) {

			count = input.count;
			invoker = input.invoker;
		}

		on eRecordDestinationDNSWeightedQueueResume do (input: (name: string)) {

			send dns, eRoute53DNSWeightedQueueReceiveRecord, (name = dnsName, region = 1, invoker = this);
		}
  }
}
