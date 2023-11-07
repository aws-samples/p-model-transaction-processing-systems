// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/*********************************************************
Events used to communicate with Route 53 DNS
**********************************************************/

// event: send record to Route 53 DNS
event eRoute53DNSFailoverQueueSendRecord: (name: string, record: tRecord, invoker: machine);
// event: send record to Route 53 DNS completed
event eRoute53DNSFailoverQueueSendRecordCompleted: (name: string, record: tRecord, success: bool);
// event: receive record from Route 53 DNS
event eRoute53DNSFailoverQueueReceiveRecord: (name: string, invoker: machine);
// event: remove record from Route 53 DNS
event eRoute53DNSFailoverQueueRemoveRecord: (name: string, record: tRecord, invoker: machine);
// event: remove record from Route 53 DNS completed
event eRoute53DNSFailoverQueueRemoveRecordCompleted: (name: string, record: tRecord, success: bool);
// event: switch active and passive region
event eRoute53DNSFailoverQueueSwitchRegions: (name: string);
// event: set the queue1
event eRoute53DNSFailoverQueueSetQueue1: (name: string, region: int, queue1: Queue, invoker: machine);
// event: set the queue1 completed
event eRoute53DNSFailoverQueueSetQueue1Completed: (name: string, region: int, queue1: Queue, success: bool);
// event: set the queue2
event eRoute53DNSFailoverQueueSetQueue2: (name: string, region: int, queue2: Queue, invoker: machine);
// event: set the queue2 completed
event eRoute53DNSFailoverQueueSetQueue2Completed: (name: string, region: int, queue2: Queue, success: bool);

/*************************************************************
 Route 53 DNS with Failover Routing as a State Machine
**************************************************************/
machine Route53DNSFailoverQueue {

  var name: string;
  var queue1Name: string;
  var queue1: Queue;
  var queue2Name: string;
  var queue2: Queue;
  var receiver: machine;

  start state Init {

    entry (input: (name: string, queue1Name: string, queue1: Queue, queue2Name: string, queue2: Queue)) {
      name = input.name;
      queue1Name = input.queue1Name;
      queue1 = input.queue1;
      queue2Name = input.queue2Name;
      queue2 = input.queue2;
      goto Region1Active;
    }
  }

  state Region1Active {

    entry {
    }

    on eRoute53DNSFailoverQueueSendRecord do (input: (name: string, record: tRecord, invoker: machine)) {
    	send queue1, eQueueSendRecord, (name = queue1Name, region = 1, record = input.record, invoker = this);
			receive {
				case eQueueSendRecordCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
					send input.invoker, eRoute53DNSFailoverQueueSendRecordCompleted, (name = input2.name, record = input2.record, success = input2.success);
				}
			}
    }

		on eRoute53DNSFailoverQueueReceiveRecord do (input: (name: string, invoker: machine)) {
			receiver = input.invoker;
			send queue1, eQueueReceiveRecord, (name = queue1Name, region = 1, invoker = input.invoker);
			send queue2, eQueueReceiveRecord, (name = queue1Name, region = 1, invoker = input.invoker);
		}

		on eRoute53DNSFailoverQueueRemoveRecord do (input: (name: string, record: tRecord, invoker: machine)) {
			send queue1, eQueueRemoveRecord, (name = queue1Name, region = 1, record = input.record, invoker = this);
			receive {
				case eQueueRemoveRecordCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
					send input.invoker, eRoute53DNSFailoverQueueRemoveRecordCompleted, (name = input2.name, record = input2.record, success = input2.success);
				}
			}
		}

    on eRoute53DNSFailoverQueueSwitchRegions do (input: (name: string)) {
      goto Region2Active;
    }

		on eRoute53DNSFailoverQueueSetQueue1 do (input: (name: string, region: int, queue1: Queue, invoker: machine)) {

			queue1 = input.queue1;
			if (receiver != null) {
				send queue1, eQueueReceiveRecord, (name = queue1Name, region = 1, invoker = receiver);
			}

			send input.invoker, eRoute53DNSFailoverQueueSetQueue1Completed, (name = name, region = input.region, queue1 = queue1, success = true);
		}

		on eRoute53DNSFailoverQueueSetQueue2 do (input: (name: string, region: int, queue2: Queue, invoker: machine)) {

			queue2 = input.queue2;
			send input.invoker, eRoute53DNSFailoverQueueSetQueue2Completed, (name = name, region = input.region, queue2 = queue1, success = true);
		}
  }

  state Region2Active {

    entry {
    }

    on eRoute53DNSFailoverQueueSendRecord do (input: (name: string, record: tRecord, invoker: machine)) {
			send queue2, eQueueSendRecord, (name = queue2Name, region = 2, record = input.record, invoker = this);
			receive {
				case eQueueSendRecordCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
					send input.invoker, eRoute53DNSFailoverQueueSendRecordCompleted, (name = input2.name, record = input2.record, success = input2.success);
				}
			}
		}

		on eRoute53DNSFailoverQueueReceiveRecord do (input: (name: string, invoker: machine)) {
			send queue2, eQueueReceiveRecord, (name = queue2Name, region = 2, invoker = input.invoker);
		}

		on eRoute53DNSFailoverQueueRemoveRecord do (input: (name: string, record: tRecord, invoker: machine)) {
			send queue2, eQueueRemoveRecord, (name = queue2Name, region = 2, record = input.record, invoker = this);
			receive {
				case eQueueRemoveRecordCompleted: (input2: (name: string, region: int, record: tRecord, success: bool)) {
					send input.invoker, eRoute53DNSFailoverQueueRemoveRecordCompleted, (name = input2.name, record = input2.record, success = input2.success);
				}
			}
		}

		on eRoute53DNSFailoverQueueSwitchRegions do (input: (name: string)) {
			goto Region1Active;
		}

		on eRoute53DNSFailoverQueueSetQueue1 do (input: (name: string, region: int, queue1: Queue, invoker: machine)) {

			queue1 = input.queue1;
			send input.invoker, eRoute53DNSFailoverQueueSetQueue1Completed, (name = name, region = input.region, queue1 = queue1, success = true);
		}

		on eRoute53DNSFailoverQueueSetQueue2 do (input: (name: string, region: int, queue2: Queue, invoker: machine)) {

			queue2 = input.queue2;
			send input.invoker, eRoute53DNSFailoverQueueSetQueue2Completed, (name = name, region = input.region, queue2 = queue1, success = true);
		}
  }
}

