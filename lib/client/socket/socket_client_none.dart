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

/// @nodoc
class WebSocketManager {
  dynamic _socket;
  final String url;

/// @nodoc
  Function()? onOpen;
  /// @nodoc
  Function(dynamic message)? onMessage;
  /// @nodoc
  Function(Object error)? onError;
  /// @nodoc
  Function(int? code, String? reason)? onClose;
/// @nodoc
  WebSocketManager({required this.url});

  /// @nodoc
  Future<void> connect() async {
    throw Exception("Web socket is not supported.");
  }

/// @nodoc
  bool sendMessage(String message) {
    return false;
  }

/// @nodoc
  bool isConnected() {
    return false;
  }

/// @nodoc
  bool isClosed() {
    return true;
  }

/// @nodoc
  void close() {
    return ;
  }
}
