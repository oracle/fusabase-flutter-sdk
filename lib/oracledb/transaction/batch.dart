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

// transaction/batch.dart

part of '../../oracledb.dart';

/// Represents a batch of write operations.
///
///
/// Use methods like set, update, delete, then commit to execute atomically.
///
/// Parameters:
/// - [name]: A unique name for the batch.
///
/// Returns:
/// An instance of [WriteBatch].
///
/// Example:
/// ```dart
/// var batch = oracledb.batch();
/// batch.set(docRef, {'name': 'New Doc'});
/// await batch.commit();
/// ```
class WriteBatch {
  String __name;
  int __status;
  List<dynamic> __operations;

  WriteBatch({required String name})
      : __status = 0,
        __name = name,
        __operations = [];

  /// Queues a delete operation for the given document.
  ///
  /// Parameters:
  /// - [docRef]: The document reference to delete.
  ///
  /// Example:
  /// ```dart
  /// batch.delete(docRef);
  /// ```
  void delete(DocumentReference docRef) {
    __operations.add(
        {"method": "delete", "docRef": docRef, "data": null, "options": null});
  }

  /// Queues a set operation for the given document.
  ///
  /// Parameters:
  /// - [docRef]: The document reference.
  /// - [data]: The data to set.
  /// - [options]: Optional set options (e.g., merge).
  ///
  /// Example:
  /// ```dart
  /// batch.set(docRef, {'field': 'value'}, SetOptions(merge: true));
  /// ```
  void set<T>(DocumentReference<T> docRef, T data, [SetOptions? options]) {
    options ??= SetOptions(merge: false);

    __operations.add(
        {"method": "set", "docRef": docRef, "data": data, "options": options});
  }

  /// Queues an update operation for the given document.
  ///
  /// Parameters:
  /// - [docRef]: The document reference.
  /// - [data]: The fields to update.
  ///
  /// Example:
  /// ```dart
  /// batch.update(docRef, {'field': 'new value'});
  /// ```
  void update(DocumentReference docRef, Map<String, dynamic> data) {
    __operations.add(
        {"method": "update", "docRef": docRef, "data": data, "options": null});
  }

  /// Internal method to execute queued operations.
  ///
  /// Returns:
  /// A Future with the index of the last operation.
  Future<dynamic> __makeOperations() async {
    var j = __operations.length - 1;
    if (j < 0) {
      __status = -1;
      return null;
    }

    for (var i = 0; i < j; i++) {
      if (__operations[i]["method"] == "get") {
        continue;
      }
      var transObj = {"name": __name, "start": 1 - __status, "end": 0};
      if (__status == 0) {
        __status = 1;
      }
      switch (__operations[i]["method"]) {
        case "set":
          await __operations[i]["docRef"].set(
              __operations[i]["data"], __operations[i]["options"], transObj);
          break;
        case "delete":
          await __operations[i]["docRef"].delete(transObj);
          break;
        case "update":
          await __operations[i]["docRef"]
              .update(__operations[i]["data"], transObj);
          break;
        default:
      }
    }

    return j;
  }

  /// Commits the batch of operations atomically.
  ///
  /// Returns:
  /// A Future that completes when the commit is done.
  ///
  /// Example:
  /// ```dart
  /// await batch.commit();
  /// ```
  Future<void> commit() async {
    int idx = await __makeOperations();
    var transObj = {"name": __name, "start": 1 - __status, "end": 1};
    __status = -1;
    switch (__operations[idx]["method"]) {
      case "set":
        await __operations[idx]["docRef"].set(
            __operations[idx]["data"], __operations[idx]["options"], transObj);
        break;
      case "delete":
        await __operations[idx]["docRef"].delete(transObj);
        break;
      case "update":
        await __operations[idx]["docRef"]
            .update(__operations[idx]["data"], transObj);
        break;
      default:
    }
  }
}
