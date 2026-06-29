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
class IDCSUserHelper {
  final FusabaseOptions? options;

  dynamic config;
  late final ONPREMUserHelper _delegate;

  IDCSUserHelper({
    required this.options,
    required this.config,
    required globals.LogLevel logLevel,
  }) {
    _delegate = ONPREMUserHelper(
      options: options,
      config: config,
      logLevel: logLevel,
    );
  }

  void _setApp(FusabaseApp app) {
    _delegate._setApp(app);
  }

  Future<dynamic> refreshAccessToken({
    required http.Client client,
    required String refreshToken,
  }) async {
    return _delegate.refreshAccessToken(
      client: client,
      refreshToken: refreshToken,
    );
  }

  bool vaidateAccessToken(accTok) {
    return _delegate.vaidateAccessToken(accTok);
  }

  bool vaidateFUSABASEToken(osbTok) {
    return _delegate.vaidateFUSABASEToken(osbTok);
  }

  Future<void> updatePasswordHelper({
    required http.Client client,
    required User user,
    required String newPassword,
    required String oldPassword,
  }) async {
    return _delegate.updatePasswordHelper(
      client: client,
      user: user,
      newPassword: newPassword,
      oldPassword: oldPassword,
    );
  }

  Future<dynamic> updateProfileNameHelper({
    required http.Client client,
    required User user,
    required String displayName,
  }) async {
    return _delegate.updateProfileNameHelper(
      client: client,
      user: user,
      displayName: displayName,
    );
  }

  Future<dynamic> updatePhoneNumberHelper({
    required http.Client client,
    required User user,
    required String phoneNumber,
  }) async {
    return _delegate.updatePhoneNumberHelper(
      client: client,
      user: user,
      phoneNumber: phoneNumber,
    );
  }

  Future<dynamic> updatePhotoURLHelper({
    http.Client? client,
    required User user,
    required String photoURL,
  }) async {
    return _delegate.updatePhotoURLHelper(user: user, photoURL: photoURL);
  }

  List<dynamic> makeNameOperations(User user, String displayName) {
    return _delegate.makeNameOperations(user, displayName);
  }

  List<dynamic> makePhoneOperations(User user, String phoneNumber) {
    return _delegate.makePhoneOperations(user, phoneNumber);
  }

  List<dynamic> makePhotoOperations(User user, String photoURL) {
    return [];
  }

  Future<dynamic> sendEmailVerificationHelper({
    required http.Client client,
    required User user,
    required String email,
    required String id,
  }) async {
    return _delegate.sendEmailVerificationHelper(
      client: client,
      user: user,
      email: email,
      id: id,
    );
  }

  Future<dynamic> fetchFusabaseToken({
    required http.Client client,
    required User user,
    required String url,
  }) async {
    return _delegate.fetchFusabaseToken(client: client, user: user, url: url);
  }

  Future<dynamic> linkWithCredentialHelper({
    required http.Client client,
    required User user,
    required dynamic credential,
  }) async {
    return _delegate.linkWithCredentialHelper(
      client: client,
      user: user,
      credential: credential,
    );
  }

  Future<dynamic> generatePKCE(dynamic provider) async {
    return _delegate.generatePKCE(provider);
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

  Future<dynamic> socialLink(dynamic provider) async {
    String errMessage = NOT_IMPLEMENTED_ERROR_IDCS;
    throw AuthUtils.authErrorHandler(
        status: globals.ErrorMap[globals.ErrorCode.NOT_IMPLEMENT] ?? 999,
        message: errMessage,
        authType: config.authType.toUpperCase());
  }

  Future<dynamic> listenForSuccess(dynamic popupWindow) async {
    throw AuthUtils.authErrorHandler(
      status: globals.ErrorMap[globals.ErrorCode.NOT_IMPLEMENT] ?? 999,
      message: AuthErrorMessageTemplates.METHOD_NOT_IMPLEMENTED,
      authType: config.authType.toUpperCase(),
    );
  }

  Future<dynamic> unlinkHelper({
    required http.Client client,
    required User user,
    dynamic providerId,
  }) async {
    return _delegate.unlinkHelper(
      client: client,
      user: user,
      providerId: providerId,
    );
  }

  Future<dynamic> linkWithRedirectHelper(
    dynamic provider,
    dynamic pkceResult,
  ) async {
    return _delegate.linkWithRedirectHelper(provider, pkceResult);
  }
}

/// @nodoc
class ONPREMUserHelper {
  final FusabaseOptions? options;

  dynamic config;
  FusabaseApp? _app;

  globals.LogLevel __logLevel;

  ONPREMUserHelper({
    required this.options,
    required this.config,
    required globals.LogLevel logLevel,
  }) : __logLevel = logLevel;

  void _setApp(FusabaseApp app) {
    _app = app;
  }

  String get _servicePath => config.authType == "idcs" ? "idcs" : "onprem";

  Future<dynamic> refreshAccessToken({
    required http.Client client,
    required String refreshToken,
  }) async {
    dynamic response;
    dynamic result;

    final String reqURL =
        "${this.config.domainURL}${ONPREMConfig.AUTHENTICATE_REST_EP}?apiKey=${options?.appID}";
    final headers = <String, String>{};
    final body = json.encode({
      "refresh_token": refreshToken,
      "grant_type": "refresh_token",
    });
    try {
      response = await client.post(
        Uri.parse(reqURL),
        headers: headers,
        body: body,
      );

      AuthUtils.checkResponse(this.__logLevel, response);
      result = json.decode(response.body);
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
        errMessage = json.decode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(
          AuthErrorMessageTemplates.FAILED_REQUEST,
          ['refresh the access token'],
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

  bool vaidateAccessToken(accTok) {
    if (accTok == null) {
      return false;
    }
    DateTime curr = DateTime.now();
    DateTime ref = accTok.expirationTime ?? curr;

    if (ref.isBefore(curr)) {
      return false;
    }
    return true;
  }

  bool vaidateFUSABASEToken(osbTok) {
    if (osbTok == null) {
      return false;
    }
    DateTime curr = DateTime.now();
    DateTime ref = osbTok?.expirationTime ?? curr;

    if (ref.isBefore(curr)) {
      return false;
    }
    return true;
  }

  Future<void> updatePasswordHelper({
    required http.Client client,
    required User user,
    required String newPassword,
    required String oldPassword,
  }) async {
    dynamic response;
    final reqURL =
        "${this.config.domainURL}${ONPREMConfig.UPDATE_PASSWORD_HELPER}?apiKey=${options?.appID}";
    String? idToken = await user.getIdToken();
    final headers = <String, String>{"X-AUTHZ": idToken ?? ""};
    final body = json.encode({
      "password": newPassword,
      "oldPassword": oldPassword,
    });

    try {
      response = await client.put(
        Uri.parse(reqURL),
        headers: headers,
        body: body,
      );

      AuthUtils.checkResponse(this.__logLevel, response);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "PUT request");
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
        errMessage = json.decode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.PASSWORD_UPDATE_FAILED;
      }

      throw AuthUtils.authErrorHandler(
        status: response.statusCode ?? 999,
        message: errMessage,
        authType: config.authType.toUpperCase(),
        stackTrace: stacktrace,
      );
    }
  }

  Future<dynamic> updateProfileNameHelper({
    required http.Client client,
    required User user,
    required String displayName,
  }) async {
    dynamic response;
    final reqURL =
        "${this.config.domainURL}${ONPREMConfig.UPDATE_PROFILE_HELPER}?apiKey=${options?.appID}";
    String? accessToken = await user.getIdToken();
    final headers = <String, String>{"X-AUTHZ": accessToken ?? ""};
    final body = json.encode({
      "Operations": makeNameOperations(user, displayName),
    });

    try {
      response = await client.put(
        Uri.parse(reqURL),
        headers: headers,
        body: body,
      );

      AuthUtils.checkResponse(this.__logLevel, response);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "PUT request");
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
        errMessage = json.decode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(
          AuthErrorMessageTemplates.FAILED_REQUEST,
          ['update the profile name of the user'],
        );
      }

      throw AuthUtils.authErrorHandler(
        status: response.statusCode ?? 999,
        message: errMessage,
        authType: config.authType.toUpperCase(),
        stackTrace: stacktrace,
      );
    }

    return {"displayName": displayName};
  }

  Future<dynamic> updatePhoneNumberHelper({
    required http.Client client,
    required User user,
    required String phoneNumber,
  }) async {
    dynamic response;
    final reqURL =
        "${this.config.domainURL}${ONPREMConfig.UPDATE_PROFILE_HELPER}?apiKey=${options?.appID}";
    String? accessToken = await user.getIdToken();
    final headers = <String, String>{"X-AUTHZ": accessToken ?? ""};
    final body = json.encode({
      "Operations": makePhoneOperations(user, phoneNumber),
    });

    try {
      response = await client.put(
        Uri.parse(reqURL),
        headers: headers,
        body: body,
      );

      AuthUtils.checkResponse(this.__logLevel, response);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "PUT request");
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
        errMessage = json.decode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(
          AuthErrorMessageTemplates.FAILED_REQUEST,
          ['update the phone number of the user'],
        );
      }

      throw AuthUtils.authErrorHandler(
        status: response.statusCode ?? 999,
        message: errMessage,
        authType: config.authType.toUpperCase(),
        stackTrace: stacktrace,
      );
    }

    return {"phoneNumber": phoneNumber};
  }

  Future<dynamic> updatePhotoURLHelper({
    required User user,
    required String photoURL,
  }) async {
    String errMessage = AuthErrorMessageTemplates.METHOD_NOT_SUPPORTED_ONPREM;
    throw AuthUtils.authErrorHandler(
      status: globals.ErrorMap[globals.ErrorCode.NOT_IMPLEMENT] ?? 999,
      message: errMessage,
      authType: config.authType.toUpperCase(),
    );
  }

  List<dynamic> makeNameOperations(User user, String displayName) {
    List<dynamic> operations = [];
    if (user.displayName != displayName) {
      operations.add({
        "op":
            user.displayName != null
                ? displayName != null
                    ? "replace"
                    : "replace"
                : "add",
        "path": "displayName",
        "value": displayName,
      });
    }

    return operations;
  }

  List<dynamic> makePhoneOperations(User user, String phoneNumber) {
    List<dynamic> operations = [];
    if (user.phoneNumber != phoneNumber) {
      operations.add({
        "op":
            user.phoneNumber != null
                ? phoneNumber != null
                    ? "replace"
                    : "replace"
                : "add",
        "path": "phoneNumber",
        "value": phoneNumber,
      });
    }

    return operations;
  }

  Future<dynamic> sendEmailVerificationHelper({
    required http.Client client,
    required User user,
    required String email,
    required String id,
  }) async {
    dynamic response;
    dynamic result;
    final reqURL =
        "${config.domainURL}${ONPREMConfig.SEND_EMAIL_VERIFICATION}?apiKey=${options?.appID}&email=${email}&requesttype=verifyemail";
    String? idToken = await user.getIdToken();
    final headers = <String, String>{
      "Content-Type": "application/json",
      "Authorization": "Bearer ${idToken}",
    };

    try {
      response = await client.get(Uri.parse(reqURL), headers: headers);

      AuthUtils.checkResponse(__logLevel, response);
      result = response.body;
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(__logLevel, "GETrequest");
      AuthUtils.baasTrace(__logLevel, reqURL, headers, null, e, stacktrace);
      String errMessage = "";

      try {
        errMessage = json.decode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(
          AuthErrorMessageTemplates.FAILED_REQUEST,
          ['send verification email'],
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

  Future<dynamic> fetchFusabaseToken({
    required http.Client client,
    required User user,
    required String url,
  }) async {
    String? idToken = await user.getIdToken();
    return idToken;
  }

  Future<dynamic> linkWithCredentialHelper({
    required http.Client client,
    required User user,
    required dynamic credential,
  }) async {
    dynamic response;
    dynamic result;
    Map<String, String> body = {"token": "", "password": ""};
    var linkProvider = credential.providerId;
    String? idToken = await user.getIdToken();
    if (credential is EmailAuthCredential) {
      body["password"] = credential.password ?? "";
      linkProvider = "epw";
    } else {
      body["token"] = credential.idToken;
    }
    final reqURL =
        "${config.domainURL}${ONPREMConfig.SIGN_IN_WITH_CREDENTIAL}?apiKey=${options?.appID}&method=${linkProvider}&link=1";
    final headers = <String, String>{
      "Content-Type": "application/json",
      "Authorization": "Bearer ${idToken}",
    };

    try {
      response = await client.post(
        Uri.parse(reqURL),
        headers: headers,
        body: jsonEncode(body),
      );
      AuthUtils.checkResponse(__logLevel, response);
      result = json.decode(response.body);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(__logLevel, "GETrequest");
      AuthUtils.baasTrace(__logLevel, reqURL, headers, null, e, stacktrace);
      String errMessage = "";

      try {
        errMessage = json.decode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(
          AuthErrorMessageTemplates.FAILED_REQUEST,
          ['link the user'],
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

  Future<dynamic> getTokensAfterRedirect({
    required http.Client client,
    required String code,
    required String verifier,
  }) async {
    dynamic response;
    dynamic result;

    final reqURL =
        "${config.domainURL}${ONPREMConfig.REDIRECT_RESULT}?apiKey=${options?.appID}";

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

  Future<dynamic> socialLink(dynamic provider) async {
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
          "link": "1",
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
          "device": "mobile",
          "link": "1",
          "apiKey": options?.appID ?? "",
        },
        callbackUrlScheme: 'baasmobile$appID',
      );
    }

    try {
      response = await socialPlugin.socialLink(codeVerifier, codeChallenge);
      if (!kIsWeb) {
        fResponse = await getTokensAfterRedirect(
          client: createClient(_app),
          code: response,
          verifier: codeVerifier,
        );
      } else {
        fResponse = response;
      }
      //response = jsonDecode(response);
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

  Future<dynamic> unlinkHelper({
    required http.Client client,
    required User user,
    dynamic providerId,
  }) async {
    dynamic response;
    dynamic result;
    var linkProvider = providerId;
    if (providerId == EmailAuthProvider.PROVIDER_ID) {
      linkProvider = "epw";
    }
    String? idToken = await user.getIdToken();
    final reqURL =
        "${config.domainURL}${ONPREMConfig.SIGN_IN_WITH_CREDENTIAL}?apiKey=${options?.appID}&method=${linkProvider}";
    final headers = <String, String>{
      "Content-Type": "application/json",
      "Authorization": "Bearer ${idToken}",
    };

    try {
      response = await client.delete(Uri.parse(reqURL), headers: headers);
      AuthUtils.checkResponse(__logLevel, response);
      result = json.decode(response.body);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(__logLevel, "GETrequest");
      AuthUtils.baasTrace(__logLevel, reqURL, headers, null, e, stacktrace);
      String errMessage = "";

      try {
        errMessage = json.decode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = "Can't unlink the user";
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

  Future<dynamic> linkWithRedirectHelper(
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
          "link": "1",
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
    response["codeVerifier"] = codeVerifier;
    return response;
  }
}

/// @nodoc
// class ONPREMSRPUserHelper extends ONPREMUserHelper {
//   ONPREMSRPUserHelper(
//       {required super.options,
//       required super.config,
//       required super.accessToken,
//       required super.logLevel});
// }
