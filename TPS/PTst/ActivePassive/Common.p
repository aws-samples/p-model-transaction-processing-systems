// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

type tActivePassiveConstants = (inboundQueueName: string, 
                               inboundPreprocessQueueName: string,
                               preprocessCoreQueueName: string, 
                               corePostprocessQueueName: string, 
                               postprocessOutboundQueueName: string,
                               outboundQueueName: string,
                               inboundDatabaseName: string,
                               preprocessDatabaseName: string,
                               coreDatabaseName: string,
                               postprocessDatabaseName: string,
                               outboundDatabaseName: string,
                               inboundContainerName: string,
                               preprocessContainerName: string,
                               coreContainerName: string,
                               postprocessContainerName: string,
                               outboundContainerName: string,
                               inDNSName: string,
                               outDNSName: string,
                               recordSourceDNSName: string, 
                               recordDestinationDNSName: string);

fun getActivePassiveConstants(): tActivePassiveConstants {

  return (inboundQueueName = "inbound-queue", 
          inboundPreprocessQueueName = "inbound-preprocess-queue",
          preprocessCoreQueueName = "preprocess-core-queue", 
          corePostprocessQueueName = "core-postprocess-queue", 
          postprocessOutboundQueueName = "postprocess-outbound-queue",
          outboundQueueName = "outbound-queue",
          inboundDatabaseName = "inbound-database",
          preprocessDatabaseName = "preprocess-database",
          coreDatabaseName = "core-database",
          postprocessDatabaseName = "postprocess-database",
          outboundDatabaseName = "outbound-database",
          inboundContainerName = "inbound-container",
          preprocessContainerName = "preprocess-container",
          coreContainerName = "core-container",
          postprocessContainerName = "postprocess-container",
          outboundContainerName = "outbound-container",
          inDNSName = "in-dns",
          outDNSName = "out-dns",
          recordSourceDNSName = "record-source-dns", 
          recordDestinationDNSName = "decord-destination-dns");
}                