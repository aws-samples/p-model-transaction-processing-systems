// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/***************************************************************
This file contains the workload1 machine
****************************************************************/

//
// The workload1 machine.
//

machine Workload1 {

  var systemConstants: tWorkload1Constants;

  var inboundKafka1: Kafka;
  var inboundKafka2: Kafka;

  var outboundKafka1: Kafka;
  var outboundKafka2: Kafka;

  var receiverDatabase: MongoDBAtlas;
  var validatorDatabase: MongoDBAtlas;
  var processorDatabase: MongoDBAtlas;

  var receiverContainer1: APIMongoAPIContainer;
  var receiverContainer2: APIMongoAPIContainer;

  var validatorContainer1: APIMongoKafkaContainer;
  var validatorContainer2: APIMongoKafkaContainer;

  var processorContainer1: KafkaMongoKafkaContainer;
  var processorContainer2: KafkaMongoKafkaContainer;

  var inDNS: Route53DNSWeightedAPI;
  var outDNS: Route53DNSWeightedKafka;

  var recordSourceDNS: RecordSourceDNSWeightedAPI;
  var recordDestinationDNS: RecordDestinationDNSWeightedKafka;

  var records: seq[seq[tRecord]];

  var sizes: seq[int];

  start state Init {

    entry (input: (systemConstants: tWorkload1Constants,
                   records: seq[seq[tRecord]],
                   sizes: seq[int])) {

      systemConstants = input.systemConstants;							
      records = input.records;      
      sizes = input.sizes;              
      
      inboundKafka1 = new Kafka((name = systemConstants.inboundKafkaName, region = 1, batch = 5));
      inboundKafka2 = new Kafka((name = systemConstants.inboundKafkaName, region = 2, batch = 5));

      outboundKafka1 = new Kafka((name = systemConstants.outboundKafkaName, region = 1, batch = 5));
      outboundKafka2 = new Kafka((name = systemConstants.outboundKafkaName, region = 2, batch = 5));

      receiverDatabase = new MongoDBAtlas((name = systemConstants.receiverDatabaseName,));
      validatorDatabase = new MongoDBAtlas((name = systemConstants.validatorDatabaseName,));
      processorDatabase = new MongoDBAtlas((name = systemConstants.processorDatabaseName,));

      processorContainer1 = new KafkaMongoKafkaContainer((name = systemConstants.processorContainerName,
                                                          region = 1,
                                                          inKafkaName = systemConstants.inboundKafkaName,
                                                          inKafka = inboundKafka1,
                                                          databaseName = systemConstants.processorDatabaseName,
                                                          database = processorDatabase,
                                                          outKafkaName = systemConstants.outboundKafkaName,
                                                          outKafka = outboundKafka1));
      processorContainer2 = new KafkaMongoKafkaContainer((name = systemConstants.processorContainerName,
                                                          region = 2,
                                                          inKafkaName = systemConstants.inboundKafkaName,
                                                          inKafka = inboundKafka2,
                                                          databaseName = systemConstants.processorDatabaseName,
                                                          database = processorDatabase,
                                                          outKafkaName = systemConstants.outboundKafkaName,
                                                          outKafka = outboundKafka2));

      validatorContainer1 = new APIMongoKafkaContainer((name = systemConstants.validatorContainerName,
                                                        region = 1,
                                                        databaseName = systemConstants.validatorDatabaseName,
                                                        database = validatorDatabase,
                                                        outKafkaName = systemConstants.inboundKafkaName,
                                                        outKafka = inboundKafka1));
      validatorContainer2 = new APIMongoKafkaContainer((name = systemConstants.validatorContainerName,
                                                        region = 2,
                                                        databaseName = systemConstants.validatorDatabaseName,
                                                        database = validatorDatabase,
                                                        outKafkaName = systemConstants.inboundKafkaName,
                                                        outKafka = inboundKafka2));

      receiverContainer1 = new APIMongoAPIContainer((name = systemConstants.receiverContainerName,
                                                    region = 1,
                                                    databaseName = systemConstants.receiverDatabaseName,
                                                    database = receiverDatabase,
                                                    outAPIName = systemConstants.validatorContainerName,
                                                    outAPI = validatorContainer1));
      receiverContainer2 = new APIMongoAPIContainer((name = systemConstants.receiverContainerName,
                                                    region = 2,
                                                    databaseName = systemConstants.receiverDatabaseName,
                                                    database = receiverDatabase,
                                                    outAPIName = systemConstants.validatorContainerName,
                                                    outAPI = validatorContainer2));

      inDNS = new Route53DNSWeightedAPI((name = systemConstants.inDNSName,
                                        api1Name = systemConstants.receiverContainerName,
                                        api1 = receiverContainer1,
                                        api2Name = systemConstants.receiverContainerName,
                                        api2 = receiverContainer2));

      outDNS = new Route53DNSWeightedKafka((name = systemConstants.outDNSName,
                                            kafka1Name = systemConstants.outboundKafkaName,
                                            kafka1 = outboundKafka1,
                                            kafka2Name = systemConstants.outboundKafkaName,
                                            kafka2 = outboundKafka2));

      recordSourceDNS = new RecordSourceDNSWeightedAPI((name = systemConstants.recordSourceDNSName,
                                                        region = 1,
                                                        dnsName = systemConstants.inDNSName,
                                                        dns = inDNS,
                                                        records = records));
      recordDestinationDNS = new RecordDestinationDNSWeightedKafka((name = systemConstants.recordDestinationDNSName,
                                                                    region = 2,
                                                                    dnsName = systemConstants.outDNSName,
                                                                    dns = outDNS));
    }

    on eKafkaReceiveNotification do (input: (name: string, region: int, count: int, invoker: machine)) {

			if (input.name == systemConstants.inboundKafkaName && input.region == 1) {
				send inboundKafka1, eKafkaReceiveNotification, (name = input.name, region = input.region, count = input.count, invoker = input.invoker);
			}
			else if (input.name == systemConstants.inboundKafkaName && input.region == 2) {
				send inboundKafka2, eKafkaReceiveNotification, (name = input.name, region = input.region, count = input.count, invoker = input.invoker);
			}
			else if (input.name == systemConstants.outboundKafkaName && input.region == 1) {
				send outboundKafka1, eKafkaReceiveNotification, (name = input.name, region = input.region, count = input.count, invoker = input.invoker);
			}
			else if (input.name == systemConstants.outboundKafkaName && input.region == 2) {
				send outboundKafka1, eKafkaReceiveNotification, (name = input.name, region = input.region, count = input.count, invoker = input.invoker);
			}
		}

    on eKafkaFail do (input: (name: string, region: int, invoker: machine)) {

			if (input.name == systemConstants.inboundKafkaName && input.region == 1) {
				send inboundKafka1, eKafkaFail, (name = input.name, region = input.region, invoker = input.invoker);
			}
			else if (input.name == systemConstants.inboundKafkaName && input.region == 2) {
				send inboundKafka2, eKafkaFail, (name = input.name, region = input.region, invoker = input.invoker);
			}
			else if (input.name == systemConstants.outboundKafkaName && input.region == 1) {
				send outboundKafka1, eKafkaFail, (name = input.name, region = input.region, invoker = input.invoker);
			}
			else if (input.name == systemConstants.outboundKafkaName && input.region == 2) {
				send outboundKafka1, eKafkaFail, (name = input.name, region = input.region, invoker = input.invoker);
			}
		}

    on eKafkaRecover do (input: (name: string, region: int)) {

			if (input.name == systemConstants.inboundKafkaName && input.region == 1) {
				send inboundKafka1, eKafkaRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.inboundKafkaName && input.region == 2) {
				send inboundKafka2, eKafkaRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.outboundKafkaName && input.region == 1) {
				send outboundKafka1, eKafkaRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.outboundKafkaName && input.region == 2) {
				send outboundKafka1, eKafkaRecover, (name = input.name, region = input.region);
			}
		}

    on eKafkaMongoKafkaContainerFail do (input: (name: string, region: int)) {

			if (input.name == systemConstants.receiverContainerName && input.region == 1) {
				send receiverContainer1, eKafkaMongoKafkaContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.receiverContainerName && input.region == 2) {
				send receiverContainer2, eKafkaMongoKafkaContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.validatorContainerName && input.region == 1) {
				send validatorContainer1, eKafkaMongoKafkaContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.validatorContainerName && input.region == 2) {
				send validatorContainer1, eKafkaMongoKafkaContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.processorContainerName && input.region == 1) {
				send processorContainer1, eKafkaMongoKafkaContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.processorContainerName && input.region == 2) {
				send processorContainer2, eKafkaMongoKafkaContainerFail, (name = input.name, region = input.region);
			}
		}

    on eKafkaMongoKafkaContainerRecover do (input: (name: string, region: int)) {

			if (input.name == systemConstants.receiverContainerName && input.region == 1) {
				send receiverContainer1, eKafkaMongoKafkaContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.receiverContainerName && input.region == 2) {
				send receiverContainer2, eKafkaMongoKafkaContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.validatorContainerName && input.region == 1) {
				send validatorContainer1, eKafkaMongoKafkaContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.validatorContainerName && input.region == 2) {
				send validatorContainer1, eKafkaMongoKafkaContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.processorContainerName && input.region == 1) {
				send processorContainer1, eKafkaMongoKafkaContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.processorContainerName && input.region == 2) {
				send processorContainer2, eKafkaMongoKafkaContainerRecover, (name = input.name, region = input.region);
			}
		}

    on eAPIMongoAPIContainerFail do (input: (name: string, region: int)) {

			if (input.name == systemConstants.receiverContainerName && input.region == 1) {
				send receiverContainer1, eAPIMongoAPIContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.receiverContainerName && input.region == 2) {
				send receiverContainer2, eAPIMongoAPIContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.validatorContainerName && input.region == 1) {
				send validatorContainer1, eAPIMongoAPIContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.validatorContainerName && input.region == 2) {
				send validatorContainer1, eAPIMongoAPIContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.processorContainerName && input.region == 1) {
				send processorContainer1, eAPIMongoAPIContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.processorContainerName && input.region == 2) {
				send processorContainer2, eAPIMongoAPIContainerFail, (name = input.name, region = input.region);
			}
		}

    on eAPIMongoAPIContainerRecover do (input: (name: string, region: int)) {

			if (input.name == systemConstants.receiverContainerName && input.region == 1) {
				send receiverContainer1, eAPIMongoAPIContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.receiverContainerName && input.region == 2) {
				send receiverContainer2, eAPIMongoAPIContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.validatorContainerName && input.region == 1) {
				send validatorContainer1, eAPIMongoAPIContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.validatorContainerName && input.region == 2) {
				send validatorContainer1, eAPIMongoAPIContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.processorContainerName && input.region == 1) {
				send processorContainer1, eAPIMongoAPIContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.processorContainerName && input.region == 2) {
				send processorContainer2, eAPIMongoAPIContainerRecover, (name = input.name, region = input.region);
			}
		}

    on eAPIMongoKafkaContainerFail do (input: (name: string, region: int)) {

			if (input.name == systemConstants.receiverContainerName && input.region == 1) {
				send receiverContainer1, eAPIMongoKafkaContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.receiverContainerName && input.region == 2) {
				send receiverContainer2, eAPIMongoKafkaContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.validatorContainerName && input.region == 1) {
				send validatorContainer1, eAPIMongoKafkaContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.validatorContainerName && input.region == 2) {
				send validatorContainer1, eAPIMongoKafkaContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.processorContainerName && input.region == 1) {
				send processorContainer1, eAPIMongoKafkaContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.processorContainerName && input.region == 2) {
				send processorContainer2, eAPIMongoKafkaContainerFail, (name = input.name, region = input.region);
			}
		}

    on eAPIMongoKafkaContainerRecover do (input: (name: string, region: int)) {

			if (input.name == systemConstants.receiverContainerName && input.region == 1) {
				send receiverContainer1, eAPIMongoKafkaContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.receiverContainerName && input.region == 2) {
				send receiverContainer2, eAPIMongoKafkaContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.validatorContainerName && input.region == 1) {
				send validatorContainer1, eAPIMongoKafkaContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.validatorContainerName && input.region == 2) {
				send validatorContainer1, eAPIMongoKafkaContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.processorContainerName && input.region == 1) {
				send processorContainer1, eAPIMongoKafkaContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.processorContainerName && input.region == 2) {
				send processorContainer2, eAPIMongoKafkaContainerRecover, (name = input.name, region = input.region);
			}
		}

    on eMongoFail do (input: (name: string)) {

      if (input.name == systemConstants.receiverDatabaseName) {
				send receiverDatabase, eMongoFail, (name = input.name, );
			}
			else if (input.name == systemConstants.validatorDatabaseName) {
				send validatorDatabase, eMongoFail, (name = input.name, );
			}
			else if (input.name == systemConstants.processorDatabaseName) {
				send processorDatabase, eMongoFail, (name = input.name, );
			}
		}

    on eMongoRecover do (input: (name: string)) {

      if (input.name == systemConstants.receiverDatabaseName) {
				send receiverDatabase, eMongoRecover, (name = input.name, );
			}
			else if (input.name == systemConstants.validatorDatabaseName) {
				send validatorDatabase, eMongoRecover, (name = input.name, );
			}
			else if (input.name == systemConstants.processorDatabaseName) {
				send processorDatabase, eMongoRecover, (name = input.name, );
			}
		}

    on eMongoSwitchRegions do (input: (name: string, invoker: machine)) {

      if (input.name == systemConstants.receiverDatabaseName) {
				send receiverDatabase, eMongoSwitchRegions, (name = input.name, invoker = input.invoker);
			}
			else if (input.name == systemConstants.validatorDatabaseName) {
				send validatorDatabase, eMongoSwitchRegions, (name = input.name, invoker = input.invoker);
			}
			else if (input.name == systemConstants.processorDatabaseName) {
				send processorDatabase, eMongoSwitchRegions, (name = input.name, invoker = input.invoker);
			}
    }

    on eRecordSourceDNSWeightedAPIGenerateRecords do (input: (name: string, region: int, batch: int, invoker: machine)) {

			send recordSourceDNS, eRecordSourceDNSWeightedAPIGenerateRecords, (name = input.name, region = input.region, batch = input.batch, invoker = input.invoker);
    }

    on eRecordDestinationDNSWeightedKafkaReceiveNotification do (input: (name: string, region: int, count: int, invoker: machine)) {

      send recordDestinationDNS, eRecordDestinationDNSWeightedKafkaReceiveNotification, (name = input.name, region = input.region, count = input.count, invoker = input.invoker);
		}

    on eRoute53DNSWeightedAPISwitchRegionOffline do (input: (name: string, region: int)) {

			if (input.name == systemConstants.inDNSName) {
				send inDNS, eRoute53DNSWeightedAPISwitchRegionOffline, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.outDNSName) {
				send outDNS, eRoute53DNSWeightedAPISwitchRegionOffline, (name = input.name, region = input.region);
			}
		}

    on eRoute53DNSWeightedKafkaSwitchRegionOffline do (input: (name: string, region: int)) {

			if (input.name == systemConstants.inDNSName) {
				send inDNS, eRoute53DNSWeightedKafkaSwitchRegionOffline, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.outDNSName) {
				send outDNS, eRoute53DNSWeightedKafkaSwitchRegionOffline, (name = input.name, region = input.region);
			}
		}
  }
}
