// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

type tActiveActiveConstants = (inboundQueueName: string, 
                               inboundPreprocessQueueName: string,
                               preprocessCoreQueueName: string, 
                               corePostprocessQueueName: string, 
                               postprocessOutboundQueueName: string,
                               outboundQueueName: string,
                               inboundTableName: string,
                               preprocessTableName: string,
                               coreTableName: string,
                               postprocessTableName: string,
                               outboundTableName: string,
                               inboundContainerName: string,
                               preprocessContainerName: string,
                               coreContainerName: string,
                               postprocessContainerName: string,
                               outboundContainerName: string,
                               inDNSName: string,
                               outDNSName: string,
                               recordSourceDNSName: string, 
                               recordDestinationDNSName: string);

fun getActiveActiveConstants(): tActiveActiveConstants {

  return (inboundQueueName = "inbound-queue", 
          inboundPreprocessQueueName = "inbound-preprocess-queue",
          preprocessCoreQueueName = "preprocess-core-queue", 
          corePostprocessQueueName = "core-postprocess-queue", 
          postprocessOutboundQueueName = "postprocess-outbound-queue",
          outboundQueueName = "outbound-queue",
          inboundTableName = "inbound-table",
          preprocessTableName = "preprocess-table",
          coreTableName = "core-table",
          postprocessTableName = "postprocess-table",
          outboundTableName = "outbound-table",
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