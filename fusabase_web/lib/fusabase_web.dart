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

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'fusabase_web_platform_interface.dart';

class FusabaseWeb {
  String host;
  Map<String, String> queryParameters;
  String callbackUrlScheme;

  FusabaseWeb(
      {
      required this.host,
      required this.queryParameters,
      required this.callbackUrlScheme});

  static FusabaseWebPlatform get _platform => FusabaseWebPlatform.instance;

  Future<dynamic> socialLogin(String codeVerifier,
       String codeChallenge) async {

    // Constructing a Uri object from the URL string
    Uri uri = Uri.parse(host);
    var urlLoc = await _platform.getLocation();
    Uri uriWin = Uri.parse(urlLoc);
    // Build context URI like JS: origin + pathname
    String contextUri = '${uriWin.scheme}://${uriWin.authority}${uriWin.path}';
    // Add to query params
    queryParameters['context_uri'] = contextUri;

    // Adding query parameters
    Uri url = uri.replace(queryParameters: queryParameters);

    var response = await _platform.authenticate(
        url: url.toString(), callbackUrlScheme: callbackUrlScheme);
    var res = jsonDecode(response);
    return res;
  }

  Future<dynamic> socialLink(String codeVerifier,
       String codeChallenge) async {

    // Constructing a Uri object from the URL string
    Uri uri = Uri.parse(host);
    var urlLoc = await _platform.getLocation();
    Uri uriWin = Uri.parse(urlLoc);
    // Build context URI like JS: origin + pathname
    String contextUri = '${uriWin.scheme}://${uriWin.authority}${uriWin.path}';
    // Add to query params
    queryParameters['context_uri'] = contextUri;

    // Adding query parameters
    Uri url = uri.replace(queryParameters: queryParameters);

    var response = await _platform.authenticate(
        url: url.toString(), callbackUrlScheme: callbackUrlScheme);
    var res = jsonDecode(response);
    return res;
  }

  Future<dynamic> redirectLogin(String codeVerifier,
       String codeChallenge) async {
    queryParameters["code_challenge"] = codeChallenge;
    queryParameters["code_challenge_method"] = "S256";
    var urlLoc = await _platform.getLocation();
    Uri uriWin = Uri.parse(urlLoc);
    // Build context URI like JS: origin + pathname
    String contextUri = '${uriWin.scheme}://${uriWin.authority}${uriWin.path}';
    // Add to query params
    queryParameters['context_uri'] = contextUri;

    // Constructing a Uri object from the URL string
    Uri uri = Uri.parse(host);

    // Adding query parameters
    Uri url = uri.replace(queryParameters: queryParameters);

    await _platform.authenticateRedirect(
        url: url.toString(), callbackUrlScheme: callbackUrlScheme);

    return {};
  }

  Future<String> getCodeFromURL() async {
    var response = await _platform.getCodeFromURL();
    return response;
  }

  Future<dynamic> generatePKCEVerifiers() async {
    var response = await _platform.generatePKCEVerifiers();
    return response;
  }

  void removeCodeParamFromUrl() {
    _platform.removeCodeParamFromUrl();
  }
}
