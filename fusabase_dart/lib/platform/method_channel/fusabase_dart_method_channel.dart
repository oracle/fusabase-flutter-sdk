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

import 'package:flutter/services.dart';
import '../fusabase_dart_platform_interface.dart';

/// Method channel implementation of the [FusabaseDartPlatform].
class FusabaseDartMethodChannel extends FusabaseDartPlatform {
  static const MethodChannel channel = MethodChannel('fusabase_dart_auth');

  @override
  Future<String> authenticate({
    required String url,
    required String callbackUrlScheme,
    required Map<String, dynamic> options,
  }) async =>
      await channel.invokeMethod<String>('fusabaseauthenticate', <String, dynamic>{
        'url': url,
        'callbackUrlScheme': callbackUrlScheme,
        'options': options,
      }) ??
      '';

  @override
  Future<String> redirectLogin({
    required String url,
    required String callbackUrlScheme,
    required Map<String, dynamic> options,
  }) async =>
      await channel.invokeMethod<String>('fusabaseredirectlogin', <String, dynamic>{
        'url': url,
        'callbackUrlScheme': callbackUrlScheme,
        'options': options,
      }) ??
      '';

  @override
  Future<dynamic> generatePKCEVerifiers() async =>
      await channel.invokeMethod<dynamic>('pkceredirectgenerate') ??
      '';

  @override
  Future clearAllDanglingCalls() async =>
      channel.invokeMethod('fusabasecleanUpDanglingCalls');

   Future<bool> setValue(String key, String value) async {
    final result = await channel.invokeMethod<bool>(
      'setValue',
      {'key': key, 'value': value},
    );
    return result ?? false;
  }

  Future<String?> getValue(String key) async {
    return await channel.invokeMethod<String>(
      'getValue',
      {'key': key},
    );
  }

  Future<bool> removeValue(String key) async {
    final result = await channel.invokeMethod<bool>(
      'removeValue',
      {'key': key},
    );
    return result ?? false;
  }
}
