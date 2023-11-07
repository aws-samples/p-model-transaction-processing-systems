// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

/*************************
User Defined Types
**************************/

type tRecord = (recordId: int, recordValue: int);

// creates a collection of records
fun CreateRecords(numRecords: int, startingIndex: int) : seq[tRecord] {

  var i: int;
  var records: seq[tRecord];
  while(i < numRecords) {
    records += (sizeof(records), (recordId = startingIndex + i, recordValue = choose(100000) + 1));
    i = i + 1;
  }
  return records;
}

// compare two records
fun CompareRecords(first: tRecord, second: tRecord) : bool {

  if (first.recordId == second.recordId && first.recordValue == second.recordValue) {
    return true;
  }
  else {
    return false;
  }
}

// compare two records
fun CombineRecords(recordSets: seq[seq[tRecord]]) : seq[tRecord] {

	var recordSet: seq[tRecord];
	var records: seq[tRecord];
	var record: tRecord;
	var index: int;

	foreach (recordSet in recordSets) {
		foreach (record in recordSet) {
			records += (index, record);
			index = index + 1;
		}
	}

  return records;
}

// compare two records
fun RecordInList(records: seq[tRecord], record: tRecord) : bool {

	var item: tRecord;

	foreach (item in records) {
		if (item.recordId == record.recordId) {
			return true;
		}
	}

  return false;
}

// add entry if it does not exist
fun addEntryIfDoesNotExist(map_instance: map[string, seq[tRecord]], key: string) : map[string, seq[tRecord]] {
  var x: seq[tRecord];
  if (!(key in map_instance)) {
    map_instance[key] = x;
  }
  return map_instance;
}