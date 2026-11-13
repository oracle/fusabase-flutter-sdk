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
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// @nodoc
class DBHelper {
  Database? _database;
  final String name;
  final String storeName;

  DBHelper({required this.name, required this.storeName});

  Future<String> _databasePath() async {
    return join(await getDatabasesPath(), "${name}_${storeName}.db");
  }

  // Initialize and open the database.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Create the database.
  Future<Database> _initDatabase() async {
    final String path = await _databasePath();
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $storeName (
            queryId TEXT PRIMARY KEY,
            data TEXT
          )
        ''');
      },
    );
  }

  // Insert a record
  Future<void> insertData(Map<String, dynamic> jsonData) async {
    final db = await database;
    await db.insert(
      storeName,
      {
        'queryId': jsonData['queryId'],
        'data': jsonEncode(jsonData)
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get a record by queryID
  Future<dynamic> getData(String queryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      storeName,
      where: 'queryId = ?',
      whereArgs: [queryId],
    );

    if (maps.isNotEmpty) {
      return jsonDecode(maps.first['data']);
    } else {
      return null;
    }
  }

  // Update a record
  Future<void> updateData(Map<String, dynamic> jsonData) async {
    final db = await database;
    await db.update(
      storeName,
      {
        'data': jsonEncode(jsonData)
      },
      where: 'queryId = ?',
      whereArgs: [jsonData['queryId']],
    );
  }

  // Delete a record
  Future<void> deleteData(String queryID) async {
    final db = await database;
    await db.delete(
      storeName,
      where: 'queryId = ?',
      whereArgs: [queryID],
    );
  }

  // Delete the exact database file opened by this helper.
  Future<void> deleteDatabase() async {
    final String path = await _databasePath();
    await _database?.close();
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}

