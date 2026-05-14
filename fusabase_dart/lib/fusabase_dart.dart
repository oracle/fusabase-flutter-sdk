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
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import './src/options.dart';
import './platform/fusabase_dart_platform_interface.dart';

// export 'src/options.dart';

class _OnAppLifecycleResumeObserver extends WidgetsBindingObserver {
  final Function onResumed;

  _OnAppLifecycleResumeObserver(this.onResumed);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    }
  }
}

class FusabaseDartPlugin {
  String host;
  Map<String, String> queryParameters;
  String callbackUrlScheme;

  FusabaseDartPlugin(
      {
      required this.host,
      required this.queryParameters,
      required this.callbackUrlScheme});

  static FusabaseDartPlatform get _platform => FusabaseDartPlatform.instance;

  static final _OnAppLifecycleResumeObserver _resumedObserver =
      _OnAppLifecycleResumeObserver(_fusabasecleanUpDanglingCalls);

  Future<dynamic> socialLogin(String codeVerifier,
       String codeChallenge) async {
    FusabaseDartOptions options = const FusabaseDartOptions();
    queryParameters["code_challenge"] = codeChallenge;
    queryParameters["code_challenge_method"] = "S256";

    // Constructing a Uri object from the URL string
    Uri uri = Uri.parse(host);

    // Adding query parameters
    Uri url = uri.replace(queryParameters: queryParameters);

    WidgetsBinding.instance.removeObserver(
      _resumedObserver,
    );

    WidgetsBinding.instance.addObserver(_resumedObserver);

    var response = await _platform.authenticate(
      url: url.toString(),
      callbackUrlScheme: callbackUrlScheme,
      options: options.toJson(),
    );
    final code = Uri.parse(response).queryParameters['resp'];
    final newCode = code?.split("=")[1];
    return newCode;
  }

  Future<dynamic> socialLink(String codeVerifier,
       String codeChallenge) async {
    FusabaseDartOptions options = const FusabaseDartOptions();
    queryParameters["code_challenge"] = codeChallenge;
    queryParameters["code_challenge_method"] = "S256";

    // Constructing a Uri object from the URL string
    Uri uri = Uri.parse(host);

    // Adding query parameters
    Uri url = uri.replace(queryParameters: queryParameters);

    WidgetsBinding.instance.removeObserver(
      _resumedObserver,
    );

    WidgetsBinding.instance.addObserver(_resumedObserver);

    var response = await _platform.authenticate(
      url: url.toString(),
      callbackUrlScheme: callbackUrlScheme,
      options: options.toJson(),
    );
    final code = Uri.parse(response).queryParameters['resp'];
    final newCode = code?.split("=")[1];
    return newCode;
  }

  Future<bool> setString(String key, String value) {
    return _platform.setValue(key, value);
  }

  Future<String?> getString(String key) {
    return _platform.getValue(key);
  }

  Future<bool> remove(String key) {
    return _platform.removeValue(key);
  }
  
  Future<dynamic> redirectLogin(String codeVerifier,
       String codeChallenge) async {
    FusabaseDartOptions options = const FusabaseDartOptions();
    queryParameters["code_challenge"] = codeChallenge;
    queryParameters["code_challenge_method"] = "S256";

    // Constructing a Uri object from the URL string
    Uri uri = Uri.parse(host);

    // Adding query parameters
    Uri url = uri.replace(queryParameters: queryParameters);

    WidgetsBinding.instance.removeObserver(
      _resumedObserver,
    );

    WidgetsBinding.instance.addObserver(_resumedObserver);

    var response = await _platform.authenticate(
      url: url.toString(),
      callbackUrlScheme: callbackUrlScheme,
      options: options.toJson(),
    );
    final code = Uri.parse(response).queryParameters['resp'];
    return {"code":code};
  }

  Future<dynamic> generatePKCEVerifiers() async {
    var response = await _platform.generatePKCEVerifiers();
    return response;
  }

  static Future<void> _fusabasecleanUpDanglingCalls() async {
    await _platform.clearAllDanglingCalls();
    WidgetsBinding.instance.removeObserver(_resumedObserver);
  }
}
