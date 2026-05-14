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

// transaction/transaction.dart
part of '../../oracledb.dart';

/// Represents a transaction for atomic operations.
///
///
/// Use in runTransaction to perform gets, sets, updates, deletes atomically.
///
/// Parameters:
/// - [name]: A unique name for the transaction.
///
/// Returns:
/// An instance of [Transaction].
///
/// Example:
/// ```dart
/// await oracledb.runTransaction((transaction) async {
///   var doc = await transaction.get(docRef);
///   transaction.update(docRef, {'count': doc.data()['count'] + 1});
/// });
/// ```
class Transaction {
  String __name;
  int __status;
  List<dynamic> __operations;
  Map<String, dynamic> __versions;

  Transaction({required String name})
      : __status = 0,
        __name = name,
        __operations = [],
        __versions = <String, dynamic>{};

  /// Gets a document within the transaction.
  ///
  /// Parameters:
  /// - [docRef]: The document reference.
  ///
  /// Returns:
  /// A Future with the DocumentSnapshot.
  ///
  /// Example:
  /// ```dart
  /// var doc = await transaction.get(docRef);
  /// ```
  Future<DocumentSnapshot<T>> get<T extends Object?>(
      DocumentReference<T> docRef) async {
    if (__status == -1) {
      throw Utils.oracledbErrorHandler(400, OracledbErrorMessages.transactionEnded, null);
    }

    dynamic transObj = {"name": __name, "start": 1 - __status, "end": 0};
    if (__status == 0) {
      __status = 1;
    }
    __operations.add(
        {"method": "get", "docRef": docRef, "data": null, "options": null, "version":null});
    GetOptions op = GetOptions();
    dynamic res = await docRef.get(op, transObj);
    __versions[docRef.path] = res.version;
    return res;
  }

  /// Queues a delete operation for the given document.
  ///
  /// Parameters:
  /// - [docRef]: The document reference to delete.
  ///
  /// Returns:
  /// The Transaction instance for chaining.
  ///
  /// Example:
  /// ```dart
  /// transaction.delete(docRef);
  /// ```
  Transaction delete(DocumentReference docRef) {
    if (__status == -1) {
      throw Utils.oracledbErrorHandler(400, OracledbErrorMessages.transactionEnded, null);
    }
    __operations.add({
      "method": "delete",
      "docRef": docRef,
      "data": null,
      "options": null,
      "version": __versions[docRef.path]
    });

    return this;
  }

  /// Queues a set operation for the given document.
  ///
  /// Parameters:
  /// - [docRef]: The document reference.
  /// - [data]: The data to set.
  /// - [options]: Optional set options.
  ///
  /// Returns:
  /// The Transaction instance for chaining.
  ///
  /// Example:
  /// ```dart
  /// transaction.set(docRef, {'field': 'value'});
  /// ```
  Transaction set<T>(DocumentReference<T> docRef, T data,
      [SetOptions? options]) {
    if (__status == -1) {
      throw Utils.oracledbErrorHandler(400, OracledbErrorMessages.transactionEnded, null);
    }
    options ??= SetOptions(merge: false);

    __operations.add({
      "method": "set",
      "docRef": docRef,
      "data": data,
      "options": options,
      "version": __versions[docRef.path]
    });

    return this;
  }

  /// Queues an update operation for the given document.
  ///
  /// Parameters:
  /// - [docRef]: The document reference.
  /// - [data]: The fields to update.
  ///
  /// Returns:
  /// The Transaction instance for chaining.
  ///
  /// Example:
  /// ```dart
  /// transaction.update(docRef, {'field': 'new value'});
  /// ```
  Transaction update(DocumentReference docRef, Map<String, dynamic> data) {
    if (__status == -1) {
      throw Utils.oracledbErrorHandler(400, OracledbErrorMessages.transactionEnded, null);
    }
    __operations.add({
      "method": "update",
      "docRef": docRef,
      "data": data,
      "options": null,
      "version": __versions[docRef.path]
    });

    return this;
  }

  /// Resets the transaction state.
  void __reset() {
    __name = generateRandomString(25);
    __operations = [];
    __status = 0;
    __versions = <String, dynamic>{};
  }

  /// Internal method to execute queued operations.
  ///
  /// Returns:
  /// A Future with the result of the last operation.
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
      var transObj = {
        "name": __name,
        "start": 1 - __status,
        "end": 0,
        "version": __operations[i]["version"]
      };

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
      __versions[__operations[i]["docRef"].path] = transObj["version"];
    }

    dynamic res = await __commit(j);

    __status = -1;
    return res;
  }

  /// Internal method to commit the last operation.
  ///
  /// Parameters:
  /// - [idx]: Index of the operation to commit.
  ///
  /// Returns:
  /// A Future with the result.
  Future<dynamic> __commit(idx) async {
    var transObj = {
      "name": __name,
      "start": 1 - __status,
      "end": 1,
      "version": __operations[idx]["version"]
    };
    dynamic res = null;
    switch (__operations[idx]["method"]) {
      case "set":
        res = await __operations[idx]["docRef"].set(
            __operations[idx]["data"], __operations[idx]["options"], transObj);
        break;
      case "delete":
        res = await __operations[idx]["docRef"].delete(transObj);
        break;
      case "update":
        res = await __operations[idx]["docRef"]
            .update(__operations[idx]["data"], transObj);
        break;
      case "get":
        GetOptions op = GetOptions();
        res = await __operations[idx]["docRef"].get(op, transObj);
        break;
      default:
    }

    return res;
  }
}
