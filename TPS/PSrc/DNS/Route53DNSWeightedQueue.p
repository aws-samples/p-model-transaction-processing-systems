// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/*********************************************************
Events used to communicate with Route 53 DNS
**********************************************************/

// event: send record to Route 53 DNS
event eRoute53DNSWeightedQueueSendRecord: (name: string, record: tRecord, invoker: machine);
// event: send record to Route 53 DNS completed
event eRoute53DNSWeightedQueueSendRecordCompleted: (name: string, record: tRecord, success: bool);
// event: receive record from Route 53 DNS
event eRoute53DNSWeightedQueueReceiveRecord: (name: string, region: int, invoker: machine);
// event: remove record from Route 53 DNS
event eRoute53DNSWeightedQueueRemoveRecord: (name: string, region: int, record: tRecord, invoker: machine);
// event: remove record from Route 53 DNS completed
event eRoute53DNSWeightedQueueRemoveRecordCompleted: (name: string, region: int, record: tRecord, success: bool);
// event: switch region offline
event eRoute53DNSWeightedQueueSwitchRegionOffline: (name: string, region: int);
// event: set the queue1
event eRoute53DNSWeightedQueueSetQueue1: (name: string, region: int, queue1: Queue, invoker: machine);
// event: set the queue1 completed
event eRoute53DNSWeightedQueueSetQueue1Completed: (name: string, region: int, queue1: Queue, success: bool);
// event: set the queue2
event eRoute53DNSWeightedQueueSetQueue2: (name: string, region: int, queue2: Queue, invoker: machine);
// event: set the queue2 completed
event eRoute53DNSWeightedQueueSetQueue2Completed: (name: string, region: int, queue2: Queue, success: bool);

/*************************************************************
 Route 53 DNS with Weighted Routing as a State Machine
**************************************************************/
machine Route53DNSWeightedQueue {

  var name: string;
  var queue1Name: string;
  var queue1: Queue;
  var queue2Name: string;
  var queue2: Queue;
	var currentRegion: int;
	var receiver: machine;
	var offlineRegion: int;

  start state Init {

    entry (input: (name: string, queue1Name: string, queue1: Queue, queue2Name: string, queue2: Queue)) {
      name = input.name;
      queue1Name = input.queue1Name;
      queue1 = input.queue1;
      queue2Name = input.queue2Name;
      queue2 = input.queue2;
      currentRegion = 1;
      offlineRegion = 0;
      goto ProcessRecords;
    }
  }

  state ProcessRecords {

    on eRoute53DNSWeightedQueueSendRecord do (input: (name: string, record: tRecord, invoker: machine)) {

			if (offlineRegion == 0) {

				if (currentRegion == 1) {
					send queue1, eQueueSendRecord, (name = queue1Name, region = 1, record = input.record, invoker = this);
					receive {
						case eQueueSendRecordCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
							send input.invoker, eRoute53DNSWeightedQueueSendRecordCompleted, (name = input.name, record = input.record, success = input2.success);
							if (input2.success == true) {
							  currentRegion = 2;
							}
						}
					}
				}
				else {
					send queue2, eQueueSendRecord, (name = queue2Name, region = 2, record = input.record, invoker = this);
					receive {
						case eQueueSendRecordCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
							send input.invoker, eRoute53DNSWeightedQueueSendRecordCompleted, (name = input.name, record = input.record, success = input2.success);
							if (input2.success == true) {
							  currentRegion = 1;
							}
						}
					}
				}
    	}
    	else {

    		if (offlineRegion == 1) {
					send queue2, eQueueSendRecord, (name = queue2Name, region = 2, record = input.record, invoker = this);
					receive {
						case eQueueSendRecordCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
							send input.invoker, eRoute53DNSWeightedQueueSendRecordCompleted, (name = input.name, record = input.record, success = input2.success);
						}
					}
				}
				else {
					send queue1, eQueueSendRecord, (name = queue1Name, region = 1, record = input.record, invoker = this);
					receive {
						case eQueueSendRecordCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
							send input.invoker, eRoute53DNSWeightedQueueSendRecordCompleted, (name = input.name, record = input.record, success = input2.success);
						}
					}
				}
    	}
    }

		on eRoute53DNSWeightedQueueReceiveRecord do (input: (name: string, region: int, invoker: machine)) {

			receiver = input.invoker;

			if (offlineRegion == 0) {

				if (input.region == 1) {
					send queue1, eQueueReceiveRecord, (name = queue1Name, region = 1, invoker = input.invoker);
				}
				else {
					send queue2, eQueueReceiveRecord, (name = queue2Name, region = 2, invoker = input.invoker);
				}
			}
			else {
				if (offlineRegion == 1) {
					send queue2, eQueueReceiveRecord, (name = queue2Name, region = 2, invoker = input.invoker);
				}
				else {
					send queue1, eQueueReceiveRecord, (name = queue1Name, region = 1, invoker = input.invoker);
				}
			}
		}

		on eRoute53DNSWeightedQueueRemoveRecord do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

			if (offlineRegion == 0) {
				if (input.region == 1) {
					send queue1, eQueueRemoveRecord, (name = queue1Name, region = 1, record = input.record, invoker = this);
					receive {
						case eQueueRemoveRecordCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
							send input.invoker, eRoute53DNSWeightedQueueRemoveRecordCompleted, (name = input.name, region = input.region, record = input.record, success = true);
						}
					}
					currentRegion = 2;
				}
				else {
					send queue2, eQueueRemoveRecord, (name = queue2Name, region = 2, record = input.record, invoker = this);
					receive {
						case eQueueRemoveRecordCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
							send input.invoker, eRoute53DNSWeightedQueueRemoveRecordCompleted, (name = input.name, region = input.region, record = input.record, success = true);
						}
					}
					currentRegion = 1;
				}
			}
			else {
				if (offlineRegion == 1) {
					send queue2, eQueueRemoveRecord, (name = queue2Name, region = 2, record = input.record, invoker = this);
					receive {
						case eQueueRemoveRecordCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
							send input.invoker, eRoute53DNSWeightedQueueRemoveRecordCompleted, (name = input.name, region = input.region, record = input.record, success = true);
						}
					}
				}
				else {
					send queue1, eQueueRemoveRecord, (name = queue1Name, region = 1, record = input.record, invoker = this);
					receive {
						case eQueueRemoveRecordCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
							send input.invoker, eRoute53DNSWeightedQueueRemoveRecordCompleted, (name = input.name, region = input.region, record = input.record, success = true);
						}
					}
				}
			}
		}

		on eRoute53DNSWeightedQueueSetQueue1 do (input: (name: string, region: int, queue1: Queue, invoker: machine)) {

			queue1 = input.queue1;
			if (receiver != null) {
				send queue1, eQueueReceiveRecord, (name = queue1Name, region = 1, invoker = receiver);
			}

			if (offlineRegion != 1) {
				send input.invoker, eRoute53DNSWeightedQueueSetQueue1Completed, (name = name, region = input.region, queue1 = queue1, success = true);
			}
		}

		on eRoute53DNSWeightedQueueSetQueue2 do (input: (name: string, region: int, queue2: Queue, invoker: machine)) {

			queue2 = input.queue2;
			if (receiver != null) {
				send queue1, eQueueReceiveRecord, (name = queue1Name, region = 1, invoker = receiver);
			}

			if (offlineRegion != 2) {
				send input.invoker, eRoute53DNSWeightedQueueSetQueue2Completed, (name = name, region = input.region, queue2 = queue1, success = true);
			}
		}

		on eRoute53DNSWeightedQueueSwitchRegionOffline do (input: (name: string, region: int)) {

			offlineRegion = input.region;
		}
  }
}

