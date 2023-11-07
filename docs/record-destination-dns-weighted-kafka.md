## Record Destination DNS Weighted Kafka

Receives records from Route 53 DNS configured to route to Kafka streams with Weighted routing policy

### States

![Record Destination DNS Weighted Kafka States!](images/RecordDestinationDNSWeightedKafkaStates.jpg)

### Events

1. RecordDestinationDNSWeightedKafka(name: string, region: int, dnsName: string, dns: Route53DNSWeightedKafka)
2. eRecordDestinationDNSWeightedKafkaReceiveNotification: (name: string, region: int, count: int, invoker: machine)
3. eRecordDestinationDNSWeightedKafkaReceiveNotificationResponse: (name: string, region: int, count: int)
4. eRecordDestinationDNSWeightedKafkaResume: (name: string)