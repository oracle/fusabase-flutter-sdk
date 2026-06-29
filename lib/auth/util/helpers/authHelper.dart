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

part of "../../../auth.dart";

/// @nodoc
class IDCSAuthHelper {
  final FusabaseOptions? options;

  dynamic config;
  FusabaseApp? _app;

  globals.LogLevel __logLevel;
  late final ONPREMAuthHelper _delegate;

  IDCSAuthHelper({
    required this.options,
    required this.config,
    required globals.LogLevel logLevel,
  }) : __logLevel = logLevel {
    _delegate = ONPREMAuthHelper(
      options: options,
      config: config,
      logLevel: logLevel,
    );
  }

  void _setApp(FusabaseApp app) {
    _app = app;
    _delegate._setApp(app);
  }

  Future<IdTokenResult?> getBearerToken([http.Client? client]) async {
    return _delegate.getBearerToken();
  }

  Future<dynamic> getAuthForm({
    http.Client? client,
    required IdTokenResult? bearerToken,
  }) async {
    return _delegate.getAuthForm(bearerToken: bearerToken);
  }

  Future<dynamic> authenticateAndGetDetails({
    required String email,
    required String password,
  }) async {
    return _delegate.authenticateAndGetDetails(
      email: email,
      password: password,
    );
  }

  Future<dynamic> authenticateUser({
    required http.Client client,
    required String email,
    required String password,
  }) async {
    return _delegate.authenticateUser(
      client: client,
      email: email,
      password: password,
    );
  }

  Future<dynamic> getAccessToken({
    http.Client? client,
    required IdTokenResult authnToken,
  }) async {
    return _delegate.getAccessToken(authnToken: authnToken);
  }

  Future<dynamic> reloadUser({required User user}) async {
    return _delegate.reloadUser(user: user);
  }

  Future<dynamic> getUserDetails({required IdTokenResult accessToken}) async {
    return _delegate.getUserDetails(accessToken: accessToken);
  }

  Future<dynamic> fetchUserDetails({required IdTokenResult accessToken}) async {
    return _delegate.fetchUserDetails(accessToken: accessToken);
  }

  Future<void> performSignOut(String? refreshToken) async {
    try {
      await _delegate.performSignOut(refreshToken ?? "");
    } finally {
      await signOutFromIDCS();
    }
  }

  Future<void> signOutFromIDCS() async {
    dynamic response;
    final reqURL = "${config.idcsDomainURL}${IDCSConfig.LOGOUT_REST_EP}";
    final headers = <String, String>{"Content-Type": "application/scim+json"};

    try {
      response = await createClient(
        _app,
      ).get(Uri.parse(reqURL), headers: headers);
      AuthUtils.checkResponse(__logLevel, response);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(__logLevel, "GET request");
      AuthUtils.baasTrace(__logLevel, reqURL, headers, null, e, stacktrace);
      String errMessage = response == null ? "Network error" : "Unknown";
      final int status = response == null ? 408 : response.statusCode;
      if (response != null) {
        try {
          final newMessage = jsonDecode(response.body);
          errMessage =
              newMessage["detail"] ??
              newMessage["error"] ??
              newMessage["message"] ??
              errMessage;
        } catch (_) {}
      }
      throw AuthUtils.authErrorHandler(
        status: status,
        message: errMessage,
        authType: config.authType.toUpperCase(),
        stackTrace: stacktrace,
      );
    }
  }

  Future<void> revokeRefreshToken({
    required http.Client client,
    required String? refreshToken,
  }) async {
    return _delegate.revokeRefreshToken(
      client: client,
      refreshToken: refreshToken,
    );
  }

  Future<dynamic> registerUser({
    required http.Client client,
    required String email,
    required String password,
    required String url,
  }) async {
    return _delegate.registerUser(
      client: client,
      email: email,
      password: password,
      url: url,
    );
  }

  Future<dynamic> signInWithBrowserHelper(dynamic provider) async {
    dynamic response;
    dynamic fResponse;
    final String host = options?.ordsHost ?? "";
    final String appID = options?.appID.toLowerCase() ?? "";
    dynamic pkceResult = await generatePKCE(provider);
    String codeVerifier = pkceResult["codeVerifier"];
    String codeChallenge = pkceResult["codeChallenge"];
    dynamic socialPlugin;

    if (kIsWeb) {
      socialPlugin = FusabaseWeb(
          host: "${host}_/baas-services/idm/idcs/${options?.projectID}/social",
          queryParameters: {
            "method": provider.providerId + "-idcs",
            "device": "web",
            "appID": appID,
            "link":"0",
            "apiKey": options?.appID ?? ""
          },
          callbackUrlScheme: 'baasmobile$appID');
    } else {
      socialPlugin = FusabaseDartPlugin(
          host: "${host}_/baas-services/idm/idcs/${options?.projectID}/social",
          queryParameters: {
            "method": provider.providerId + "-idcs",
            "device": "mobile",
            "appID": appID,
            "link":"0",
            "apiKey": options?.appID ?? ""
          },
          callbackUrlScheme: 'baasmobile$appID');
    }
    try {
      response = await socialPlugin.socialLogin(codeVerifier,
       codeChallenge);
      if (!kIsWeb) {
        fResponse = await getTokensAfterRedirect(client:
          createClient(_app), code: response, verifier: codeVerifier);
      } else {
        fResponse = response;
      }
    } catch (e, stacktrace) {
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["message"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['login using the browser']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }

    return fResponse;
  }

  Future<dynamic> generatePKCE(dynamic provider) async {
    return _delegate.generatePKCE(provider);
  }

  Future<dynamic> signInWithRedirectHelper(
    dynamic provider,
    dynamic pkceResult,
  ) async {
    return _delegate.signInWithRedirectHelper(provider, pkceResult);
  }

  Future<dynamic> getTokensAfterRedirect({
    required http.Client client,
    required String code,
    required String verifier,
  }) async {
    return _delegate.getTokensAfterRedirect(
      client: client,
      code: code,
      verifier: verifier,
    );
  }

  Future<String> getCodeFromURL() async {
    return _delegate.getCodeFromURL();
  }

  void removeCodeParamFromUrl() {
    _delegate.removeCodeParamFromUrl();
  }

  dynamic getProvider(String id) {
    return _delegate.getProvider(id);
  }

  Future<void> sendPasswordResetEmailHelper({
    required http.Client client,
    required String email,
  }) async {
    return _delegate.sendPasswordResetEmailHelper(client: client, email: email);
  }

  Future<String> verifyPasswordResetCodeHelper({
    required http.Client client,
    required String code,
  }) async {
    return _delegate.verifyPasswordResetCodeHelper(client: client, code: code);
  }

  Future<void> confirmPasswordResetHelper({
    required http.Client client,
    required String code,
    required String newPassword,
  }) async {
    return _delegate.confirmPasswordResetHelper(
      client: client,
      code: code,
      newPassword: newPassword,
    );
  }

  Future<dynamic> signInWithCredentialHelper({
    required http.Client client,
    dynamic credential,
  }) async {
    return _delegate.signInWithCredentialHelper(
      client: client,
      credential: credential,
    );
  }
}

/// @nodoc
class ONPREMAuthHelper {
  final FusabaseOptions? options;

  dynamic config;
  FusabaseApp? _app;

  globals.LogLevel __logLevel;

  ONPREMAuthHelper({
    required this.options,
    required this.config,
    required globals.LogLevel logLevel,
  }) : __logLevel = logLevel;

  void _setApp(FusabaseApp app) {
    _app = app;
  }

  String get _servicePath => config.authType == "idcs" ? "idcs" : "onprem";

  Future<IdTokenResult?> getBearerToken() async {
    String errMessage = NOT_IMPLEMENTED_ERROR;
    throw AuthUtils.authErrorHandler(
      status: globals.ErrorMap[globals.ErrorCode.NOT_IMPLEMENT] ?? 999,
      message: errMessage,
      authType: config.authType.toUpperCase(),
    );
  }

  Future<dynamic> getAuthForm({required IdTokenResult? bearerToken}) async {
    String errMessage = NOT_IMPLEMENTED_ERROR;
    throw AuthUtils.authErrorHandler(
      status: globals.ErrorMap[globals.ErrorCode.NOT_IMPLEMENT] ?? 999,
      message: errMessage,
      authType: config.authType.toUpperCase(),
    );
  }

  Future<dynamic> authenticateAndGetDetails({
    required String email,
    required String password,
  }) async {
    final tok_res = await this.authenticateUser(
      client: createClient(_app),
      email: email,
      password: password,
    );
    IdTokenResult accessToken = tok_res["access_token"];
    String refreshToken = tok_res["refresh_token"];
    final userDetails = await this.getUserDetails(accessToken: accessToken);

    return {
      "userDetails": userDetails,
      "authnToken": null,
      "accessToken": accessToken,
      "refreshToken": refreshToken,
    };
  }

  Future<dynamic> authenticateUser({
    required http.Client client,
    required String email,
    required String password,
  }) async {
    dynamic response;
    dynamic result;

    final reqURL =
        "${this.config.domainURL}${ONPREMConfig.AUTHENTICATE_REST_EP}?apiKey=${options?.appID}";
    final headers = <String, String>{};
    final body = json.encode({
      "grant_type": "user_credentials",
      "username": email,
      "password": password,
    });
    try {
      response = await client.post(
        Uri.parse(reqURL),
        headers: headers,
        body: body,
      );
      AuthUtils.checkResponse(this.__logLevel, response);
      result = jsonDecode(response.body);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "POST request");
      AuthUtils.baasTrace(
        this.__logLevel,
        reqURL,
        headers,
        body,
        e,
        stacktrace,
      );
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(
          AuthErrorMessageTemplates.FAILED_REQUEST,
          ['authenticate the user'],
        );
      }

      throw AuthUtils.authErrorHandler(
        status: response.statusCode ?? 999,
        message: errMessage,
        authType: config.authType.toUpperCase(),
        stackTrace: stacktrace,
      );
    }
    return {
      "access_token": IdTokenResult(token: result["access_token"]),
      "refresh_token": result["refresh_token"],
    };
  }

  Future<dynamic> getAccessToken({required IdTokenResult authnToken}) async {
    String errMessage = NOT_IMPLEMENTED_ERROR;
    throw AuthUtils.authErrorHandler(
      status: globals.ErrorMap[globals.ErrorCode.NOT_IMPLEMENT] ?? 999,
      message: errMessage,
      authType: config.authType.toUpperCase(),
    );
  }

  Future<dynamic> reloadUser({required User user}) async {
    IdTokenResult accessToken = await user.getIdTokenResult(true);
    return this.getUserDetails(accessToken: accessToken);
  }

  Future<dynamic> getUserDetails({required IdTokenResult accessToken}) async {
    return fetchUserDetails(accessToken: accessToken);
  }

  Future<dynamic> fetchUserDetails({required IdTokenResult accessToken}) async {
    dynamic result;
    dynamic data = AuthUtils.parseJwt(accessToken.token);
    result = {
      "displayName": data["user_displayname"],
      "emails": [
        {"value": data["sub"]},
      ],
      "meta": {
        "created": data["creation_time"],
        "lastSignIn": convertIatToTimestamp(data["iat"]),
      },
      "id": data["user_id"],
      "idcsCreatedBy": data["iss"],
      "schemas": null,
      'phoneNumbers': [
        {"value": data["user_phonenumber"]},
      ],
      'photos': [
        {"value": data["photo_url"]},
      ],
      'ocid': null,
      "idp_name": data["idp_name"],
      "idp_type": data["idp_type"],
      'emailVerified': data["email_verified"],
    };
    return result;
  }

  Future<void> performSignOut(String refreshToken) async {
    await revokeRefreshToken(
      client: createClient(_app),
      refreshToken: refreshToken,
    );
  }

  Future<void> signOutFromIDCS() async {
    String errMessage = NOT_IMPLEMENTED_ERROR;
    throw AuthUtils.authErrorHandler(
      status: globals.ErrorMap[globals.ErrorCode.NOT_IMPLEMENT] ?? 999,
      message: errMessage,
      authType: config.authType.toUpperCase(),
    );
  }

  Future<void> revokeRefreshToken({
    required http.Client client,
    required String? refreshToken,
  }) async {
    dynamic response;
    final reqURL =
        "${this.config.domainURL}${ONPREMConfig.REVOKE_REFRESH_TOKEN}?apiKey=${options?.appID}";
    final headers = <String, String>{};
    dynamic body = json.encode({"token": refreshToken});
    try {
      response = await client.put(
        Uri.parse(reqURL),
        headers: headers,
        body: body,
      );
      AuthUtils.checkResponse(this.__logLevel, response);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "DELETE request");
      AuthUtils.baasTrace(
        this.__logLevel,
        reqURL,
        headers,
        null,
        e,
        stacktrace,
      );
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(
          AuthErrorMessageTemplates.FAILED_REQUEST,
          ['revoke the refresh token'],
        );
      }

      throw AuthUtils.authErrorHandler(
        status: response.statusCode ?? 999,
        message: errMessage,
        authType: config.authType.toUpperCase(),
        stackTrace: stacktrace,
      );
    }
  }

  Future<dynamic> registerUser({
    required http.Client client,
    required String email,
    required String password,
    required String url,
  }) async {
    dynamic response;
    dynamic result;

    final reqURL =
        "${this.config.domainURL}${ONPREMConfig.SELF_REGISTER_EP}?apiKey=${options?.appID}";

    String data = json.encode({
      "first_name": "-",
      "last_name": "-",
      "email": email,
      "password": password,
    });
    final headers = <String, String>{"Content-Type": "application/json"};
    try {
      response = await client.post(
        Uri.parse(reqURL),
        headers: headers,
        body: data,
      );

      AuthUtils.checkResponse(this.__logLevel, response);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "POST request");
      AuthUtils.baasTrace(
        this.__logLevel,
        reqURL,
        headers,
        data,
        e,
        stacktrace,
      );
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(
          AuthErrorMessageTemplates.FAILED_REQUEST,
          ['add the user'],
        );
      }

      throw AuthUtils.authErrorHandler(
        status: response.statusCode ?? 999,
        message: errMessage,
        authType: config.authType.toUpperCase(),
        stackTrace: stacktrace,
      );
    }
  }

  Future<dynamic> signInWithBrowserHelper(dynamic provider) async {
    dynamic response;
    dynamic fResponse;
    final String host = options?.ordsHost ?? "";
    final String appID = options?.appID.toLowerCase() ?? "";
    dynamic pkceResult = await generatePKCE(provider);
    String codeVerifier = pkceResult["codeVerifier"];
    String codeChallenge = pkceResult["codeChallenge"];
    dynamic socialPlugin;

    if (kIsWeb) {
      socialPlugin = FusabaseWeb(
        host:
            "${host}_/baas-services/idm/${_servicePath}/${options?.projectID}/socialidp",
        queryParameters: {
          "method": provider.providerId,
          "link": "0",
          "app_id": appID,
          "device": "web",
          "apiKey": options?.appID ?? "",
        },
        callbackUrlScheme: 'baasmobile$appID',
      );
    } else {
      socialPlugin = FusabaseDartPlugin(
        host:
            "${host}_/baas-services/idm/${_servicePath}/${options?.projectID}/socialidp",
        queryParameters: {
          "method": provider.providerId,
          "app_id": appID,
          "link": "0",
          "device": "mobile",
          "apiKey": options?.appID ?? "",
        },
        callbackUrlScheme: 'baasmobile$appID',
      );
    }

    try {
      response = await socialPlugin.socialLogin(codeVerifier, codeChallenge);
      if (!kIsWeb) {
        fResponse = await getTokensAfterRedirect(
          client: createClient(_app),
          code: response,
          verifier: codeVerifier,
        );
      } else {
        fResponse = response;
      }
    } catch (e, stacktrace) {
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(
          AuthErrorMessageTemplates.FAILED_REQUEST,
          ['login using the browser'],
        );
      }

      throw AuthUtils.authErrorHandler(
        status: response.statusCode ?? 999,
        message: errMessage,
        authType: config.authType.toUpperCase(),
        stackTrace: stacktrace,
      );
    }

    return fResponse;
  }

  Future<dynamic> generatePKCE(dynamic provider) async {
    dynamic response;
    final String host = options?.ordsHost ?? "";
    final String appID = options?.appID.toLowerCase() ?? "";
    final String method = provider.providerId;

    dynamic socialPlugin;
    if (kIsWeb) {
      socialPlugin = FusabaseWeb(
        host:
            "${host}_/baas-services/idm/${_servicePath}/${options?.projectID}/socialidp",
        queryParameters: {
          "method": method,
          "app_id": appID,
          "link": "0",
          "device": "web",
          "apiKey": options?.appID ?? "",
        },
        callbackUrlScheme: 'baasmobile$appID',
      );
    } else {
      socialPlugin = FusabaseDartPlugin(
        host:
            "${host}_/baas-services/idm/${_servicePath}/${options?.projectID}/socialidp",
        queryParameters: {
          "method": method,
          "app_id": appID,
          "link": "0",
          "device": "web",
          "apiKey": options?.appID ?? "",
        },
        callbackUrlScheme: 'baasmobile$appID',
      );
    }

    try {
      response = await socialPlugin.generatePKCEVerifiers();
    } catch (e, stacktrace) {
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(
          AuthErrorMessageTemplates.FAILED_REQUEST,
          ['generate verifiers'],
        );
      }

      throw AuthUtils.authErrorHandler(
        status: response.statusCode ?? 999,
        message: errMessage,
        authType: config.authType.toUpperCase(),
        stackTrace: stacktrace,
      );
    }

    return response;
  }

  Future<dynamic> signInWithRedirectHelper(
    dynamic provider,
    dynamic pkceResult,
  ) async {
    dynamic response;
    final String host = options?.ordsHost ?? "";
    final String appID = options?.appID.toLowerCase() ?? "";
    final String method = provider.providerId;

    dynamic socialPlugin;
    if (kIsWeb) {
      socialPlugin = FusabaseWeb(
        host:
            "${host}_/baas-services/idm/${_servicePath}/${options?.projectID}/socialidp",
        queryParameters: {
          "method": method,
          "app_id": appID,
          "link": "0",
          "device": "web",
          "apiKey": options?.appID ?? "",
        },
        callbackUrlScheme: 'baasmobile$appID',
      );
    } else {
      throw AuthUtils.authErrorHandler(
        status: globals.ErrorMap[globals.ErrorCode.NOT_IMPLEMENT] ?? 999,
        message: AuthErrorMessageTemplates.METHOD_NOT_IMPLEMENTED,
        authType: config.authType.toUpperCase(),
      );
    }

    String codeVerifier = pkceResult["codeVerifier"];
    String codeChallenge = pkceResult["codeChallenge"];

    try {
      response = await socialPlugin.redirectLogin(codeVerifier, codeChallenge);
    } catch (e, stacktrace) {
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(
          AuthErrorMessageTemplates.FAILED_REQUEST,
          ['login using the browser'],
        );
      }

      throw AuthUtils.authErrorHandler(
        status: response.statusCode ?? 999,
        message: errMessage,
        authType: config.authType.toUpperCase(),
        stackTrace: stacktrace,
      );
    }
    return response;
  }

  Future<dynamic> getTokensAfterRedirect({
    required http.Client client,
    required String code,
    required String verifier,
  }) async {
    dynamic response;
    dynamic result;

    final reqURL =
        "${this.config.domainURL}${ONPREMConfig.REDIRECT_RESULT}?apiKey=${options?.appID}";

    String data = json.encode({"code_verifier": verifier, "code": code});
    final headers = <String, String>{"Content-Type": "application/json"};
    try {
      response = await client.post(
        Uri.parse(reqURL),
        headers: headers,
        body: data,
      );

      AuthUtils.checkResponse(this.__logLevel, response);
      result = jsonDecode(response.body);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "POST request");
      AuthUtils.baasTrace(
        this.__logLevel,
        reqURL,
        headers,
        data,
        e,
        stacktrace,
      );
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(
          AuthErrorMessageTemplates.FAILED_REQUEST,
          ['get tokens after redirect'],
        );
      }

      throw AuthUtils.authErrorHandler(
        status: response.statusCode ?? 999,
        message: errMessage,
        authType: config.authType.toUpperCase(),
        stackTrace: stacktrace,
      );
    }
    return result;
  }

  Future<String> getCodeFromURL() async {
    dynamic response;
    dynamic socialPlugin;

    final String host = options?.ordsHost ?? "";
    final String appID = options?.appID.toLowerCase() ?? "";
    final String method = "";

    socialPlugin = FusabaseWeb(
      host:
          "${host}_/baas-services/idm/${_servicePath}/${options?.projectID}/socialidp",
      queryParameters: {
        "method": method,
        "app_id": appID,
        "device": "web",
        "apiKey": options?.appID ?? "",
      },
      callbackUrlScheme: 'baasmobile$appID',
    );

    try {
      response = await socialPlugin.getCodeFromURL();
    } catch (e, stacktrace) {
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = "Failed to generate verifiers!";
      }

      throw AuthUtils.authErrorHandler(
        status: response.statusCode ?? 999,
        message: errMessage,
        authType: config.authType.toUpperCase(),
        stackTrace: stacktrace,
      );
    }

    return response;
  }

  void removeCodeParamFromUrl() {
    dynamic response;
    dynamic socialPlugin;

    final String host = options?.ordsHost ?? "";
    final String appID = options?.appID.toLowerCase() ?? "";
    final String method = "";

    socialPlugin = FusabaseWeb(
      host:
          "${host}_/baas-services/idm/${_servicePath}/${options?.projectID}/socialidp",
      queryParameters: {
        "method": method,
        "app_id": appID,
        "device": "web",
        "apiKey": options?.appID ?? "",
      },
      callbackUrlScheme: 'baasmobile$appID',
    );

    try {
      socialPlugin.removeCodeParamFromUrl();
    } catch (e, stacktrace) {}
  }

  dynamic getProvider(String id) {
    if (id == "google") {
      return GoogleAuthProvider();
    }
    if (id == "idcs") {
      return IDCSAuthProvider();
    }
    if (id == "facebook") {
      return FacebookAuthProvider();
    }
    if (id == "github") {
      return GithubAuthProvider();
    }
    if (id.startsWith("saml_")) {
      return SAMLAuthProvider(id.substring(5));
    }
    if (id.startsWith("oidc_")) {
      return OAuthProvider(id.substring(5));
    }
  }

  Future<void> sendPasswordResetEmailHelper({
    required http.Client client,
    required String email,
  }) async {
    dynamic response;
    dynamic result;
    final reqURL =
        "${config.domainURL}${ONPREMConfig.SEND_PASSWORD_RESET_EMAIL}?apiKey=${options?.appID}&email=${email}&requesttype=resetpwd";
    final headers = <String, String>{"Content-Type": "application/json"};

    try {
      response = await client.get(Uri.parse(reqURL), headers: headers);

      AuthUtils.checkResponse(__logLevel, response);
      result = response.body;
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(__logLevel, "GETrequest");
      AuthUtils.baasTrace(__logLevel, reqURL, headers, null, e, stacktrace);
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(
          AuthErrorMessageTemplates.FAILED_REQUEST,
          ['send password reset email'],
        );
      }

      throw AuthUtils.authErrorHandler(
        status: response.statusCode ?? 999,
        message: errMessage,
        authType: config.authType.toUpperCase(),
        stackTrace: stacktrace,
      );
    }

    return result;
  }

  Future<String> verifyPasswordResetCodeHelper({
    required http.Client client,
    required String code,
  }) async {
    dynamic response;
    dynamic result;
    final reqURL =
        "${config.domainURL}${ONPREMConfig.VERIFY_PASSWORD_RESET_CODE}?apiKey=${options?.appID}&code=${code}&requesttype=resetpwd";
    final headers = <String, String>{"Content-Type": "application/json"};

    try {
      response = await client.get(Uri.parse(reqURL), headers: headers);

      AuthUtils.checkResponse(__logLevel, response);
      result = jsonDecode(response.body);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(__logLevel, "GETrequest");
      AuthUtils.baasTrace(__logLevel, reqURL, headers, null, e, stacktrace);
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(
          AuthErrorMessageTemplates.FAILED_REQUEST,
          ['verify password reset code'],
        );
      }

      throw AuthUtils.authErrorHandler(
        status: response.statusCode ?? 999,
        message: errMessage,
        authType: config.authType.toUpperCase(),
        stackTrace: stacktrace,
      );
    }
    if (result != null && result["username"] != null) {
      return result["username"];
    }

    return result;
  }

  Future<void> confirmPasswordResetHelper({
    required http.Client client,
    required String code,
    required String newPassword,
  }) async {
    dynamic response;
    dynamic result;

    final reqURL =
        "${this.config.domainURL}${ONPREMConfig.CONFIRM_PASSWORD_RESET}?apiKey=${options?.appID}&requestType=resetpwd";

    String data = json.encode({"password": newPassword, "code": code});
    final headers = <String, String>{"Content-Type": "application/json"};
    try {
      response = await client.post(
        Uri.parse(reqURL),
        headers: headers,
        body: data,
      );

      AuthUtils.checkResponse(this.__logLevel, response);
      result = jsonDecode(response.body);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "POST request");
      AuthUtils.baasTrace(
        this.__logLevel,
        reqURL,
        headers,
        data,
        e,
        stacktrace,
      );
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.PASSWORD_RESET_FAILED;
      }

      throw AuthUtils.authErrorHandler(
        status: response.statusCode ?? 999,
        message: errMessage,
        authType: config.authType.toUpperCase(),
        stackTrace: stacktrace,
      );
    }
  }

  Future<dynamic> signInWithCredentialHelper({
    required http.Client client,
    dynamic credential,
  }) async {
    dynamic response;
    dynamic result;

    final reqURL =
        "${config.domainURL}${ONPREMConfig.SIGN_IN_WITH_CREDENTIAL}?apiKey=${options?.appID}&method=${credential.providerId}&link=0";

    String data = json.encode({"token": credential.idToken});
    final headers = <String, String>{"Content-Type": "application/json"};
    try {
      response = await client.post(
        Uri.parse(reqURL),
        headers: headers,
        body: data,
      );

      AuthUtils.checkResponse(this.__logLevel, response);
      result = jsonDecode(response.body);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "POST request");
      AuthUtils.baasTrace(
        this.__logLevel,
        reqURL,
        headers,
        data,
        e,
        stacktrace,
      );
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(
          AuthErrorMessageTemplates.FAILED_REQUEST,
          ['sign in with credential'],
        );
      }

      throw AuthUtils.authErrorHandler(
        status: response.statusCode ?? 999,
        message: errMessage,
        authType: config.authType.toUpperCase(),
        stackTrace: stacktrace,
      );
    }

    return result;
  }
}

/// @nodoc
// class ONPREMSRPAuthHelper extends ONPREMAuthHelper {
//   ONPREMSRPAuthHelper(
//       {required super.options, super.config, required super.logLevel});

//   BigInt generateRandomBigInteger(int bits) {
//     final bytes = bits ~/ 8;
//     final random = Random.secure();
//     final buffer = List<int>.generate(bytes, (_) => random.nextInt(256));
//     return BigInt.parse(buffer.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
//   }

//   String generateSalt() {
//     final lengthInBytes = 128 ~/ 8;
//     final random = Random.secure();
//     final array = List<int>.generate(lengthInBytes, (_) => random.nextInt(256));
//     return array.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
//   }

//   Future<String> generateHash(String input) async {
//     final bytes = utf8.encode(input);
//     final base64Str = base64Url.encode(bytes);
//     return base64Str;
//   }

//   Future<BigInt> encodeToBigInt(String text) async {
//     final hex = await generateHash(text);
//     return BigInt.parse('0x$hex');
//   }

//   Future<dynamic> getSharedKey(
//       {required http.Client client, required String email}) async {
//     dynamic response;
//     dynamic result;
//     final reqURL =
//         "${config.domainURL}${ONPREMSRPConfig.GET_SHARED_KEY}?apiKey=${options?.appID}&email=${email}";
//     final headers = <String, String>{"Content-Type": "application/json"};

//     try {
//       response = await client.get(Uri.parse(reqURL), headers: headers);

//       AuthUtils.checkResponse(__logLevel, response);
//       result = jsonDecode(response.body);
//     } catch (e, stacktrace) {
//       AuthUtils.baasLogger(__logLevel, "GETrequest");
//       AuthUtils.baasTrace(__logLevel, reqURL, headers, null, e, stacktrace);
//       String errMessage = "";

//       try {
//         errMessage = jsonDecode(response.body)["error"];
//       } catch (jsonErr) {
//         errMessage = "Failed to verify password reset code!";
//       }

//       throw AuthUtils.authErrorHandler(
//           status: response.statusCode ?? 999,
//           message: errMessage,
//           authType: config.authType.toUpperCase(),
//           stackTrace: stacktrace);
//     }

//     return result;
//   }

//   Future<dynamic> addUserUsingSRP(
//       {required http.Client client, dynamic body}) async {
//     dynamic response;
//     dynamic result;

//     final String reqURL =
//         "${this.config.domainURL}${ONPREMSRPConfig.SRP_ADD_USER}?apiKey=${options?.appID}";
//     final headers = <String, String>{"Content-Type": "application/json"};

//     try {
//       response = await client.post(Uri.parse(reqURL),
//           headers: headers, body: jsonEncode(body));
//       AuthUtils.checkResponse(this.__logLevel, response);
//       result = jsonDecode(response.body);
//     } catch (e, stacktrace) {
//       AuthUtils.baasLogger(this.__logLevel, "POST request");
//       AuthUtils.baasTrace(
//           this.__logLevel, reqURL, headers, body, e, stacktrace);
//       String errMessage = "";

//       try {
//         errMessage = jsonDecode(response.body)["message"];
//       } catch (jsonErr) {
//         errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['add user using SRP']);
//       }

//       throw AuthUtils.authErrorHandler(
//           status: response.statusCode ?? 999,
//           message: errMessage,
//           authType: config.authType.toUpperCase(),
//           stackTrace: stacktrace);
//     }

//     return result;
//   }

//   Future<dynamic> keyExchangeSRP(
//       {required http.Client client,
//       required BigInt A,
//       required String email}) async {
//     dynamic response;
//     dynamic result;

//     final String reqURL =
//         "${this.config.domainURL}${ONPREMSRPConfig.SRP_AUTHENTICATE_USER}?apiKey=${options?.appID}&reqtype=key_exchange";
//     final headers = <String, String>{"Content-Type": "application/json"};

//     final body = jsonEncode({"A": A, "email": email});

//     try {
//       response =
//           await client.post(Uri.parse(reqURL), headers: headers, body: body);
//       AuthUtils.checkResponse(this.__logLevel, response);
//       result = jsonDecode(response.body);
//     } catch (e, stacktrace) {
//       AuthUtils.baasLogger(this.__logLevel, "POST request");
//       AuthUtils.baasTrace(
//           this.__logLevel, reqURL, headers, body, e, stacktrace);
//       String errMessage = "";

//       try {
//         errMessage = jsonDecode(response.body)["message"];
//       } catch (jsonErr) {
//         errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['perform key exchange SRP']);
//       }

//       throw AuthUtils.authErrorHandler(
//           status: response.statusCode ?? 999,
//           message: errMessage,
//           authType: config.authType.toUpperCase(),
//           stackTrace: stacktrace);
//     }

//     return result;
//   }

//   Future<dynamic> sessionMatchSRP(
//       {required http.Client client,
//       required BigInt sharedkey,
//       required String email}) async {
//     dynamic response;
//     dynamic result;

//     final String reqURL =
//         "${this.config.domainURL}${ONPREMSRPConfig.SRP_AUTHENTICATE_USER}?apiKey=${options?.appID}&reqtype=session_match";
//     final headers = <String, String>{"Content-Type": "application/json"};

//     final body = jsonEncode({"sharedkey": sharedkey, "email": email});

//     try {
//       response =
//           await client.post(Uri.parse(reqURL), headers: headers, body: body);
//       AuthUtils.checkResponse(__logLevel, response);
//       result = jsonDecode(response.body);
//     } catch (e, stacktrace) {
//       AuthUtils.baasLogger(__logLevel, "POST request");
//       AuthUtils.baasTrace(__logLevel, reqURL, headers, body, e, stacktrace);
//       String errMessage = "";

//       try {
//         errMessage = jsonDecode(response.body)["message"];
//       } catch (jsonErr) {
//         errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['perform session match SRP']);
//       }

//       throw AuthUtils.authErrorHandler(
//           status: response.statusCode ?? 999,
//           message: errMessage,
//           authType: config.authType.toUpperCase(),
//           stackTrace: stacktrace);
//     }

//     return result;
//   }

//   @override
//   Future<dynamic> registerUser(
//       {required http.Client client,
//       required String email,
//       required String password}) async {
//     dynamic res = await getSharedKey(client: createClient(), email: email);
//     String salt = generateSalt();
//     final credHash = await generateHash('$email$password');
//     final X = await encodeToBigInt('$salt$credHash');
//     final N = BigInt.parse(res["N"]);
//     final G = BigInt.parse(res["G"]);
//     final K = BigInt.parse(res["K"]);
//     final V = modPow(G, X, N);
//     dynamic tokens = await addUserUsingSRP(client: createClient(), body: {
//       "N": N,
//       "G": G,
//       "K": K,
//       "V": V,
//       "salt": salt,
//       "email": email,
//       "first_name": "-",
//       "last_name": "-"
//     });

//     var data = {
//       "access_token": IdTokenResult(token: "${tokens['access_token']}"),
//       "refresh_token": "${tokens['refresh_token']}",
//     };

//     final userDetails =
//         await getUserDetails(accessToken: tokens["access_token"]);

//     return {
//       "userDetails": userDetails,
//       "authnToken": null,
//       "accessToken": data["access_token"],
//       "refreshToken": data["refresh_token"]
//     };
//   }

//   @override
//   Future<dynamic> authenticateAndGetDetails(
//       {required String email, required String password}) async {
//     final a = generateRandomBigInteger(256);

//     final res = await getSharedKey(client: createClient(), email: email);
//     final G = BigInt.parse(res["G"]);
//     final N = BigInt.parse(res["N"]);
//     final K = BigInt.parse(res["K"]);
//     final A = modPow(G, a, N);
//     final keyRes =
//         await keyExchangeSRP(client: createClient(), A: A, email: email);
//     final U = await encodeToBigInt('${A.toString()}${keyRes["B"]}');
//     final B = BigInt.parse(keyRes["B"]);
//     final salt = BigInt.parse(keyRes["salt"]);
//     final credHash = await generateHash('$email$password');
//     final X = await encodeToBigInt('$salt$credHash');

//     final gPowXmodN = modPow(G, X, N);
//     final kTimesgPowXmodN = K * gPowXmodN;
//     final subB = B - kTimesgPowXmodN;
//     final subtractedValue = subB % N;
//     final exponent = a + (U * X);
//     final S = modPow(subtractedValue, exponent, N);
//     final fK = await encodeToBigInt(S.toString());

//     dynamic tokens = await sessionMatchSRP(
//         client: createClient(), sharedkey: fK, email: email);

//     var data = {
//       "access_token": IdTokenResult(token: "${tokens['access_token']}"),
//       "refresh_token": "${tokens['refresh_token']}",
//     };

//     final userDetails =
//         await getUserDetails(accessToken: tokens["access_token"]);

//     return {
//       "userDetails": userDetails,
//       "authnToken": null,
//       "accessToken": data["access_token"],
//       "refreshToken": data["refresh_token"]
//     };
//   }
// }
