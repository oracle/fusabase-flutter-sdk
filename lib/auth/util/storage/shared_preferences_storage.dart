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

import 'package:fusabase_dart/fusabase_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth.dart';

// class SharedPreferencesPersistence {
//   dynamic _storage;

//   Persistence type;

//   final String name;

//   SharedPreferencesPersistence({required this.name}) : type = Persistence.LOCAL;

//   Future<bool> setToken(String key, String token) async {
//     try {
//       if (this._storage == null) {
//         this._storage = await SharedPreferences.getInstance();
//       }

//       await this._storage?.setString(key, token);
//     } catch (e) {
//       return false;
//     }
//     return true;
//   }

//   Future<String?> getToken(String key) async {
//     if (this._storage == null) {
//       this._storage = await SharedPreferences.getInstance();
//     }
//     String? value;
//     try {
//       value = await _storage?.getString(key);
//     } catch (e) {
//       return null;
//     }
//     return value;
//   }

//   Future<bool> removeToken(String key) async {
//     if (this._storage == null) {
//       return false;
//     }
//     try {
//       await this._storage?.remove(key);
//     } catch (e) {
//       return false;
//     }
//     return true;
//   }

//   Future<bool> isAvailable() async {
//     dynamic res1 = await setToken(storagekey, "BAAS");
//     dynamic res2 = await removeToken(storagekey);
//     return res1 && res2;
//   }
// }

class SharedPreferencesPersistence {
  dynamic _storage;

  Persistence type;

  final String name;

  SharedPreferencesPersistence({required this.name}) : type = Persistence.LOCAL,
  _storage = FusabaseDartPlugin(
          host: "",
          queryParameters: {},
          callbackUrlScheme: "");

  Future<bool> setToken(String key, String token) async {
    try {
      var res = await this._storage?.setString(key, token);
    } catch (e) {
      return false;
    }
    return true;
  }

  Future<String?> getToken(String key) async {
    String? value;
    try {
      value = await _storage?.getString(key);
    } catch (e) {
      return null;
    }
    return value;
  }

  Future<bool> removeToken(String key) async {
    if (this._storage == null) {
      return false;
    }
    try {
      await this._storage?.remove(key);
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
