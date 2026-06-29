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
import 'dart:html';

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
  Function(int? code, String? reason)? onClose;

  /// @nodoc
  WebSocketManager({required this.url});

  /// @nodoc
  Future<void> connect() async {
    final completer = Completer<void>();
    bool opened = false;
    _socket = WebSocket(url);

    _socket!.onOpen.listen((event) {
      opened = true;
      if (!completer.isCompleted) {
        completer.complete();
      }
      if (onOpen != null) onOpen!();
    });

    _socket!.onMessage.listen((MessageEvent event) {
      if (onMessage != null) onMessage!(event.data);
    });

    _socket!.onError.listen((event) {
      if (!opened && !completer.isCompleted) {
        completer.complete();
      }
      if (onError != null) onError!("WebSocket error");
    });

    _socket!.onClose.listen((CloseEvent event) {
      if (!opened && !completer.isCompleted) {
        completer.complete();
      }
      if (onClose != null) onClose!(event.code, event.reason);
    });

    await completer.future;
  }

  /// @nodoc
  bool sendMessage(String message) {
    if (_socket != null && _socket!.readyState == WebSocket.OPEN) {
      _socket!.send(message);
      return true;
    } else {
      return false;
    }
  }

  /// @nodoc
  bool isConnected() {
    return _socket != null && _socket!.readyState == WebSocket.OPEN;
  }

  /// @nodoc
  bool isClosed() {
    return _socket != null && _socket!.readyState == WebSocket.CLOSED;
  }

  /// @nodoc
  void close() {
    _socket?.close();
  }
}
