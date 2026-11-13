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

import 'dart:convert';
import 'dart:html';

import "../../../auth.dart";

/// @nodoc
class IndexedDBPersistence {
  dynamic db;

  Persistence type;

  final String name;

  final String storeName;

  IndexedDBPersistence({required this.name}) : type = Persistence.INDEXED_DB,
   storeName = "__baas_tokens__";

   Future<void> openDatabase() async {
    db = await window.indexedDB!.open(name, version: 1,
        onUpgradeNeeded: (dynamic e) {
      final db = e.target.result;
      if (!db.objectStoreNames!.contains(storeName)) {
        db.createObjectStore(storeName, keyPath: 'key');
      }
    });
  }

  void closeDatabase() {
    db?.close();
  }

  Future<void> deleteDatabase() async {
    await window.indexedDB!.deleteDatabase(name);
  }

  Future<void> _set(String key, String value) async {
    var data = {
      "key":key,
      "value":value
    };
    await openDatabase();
    final transaction = db!.transaction(storeName, 'readwrite');
    final store = transaction.objectStore(storeName);
    await store.put(data);
    closeDatabase();
  }

  Future<String> _get(String key) async {
    await openDatabase();
    final transaction = db!.transaction(storeName, 'readonly');
    final store = transaction.objectStore(storeName);
    final result = await store.getObject(key);
    closeDatabase();
    return result["value"];
  }

  Future<void> _delete(String key) async {
    await openDatabase();
    final transaction = db!.transaction(storeName, 'readwrite');
    final store = transaction.objectStore(storeName);
    await store.delete(key);
    closeDatabase();
  }

  Future<bool> setToken(String key, String token) async {
    try {
      await _set(key, token);
    } catch (e) {
      return false;
    }
    return true;
  }

  Future<String?> getToken(String key) async {
    dynamic res;
    try {
      res = await _get(key);
    } catch (e) {
      return null;
    }
    return res;
  }

  Future<bool> removeToken(String key) async {
    try {
      await _delete(key);
    } catch (e) {
      return false;
    }
    return true;
  }

  Future<bool> isAvailable() async {
    dynamic res1 = await setToken(storagekey, "BAAS");
    dynamic res2 = await removeToken(storagekey);
    return res1 && res2;
  }
}
