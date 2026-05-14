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

import 'inmemory_storage.dart'
    if (dart.library.io) './sqllite.dart'
    if (dart.library.html) './indexed_db.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class StorageManager {
  dynamic db;

  StorageManager (String name, String storeName) : db =  DBHelper(name:name, storeName: storeName) {
    db.deleteDatabase();
  }

  // Insert a record
  Future<void> insertData(Map<String, dynamic> jsonData) async {
    return db.insertData(jsonData);
  }

  // Get a record by queryID
  Future<dynamic> getData(String queryID) async {
    return db.getData(queryID);
  }

  // Update a record
  Future<void> updateData(Map<String, dynamic> jsonData) async {
    return db.updateData(jsonData);
  }

  // Delete a record
  Future<void> deleteData(String queryID) async {
    return db.deleteData(queryID);
  }

  // Delete the entire database
  Future<void> deleteDatabase() async {
    return db.deleteDatabase();
  }
}
