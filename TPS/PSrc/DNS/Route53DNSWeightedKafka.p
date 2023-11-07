// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/******************************************************************************************
Events used to communicate with Route 53 DNS with weighted policy routing to a Kafka stream
*******************************************************************************************/

// event: send record to Route 53 DNS
event eRoute53DNSWeightedKafkaSendRecords: (name: string, records: seq[tRecord], invoker: machine);
// event: send record to Route 53 DNS completed
event eRoute53DNSWeightedKafkaSendRecordsCompleted: (name: string, records: seq[tRecord], success: bool);
// event: receive record from Route 53 DNS
event eRoute53DNSWeightedKafkaReceiveRecords: (name: string, region: int, invoker: machine);
// event: remove record from Route 53 DNS
event eRoute53DNSWeightedKafkaRemoveRecords: (name: string, region: int, records: seq[tRecord], invoker: machine);
// event: remove record from Route 53 DNS completed
event eRoute53DNSWeightedKafkaRemoveRecordsCompleted: (name: string, region: int, records: seq[tRecord], success: bool);
// event: switch region offline
event eRoute53DNSWeightedKafkaSwitchRegionOffline: (name: string, region: int);
// event: set the queue1
event eRoute53DNSWeightedKafkaSetKafka1: (name: string, region: int, kafka1: Kafka, invoker: machine);
// event: set the kafka1 completed
event eRoute53DNSWeightedKafkaSetKafka1Completed: (name: string, region: int, kafka1: Kafka, success: bool);
// event: set the kafka2
event eRoute53DNSWeightedKafkaSetKafka2: (name: string, region: int, kafka2: Kafka, invoker: machine);
// event: set the kafka2 completed
event eRoute53DNSWeightedKafkaSetKafka2Completed: (name: string, region: int, kafka2: Kafka, success: bool);

/*************************************************************
 Route 53 DNS with Weighted Routing as a State Machine
**************************************************************/
machine Route53DNSWeightedKafka {

  var name: string;
  var kafka1Name: string;
  var kafka1: Kafka;
  var kafka2Name: string;
  var kafka2: Kafka;
	var currentRegion: int;
	var receiver: machine;
	var offlineRegion: int;

  start state Init {

    entry (input: (name: string, kafka1Name: string, kafka1: Kafka, kafka2Name: string, kafka2: Kafka)) {
      name = input.name;
      kafka1Name = input.kafka1Name;
      kafka1 = input.kafka1;
      kafka2Name = input.kafka2Name;
      kafka2 = input.kafka2;
      currentRegion = 1;
      offlineRegion = 0;
      goto ProcessRecords;
    }
  }

  state ProcessRecords {

    on eRoute53DNSWeightedKafkaSendRecords do (input: (name: string, records: seq[tRecord], invoker: machine)) {

			if (offlineRegion == 0) {

				if (currentRegion == 1) {
					send kafka1, eKafkaSendRecords, (name = kafka1Name, region = 1, records = input.records, invoker = this);
					receive {
						case eKafkaSendRecordsCompleted: (input2: (name: string, region: int, records: seq[tRecord], success: bool)) {
							send input.invoker, eRoute53DNSWeightedKafkaSendRecordsCompleted, (name = input.name, records = input.records, success = true);
							if (input2.success == true) {
							  currentRegion = 2;
							}
						}
					}
				}
				else {
					send kafka2, eKafkaSendRecords, (name = kafka2Name, region = 2, records = input.records, invoker = this);
					receive {
						case eKafkaSendRecordsCompleted: (input2: (name: string, region: int, records: seq[tRecord], success: bool)) {
							send input.invoker, eRoute53DNSWeightedKafkaSendRecordsCompleted, (name = input.name, records = input.records, success = true);
							if (input2.success == true) {
							  currentRegion = 1;
							}
						}
					}
				}
    	}
    	else {

    		if (offlineRegion == 1) {
					send kafka2, eKafkaSendRecords, (name = kafka2Name, region = 2, records = input.records, invoker = this);
					receive {
						case eKafkaSendRecordsCompleted: (input2: (name: string, region: int, records: seq[tRecord], success: bool)) {
							send input.invoker, eRoute53DNSWeightedKafkaSendRecordsCompleted, (name = input.name, records = input.records, success = true);
						}
					}
				}
				else {
					send kafka1, eKafkaSendRecords, (name = kafka1Name, region = 1, records = input.records, invoker = this);
					receive {
						case eKafkaSendRecordsCompleted: (input2: (name: string, region: int, records: seq[tRecord], success: bool)) {
							send input.invoker, eRoute53DNSWeightedKafkaSendRecordsCompleted, (name = input.name, records = input.records, success = true);
						}
					}
				}
    	}
    }

		on eRoute53DNSWeightedKafkaReceiveRecords do (input: (name: string, region: int, invoker: machine)) {

			receiver = input.invoker;

			if (offlineRegion == 0) {

				if (input.region == 1) {
					send kafka1, eKafkaReceiveRecords, (name = kafka1Name, region = 1, invoker = input.invoker);
				}
				else {
					send kafka2, eKafkaReceiveRecords, (name = kafka2Name, region = 2, invoker = input.invoker);
				}
			}
			else {
				if (offlineRegion == 1) {
					send kafka2, eKafkaReceiveRecords, (name = kafka2Name, region = 2, invoker = input.invoker);
				}
				else {
					send kafka1, eKafkaReceiveRecords, (name = kafka1Name, region = 1, invoker = input.invoker);
				}
			}
		}

		on eRoute53DNSWeightedKafkaRemoveRecords do (input: (name: string, region: int, records: seq[tRecord], invoker: machine)) {

			if (offlineRegion == 0) {
				if (input.region == 1) {
					send kafka1, eKafkaRemoveRecords, (name = kafka1Name, region = 1, records = input.records, invoker = this);
					receive {
						case eKafkaRemoveRecordsCompleted: (input2: (name: string, region: int, records: seq[tRecord], success: bool)) {
							send input.invoker, eRoute53DNSWeightedKafkaRemoveRecordsCompleted, (name = input.name, region = input.region, records = input.records, success = true);
						}
					}
					currentRegion = 2;
				}
				else {
					send kafka2, eKafkaRemoveRecords, (name = kafka2Name, region = 2, records = input.records, invoker = this);
					receive {
						case eKafkaRemoveRecordsCompleted: (input2: (name: string, region: int, records: seq[tRecord], success: bool)) {
							send input.invoker, eRoute53DNSWeightedKafkaRemoveRecordsCompleted, (name = input.name, region = input.region, records = input.records, success = true);
						}
					}
					currentRegion = 1;
				}
			}
			else {
				if (offlineRegion == 1) {
					send kafka2, eKafkaRemoveRecords, (name = kafka2Name, region = 2, records = input.records, invoker = this);
					receive {
						case eKafkaRemoveRecordsCompleted: (input2: (name: string, region: int, records: seq[tRecord], success: bool)) {
							send input.invoker, eRoute53DNSWeightedKafkaRemoveRecordsCompleted, (name = input.name, region = input.region, records = input.records, success = true);
						}
					}
				}
				else {
					send kafka1, eKafkaRemoveRecords, (name = kafka1Name, region = 1, records = input.records, invoker = this);
					receive {
						case eKafkaRemoveRecordsCompleted: (input2: (name: string, region: int, records: seq[tRecord], success: bool)) {
							send input.invoker, eRoute53DNSWeightedKafkaRemoveRecordsCompleted, (name = input.name, region = input.region, records = input.records, success = true);
						}
					}
				}
			}
		}

		on eRoute53DNSWeightedKafkaSetKafka1 do (input: (name: string, region: int, kafka1: Kafka, invoker: machine)) {

			kafka1 = input.kafka1;
			if (receiver != null) {
				send kafka1, eKafkaReceiveRecords, (name = kafka1Name, region = 1, invoker = receiver);
			}

			if (offlineRegion != 1) {
				send input.invoker, eRoute53DNSWeightedKafkaSetKafka1Completed, (name = name, region = input.region, kafka1 = kafka1, success = true);
			}
		}

		on eRoute53DNSWeightedKafkaSetKafka2 do (input: (name: string, region: int, kafka2: Kafka, invoker: machine)) {

			kafka2 = input.kafka2;
			if (receiver != null) {
				send kafka1, eKafkaReceiveRecords, (name = kafka1Name, region = 1, invoker = receiver);
			}

			if (offlineRegion != 2) {
				send input.invoker, eRoute53DNSWeightedKafkaSetKafka2Completed, (name = name, region = input.region, kafka2 = kafka1, success = true);
			}
		}

		on eRoute53DNSWeightedKafkaSwitchRegionOffline do (input: (name: string, region: int)) {

			offlineRegion = input.region;
		}
  }
}

