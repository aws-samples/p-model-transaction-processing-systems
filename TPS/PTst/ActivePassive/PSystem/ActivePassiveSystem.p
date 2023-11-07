// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/***************************************************************
This file contains the active-passive machine
****************************************************************/

//
// The active-passive machine.
//

machine ActivePassive {

  var systemConstants: tActivePassiveConstants;

  var inboundQueue1: Queue;
  var inboundQueue2: Queue;

  var inboundPreprocessQueue1: Queue;
  var inboundPreprocessQueue2: Queue;

  var preprocessCoreQueue1: Queue;
  var preprocessCoreQueue2: Queue;

  var corePostprocessQueue1: Queue;
  var corePostprocessQueue2: Queue;

  var postprocessOutboundQueue1: Queue;
  var postprocessOutboundQueue2: Queue;

  var outboundQueue1: Queue;
  var outboundQueue2: Queue;

  var inboundDatabase: AuroraGlobalDatabase;
  var preprocessDatabase: AuroraGlobalDatabase;
  var coreDatabase: AuroraGlobalDatabase;
  var postprocessDatabase: AuroraGlobalDatabase;
  var outboundDatabase: AuroraGlobalDatabase;

  var inboundContainer1: QueueAuroraQueueContainer;
  var inboundContainer2: QueueAuroraQueueContainer;

  var preprocessContainer1: QueueAuroraQueueContainer;
  var preprocessContainer2: QueueAuroraQueueContainer;

  var coreContainer1: QueueAuroraQueueContainer;
  var coreContainer2: QueueAuroraQueueContainer;

  var postprocessContainer1: QueueAuroraQueueContainer;
  var postprocessContainer2: QueueAuroraQueueContainer;

  var outboundContainer1: QueueAuroraQueueContainer;
  var outboundContainer2: QueueAuroraQueueContainer;

  var inDNS: Route53DNSFailoverQueue;
  var outDNS: Route53DNSFailoverQueue;

  var recordSourceDNS: RecordSourceDNSFailoverQueue;
  var recordDestinationDNS: RecordDestinationDNSFailoverQueue;

  var records: seq[seq[tRecord]];

  start state Init {

    entry (input: (systemConstants: tActivePassiveConstants,
                   records: seq[seq[tRecord]])) {

      systemConstants = input.systemConstants;							
      records = input.records;

			inboundQueue1 = new Queue((name = systemConstants.inboundQueueName, region = 1));
			inboundQueue2 = new Queue((name = systemConstants.inboundQueueName, region = 2));

			inboundPreprocessQueue1 = new Queue((name = systemConstants.inboundPreprocessQueueName, region = 1));
			inboundPreprocessQueue2 = new Queue((name = systemConstants.inboundPreprocessQueueName, region = 2));

			preprocessCoreQueue1 = new Queue((name = systemConstants.preprocessCoreQueueName, region = 1));
			preprocessCoreQueue2 = new Queue((name = systemConstants.preprocessCoreQueueName, region = 2));

			corePostprocessQueue1 = new Queue((name = systemConstants.corePostprocessQueueName, region = 1));
			corePostprocessQueue2 = new Queue((name = systemConstants.corePostprocessQueueName, region = 2));

			postprocessOutboundQueue1 = new Queue((name = systemConstants.postprocessOutboundQueueName, region = 1));
			postprocessOutboundQueue2 = new Queue((name = systemConstants.postprocessOutboundQueueName, region = 2));

			outboundQueue1 = new Queue((name = systemConstants.outboundQueueName, region = 1));
			outboundQueue2 = new Queue((name = systemConstants.outboundQueueName, region = 2));

			inboundDatabase = new AuroraGlobalDatabase((name = systemConstants.inboundDatabaseName,));
			preprocessDatabase = new AuroraGlobalDatabase((name = systemConstants.preprocessDatabaseName,));
			coreDatabase = new AuroraGlobalDatabase((name = systemConstants.coreDatabaseName,));
			postprocessDatabase = new AuroraGlobalDatabase((name = systemConstants.postprocessDatabaseName,));
			outboundDatabase = new AuroraGlobalDatabase((name = systemConstants.outboundDatabaseName,));

			inboundContainer1 = new QueueAuroraQueueContainer((name = systemConstants.inboundContainerName,
                                                         region = 1,
                                                         inQueueName = systemConstants.inboundQueueName,
                                                         inQueue = inboundQueue1,
                                                         databaseName = systemConstants.inboundDatabaseName,
                                                         database = inboundDatabase,
                                                         outQueueName = systemConstants.inboundPreprocessQueueName,
                                                         outQueue = inboundPreprocessQueue1));
			inboundContainer2 = new QueueAuroraQueueContainer((name = systemConstants.inboundContainerName,
                                                         region = 2,
                                                         inQueueName = systemConstants.inboundQueueName,
                                                         inQueue = inboundQueue2,
                                                         databaseName = systemConstants.inboundDatabaseName,
                                                         database = inboundDatabase,
                                                         outQueueName = systemConstants.inboundPreprocessQueueName,
                                                         outQueue = inboundPreprocessQueue2));

			preprocessContainer1 = new QueueAuroraQueueContainer((name = systemConstants.preprocessContainerName,
                                                            region = 1,
                                                            inQueueName = systemConstants.inboundPreprocessQueueName,
                                                            inQueue = inboundPreprocessQueue1,
                                                            databaseName = systemConstants.preprocessDatabaseName,
                                                            database = preprocessDatabase,
                                                            outQueueName = systemConstants.preprocessCoreQueueName,
                                                            outQueue = preprocessCoreQueue1));
			preprocessContainer2 = new QueueAuroraQueueContainer((name = systemConstants.preprocessContainerName,
                                                            region = 2,
                                                            inQueueName = systemConstants.inboundPreprocessQueueName,
                                                            inQueue = inboundPreprocessQueue2,
                                                            databaseName = systemConstants.preprocessDatabaseName,
                                                            database = preprocessDatabase,
                                                            outQueueName = systemConstants.preprocessCoreQueueName,
                                                            outQueue = preprocessCoreQueue2));

			coreContainer1 = new QueueAuroraQueueContainer((name = systemConstants.coreContainerName,
                                                      region = 1,
                                                      inQueueName = systemConstants.preprocessCoreQueueName,
                                                      inQueue = preprocessCoreQueue1,
                                                      databaseName = systemConstants.coreDatabaseName,
                                                      database = coreDatabase,
                                                      outQueueName = systemConstants.corePostprocessQueueName,
                                                      outQueue = corePostprocessQueue1));
			coreContainer2 = new QueueAuroraQueueContainer((name = systemConstants.coreContainerName,
                                                      region = 2,
                                                      inQueueName = systemConstants.preprocessCoreQueueName,
                                                      inQueue = preprocessCoreQueue2,
                                                      databaseName = systemConstants.coreDatabaseName,
                                                      database = coreDatabase,
                                                      outQueueName = systemConstants.corePostprocessQueueName,
                                                      outQueue = corePostprocessQueue2));

			postprocessContainer1 = new QueueAuroraQueueContainer((name = systemConstants.postprocessContainerName,
                                                             region = 1,
                                                             inQueueName = systemConstants.corePostprocessQueueName,
                                                             inQueue = corePostprocessQueue1,
                                                             databaseName = systemConstants.postprocessDatabaseName,
                                                             database = postprocessDatabase,
                                                             outQueueName = systemConstants.postprocessOutboundQueueName,
                                                             outQueue = postprocessOutboundQueue1));
			postprocessContainer2 = new QueueAuroraQueueContainer((name = systemConstants.postprocessContainerName,
                                                             region = 2,
                                                             inQueueName = systemConstants.corePostprocessQueueName,
                                                             inQueue = corePostprocessQueue2,
                                                             databaseName = systemConstants.postprocessDatabaseName,
                                                             database = postprocessDatabase,
                                                             outQueueName = systemConstants.postprocessOutboundQueueName,
                                                             outQueue = postprocessOutboundQueue2));

			outboundContainer1 = new QueueAuroraQueueContainer((name = systemConstants.outboundContainerName,
                                                          region = 1,
                                                          inQueueName = systemConstants.postprocessOutboundQueueName,
                                                          inQueue = postprocessOutboundQueue1,
                                                          databaseName = systemConstants.outboundDatabaseName,
                                                          database = outboundDatabase,
                                                          outQueueName = systemConstants.outboundQueueName,
                                                          outQueue = outboundQueue1));
			outboundContainer2 = new QueueAuroraQueueContainer((name = systemConstants.outboundContainerName,
                                                          region = 2,
                                                          inQueueName = systemConstants.postprocessOutboundQueueName,
                                                          inQueue = postprocessOutboundQueue2,
                                                          databaseName = systemConstants.outboundDatabaseName,
                                                          database = outboundDatabase,
                                                          outQueueName = systemConstants.outboundQueueName,
                                                          outQueue = outboundQueue2));

			inDNS = new Route53DNSFailoverQueue((name = systemConstants.inDNSName,
                                           queue1Name = systemConstants.inboundQueueName,
                                           queue1 = inboundQueue1,
                                           queue2Name = systemConstants.inboundQueueName,
                                           queue2 = inboundQueue2));
			outDNS = new Route53DNSFailoverQueue((name = systemConstants.outDNSName,
                                            queue1Name = systemConstants.outboundQueueName,
                                            queue1 = outboundQueue1,
                                            queue2Name = systemConstants.outboundQueueName,
                                            queue2 = outboundQueue2));

			recordSourceDNS = new RecordSourceDNSFailoverQueue((name = systemConstants.recordSourceDNSName,
                                                          region = 1,
                                                          dnsName = systemConstants.inDNSName,
                                                          dns = inDNS,
                                                          records = records));
			recordDestinationDNS = new RecordDestinationDNSFailoverQueue((name = systemConstants.recordDestinationDNSName,
                                                                    region = 2,
                                                                    dnsName = systemConstants.outDNSName,
                                                                    dns = outDNS));
    }

		on eQueueReceiveNotification do (input: (name: string, region: int, count: int, invoker: machine)) {

			if (input.name == systemConstants.inboundQueueName && input.region == 1) {
				send inboundQueue1, eQueueReceiveNotification, (name = input.name, region = input.region, count = input.count, invoker = input.invoker);
			}
			else if (input.name == systemConstants.inboundQueueName && input.region == 2) {
				send inboundQueue2, eQueueReceiveNotification, (name = input.name, region = input.region, count = input.count, invoker = input.invoker);
			}
			else if (input.name == systemConstants.inboundPreprocessQueueName && input.region == 1) {
				send inboundPreprocessQueue1, eQueueReceiveNotification, (name = input.name, region = input.region, count = input.count, invoker = input.invoker);
			}
			else if (input.name == systemConstants.inboundPreprocessQueueName && input.region == 2) {
				send inboundPreprocessQueue2, eQueueReceiveNotification, (name = input.name, region = input.region, count = input.count, invoker = input.invoker);
			}
			else if (input.name == systemConstants.preprocessCoreQueueName && input.region == 1) {
				send preprocessCoreQueue1, eQueueReceiveNotification, (name = input.name, region = input.region, count = input.count, invoker = input.invoker);
			}
			else if (input.name == systemConstants.preprocessCoreQueueName && input.region == 2) {
				send preprocessCoreQueue2, eQueueReceiveNotification, (name = input.name, region = input.region, count = input.count, invoker = input.invoker);
			}
			else if (input.name == systemConstants.corePostprocessQueueName && input.region == 1) {
				send corePostprocessQueue1, eQueueReceiveNotification, (name = input.name, region = input.region, count = input.count, invoker = input.invoker);
			}
			else if (input.name == systemConstants.corePostprocessQueueName && input.region == 2) {
				send corePostprocessQueue2, eQueueReceiveNotification, (name = input.name, region = input.region, count = input.count, invoker = input.invoker);
			}
			else if (input.name == systemConstants.postprocessOutboundQueueName && input.region == 1) {
				send postprocessOutboundQueue1, eQueueReceiveNotification, (name = input.name, region = input.region, count = input.count, invoker = input.invoker);
			}
			else if (input.name == systemConstants.postprocessOutboundQueueName && input.region == 2) {
				send postprocessOutboundQueue2, eQueueReceiveNotification, (name = input.name, region = input.region, count = input.count, invoker = input.invoker);
			}
			else if (input.name == systemConstants.outboundQueueName && input.region == 1) {
				send outboundQueue1, eQueueReceiveNotification, (name = input.name, region = input.region, count = input.count, invoker = input.invoker);
			}
			else if (input.name == systemConstants.outboundQueueName && input.region == 2) {
				send outboundQueue2, eQueueReceiveNotification, (name = input.name, region = input.region, count = input.count, invoker = input.invoker);
			}
		}

		on eQueueFail do (input: (name: string, region: int, invoker: machine)) {

			if (input.name == systemConstants.inboundQueueName && input.region == 1) {
				send inboundQueue1, eQueueFail, (name = input.name, region = input.region, invoker = input.invoker);
			}
			else if (input.name == systemConstants.inboundQueueName && input.region == 2) {
				send inboundQueue2, eQueueFail, (name = input.name, region = input.region, invoker = input.invoker);
			}
			else if (input.name == systemConstants.inboundPreprocessQueueName && input.region == 1) {
				send inboundPreprocessQueue1, eQueueFail, (name = input.name, region = input.region, invoker = input.invoker);
			}
			else if (input.name == systemConstants.inboundPreprocessQueueName && input.region == 2) {
				send inboundPreprocessQueue2, eQueueFail, (name = input.name, region = input.region, invoker = input.invoker);
			}
			else if (input.name == systemConstants.preprocessCoreQueueName && input.region == 1) {
				send preprocessCoreQueue1, eQueueFail, (name = input.name, region = input.region, invoker = input.invoker);
			}
			else if (input.name == systemConstants.preprocessCoreQueueName && input.region == 2) {
				send preprocessCoreQueue2, eQueueFail, (name = input.name, region = input.region, invoker = input.invoker);
			}
			else if (input.name == systemConstants.corePostprocessQueueName && input.region == 1) {
				send corePostprocessQueue1, eQueueFail, (name = input.name, region = input.region, invoker = input.invoker);
			}
			else if (input.name == systemConstants.corePostprocessQueueName && input.region == 2) {
				send corePostprocessQueue2, eQueueFail, (name = input.name, region = input.region, invoker = input.invoker);
			}
			else if (input.name == systemConstants.postprocessOutboundQueueName && input.region == 1) {
				send postprocessOutboundQueue1, eQueueFail, (name = input.name, region = input.region, invoker = input.invoker);
			}
			else if (input.name == systemConstants.postprocessOutboundQueueName && input.region == 2) {
				send postprocessOutboundQueue2, eQueueFail, (name = input.name, region = input.region, invoker = input.invoker);
			}
			else if (input.name == systemConstants.outboundQueueName && input.region == 1) {
				send outboundQueue1, eQueueFail, (name = input.name, region = input.region, invoker = input.invoker);
			}
			else if (input.name == systemConstants.outboundQueueName && input.region == 2) {
				send outboundQueue2, eQueueFail, (name = input.name, region = input.region, invoker = input.invoker);
			}
		}

		on eQueueRecover do (input: (name: string, region: int)) {

			if (input.name == systemConstants.inboundQueueName && input.region == 1) {
				send inboundQueue1, eQueueRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.inboundQueueName && input.region == 2) {
				send inboundQueue2, eQueueRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.inboundPreprocessQueueName && input.region == 1) {
				send inboundPreprocessQueue1, eQueueRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.inboundPreprocessQueueName && input.region == 2) {
				send inboundPreprocessQueue2, eQueueRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.preprocessCoreQueueName && input.region == 1) {
				send preprocessCoreQueue1, eQueueRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.preprocessCoreQueueName && input.region == 2) {
				send preprocessCoreQueue2, eQueueRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.corePostprocessQueueName && input.region == 1) {
				send corePostprocessQueue1, eQueueRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.corePostprocessQueueName && input.region == 2) {
				send corePostprocessQueue2, eQueueRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.postprocessOutboundQueueName && input.region == 1) {
				send postprocessOutboundQueue1, eQueueRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.postprocessOutboundQueueName && input.region == 2) {
				send postprocessOutboundQueue2, eQueueRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.outboundQueueName && input.region == 1) {
				send outboundQueue1, eQueueRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.outboundQueueName && input.region == 2) {
				send outboundQueue2, eQueueRecover, (name = input.name, region = input.region);
			}
		}

		on eQueueAuroraQueueContainerFail do (input: (name: string, region: int)) {

			if (input.name == systemConstants.inboundContainerName && input.region == 1) {
				send inboundContainer1, eQueueAuroraQueueContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.inboundContainerName && input.region == 2) {
				send inboundContainer2, eQueueAuroraQueueContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.preprocessContainerName && input.region == 1) {
				send preprocessContainer1, eQueueAuroraQueueContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.preprocessContainerName && input.region == 2) {
				send preprocessContainer2, eQueueAuroraQueueContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.coreContainerName && input.region == 1) {
				send coreContainer1, eQueueAuroraQueueContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.coreContainerName && input.region == 2) {
				send coreContainer2, eQueueAuroraQueueContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.postprocessContainerName && input.region == 1) {
				send postprocessContainer1, eQueueAuroraQueueContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.postprocessContainerName && input.region == 2) {
				send postprocessContainer2, eQueueAuroraQueueContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.outboundContainerName && input.region == 1) {
				send outboundContainer1, eQueueAuroraQueueContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.outboundContainerName && input.region == 2) {
				send outboundContainer2, eQueueAuroraQueueContainerFail, (name = input.name, region = input.region);
			}
		}

		on eQueueAuroraQueueContainerRecover do (input: (name: string, region: int)) {

			if (input.name == systemConstants.inboundContainerName && input.region == 1) {
				send inboundContainer1, eQueueAuroraQueueContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.inboundContainerName && input.region == 2) {
				send inboundContainer2, eQueueAuroraQueueContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.preprocessContainerName && input.region == 1) {
				send preprocessContainer1, eQueueAuroraQueueContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.preprocessContainerName && input.region == 2) {
				send preprocessContainer2, eQueueAuroraQueueContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.coreContainerName && input.region == 1) {
				send coreContainer1, eQueueAuroraQueueContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.coreContainerName && input.region == 2) {
				send coreContainer2, eQueueAuroraQueueContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.postprocessContainerName && input.region == 1) {
				send postprocessContainer1, eQueueAuroraQueueContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.postprocessContainerName && input.region == 2) {
				send postprocessContainer2, eQueueAuroraQueueContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.outboundContainerName && input.region == 1) {
				send outboundContainer1, eQueueAuroraQueueContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.outboundContainerName && input.region == 2) {
				send outboundContainer2, eQueueAuroraQueueContainerRecover, (name = input.name, region = input.region);
			}
		}

		on eAuroraFail do (input: (name: string, invoker: machine)) {

			if (input.name == systemConstants.inboundDatabaseName) {
				send inboundDatabase, eAuroraFail, (name = input.name, invoker = input.invoker);
			}
			else if (input.name == systemConstants.preprocessDatabaseName) {
				send preprocessDatabase, eAuroraFail, (name = input.name, invoker = input.invoker);
			}
			else if (input.name == systemConstants.coreDatabaseName) {
				send coreDatabase, eAuroraFail, (name = input.name, invoker = input.invoker);
			}
			else if (input.name == systemConstants.postprocessDatabaseName) {
				send postprocessDatabase, eAuroraFail, (name = input.name, invoker = input.invoker);
			}
			else if (input.name == systemConstants.outboundDatabaseName) {
				send outboundDatabase, eAuroraFail, (name = input.name, invoker = input.invoker);
			}
		}

		on eAuroraRecover do (input: (name: string, invoker: machine)) {

			if (input.name == systemConstants.inboundDatabaseName) {
				send inboundDatabase, eAuroraRecover, (name = input.name, invoker = input.invoker);
			}
			else if (input.name == systemConstants.preprocessDatabaseName) {
				send preprocessDatabase, eAuroraRecover, (name = input.name, invoker = input.invoker);
			}
			else if (input.name == systemConstants.coreDatabaseName) {
				send coreDatabase, eAuroraRecover, (name = input.name, invoker = input.invoker);
			}
			else if (input.name == systemConstants.postprocessDatabaseName) {
				send postprocessDatabase, eAuroraRecover, (name = input.name, invoker = input.invoker);
			}
			else if (input.name == systemConstants.outboundDatabaseName) {
				send outboundDatabase, eAuroraRecover, (name = input.name, invoker = input.invoker);
			}
		} 

		on eAuroraFailReplication do (input: (name: string, invoker: machine)) {

			if (input.name == systemConstants.inboundDatabaseName) {
				send inboundDatabase, eAuroraFailReplication, (name = input.name, invoker = input.invoker);
			}
			else if (input.name == systemConstants.preprocessDatabaseName) {
				send preprocessDatabase, eAuroraFailReplication, (name = input.name, invoker = input.invoker);
			}
			else if (input.name == systemConstants.coreDatabaseName) {
				send coreDatabase, eAuroraFailReplication, (name = input.name, invoker = input.invoker);
			}
			else if (input.name == systemConstants.postprocessDatabaseName) {
				send postprocessDatabase, eAuroraFailReplication, (name = input.name, invoker = input.invoker);
			}
			else if (input.name == systemConstants.outboundDatabaseName) {
				send outboundDatabase, eAuroraFailReplication, (name = input.name, invoker = input.invoker);
			}
		}

		on eAuroraRecoverReplication do (input: (name: string)) {

			if (input.name == systemConstants.inboundDatabaseName) {
				send inboundDatabase, eAuroraRecoverReplication, (name = input.name, );
			}
			else if (input.name == systemConstants.preprocessDatabaseName) {
				send preprocessDatabase, eAuroraRecoverReplication, (name = input.name, );
			}
			else if (input.name == systemConstants.coreDatabaseName) {
				send coreDatabase, eAuroraRecoverReplication, (name = input.name, );
			}
			else if (input.name == systemConstants.postprocessDatabaseName) {
				send postprocessDatabase, eAuroraRecoverReplication, (name = input.name, );
			}
			else if (input.name == systemConstants.outboundDatabaseName) {
				send outboundDatabase, eAuroraRecoverReplication, (name = input.name, );
			}
		} 

		on eAuroraSwitchRegions do (input: (name: string, invoker: machine)) {

			if (input.name == systemConstants.inboundDatabaseName) {
				send inboundDatabase, eAuroraSwitchRegions, (name = input.name, invoker = input.invoker);
			}
			else if (input.name == systemConstants.preprocessDatabaseName) {
				send preprocessDatabase, eAuroraSwitchRegions, (name = input.name, invoker = input.invoker);
			}
			else if (input.name == systemConstants.coreDatabaseName) {
				send coreDatabase, eAuroraSwitchRegions, (name = input.name, invoker = input.invoker);
			}
			else if (input.name == systemConstants.postprocessDatabaseName) {
				send postprocessDatabase, eAuroraSwitchRegions, (name = input.name, invoker = input.invoker);
			}
			else if (input.name == systemConstants.outboundDatabaseName) {
				send outboundDatabase, eAuroraSwitchRegions, (name = input.name, invoker = input.invoker);
			}
    }

		on eRecordSourceDNSFailoverQueueGenerateRecords do (input: (name: string, region: int, batch: int, invoker: machine)) {

			send recordSourceDNS, eRecordSourceDNSFailoverQueueGenerateRecords, (name = input.name, region = input.region, batch = input.batch, invoker = input.invoker);
    }
		
		on eRecordDestinationDNSFailoverQueueReceiveNotification do (input: (name: string, region: int, count: int, invoker: machine)) {

			send recordDestinationDNS, eRecordDestinationDNSFailoverQueueReceiveNotification, (name = input.name, region = input.region, count = input.count, invoker = input.invoker);
		}

		on eRoute53DNSFailoverQueueSwitchRegions do (input: (name: string)) {

			if (input.name == systemConstants.inDNSName) {
				send inDNS, eRoute53DNSFailoverQueueSwitchRegions, (name = input.name, );
			}
			else if (input.name == systemConstants.outDNSName) {
				send outDNS, eRoute53DNSFailoverQueueSwitchRegions, (name = input.name, );
			}
		}
  }
}
