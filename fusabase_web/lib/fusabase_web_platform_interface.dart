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

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'fusabase_web_method_channel.dart';

abstract class FusabaseWebPlatform extends PlatformInterface {
  /// Constructs a FusabaseWebPlatform.
  FusabaseWebPlatform() : super(token: _token);

  static final Object _token = Object();

  static FusabaseWebPlatform _instance = MethodChannelFusabaseWeb();

  /// The default instance of [FusabaseWebPlatform] to use.
  ///
  /// Defaults to [MethodChannelFusabaseWeb].
  static FusabaseWebPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FusabaseWebPlatform] when
  /// they register themselves.
  static set instance(FusabaseWebPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String> authenticate(
          {required String url, required String callbackUrlScheme}) =>
      _instance.authenticate(url: url, callbackUrlScheme: callbackUrlScheme);

  Future<String> authenticateRedirect(
          {required String url, required String callbackUrlScheme}) =>
      _instance.authenticateRedirect(
          url: url, callbackUrlScheme: callbackUrlScheme);

  Future<String> getLocation() =>
      _instance.getLocation();

  Future<String> getCodeFromURL() =>
      _instance.getCodeFromURL();

  Future<dynamic> generatePKCEVerifiers() =>
      _instance.generatePKCEVerifiers();

  void removeCodeParamFromUrl() =>
    _instance.removeCodeParamFromUrl();
}
