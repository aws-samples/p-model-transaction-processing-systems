// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

type tWorkload1Constants = (inboundKafkaName: string, 
                            outboundKafkaName: string,
                            receiverDatabaseName: string, 
                            validatorDatabaseName: string, 
                            processorDatabaseName: string,
                            receiverContainerName: string,
                            validatorContainerName: string,
                            processorContainerName: string,
                            inDNSName: string,
                            outDNSName: string,
                            recordSourceDNSName: string, 
                            recordDestinationDNSName: string);

fun getWorkload1Constants(): tWorkload1Constants {

  return (inboundKafkaName = "inbound-kafka", 
          outboundKafkaName = "outbound-kafka",
          receiverDatabaseName = "receiver-database", 
          validatorDatabaseName = "validator-database", 
          processorDatabaseName = "processor-database",
          receiverContainerName = "receiver-container",
          validatorContainerName = "validator-container",
          processorContainerName = "processor-container",
          inDNSName = "in-dns",
          outDNSName = "out-dns",
          recordSourceDNSName = "record-source-dns", 
          recordDestinationDNSName = "decord-destination-dns");
}                