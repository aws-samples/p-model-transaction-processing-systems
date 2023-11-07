// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/*********************************************************
Events used to communicate with a Queue
**********************************************************/

// event: send record to the queue
event eQueueSendRecord: (name: string, region: int, record: tRecord, invoker: machine);
// event: send record to the queue completed
event eQueueSendRecordCompleted: (name: string, region: int, record: tRecord, success: bool);
// event: receive record from the queue
event eQueueReceiveRecord: (name: string, region: int, invoker: machine);
// event: receive record response from the queue
event eQueueReceiveRecordResponse: (name: string, region: int, record: tRecord, queueDepth: int, success: bool);
// event: delete record from the queue
event eQueueRemoveRecord: (name: string, region: int, record: tRecord, invoker: machine);
// event: delete record from the queue completed
event eQueueRemoveRecordCompleted: (name: string, region: int, record: tRecord, success: bool);
// event: get queue depth from the queue
event eQueueGetQueueDepth: (name: string, region: int, invoker: machine);
// event: get queue depth response from the queue
event eQueueGetQueueDepthResponse: (name: string, region: int, queueDepth: int, success: bool);
// event: receive notification from the queue
event eQueueReceiveNotification: (name: string, region: int, count: int, invoker: machine);
// event: receive notification response from the queue
event eQueueReceiveNotificationResponse: (name: string, region: int, count: int, success: bool);
// event: fail the queue
event eQueueFail: (name: string, region: int, invoker: machine);
// event: fail the queue completed
event eQueueFailCompleted: (name: string, region: int);
// event: recover the queue
event eQueueRecover: (name: string, region: int);
// event: kill the queue
event eQueueKill: (name: string, region: int);

/*************************************************************
A Queue as a State Machine
*************************************************************/
machine Queue {

  var name: string;
  var region: int;
  var receivers: seq[machine];
  var records: seq[tRecord];
  var count: int;
  var notificationCount: int;
  var notificationInvoker: machine;

  start state Init {

  	entry (input: (name: string, region: int)) {

			name = input.name;
			region = input.region;

			goto ProcessRecords;
		}
	}

 	state ProcessRecords {

    on eQueueSendRecord do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      var receiver: machine;
      var record: tRecord;

      records += (sizeof(records), input.record);
      count = count + 1;

      if (sizeof(receivers) > 0) {
        foreach (receiver in receivers) {
          if (sizeof(records) > 0) {
          	record = records[0];
            send receivers[0], eQueueReceiveRecordResponse, (name = name, region = region, record = records[0], queueDepth = sizeof(records), success = true);
            receivers -= (0);
          }
        }
      }

      if (count == notificationCount) {
      	send notificationInvoker, eQueueReceiveNotificationResponse, (name = name, region = region, count = count, success = true);
      }

      send input.invoker, eQueueSendRecordCompleted, (name = input.name, region = input.region, record = input.record, success = true);
    }

    on eQueueReceiveRecord do (input: (name: string, region: int, invoker: machine)) {

      var receiver: machine;
			var record: tRecord;


      if (!(input.invoker in receivers)) {

        receivers += (sizeof(receivers), input.invoker);

        if (sizeof(records) > 0) {
          foreach (receiver in receivers) {
            if (sizeof(records) > 0) {
              record = records[0];
              send receivers[0], eQueueReceiveRecordResponse, (name = name, region = region, record = record, queueDepth = sizeof(records), success = true);
              receivers -= (0);
            }
          }
        }
      }
    }

    on eQueueRemoveRecord do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      if (sizeof(records) > 0) {
        records -= (0);
      }

      send input.invoker, eQueueRemoveRecordCompleted, (name = input.name, region = input.region, record = input.record, success = true);
    }

    on eQueueGetQueueDepth do (input: (name: string, region: int, invoker: machine)) {

      send input.invoker, eQueueGetQueueDepthResponse, (name = name, region = region, queueDepth = sizeof(records), success = true);
    }

    on eQueueReceiveNotification do (input: (name: string, region: int, count: int, invoker: machine)) {

			notificationCount = input.count;
			notificationInvoker = input.invoker;
		}

		on eQueueFail do (input: (name: string, region: int, invoker: machine)) {

			send input.invoker, eQueueFailCompleted, (name = input.name, region = input.region);
			goto FailedProcessing;
		}

		ignore eQueueRecover;

		on eQueueKill do (input: (name: string, region: int)) {

			raise halt;
		}
  }

  state FailedProcessing {

    on eQueueSendRecord do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      send input.invoker, eQueueSendRecordCompleted, (name = input.name, region = input.region, record = input.record, success = false);
    }

    on eQueueReceiveRecord do (input: (name: string, region: int, invoker: machine)) {

			send input.invoker, eQueueReceiveRecordResponse, (name = name, region = region, record = (recordId = 0, recordValue = 0), queueDepth = 0, success = false);
    }

    on eQueueRemoveRecord do (input: (name: string, region: int, record: tRecord, invoker: machine)) {

      send input.invoker, eQueueRemoveRecordCompleted, (name = input.name, region = input.region, record = input.record, success = false);
    }

    on eQueueGetQueueDepth do (input: (name: string, region: int, invoker: machine)) {

      send input.invoker, eQueueGetQueueDepthResponse, (name = name, region = region, queueDepth = 0, success = false);
    }

    on eQueueReceiveNotification do (input: (name: string, region: int, count: int, invoker: machine)) {

			send input.invoker, eQueueReceiveNotificationResponse, (name = input.name, region = input.region, count = input.count, success = false);
		}

		ignore eQueueFail;

		on eQueueRecover do (input: (name: string, region: int)) {

			goto ProcessRecords;
		}

		on eQueueKill do (input: (name: string, region: int)) {

			raise halt;
		}
 	}
}

