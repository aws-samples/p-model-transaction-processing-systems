// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/**********************************************************************************
Events used to communicate with Route 53 DNS with weighted policy routing to an API
***********************************************************************************/

// event: send record to Route 53 DNS
event eRoute53DNSWeightedAPISendRecord: (name: string, record: tRecord, invoker: machine);
// event: send record to Route 53 DNS completed
event eRoute53DNSWeightedAPISendRecordCompleted: (name: string, record: tRecord, success: bool);
// event: switch region offline
event eRoute53DNSWeightedAPISwitchRegionOffline: (name: string, region: int);
// event: set the api1
event eRoute53DNSWeightedAPISetAPI1: (name: string, region: int, api1: APIMongoAPIContainer, invoker: machine);
// event: set the api1 completed
event eRoute53DNSWeightedAPISetAPI1Completed: (name: string, region: int, api1: APIMongoAPIContainer, success: bool);
// event: set the api2
event eRoute53DNSWeightedAPISetAPI2: (name: string, region: int, api2: APIMongoAPIContainer, invoker: machine);
// event: set the api2 completed
event eRoute53DNSWeightedAPISetAPI2Completed: (name: string, region: int, api2: APIMongoAPIContainer, success: bool);

/***********************************************************************************
 Route 53 DNS with Weighted Routing as a State Machine forwarding messages to an API
************************************************************************************/
machine Route53DNSWeightedAPI {

  var name: string;
  var api1Name: string;
  var api1: APIMongoAPIContainer;
  var api2Name: string;
  var api2: APIMongoAPIContainer;
	var currentRegion: int;
	var receiver: machine;
	var offlineRegion: int;

  start state Init {

    entry (input: (name: string, api1Name: string, api1: APIMongoAPIContainer, api2Name: string, api2: APIMongoAPIContainer)) {
      name = input.name;
      api1Name = input.api1Name;
      api1 = input.api1;
      api2Name = input.api2Name;
      api2 = input.api2;
      currentRegion = 1;
      offlineRegion = 0;
      goto ProcessRecords;
    }
  }

  state ProcessRecords {

    on eRoute53DNSWeightedAPISendRecord do (input: (name: string, record: tRecord, invoker: machine)) {

			if (offlineRegion == 0) {

				if (currentRegion == 1) {
					send api1, eAPIMongoAPIContainerInvoke, (name = api1Name, region = 1, record = input.record, invoker = this);
					receive {
						case eAPIMongoAPIContainerInvokeCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
							send input.invoker, eRoute53DNSWeightedAPISendRecordCompleted, (name = input.name, record = input.record, success = input2.success);
							if (input2.success == true) {
							  currentRegion = 2;
							}
						}
					}
				}
				else {
					send api2, eAPIMongoAPIContainerInvoke, (name = api2Name, region = 2, record = input.record, invoker = this);
					receive {
						case eAPIMongoAPIContainerInvokeCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
							send input.invoker, eRoute53DNSWeightedAPISendRecordCompleted, (name = input.name, record = input.record, success = input2.success);
							if (input2.success == true) {
							  currentRegion = 1;
							}
						}
					}
				}
    	}
    	else {

    		if (offlineRegion == 1) {
					send api2, eAPIMongoAPIContainerInvoke, (name = api2Name, region = 2, record = input.record, invoker = this);
					receive {
						case eAPIMongoAPIContainerInvokeCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
							send input.invoker, eRoute53DNSWeightedAPISendRecordCompleted, (name = input.name, record = input.record, success = input2.success);
						}
					}
				}
				else {
					send api1, eAPIMongoAPIContainerInvoke, (name = api1Name, region = 1, record = input.record, invoker = this);
					receive {
						case eAPIMongoAPIContainerInvokeCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
							send input.invoker, eRoute53DNSWeightedAPISendRecordCompleted, (name = input.name, record = input.record, success = input2.success);
						}
					}
				}
    	}
    }

		on eRoute53DNSWeightedAPISetAPI1 do (input: (name: string, region: int, api1: APIMongoAPIContainer, invoker: machine)) {

			api1 = input.api1;

			if (offlineRegion != 1) {
				send input.invoker, eRoute53DNSWeightedAPISetAPI1Completed, (name = name, region = input.region, api1 = api1, success = true);
			}
		}

		on eRoute53DNSWeightedAPISetAPI2 do (input: (name: string, region: int, api2: APIMongoAPIContainer, invoker: machine)) {

			api2 = input.api2;

			if (offlineRegion != 2) {
				send input.invoker, eRoute53DNSWeightedAPISetAPI2Completed, (name = name, region = input.region, api2 = api1, success = true);
			}
		}

		on eRoute53DNSWeightedAPISwitchRegionOffline do (input: (name: string, region: int)) {

			offlineRegion = input.region;
		}
  }
}

