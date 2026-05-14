// Copyright (c) 2015, 2026, Oracle and/or its affiliates.

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
// 


import 'dart:html';

const String _dbName = 'fusabase-app-trust';
const int _dbVersion = 1;
const String _storeName = 'tokens';

Future<dynamic> _openDatabase() async {
  return window.indexedDB!.open(_dbName, version: _dbVersion,
      onUpgradeNeeded: (dynamic e) {
    final db = e.target.result;
    if (!db.objectStoreNames!.contains(_storeName)) {
      db.createObjectStore(_storeName);
    }
  });
}

Future<Map<String, dynamic>?> getPersistedToken(String key) async {
  final db = await _openDatabase();
  try {
    final transaction = db.transaction(_storeName, 'readonly');
    final store = transaction.objectStore(_storeName);
    final result = await store.getObject(key);
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    return null;
  } finally {
    db.close();
  }
}

Future<void> setPersistedToken(String key, Map<String, dynamic> value) async {
  final db = await _openDatabase();
  try {
    final transaction = db.transaction(_storeName, 'readwrite');
    final store = transaction.objectStore(_storeName);
    await store.put(value, key);
  } finally {
    db.close();
  }
}

Future<void> removePersistedToken(String key) async {
  final db = await _openDatabase();
  try {
    final transaction = db.transaction(_storeName, 'readwrite');
    final store = transaction.objectStore(_storeName);
    await store.delete(key);
  } finally {
    db.close();
  }
}
