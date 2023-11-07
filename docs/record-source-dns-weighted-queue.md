## Record Source DNS Weighted Queue

Publishes records to Route 53 DNS configured to route to Queues with Weighted routing policy

### States

![Record Source DNS Weighted Queue States!](images/RecordSourceDNSWeightedStates.jpg)

### Events

1. RecordSourceDNSWeightedQueue(name: string, region: int, dnsName: string, dns: Route53DNSWeightedQueue, records: seq[seq[tRecord]])
2. eRecordSourceDNSWeightedQueueGenerateRecords: (name: string, region: int, batch: int, invoker: machine)
3. eRecordSourceDNSWeightedQueueGenerateRecordsNotification: (name: string, region: int, batch: int, count: int)
