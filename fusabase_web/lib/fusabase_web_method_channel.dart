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

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'fusabase_web_platform_interface.dart';

/// An implementation of [FusabaseWebPlatform] that uses method channels.
class MethodChannelFusabaseWeb extends FusabaseWebPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('fusabase_web');

  @override
  Future<String> authenticate(
          {required String url, required String callbackUrlScheme}) async =>
      await methodChannel.invokeMethod<String>(
          'authenticate', <String, dynamic>{
        'url': url,
        'callbackUrlScheme': callbackUrlScheme
      }) ??
      '';

@override
  Future<String> authenticateRedirect(
          {required String url, required String callbackUrlScheme}) async =>
      await methodChannel.invokeMethod<String>(
          'authenticate', <String, dynamic>{
        'url': url,
        'callbackUrlScheme': callbackUrlScheme
      }) ??
      '';

@override
  Future<String> getLocation() async =>
      await methodChannel.invokeMethod<String>('getLocation') ?? '';

@override
  Future<String> getCodeFromURL() async =>
      await methodChannel.invokeMethod<String>('getCodeFromURL') ?? '';

@override
  Future<dynamic> generatePKCEVerifiers() async =>
      await methodChannel.invokeMethod<dynamic>('generatePKCEVerifiers') ?? '';

@override
  void removeCodeParamFromUrl() =>
      methodChannel.invokeMethod<dynamic>('removeCodeParamFromUrl') ?? '';
}
