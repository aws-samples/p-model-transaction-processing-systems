// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/************************************************************************************************************
Events used to communicate with a Record Destination receiving records from a Kafka stream routed through DNS
*************************************************************************************************************/

// event: send receive notification event to destination
event eRecordDestinationDNSWeightedKafkaReceiveNotification: (name: string, region: int, count: int, invoker: machine);
// event: send receive notification response event to invoker
event eRecordDestinationDNSWeightedKafkaReceiveNotificationResponse: (name: string, region: int, count: int);
// event: resume record destination
event eRecordDestinationDNSWeightedKafkaResume: (name: string);

/***********************************************************************************************
Record Destination as a State Machine that reads messages from a Kafka stream routed through DNS
************************************************************************************************/
machine RecordDestinationDNSWeightedKafka {

  var name: string;
  var region: int;
  var dnsName: string;
  var dns: Route53DNSWeightedKafka;
  var records: seq[tRecord];
  var count: int;
  var invoker: machine;

  start state Init {

    entry (input: (name: string, region: int, dnsName: string, dns: Route53DNSWeightedKafka)) {

      name = input.name;
      region = input.region;
      dnsName = input.dnsName;
      dns = input.dns;
      send dns, eRoute53DNSWeightedKafkaReceiveRecords, (name = dnsName, region = 1, invoker = this);
      send dns, eRoute53DNSWeightedKafkaReceiveRecords, (name = dnsName, region = 2, invoker = this);
      goto ProcessRecords;
    }
  }

  state ProcessRecords {

    on eKafkaReceiveRecordsResponse do (input: (name: string, region: int, records: seq[tRecord], kafkaDepth: int, success: bool)) {

      var record: tRecord;

			if (input.success) {

        foreach (record in input.records) {

          records += (sizeof(records), record);

          if (sizeof(records) == count) {
            send invoker, eRecordDestinationDNSWeightedKafkaReceiveNotificationResponse, (name = name, region = region, count = count);
          }
				}

        send dns, eRoute53DNSWeightedKafkaRemoveRecords, (name = dnsName, region = input.region, records = input.records, invoker = this);
        receive {
          case eRoute53DNSWeightedKafkaRemoveRecordsCompleted: (input: (name: string, region: int, records: seq[tRecord], success: bool)) {
          }
        }
			}

			send dns, eRoute53DNSWeightedKafkaReceiveRecords, (name = dnsName, region = input.region, invoker = this);
    }

    on eRecordDestinationDNSWeightedKafkaReceiveNotification do (input: (name: string, region: int, count: int, invoker: machine)) {

			count = input.count;
			invoker = input.invoker;
		}

		on eRecordDestinationDNSWeightedKafkaResume do (input: (name: string)) {

			send dns, eRoute53DNSWeightedKafkaReceiveRecords, (name = dnsName, region = 1, invoker = this);
		}
  }
}
