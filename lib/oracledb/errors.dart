// Copyright (c) 2015, 2025, Oracle and/or its affiliates.

//-----------------------------------------------------------------------------
//
// This software is dual-licensed to you under the Universal Permissive License
// (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl and Apache License
// 2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
// either license.
//
// If you elect to accept the software under the Apache License, Version 2.0,
// the following applies:
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//-----------------------------------------------------------------------------

part of '../oracledb.dart';

/// @nodoc
class OracledbErrorMessages {
  // 🔹 Error message constants
  static const deleteFieldNotAllowedInSet = 'Delete FieldValue is not allowed in set method.';
  static const serverTimestampNotSupported = 'FieldValue.serverTimestamp is not supported in oracledb version 1';
  static const valueCannotBeNull = 'Value cannot be null or undefined';
  static const expectedType = 'Expected one of {0} but got {1}';
  static const expectedInstance = 'Expected instance of {0} but got {1}';
  static const unknownError = 'Unknown';
  static const invalidSecondsRange = 'Seconds must be from 0001-01-01T00:00:00Z to 9999-12-31T23:59:59Z inclusive.';
  static const invalidNanosecondsRange = 'Nanoseconds must be from 0 to 999,999,999 inclusive.';
  static const notTimestampInstance = 'The provided object must be an instance of Timestamp.';
  static const invalidTimestampString = 'Invalid timestamp string: {0}';
  static const transactionEnded = 'Transaction has ended!';
  static const invalidDocumentReference = 'Invalid document reference passed';
  static const notSnapshotMetadataInstance = 'The other instance to be compared should be an instance of SnapshotMetadata';
  static const cannotSetNullEntry = "Can't set null entry!";
  static const entryNotFound = 'Entry not found!';
  static const unsupportedBundleDataType = 'Supported data types for bundle load are ArrayBuffer, ReadableStream <Uint8Array> and string';
  static const documentDataNotPresent = 'Document data is not present.';
  static const unsupportedDataType = 'Unsupported data type';
  static const viewNameCannotBeEmpty = 'View name cannot be empty for a duality view collection!';
  static const incorrectDualityViewPath = 'Incorrect path for DualityView';
  static const docIdNotReturned = 'DocID not returned!';
  static const notDualityViewColReference = 'The other instance to be compared should be an instance of DualityViewColReference';
  static const pathAndParentCannotBeNull = 'Both path and parent cannot be null!';
  static const incorrectDualityViewDocId = 'Incorrect duality view document id!';
  static const parentCollectionCannotBeNull = "Parent Collection can't be null";
  static const incorrectDualityViewDocPath = 'Incorrect path for DuaityView document';
  static const notDualityViewDocReference = 'The other instance to be compared should be an instance of DualityViewDocReference';
  static const documentIdNotFound = 'DocumentID not found';
  static const errorFetchingDocumentUpdate = 'Error occured while fetching docunent during update.';
  static const noSuchDocument = 'No such doc exists!';
  static const unsubscribeCalled = 'Unsubscribe called!';
  static const notFieldPathInstance = 'The other instance to be compared should be a FieldPath.';
  static const notFieldValueInstance = 'The provided object must be an instance of FieldValue.';
  static const collectionPathCannotBeEmpty = 'Path cannot be empty for a collection!';
  static const incorrectCollectionPath = 'Incorrect path for Collection';
  static const notCollectionReference = 'The other instance to be compared should be an instance of CollectionReference';
  static const incorrectDocumentId = 'Incorrect document id!';
  static const notDocumentReference = 'The other instance to be compared should be an instance of DocumentReference';
  static const notQuerySnapshot = 'The other instance to be compared should be an instance of QuerySnapshot';
  static const documentDoesNotExist = 'Document does not exist!';
  static const notDocumentSnapshot = 'The other instance to be compared should be an instance of DocumentSnapshot';
  static const notAggregateField = 'The other instance to be compared should be an instance of AggregateField.';
  static const notAggregateQuery = 'The other instance to be compared should be an instance of AggregateQuery.';
  static const notAggregateQuerySnapshot = 'The other instance to be compared should be an instance of AggregateQuerySnapshot.';
  static const notQueryInstance = 'The other instance to be compared should be an instance of Query.';
  static const operationNotSupportedInNamedQuery = 'Operation is not supported in namedQuery';
  static const invalidArrayContainsCombination = "array-contains-any can't be used with array-contains.";
  static const incorrectComparisonOperator = 'Incorrect comparison operator';
  static const invalidDirection = 'Invalid direction.';
  static const invalidLimit = 'Invalid limit provided.';
  static const lastSnapshotNotFound = 'Could not locate last snapshot in indexed db';

  // 🔹 Helper for parameter substitution like {0}, {1}, {2}
  static String format(String template, [List<dynamic> params = const []]) {
    var result = template;
    for (var i = 0; i < params.length; i++) {
      result = result.replaceAll('{$i}', params[i].toString());
    }
    return result;
  }
}
