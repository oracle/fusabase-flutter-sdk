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

import './method_channel/fusabase_dart_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class FusabaseDartPlatform extends PlatformInterface {
  FusabaseDartPlatform() : super(token: _token);

  static final Object _token = Object();

  static FusabaseDartPlatform _instance = FusabaseDartMethodChannel();

  static FusabaseDartPlatform get instance => _instance;

  static set instance(FusabaseDartPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  Future<String> authenticate({
    required String url,
    required String callbackUrlScheme,
    required Map<String, dynamic> options,
  }) =>
      _instance.authenticate(
        url: url,
        callbackUrlScheme: callbackUrlScheme,
        options: options,
      );

  Future<String> redirectLogin({
    required String url,
    required String callbackUrlScheme,
    required Map<String, dynamic> options,
  }) =>
      _instance.authenticate(
        url: url,
        callbackUrlScheme: callbackUrlScheme,
        options: options,
      );

  Future<dynamic> generatePKCEVerifiers() =>
      _instance.generatePKCEVerifiers();

  Future clearAllDanglingCalls() => _instance.clearAllDanglingCalls();

  Future<String?> getValue(String key) =>
      _instance.getValue(
        key
      );

  Future<bool> setValue(String key, String value) =>
      _instance.setValue(
        key, value
      );

  Future<bool> removeValue(String key) =>
      _instance.removeValue(
        key
      );
}
