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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// @nodoc
class WebSocketManager {
  WebSocket? _socket;
  /// @nodoc
  final String url;

/// @nodoc
  Function()? onOpen;
  /// @nodoc
  Function(dynamic message)? onMessage;
  /// @nodoc
  Function(Object error)? onError;
  /// @nodoc
  Function(int code, String reason)? onClose;

  /// @nodoc
  WebSocketManager({required this.url});

/// @nodoc
  Future<void> connect() async {
    try {
      _socket = await WebSocket.connect(url);
      _socket?.listen(
        (data) {
          if (onMessage != null) onMessage!(data);
        },
        onError: (error) {
          if (onError != null) onError!(error);
        },
        onDone: () {
          if (onClose != null) onClose!(_socket?.closeCode ?? 0, _socket?.closeReason ?? '');
        },
      );

      if (onOpen != null) onOpen!();
    } catch (error) {
      if (onError != null) onError!(error);
    }
  }

/// @nodoc
  bool sendMessage(String message) {
    if (_socket != null && _socket!.readyState == WebSocket.open) {
      _socket!.add(message);
      return true;
    } else {
      return false;
    }
  }

/// @nodoc
  bool isConnected() {
    return _socket != null && _socket!.readyState == WebSocket.open;
  }

/// @nodoc
  bool isClosed() {
    return _socket != null && _socket!.readyState == WebSocket.closed;
  }

/// @nodoc
  Future<void> close() async {
    await _socket?.close();
  }
}
