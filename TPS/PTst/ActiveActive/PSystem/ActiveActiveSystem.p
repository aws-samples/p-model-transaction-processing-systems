// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/***************************************************************
This file contains the active-active machine
****************************************************************/

//
// The active-active machine.
//

machine ActiveActive {

	var systemConstants: tActiveActiveConstants;

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

	var inboundTable: DynamoGlobalTable;
	var preprocessTable: DynamoGlobalTable;
	var coreTable: DynamoGlobalTable;
	var postprocessTable: DynamoGlobalTable;
	var outboundTable: DynamoGlobalTable;

	var inboundContainer1: QueueDynamoQueueContainer;
	var inboundContainer2: QueueDynamoQueueContainer;

	var preprocessContainer1: QueueDynamoQueueContainer;
	var preprocessContainer2: QueueDynamoQueueContainer;

	var coreContainer1: QueueDynamoQueueContainer;
	var coreContainer2: QueueDynamoQueueContainer;

	var postprocessContainer1: QueueDynamoQueueContainer;
	var postprocessContainer2: QueueDynamoQueueContainer;

	var outboundContainer1: QueueDynamoQueueContainer;
	var outboundContainer2: QueueDynamoQueueContainer;

	var inDNS: Route53DNSWeightedQueue;
	var outDNS: Route53DNSWeightedQueue;

	var recordSourceDNS: RecordSourceDNSWeightedQueue;
	var recordDestinationDNS: RecordDestinationDNSWeightedQueue;

	var records: seq[seq[tRecord]];

  start state Init {

    entry (input: (systemConstants: tActiveActiveConstants,
									 records: seq[seq[tRecord]])) {

			systemConstants = input.systemConstants;							
			records = input.records;

			// inboundQueueName = "inbound-queue";
			inboundQueue1 = new Queue((name = systemConstants.inboundQueueName, region = 1));
			inboundQueue2 = new Queue((name = systemConstants.inboundQueueName, region = 2));

			// inboundPreprocessQueueName = "inbound-preprocess-queue";
			inboundPreprocessQueue1 = new Queue((name = systemConstants.inboundPreprocessQueueName, region = 1));
			inboundPreprocessQueue2 = new Queue((name = systemConstants.inboundPreprocessQueueName, region = 2));

			// preprocessCoreQueueName = "preprocess-core-queue";
			preprocessCoreQueue1 = new Queue((name = systemConstants.preprocessCoreQueueName, region = 1));
			preprocessCoreQueue2 = new Queue((name = systemConstants.preprocessCoreQueueName, region = 2));

			// corePostprocessQueueName = "core-postprocess-queue";
			corePostprocessQueue1 = new Queue((name = systemConstants.corePostprocessQueueName, region = 1));
			corePostprocessQueue2 = new Queue((name = systemConstants.corePostprocessQueueName, region = 2));

			// postprocessOutboundQueueName = "postprocess-outbound-queue";
			postprocessOutboundQueue1 = new Queue((name = systemConstants.postprocessOutboundQueueName, region = 1));
			postprocessOutboundQueue2 = new Queue((name = systemConstants.postprocessOutboundQueueName, region = 2));

			// outboundQueueName = "outbound-queue";
			outboundQueue1 = new Queue((name = systemConstants.outboundQueueName, region = 1));
			outboundQueue2 = new Queue((name = systemConstants.outboundQueueName, region = 2));

			// inboundTableName = "inbound-table";
			inboundTable = new DynamoGlobalTable((name = systemConstants.inboundTableName,));

			// preprocessTableName = "preprocess-table";
			preprocessTable = new DynamoGlobalTable((name = systemConstants.preprocessTableName,));

			// coreTableName = "core-table";
			coreTable = new DynamoGlobalTable((name = systemConstants.coreTableName,));

			// postprocessTableName = "postprocess-table";
			postprocessTable = new DynamoGlobalTable((name = systemConstants.postprocessTableName,));

			// outboundTableName = "outbound-table";
			outboundTable = new DynamoGlobalTable((name = systemConstants.outboundTableName,));

			// inboundContainerName = "inbound-container";
			inboundContainer1 = new QueueDynamoQueueContainer((name = systemConstants.inboundContainerName,
																												 region = 1,
																												 inQueueName = systemConstants.inboundQueueName,
																												 inQueue = inboundQueue1,
																												 tableName = systemConstants.inboundTableName,
																												 table = inboundTable,
																												 outQueueName = systemConstants.inboundPreprocessQueueName,
																												 outQueue = inboundPreprocessQueue1));
			inboundContainer2 = new QueueDynamoQueueContainer((name = systemConstants.inboundContainerName,
																												 region = 2,
																												 inQueueName = systemConstants.inboundQueueName,
																												 inQueue = inboundQueue2,
																												 tableName = systemConstants.inboundTableName,
																												 table = inboundTable,
																												 outQueueName = systemConstants.inboundPreprocessQueueName,
																												 outQueue = inboundPreprocessQueue2));

			// preprocessContainerName = "preprocess-container";
			preprocessContainer1 = new QueueDynamoQueueContainer((name = systemConstants.preprocessContainerName,
																													  region = 1,
																													  inQueueName = systemConstants.inboundPreprocessQueueName,
																													  inQueue = inboundPreprocessQueue1,
																													  tableName = systemConstants.preprocessTableName,
																													  table = preprocessTable,
																													  outQueueName = systemConstants.preprocessCoreQueueName,
																													  outQueue = preprocessCoreQueue1));
			preprocessContainer2 = new QueueDynamoQueueContainer((name = systemConstants.preprocessContainerName,
																													  region = 2,
																													  inQueueName = systemConstants.inboundPreprocessQueueName,
																													  inQueue = inboundPreprocessQueue2,
																													  tableName = systemConstants.preprocessTableName,
																													  table = preprocessTable,
																													  outQueueName = systemConstants.preprocessCoreQueueName,
																													  outQueue = preprocessCoreQueue2));

			// coreContainerName = "core-container";
			coreContainer1 = new QueueDynamoQueueContainer((name = systemConstants.coreContainerName,
																										  region = 1,
																										  inQueueName = systemConstants.preprocessCoreQueueName,
																										  inQueue = preprocessCoreQueue1,
																										  tableName = systemConstants.coreTableName,
																										  table = coreTable,
																										  outQueueName = systemConstants.corePostprocessQueueName,
																										  outQueue = corePostprocessQueue1));
			coreContainer2 = new QueueDynamoQueueContainer((name = systemConstants.coreContainerName,
																										  region = 2,
																										  inQueueName = systemConstants.preprocessCoreQueueName,
																										  inQueue = preprocessCoreQueue2,
																										  tableName = systemConstants.coreTableName,
																										  table = coreTable,
																										  outQueueName = systemConstants.corePostprocessQueueName,
																										  outQueue = corePostprocessQueue2));

			// postprocessContainerName = "postprocess-container";
			postprocessContainer1 = new QueueDynamoQueueContainer((name = systemConstants.postprocessContainerName,
																													  region = 1,
																													  inQueueName = systemConstants.corePostprocessQueueName,
																													  inQueue = corePostprocessQueue1,
																													  tableName = systemConstants.postprocessTableName,
																													  table = postprocessTable,
																													  outQueueName = systemConstants.postprocessOutboundQueueName,
																													  outQueue = postprocessOutboundQueue1));
			postprocessContainer2 = new QueueDynamoQueueContainer((name = systemConstants.postprocessContainerName,
																													  region = 2,
																													  inQueueName = systemConstants.corePostprocessQueueName,
																													  inQueue = corePostprocessQueue2,
																													  tableName = systemConstants.postprocessTableName,
																													  table = postprocessTable,
																													  outQueueName = systemConstants.postprocessOutboundQueueName,
																													  outQueue = postprocessOutboundQueue2));

			// outboundContainerName = "outbound-container";
			outboundContainer1 = new QueueDynamoQueueContainer((name = systemConstants.outboundContainerName,
																												  region = 1,
																												  inQueueName = systemConstants.postprocessOutboundQueueName,
																												  inQueue = postprocessOutboundQueue1,
																												  tableName = systemConstants.outboundTableName,
																												  table = outboundTable,
																												  outQueueName = systemConstants.outboundQueueName,
																												  outQueue = outboundQueue1));
			outboundContainer2 = new QueueDynamoQueueContainer((name = systemConstants.outboundContainerName,
																												  region = 2,
																												  inQueueName = systemConstants.postprocessOutboundQueueName,
																												  inQueue = postprocessOutboundQueue2,
																												  tableName = systemConstants.outboundTableName,
																												  table = outboundTable,
																												  outQueueName = systemConstants.outboundQueueName,
																												  outQueue = outboundQueue2));

			inDNS = new Route53DNSWeightedQueue((name = systemConstants.inDNSName,
																					 queue1Name = systemConstants.inboundQueueName,
																					 queue1 = inboundQueue1,
																					 queue2Name = systemConstants.inboundQueueName,
																					 queue2 = inboundQueue2));
								
			outDNS = new Route53DNSWeightedQueue((name = systemConstants.outDNSName,
																					  queue1Name = systemConstants.outboundQueueName,
																					  queue1 = outboundQueue1,
																					  queue2Name = systemConstants.outboundQueueName,
																					  queue2 = outboundQueue2));


			// recordSourceDNSName = "RecordSourceDNS";
			recordSourceDNS = new RecordSourceDNSWeightedQueue((name = systemConstants.recordSourceDNSName,
																												  region = 1,
																												  dnsName = systemConstants.inDNSName,
																												  dns = inDNS,
																												  records = records));
			// recordDestinationDNSName = "RecordDestinationDNS";
			recordDestinationDNS = new RecordDestinationDNSWeightedQueue((name = systemConstants.recordDestinationDNSName,
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

		on eQueueDynamoQueueContainerFail do (input: (name: string, region: int)) {

			if (input.name == systemConstants.inboundContainerName && input.region == 1) {
				send inboundContainer1, eQueueDynamoQueueContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.inboundContainerName && input.region == 2) {
				send inboundContainer2, eQueueDynamoQueueContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.preprocessContainerName && input.region == 1) {
				send preprocessContainer1, eQueueDynamoQueueContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.preprocessContainerName && input.region == 2) {
				send preprocessContainer2, eQueueDynamoQueueContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.coreContainerName && input.region == 1) {
				send coreContainer1, eQueueDynamoQueueContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.coreContainerName && input.region == 2) {
				send coreContainer2, eQueueDynamoQueueContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.postprocessContainerName && input.region == 1) {
				send postprocessContainer1, eQueueDynamoQueueContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.postprocessContainerName && input.region == 2) {
				send postprocessContainer2, eQueueDynamoQueueContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.outboundContainerName && input.region == 1) {
				send outboundContainer1, eQueueDynamoQueueContainerFail, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.outboundContainerName && input.region == 2) {
				send outboundContainer2, eQueueDynamoQueueContainerFail, (name = input.name, region = input.region);
			}
		}

		on eQueueDynamoQueueContainerRecover do (input: (name: string, region: int)) {

			if (input.name == systemConstants.inboundContainerName && input.region == 1) {
				send inboundContainer1, eQueueDynamoQueueContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.inboundContainerName && input.region == 2) {
				send inboundContainer2, eQueueDynamoQueueContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.preprocessContainerName && input.region == 1) {
				send preprocessContainer1, eQueueDynamoQueueContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.preprocessContainerName && input.region == 2) {
				send preprocessContainer2, eQueueDynamoQueueContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.coreContainerName && input.region == 1) {
				send coreContainer1, eQueueDynamoQueueContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.coreContainerName && input.region == 2) {
				send coreContainer2, eQueueDynamoQueueContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.postprocessContainerName && input.region == 1) {
				send postprocessContainer1, eQueueDynamoQueueContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.postprocessContainerName && input.region == 2) {
				send postprocessContainer2, eQueueDynamoQueueContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.outboundContainerName && input.region == 1) {
				send outboundContainer1, eQueueDynamoQueueContainerRecover, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.outboundContainerName && input.region == 2) {
				send outboundContainer2, eQueueDynamoQueueContainerRecover, (name = input.name, region = input.region);
			}
		}

		on eDynamoFail do (input: (name: string)) {

			if (input.name == systemConstants.inboundTableName) {
				send inboundTable, eDynamoFail, (name = input.name, );
			}
			else if (input.name == systemConstants.preprocessTableName) {
				send preprocessTable, eDynamoFail, (name = input.name, );
			}
			else if (input.name == systemConstants.coreTableName) {
				send coreTable, eDynamoFail, (name = input.name, );
			}
			else if (input.name == systemConstants.postprocessTableName) {
				send postprocessTable, eDynamoFail, (name = input.name, );
			}
			else if (input.name == systemConstants.outboundTableName) {
				send outboundTable, eDynamoFail, (name = input.name, );
			}
		}

		on eDynamoRecover do (input: (name: string)) {

			if (input.name == systemConstants.inboundTableName) {
				send inboundTable, eDynamoRecover, (name = input.name, );
			}
			else if (input.name == systemConstants.preprocessTableName) {
				send preprocessTable, eDynamoRecover, (name = input.name, );
			}
			else if (input.name == systemConstants.coreTableName) {
				send coreTable, eDynamoRecover, (name = input.name, );
			}
			else if (input.name == systemConstants.postprocessTableName) {
				send postprocessTable, eDynamoRecover, (name = input.name, );
			}
			else if (input.name == systemConstants.outboundTableName) {
				send outboundTable, eDynamoRecover, (name = input.name, );
			}
		} 

		on eDynamoFailReplication do (input: (name: string)) {

			if (input.name == systemConstants.inboundTableName) {
				send inboundTable, eDynamoFailReplication, (name = input.name, );
			}
			else if (input.name == systemConstants.preprocessTableName) {
				send preprocessTable, eDynamoFailReplication, (name = input.name, );
			}
			else if (input.name == systemConstants.coreTableName) {
				send coreTable, eDynamoFailReplication, (name = input.name, );
			}
			else if (input.name == systemConstants.postprocessTableName) {
				send postprocessTable, eDynamoFailReplication, (name = input.name, );
			}
			else if (input.name == systemConstants.outboundTableName) {
				send outboundTable, eDynamoFailReplication, (name = input.name, );
			}
		}

		on eDynamoRecoverReplication do (input: (name: string)) {

			if (input.name == systemConstants.inboundTableName) {
				send inboundTable, eDynamoRecoverReplication, (name = input.name, );
			}
			else if (input.name == systemConstants.preprocessTableName) {
				send preprocessTable, eDynamoRecoverReplication, (name = input.name, );
			}
			else if (input.name == systemConstants.coreTableName) {
				send coreTable, eDynamoRecoverReplication, (name = input.name, );
			}
			else if (input.name == systemConstants.postprocessTableName) {
				send postprocessTable, eDynamoRecoverReplication, (name = input.name, );
			}
			else if (input.name == systemConstants.outboundTableName) {
				send outboundTable, eDynamoRecoverReplication, (name = input.name, );
			}
		} 

		on eRecordSourceDNSWeightedQueueGenerateRecords do (input: (name: string, region: int, batch: int, invoker: machine)) {

			send recordSourceDNS, eRecordSourceDNSWeightedQueueGenerateRecords, (name = input.name, region = input.region, batch = input.batch, invoker = input.invoker);
    }
		
		on eRecordDestinationDNSWeightedQueueReceiveNotification do (input: (name: string, region: int, count: int, invoker: machine)) {

			send recordDestinationDNS, eRecordDestinationDNSWeightedQueueReceiveNotification, (name = input.name, region = input.region, count = input.count, invoker = input.invoker);
		}

		on eRoute53DNSWeightedQueueSwitchRegionOffline do (input: (name: string, region: int)) {

			if (input.name == systemConstants.inDNSName) {
				send inDNS, eRoute53DNSWeightedQueueSwitchRegionOffline, (name = input.name, region = input.region);
			}
			else if (input.name == systemConstants.outDNSName) {
				send outDNS, eRoute53DNSWeightedQueueSwitchRegionOffline, (name = input.name, region = input.region);
			}
		}
  }
}
