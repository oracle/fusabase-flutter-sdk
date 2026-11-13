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
import '../../../auth.dart';

/// @nodoc
class SessionPersistence {
  dynamic _storage;

  Persistence type;

  final String name;

  SessionPersistence({required this.name})
      : _storage = window.sessionStorage,
        type = Persistence.SESSION;

  Future<bool> setToken(String key, String token) async {
    try {
      _storage[key] = token;
    } catch (e) {
      return false;
    }
    return true;
  }

  Future<String?> getToken(String key) async {
    return _storage[key];
  }

  Future<bool> removeToken(String key) async {
    try {
      var value = _storage.remove(key);
      if (value == null) {
        return false;
      }
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
