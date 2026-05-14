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

part of '../../oracledb.dart';

/// Manages storage operations for bundles.
///
/// Parameters:
/// - [name]: The database name.
/// - [storeName]: The store name.
///
/// Returns:
/// An instance of [BundleStore].
///
/// Example:
/// ```dart
/// var store = BundleStore('bundleDB', 'bundles');
/// ```
/// @nodoc
class BundleStore {
  final StorageManager _manager;

  BundleStore (String name, String storeName) : _manager = StorageManager(name, storeName);

  /// Inserts data into the store.
  ///
  /// Parameters:
  /// - [data]: The data to insert.
  ///
  /// Returns:
  /// A Future that completes when insertion is done.
  ///
  /// Example:
  /// ```dart
  /// await store.insertData({'name': 'bundle1', 'data': bundleData});
  /// ```
  /// @nodoc
  Future<dynamic> insertData (dynamic data) async {
      dynamic finalData = {
        "name":data["name"],
        "data":data
      };
      return _manager.insertData(finalData);
  }

  /// Updates data in the store.
  ///
  /// Parameters:
  /// - [data]: The data to update.
  ///
  /// Returns:
  /// A Future that completes when update is done.
  ///
  /// Example:
  /// ```dart
  /// await store.updateData({'name': 'bundle1', 'data': updatedData});
  /// ```
  /// @nodoc
  Future<dynamic> updateData (dynamic data) async {
      dynamic finalData = {
        "name":data["name"],
        "data":data
      };
      return _manager.updateData(finalData);
  }

  /// Retrieves data from the store by ID.
  ///
  /// Parameters:
  /// - [id]: The ID of the data.
  ///
  /// Returns:
  /// A Future with the retrieved data or null.
  ///
  /// Example:
  /// ```dart
  /// var bundle = await store.getData('bundle1');
  /// ```
  /// @nodoc
  Future<dynamic> getData (String id) async {
    dynamic data = await _manager.getData(id);
    if(data == null) {
      return null;
    }
    data = data["data"];
    return data;
  }

  /// Deletes data from the store by ID.
  ///
  /// Parameters:
  /// - [id]: The ID of the data to delete.
  ///
  /// Returns:
  /// A Future that completes when deletion is done.
  ///
  /// Example:
  /// ```dart
  /// await store.deleteData('bundle1');
  /// ```
  /// @nodoc
  Future<dynamic> deleteData (String id) {
    return _manager.deleteData(id);
  }

  /// Deletes the entire storage database.
  ///
  /// Returns:
  /// A Future that completes when deletion is done.
  ///
  /// Example:
  /// ```dart
  /// await store.deleteStorage();
  /// ```
  /// @nodoc
  Future<dynamic> deleteStorage () {
    return _manager.deleteDatabase();
  }

}

/// Represents a task for loading a bundle.
///
///
/// Parameters:
/// - [db]: The FusabaseOracledb instance.
/// - [chunkSize]: The chunk size for loading.
/// - [data]: The bundle data.
///
/// Returns:
/// An instance of [LoadBundleTask].
///
/// Example:
/// ```dart
/// var task = LoadBundleTask(db, 1000, bundleData);
/// task.stream.listen((progress) { /* handle progress */ });
/// ```
/// @nodoc
class LoadBundleTask {
  final StreamController<LoadBundleTaskSnapshot> _controller;
  final FusabaseOracledb _db;
  dynamic _data;
  int _chunkSize;
  LoadBundleTaskSnapshot _taskProgress;

  LoadBundleTask (FusabaseOracledb db, int chunkSize, dynamic data) : _db = db,
  _data = data,
  _chunkSize = chunkSize,
  _taskProgress = LoadBundleTaskSnapshot(data.lengthInBytes, 0),
  _controller = StreamController<LoadBundleTaskSnapshot>();

/// @nodoc
  late final Stream<LoadBundleTaskSnapshot> stream = _controller.stream;

/// @nodoc
  void _initLoad () async {
    try {
      await _resumeLoad();
    } catch (e, stacktrace) {
      throw Utils.oracledbErrorHandler(
          500, "$e", stacktrace);
    }
  }

  Future<void> _resumeLoad () async {
    _data = parseUint8ListToJson(_data);
    _taskProgress._totalDocuments = _data["documents"].length;
    _data = LoadBundleTaskHelper.transformData(_data);

    while (true) {
      int querOffset = 0;
      int docOffset = 0;

      var y = min(docOffset + _chunkSize, _data[querOffset]["documents"].length as int);

      dynamic oldData = await _db._bundleStore.getData(_data[querOffset]["name"]);
      int oldBytes = getTotalBytesOfJson(oldData);
      bool found = true;

      if (oldData == null) {
        found = false;
        oldData = {};
        oldData["name"] = _data[querOffset]["name"];
        oldData["documents"] = [];
        oldData["bundleID"] = _data[querOffset]["bundleID"];
        oldData["metadata"] = _data[querOffset]["metadata"];
      }

      int ct = 0;

      for (var j=docOffset;j<y;j++) {
        ct +=1;
        oldData["documents"].push(_data[querOffset]["documents"][j]);
      }

      if (found) {
        await _db._bundleStore.insertData(oldData);
      } else {
        await _db._bundleStore.updateData(oldData);
      }
      
      int newBytes = getTotalBytesOfJson(oldData);
      
      docOffset = y;
      docOffset = docOffset % (_data[querOffset]["documents"].length as int);
      if (docOffset == 0) {
        querOffset +=1;
      }

      _taskProgress._documentsLoaded = _taskProgress.documentsLoaded + ct;
      _taskProgress._bytesLoaded = _taskProgress.bytesLoaded + (newBytes - oldBytes);


      if (_taskProgress.documentsLoaded == _taskProgress.totalDocuments) {
        _taskProgress._taskState = LoadBundleTaskState.success;
        _controller.add(_taskProgress);
        break;
      }

      _controller.add(_taskProgress);
    }     
  }
}
