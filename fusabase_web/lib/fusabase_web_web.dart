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

// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter
import 'dart:developer';
import 'dart:html' as html show window;
import 'dart:html';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:js_util' as js_util;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'fusabase_web_platform_interface.dart';

/// A web implementation of the FusabaseWebPlatform of the FusabaseWeb plugin.
class FusabaseWebWeb extends FusabaseWebPlatform {
  /// Constructs a FusabaseWebWeb
  FusabaseWebWeb();

  static void registerWith(Registrar registrar) {
    FusabaseWebPlatform.instance = FusabaseWebWeb();
  }

  Future<String> listenForToken(WindowBase popup, String expectedOrigin) async {
    Completer<String> completer = Completer();
    late StreamSubscription<MessageEvent> subscription;
    subscription = html.window.onMessage.listen((MessageEvent event) {
      if (event.origin != expectedOrigin) {
        return;
      }
      var data = event.data;
      // Complete the completer with the data
      if (!completer.isCompleted) {
        completer.complete(data);
      }

      subscription.cancel();
    });

    return completer.future;
  }

  @override
  Future<String> authenticate({
    required String url,
    required String callbackUrlScheme,
  }) async {
    WindowBase popup = html.window.open("", "name", "width=800,height=600");
    popup.location.href = url;
    var data = await listenForToken(popup, Uri.parse(url).origin);
    popup.close();
    return data;
  }

  @override
  Future<String> authenticateRedirect({
    required String url,
    required String callbackUrlScheme,
  }) async {
    html.window.location.href = url;
    return "";
  }

  @override
  Future<String> getLocation() async {
    return html.window.location.href;
  }

  @override
  Future<String> getCodeFromURL() async {
    final url = html.window.location.href;
    final uri = Uri.parse(url);
    final code = uri.queryParameters['code'];
    return code ?? "";
  }

  @override
  Future<dynamic> generatePKCEVerifiers() async {
    final verifier = generateCodeVerifier();
    final challenge = await generateCodeChallenge(verifier);
    return {"codeVerifier": verifier, "codeChallenge": challenge};
  }

  static String generateCodeVerifier([int length = 96]) {
    final array = Uint8List(length);
    html.window.crypto?.getRandomValues(array);
    return _base64UrlEncode(array);
  }

  static Future<String> generateCodeChallenge(String codeVerifier) async {
    final encoder = Utf8Encoder();
    final data = Uint8List.fromList(encoder.convert(codeVerifier));

    final subtle = html.window.crypto?.subtle;
    if (subtle == null) {
      throw Exception('SubtleCrypto not supported in this browser.');
    }

    final digestBuffer = await js_util.promiseToFuture(
      js_util.callMethod(subtle, 'digest', ['SHA-256', data.buffer]),
    );

    final digestBytes = Uint8List.view(digestBuffer);
    return _base64UrlEncode(digestBytes);
  }

  void removeCodeParamFromUrl() {
    final uri = Uri.parse(html.window.location.href);

    final newQueryParams = Map<String, String>.from(uri.queryParameters);
    newQueryParams.remove('code');

    final newUri = uri.replace(queryParameters: newQueryParams);

    html.window.history.replaceState(
      null, // state
      '', // title (safe to pass null)
      '${newUri.path}${newUri.hasQuery ? '?${newUri.query}' : ''}',
    );
  }

  static String _base64UrlEncode(Uint8List bytes) {
    return base64
        .encode(bytes)
        .replaceAll('+', '-')
        .replaceAll('/', '_')
        .replaceAll(RegExp(r'=+$'), '');
  }
}
