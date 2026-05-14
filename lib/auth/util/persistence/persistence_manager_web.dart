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
import '../storage/in_memory_storage.dart';
import '../storage/indexed_db_persistence.dart';
import '../storage/local_storage.dart';
import '../storage/session_storage.dart';

class PersistenceManager {
  dynamic persistence;
  dynamic lStore;

  dynamic listener;

  final String name;

  PersistenceManager({required this.name}) : listener = BroadcastChannel("${name}authEvent") {
    persistence = LocalPersistence(name:name);
    lStore = LocalPersistence(name:"${name}lStore");
    persistence.isAvailable().then((res) {}).catchError((err) {
      persistence = SessionPersistence(name:name);
      persistence.then(() {}).catchError((err) {
        persistence = InMemoryPersistence(name:name);
      });
    });

  }

  void makeEvent(String name) {
    listener.postMessage(name);
  }

  void setLocalPersistence() {
    persistence = LocalPersistence(name:name);
  }

  void setIndexedDBPersistence() {
    persistence = IndexedDBPersistence(name:name);
  }

  void setSessionPersistence() {
    persistence = SessionPersistence(name:name);
  }

  void setInMemoryPersistence() {
    persistence = InMemoryPersistence(name:name);
  }

  Future<String?> getToken(String key) async {
    return persistence.getToken(key);
  }

  Future<bool> removeToken(String key) async {
    return persistence.removeToken(key);
  }

  Future<bool> setToken(String key, String token) async {
    return persistence.setToken(key, token);
  }

  Future<String?> getLStoreToken(String key) async {
    return lStore.getToken(key);
  }

  Future<bool> removeLStoreToken(String key) async {
    return lStore.removeToken(key);
  }

  Future<bool> setLStoreToken(String key, String token) async {
    return lStore.setToken(key, token);
  }

  Future<bool> setPersistence(Persistence p) async {
  
    dynamic temp = persistence;

    switch (p) {
      case Persistence.LOCAL:
        persistence = LocalPersistence(name:name);
        break;
      case Persistence.SESSION:
        persistence = SessionPersistence(name:name);
        break;
      case Persistence.NONE:
        persistence = InMemoryPersistence(name:name);
        break;
      case Persistence.INDEXED_DB:
        persistence = IndexedDBPersistence(name:name);
        break;
      default:
        persistence = LocalPersistence(name:name);
    }

    dynamic res = await persistence.isAvailable();
    if (res != true) {
      persistence = temp;
      return false;
    }
    return true;
  }
}
