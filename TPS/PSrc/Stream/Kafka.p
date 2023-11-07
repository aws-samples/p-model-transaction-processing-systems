// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/*********************************************************
Events used to communicate with a Kafka stream
**********************************************************/

// event: send records to the queue
event eKafkaSendRecords: (name: string, region: int, records: seq[tRecord], invoker: machine);
// event: send records to the queue completed
event eKafkaSendRecordsCompleted: (name: string, region: int, records: seq[tRecord], success: bool);
// event: receive records from the queue
event eKafkaReceiveRecords: (name: string, region: int, invoker: machine);
// event: receive records response from the queue
event eKafkaReceiveRecordsResponse: (name: string, region: int, records: seq[tRecord], kafkaDepth: int, success: bool);
// event: remove records from the queue
event eKafkaRemoveRecords: (name: string, region: int, records: seq[tRecord], invoker: machine);
// event: remove records from the queue completed
event eKafkaRemoveRecordsCompleted: (name: string, region: int, records: seq[tRecord], success: bool);
// event: get queue depth from the queue
event eKafkaGetKafkaDepth: (name: string, region: int, invoker: machine);
// event: get queue depth response from the queue
event eKafkaGetKafkaDepthResponse: (name: string, region: int, kafkaDepth: int, success: bool);
// event: receive notification from the queue
event eKafkaReceiveNotification: (name: string, region: int, count: int, invoker: machine);
// event: receive notification response from the queue
event eKafkaReceiveNotificationResponse: (name: string, region: int, count: int, success: bool);
// event: fail the queue
event eKafkaFail: (name: string, region: int, invoker: machine);
// event: fail the queue completed
event eKafkaFailCompleted: (name: string, region: int);
// event: recover the queue
event eKafkaRecover: (name: string, region: int);
// event: kill the queue
event eKafkaKill: (name: string, region: int);

/*************************************************************
A Kafka as a State Machine
*************************************************************/
machine Kafka {

  var name: string;
  var region: int;
  var batch: int;
  var receivers: seq[machine];
  var records: seq[tRecord];
  var count: int;
  var notificationCount: int;
  var notificationInvoker: machine;

  start state Init {

  	entry (input: (name: string, region: int, batch: int)) {

			name = input.name;
			region = input.region;
			batch = input.batch;

			goto ProcessRecords;
		}
	}

 	state ProcessRecords {

    on eKafkaSendRecords do (input: (name: string, region: int, records: seq[tRecord], invoker: machine)) {

      var receiver: machine;
      var record: tRecord;
      var recordsToSend: seq[tRecord];
      var emptyRecords: seq[tRecord];
      var i: int;

      foreach (record in input.records) {
        records += (sizeof(records), record);
        count = count + 1;
      }

      if (sizeof(records) >= batch) {
        foreach (receiver in receivers) {
          if (sizeof(records) >= batch) {
            i = 0;
            recordsToSend = emptyRecords;
            while (i < batch) {
              recordsToSend += (sizeof(recordsToSend), records[i]);
              i = i + 1;
            }
            send receivers[0], eKafkaReceiveRecordsResponse, (name = name, region = region, records = recordsToSend, kafkaDepth = sizeof(records), success = true);
            receivers -= (0);
          }
        }
      }

      if (count == notificationCount) {
      	send notificationInvoker, eKafkaReceiveNotificationResponse, (name = name, region = region, count = count, success = true);
      }

      send input.invoker, eKafkaSendRecordsCompleted, (name = input.name, region = input.region, records = input.records, success = true);
    }

    on eKafkaReceiveRecords do (input: (name: string, region: int, invoker: machine)) {

      var receiver: machine;
			var record: tRecord;
      var recordsToSend: seq[tRecord];
      var i: int;

      if (!(input.invoker in receivers)) {

        receivers += (sizeof(receivers), input.invoker);

        if (sizeof(records) >= batch) {
          foreach (receiver in receivers) {
            if (sizeof(records) >= batch) {
              i = 0;
              while (i < batch) {
                recordsToSend += (sizeof(recordsToSend), records[i]);
                i = i + 1;
              }
              send receivers[0], eKafkaReceiveRecordsResponse, (name = name, region = region, records = recordsToSend, kafkaDepth = sizeof(records), success = true);
              receivers -= (0);
            }
          }
        }
      }
    }

    on eKafkaRemoveRecords do (input: (name: string, region: int, records: seq[tRecord], invoker: machine)) {

			var inputRecord: tRecord;
			var record: tRecord;
      var i: int;

      foreach (inputRecord in input.records) {
        i = 0;
        foreach(record in records) {
          if (inputRecord.recordId == record.recordId) {
            records -= (i);
            break;
          }
          i = i + 1;
        }
      }

      send input.invoker, eKafkaRemoveRecordsCompleted, (name = input.name, region = input.region, records = input.records, success = true);
    }

    on eKafkaGetKafkaDepth do (input: (name: string, region: int, invoker: machine)) {

      send input.invoker, eKafkaGetKafkaDepthResponse, (name = name, region = region, kafkaDepth = sizeof(records), success = true);
    }

    on eKafkaReceiveNotification do (input: (name: string, region: int, count: int, invoker: machine)) {

			notificationCount = input.count;
			notificationInvoker = input.invoker;
		}

		on eKafkaFail do (input: (name: string, region: int, invoker: machine)) {

			send input.invoker, eKafkaFailCompleted, (name = input.name, region = input.region);
			goto FailedProcessing;
		}

		ignore eKafkaRecover;

		on eKafkaKill do (input: (name: string, region: int)) {

			raise halt;
		}
  }

  state FailedProcessing {

    on eKafkaSendRecords do (input: (name: string, region: int, records: seq[tRecord], invoker: machine)) {

      send input.invoker, eKafkaSendRecordsCompleted, (name = input.name, region = input.region, records = input.records, success = false);
    }

    on eKafkaReceiveRecords do (input: (name: string, region: int, invoker: machine)) {

      var recordsToSend: seq[tRecord];
//      recordsToSend += (0, (recordId = 0, recordValue = 0));

			send input.invoker, eKafkaReceiveRecordsResponse, (name = name, region = region, records = recordsToSend, kafkaDepth = 0, success = false);
    }

    on eKafkaRemoveRecords do (input: (name: string, region: int, records: seq[tRecord], invoker: machine)) {

      send input.invoker, eKafkaRemoveRecordsCompleted, (name = input.name, region = input.region, records = input.records, success = false);
    }

    on eKafkaGetKafkaDepth do (input: (name: string, region: int, invoker: machine)) {

      send input.invoker, eKafkaGetKafkaDepthResponse, (name = name, region = region, kafkaDepth = 0, success = false);
    }

    on eKafkaReceiveNotification do (input: (name: string, region: int, count: int, invoker: machine)) {

			send input.invoker, eKafkaReceiveNotificationResponse, (name = input.name, region = input.region, count = input.count, success = false);
		}

		ignore eKafkaFail;

		on eKafkaRecover do (input: (name: string, region: int)) {

			goto ProcessRecords;
		}

		on eKafkaKill do (input: (name: string, region: int)) {

			raise halt;
		}
 	}
}

