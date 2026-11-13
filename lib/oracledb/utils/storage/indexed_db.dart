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

import 'dart:html';

/// @nodoc
class DBHelper {
  final String name;
  final String storeName;
  dynamic db;

  DBHelper({required this.name, required this.storeName});

  Future<void> openDatabase() async {
    db = await window.indexedDB!.open(name, version: 1,
        onUpgradeNeeded: (dynamic e) {
      final db = e.target.result;
      if (!db.objectStoreNames!.contains(storeName)) {
        db.createObjectStore(storeName, keyPath: 'queryId');
      }
    });

  }

  Future<void> insertData(Map<String, dynamic> data) async {
    await openDatabase();
    final transaction = db!.transaction(storeName, 'readwrite');
    final store = transaction.objectStore(storeName);
    await store.put(data);
    closeDatabase();
  }

  Future<dynamic> getData(dynamic queryId) async {
    await openDatabase();
    final transaction = db!.transaction(storeName, 'readonly');
    final store = transaction.objectStore(storeName);
    final result = await store.getObject(queryId);
    closeDatabase();
    return result;
  }

  Future<void> updateData(Map<String, dynamic> data) async {
    await openDatabase();
    await insertData(data); 
    closeDatabase();
  }

  Future<void> deleteData(dynamic queryId) async {
    await openDatabase();
    final transaction = db!.transaction(storeName, 'readwrite');
    final store = transaction.objectStore(storeName);
    await store.delete(queryId);
    closeDatabase();
  }

  Future<void> deleteDatabase() async {
    await window.indexedDB!.deleteDatabase(name);
  }

  void closeDatabase() {
    db?.close();
  }
}
