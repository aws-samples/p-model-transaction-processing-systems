## Route 53 DNS Weighted Kafka

Route 53 DNS configured to forward to Kafka streams with Weighted routing policy

### States

![Route 53 DNS Weighted Kafka States!](images/Route53DNSWeightedKafkaStates.jpg)

### Events

1. Route53DNSWeightedKafka(name: string, kafka1Name: string, kafka1: Kafka, kafka2Name: string, kafka2: Kafka)
2. eRoute53DNSWeightedKafkaSendRecords: (name: string, records: seq[tRecord], invoker: machine)
3. eRoute53DNSWeightedKafkaSendRecordsCompleted: (name: string, records: seq[tRecord], success: bool)
4. eRoute53DNSWeightedKafkaReceiveRecords: (name: string, region: int, invoker: machine)
5. eRoute53DNSWeightedKafkaRemoveRecords: (name: string, region: int, records: seq[tRecord], invoker: machine)
6. eRoute53DNSWeightedKafkaRemoveRecordsCompleted: (name: string, region: int, records: seq[tRecord], success: bool)
7. eRoute53DNSWeightedKafkaSwitchRegionOffline : (name: string, region: int)
8. eRoute53DNSWeightedKafkaSetKafka1: (name: string, region: int, kafka1: Kafka, invoker: machine)
9. eRoute53DNSWeightedKafkaSetKafka1Completed: (name: string, region: int, kafka1: Kafka, success: bool)
10. eRoute53DNSWeightedKafkaSetKafka2: (name: string, region: int, kafka2: Kafka, invoker: machine)
11. eRoute53DNSWeightedKafkaSetKafka2Completed: (name: string, region: int, kafka2: Kafka, success: bool)
