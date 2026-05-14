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


import 'storage_manager.dart';

class BundleStore {
  final StorageManager _manager;

  BundleStore (String name, String storeName) : _manager = StorageManager(name, storeName);

  Future<dynamic> insertData (dynamic data) async {
      dynamic finalData = {
        "name":data["name"],
        "data":data
      };
      return _manager.insertData(finalData);
  }

  Future<dynamic> updateData (dynamic data) async {
      dynamic finalData = {
        "name":data["name"],
        "data":data
      };
      return _manager.updateData(finalData);
  }

  Future<dynamic> getData (String id) async {
    dynamic data = await _manager.getData(id);
    if(data == null) {
      return null;
    }
    data = data["data"];
    return data;
  }

  Future<dynamic> deleteData (String id) {
    return _manager.deleteData(id);
  }

  Future<dynamic> deleteStorage () {
    return _manager.deleteDatabase();
  }

}