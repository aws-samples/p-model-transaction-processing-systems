# Workload1 Transaction Processing System

## Architecture

We have designed a payment processing workload for a customer with 3 components in an active-active architecture.

![Workload1 Transaction Process System!](images/TestWorkload1.jpg)

* The record source is a component that publishes records to a DNS target with weighted routing policy
* The in-DNS with weighted routing policy maps to receiver API in primary region or secondary region based on weighting policy
* The receiver API writes to receiver MongoDB Atlas database and invokes validator API
* The validator API writes to validator MongoDB Atlas database and publishes to inbound Kafka for processor container
* The processor container reads records from inbound Kafka stream, writes to MongoDB Atlas database and publishes to outbound Kafka stream
* The out-DNS with failover routing policy maps to outbound Kafka in primary region or secondary region based on weighting policy
* The record destination is a component that receives records from the DNS target with failover routing policy

## Collaborating State Machines

We have expressed the design of the payment processing workload with instances of collaborating state machines as shown below.

![Workload1 Transaction Process System State Machine!](images/TestWorkload1StateMachines.jpg)

* The record source is represented by an instance of state machine (RecordSourceDNSWeightedAPI) identified as #1
* The in-DNS with weighted routing is represented by an instance of state machine (Route53DNSWeightedAPI) identified as #2
* The receiver container is represented by an instance of state machine (APIMongoAPIContainer) identified as #3
* The validator container is represented by an instance of state machine (APIMongoKafkaContainer) identified as #4
* The processor container is represented by an instance of state machine (KafkaMongoKafkaContainer) identified as #5
* The MongoDB Atlas databases are represented as instances of state machine (MongoDBAtlas) identified as #6
* The Kafka streams are represented as instances of state machine (Kafka) identified as #7
* The out-DNS with weighted routing is represented as instances of state machine (Route53DNSWeightedKafka) identified as #8
* The record destination is identified as instance of state machine (RecordDestinationDNSWeightedKafka) identified as #9

## Test Steps

1. Create instances of state machines for all the components and wire them together
2. Create a record set with 1 batch of 50 randomly generated test records
3. Create Record Source with the record set
4. Initialize the Workload1 Spec with the record set
5. Send event to Record Source to publish the 50 records in the batch
6. Workload1 Spec will monitor that all the records are delivered to all the components in the architecture and finally delivered to Record Destination. Please note the spec does not check that records are delivered in order as ordering is not preserved when records are processed across 2 regions.

## Key Takeaways

1. P is an effective language to model the asynchronous distributed system
2. Even though the components in the system are: A) Independent of each other B) Process records at different speeds C) A record could be processed by any one of the components at any point of time, all the records are eventually delivered to each component, including record destination. Please note that ordering is not preserved when records are processed independently in two regions.
