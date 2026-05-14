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
  final String encodedSecret;

  dynamic config;
  FusabaseApp? _app;

  globals.LogLevel __logLevel;

  IDCSUserHelper(
      {required this.options,
      required this.config,
      required globals.LogLevel logLevel})
      : __logLevel = logLevel,
        encodedSecret = base64.encode(utf8.encode("${config.clientID}:${config.clientSecret}"));

  void _setApp(FusabaseApp app) {
    _app = app;
  }

  Future<dynamic> refreshAccessToken(
      {required http.Client client, required String refreshToken}) async {
    dynamic response;
    dynamic result;

    final String reqURL =
        "${this.config.domainURL}${IDCSConfig.OAUTH_TOKEN_REST_EP}";
    final headers = <String, String>{
      "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
      "Authorization": "Basic $encodedSecret",
    };
    final body =
        "grant_type=refresh_token&refresh_token=$refreshToken&scope=offline_access";
    try {
      response =
          await client.post(Uri.parse(reqURL), headers: headers, body: body);
      AuthUtils.checkResponse(this.__logLevel, response);
      result = json.decode(response.body);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "POST request");
      AuthUtils.baasTrace(
          this.__logLevel, reqURL, headers, body, e, stacktrace);
      String errMessage = "";

      try {
        errMessage = json.decode(response.body)["message"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['refresh the access token']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
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

  Future<void> updatePasswordHelper(
      {required http.Client client,
      required User user,
      required String newPassword,
      required String oldPassword}) async {
    dynamic response;
    final reqURL =
        "${this.config.domainURL}${IDCSConfig.UPDATE_PASSWORD_HELPER}";
    String? idToken = await user.getIdToken();
    final headers = <String, String>{
      "Content-Type": "application/scim+json",
      "Authorization": "Bearer ${idToken}",
    };
    final body = json.encode({
      "password": newPassword,
      "oldPassword": oldPassword,
      "schemas": ["urn:ietf:params:scim:schemas:oracle:idcs:MePasswordChanger"]
    });
    try {
      response =
          await client.put(Uri.parse(reqURL), headers: headers, body: body);

      AuthUtils.checkResponse(this.__logLevel, response);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "PUT request");
      AuthUtils.baasTrace(
          this.__logLevel, reqURL, headers, body, e, stacktrace);
      String errMessage = "";

      try {
        errMessage = json.decode(response.body)["message"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.PASSWORD_UPDATE_FAILED;
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }
  }

  Future<dynamic> updateProfileNameHelper(
      {required http.Client client,
      required User user,
      required String displayName}) async {
    dynamic response;
    dynamic result;
    final reqURL = "${this.config.domainURL}${IDCSConfig.SELF_ME_REST_EP}";
    String? idToken = await user.getIdToken();
    final headers = <String, String>{
      "Content-Type": "application/scim+json",
      "Authorization": "Bearer ${idToken}",
    };
    final body = json.encode({
      "schemas": ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
      "Operations": makeNameOperations(user, displayName),
    });
    try {
      response =
          await client.patch(Uri.parse(reqURL), headers: headers, body: body);

      AuthUtils.checkResponse(this.__logLevel, response);
      result = json.decode(response.body);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "PATCH request");
      AuthUtils.baasTrace(
          this.__logLevel, reqURL, headers, body, e, stacktrace);
      String errMessage = "";

      try {
        errMessage = json.decode(response.body)["message"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['update the profile name of the user']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }

    return result;
  }

  Future<dynamic> updatePhoneNumberHelper(
      {required http.Client client,
      required User user,
      required String phoneNumber}) async {
    dynamic response;
    dynamic result;
    final reqURL = "${this.config.domainURL}${IDCSConfig.SELF_ME_REST_EP}";
    String? idToken = await user.getIdToken();
    final headers = <String, String>{
      "Content-Type": "application/scim+json",
      "Authorization": "Bearer ${idToken}",
    };
    final body = json.encode({
      "schemas": ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
      "Operations": makePhoneOperations(user, phoneNumber),
    });
    try {
      response =
          await client.patch(Uri.parse(reqURL), headers: headers, body: body);

      AuthUtils.checkResponse(this.__logLevel, response);
      result = json.decode(response.body);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "PATCH request");
      AuthUtils.baasTrace(
          this.__logLevel, reqURL, headers, body, e, stacktrace);
      String errMessage = "";

      try {
        errMessage = json.decode(response.body)["message"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['update the phone number of the user']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }

    return result;
  }

  Future<dynamic> updatePhotoURLHelper(
      {required http.Client client,
      required User user,
      required String photoURL}) async {
    dynamic response;
    dynamic result;
    final reqURL = "${this.config.domainURL}${IDCSConfig.SELF_ME_REST_EP}";
    String? idToken = await user.getIdToken();
    final headers = <String, String>{
      "Content-Type": "application/scim+json",
      "Authorization": "Bearer ${idToken}",
    };
    final body = json.encode({
      "schemas": ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
      "Operations": makePhotoOperations(user, photoURL),
    });
    try {
      response =
          await client.patch(Uri.parse(reqURL), headers: headers, body: body);

      AuthUtils.checkResponse(this.__logLevel, response);
      result = json.decode(response.body);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "PATCH request");
      AuthUtils.baasTrace(
          this.__logLevel, reqURL, headers, body, e, stacktrace);
      String errMessage = "";

      try {
        errMessage = json.decode(response.body)["message"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['update the photo URL of the user']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }

    return result;
  }

  List<dynamic> makeNameOperations(User user, String displayName) {
    List<dynamic> operations = [];
    if (user.displayName != displayName) {
      operations.add({
        "op": user.displayName != null
            ? displayName != null
                ? "replace"
                : "remove"
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
        "op": user.phoneNumber != null
            ? phoneNumber != null
                ? "replace"
                : "remove"
            : "add",
        "path": "phoneNumbers",
        "value": [
          {"value": phoneNumber, "type": "home"}
        ],
      });
    }

    return operations;
  }

  List<dynamic> makePhotoOperations(User user, String photoURL) {
    List<dynamic> operations = [];
    if (user.photoURL != photoURL) {
      operations.add({
        "op": user.photoURL != null
            ? photoURL != null
                ? "replace"
                : "remove"
            : "add",
        "path": "photos",
        "value": [
          {"value": photoURL, "type": "photo"}
        ],
      });
    }

    return operations;
  }

  Future<dynamic> sendEmailVerificationHelper(
      {required http.Client client,
      required User user,
      required String email,
      required String id}) async {
    dynamic response;
    dynamic result;
    final reqURL = "${config.domainURL}${IDCSConfig.SEND_EMAIL_VERIFICATION}";
    String? idToken = await user.getIdToken();
    final headers = <String, String>{
      "Content-Type": "application/json",
      "Authorization": "Bearer ${idToken}"
    };
    final body = json.encode({
      "id": id,
      "email": email,
      "schemas": ["urn:ietf:params:scim:schemas:oracle:idcs:MeEmailVerifier"],
      "meta": {"resourceType": "MeEmailVerifier"}
    });
    try {
      response =
          await client.put(Uri.parse(reqURL), headers: headers, body: body);

      AuthUtils.checkResponse(__logLevel, response);
      result = json.decode(response.body);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(__logLevel, "PATCH request");
      AuthUtils.baasTrace(__logLevel, reqURL, headers, body, e, stacktrace);
      String errMessage = "";

      try {
        errMessage = json.decode(response.body)["message"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['send verification email']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }

    return result;
  }

  Future<dynamic> fetchFusabaseToken(
      {required http.Client client, required User user, required String url}) async {
    dynamic response;
    dynamic result;
    final reqURL = url;
    final headers = <String, String>{
      "Content-Type": "application/json"
    };
    String? idToken = await user.getIdToken();
    final body = json.encode({
      "token": idToken
    });
    try {
      response =
          await client.post(Uri.parse(reqURL), headers: headers, body: body);

      AuthUtils.checkResponse(__logLevel, response);
      result = json.decode(response.body);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(__logLevel, "PATCH request");
      AuthUtils.baasTrace(__logLevel, reqURL, headers, body, e, stacktrace);
      String errMessage = "";

      try {
        errMessage = json.decode(response.body)["message"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['send verification email']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }
    return result["access_token"];
  }

  Future<dynamic> linkWithCredentialHelper ({required http.Client client,
      required User user, required dynamic credential}) async {
    String errMessage = NOT_IMPLEMENTED_ERROR_IDCS;
    throw AuthUtils.authErrorHandler(
        status: globals.ErrorMap[globals.ErrorCode.NOT_IMPLEMENT] ?? 999,
        message: errMessage,
        authType: config.authType.toUpperCase());
  }

  Future<dynamic> generatePKCE(dynamic provider) async {
    dynamic response;
    final String host = options?.ordsHost ?? "";
    final String appID = options?.appID.toLowerCase() ?? "";
    final String method = provider.providerId;

    dynamic socialPlugin;
    if (kIsWeb) {
      socialPlugin = FusabaseWeb(
          host: "${host}_/baas-services/idm/idcs/${options?.projectID}/social",
          queryParameters: {"app_id": appID, "link":"0", "device": "web",
          "apiKey": options?.appID ?? ""},
          callbackUrlScheme: 'baasmobile$appID');
    } else {
      socialPlugin = FusabaseDartPlugin(
          host: "${host}_/baas-services/idm/idcs/${options?.projectID}/social",
          queryParameters: {"app_id": appID, "link":"0", "device": "web",
          "apiKey": options?.appID ?? ""},
          callbackUrlScheme: 'baasmobile$appID');
    }

    try {
      response = await socialPlugin.generatePKCEVerifiers();
    } catch (e, stacktrace) {
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['generate verifiers']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }

    return response;
  }

  Future<dynamic> socialLink(dynamic provider) async {
    String errMessage = NOT_IMPLEMENTED_ERROR_IDCS;
    throw AuthUtils.authErrorHandler(
        status: globals.ErrorMap[globals.ErrorCode.NOT_IMPLEMENT] ?? 999,
        message: errMessage,
        authType: config.authType.toUpperCase());
  }

  Future<dynamic> listenForSuccess(dynamic popupWindow) async {
    String errMessage = NOT_IMPLEMENTED_ERROR_IDCS;
    throw AuthUtils.authErrorHandler(
        status: globals.ErrorMap[globals.ErrorCode.NOT_IMPLEMENT] ?? 999,
        message: errMessage,
        authType: config.authType.toUpperCase());
  }

  Future<dynamic> unlinkHelper ({required http.Client client, required User user, dynamic providerId}) async {
    String errMessage = NOT_IMPLEMENTED_ERROR_IDCS;
    throw AuthUtils.authErrorHandler(
        status: globals.ErrorMap[globals.ErrorCode.NOT_IMPLEMENT] ?? 999,
        message: errMessage,
        authType: config.authType.toUpperCase());
  }

  

  Future<dynamic> linkWithRedirectHelper(dynamic provider, dynamic pkceResult) async {
    dynamic response;
    final String host = options?.ordsHost ?? "";
    final String appID = options?.appID.toLowerCase() ?? "";
    final String method = provider.providerId;

    dynamic socialPlugin;

    if (kIsWeb) {
      socialPlugin = FusabaseWeb(
          host: "${host}_/baas-services/idm/idcs/${options?.projectID}/social",
          queryParameters: {"method": method, "app_id": appID, "link":"1", "device": "web",
          "apiKey": options?.appID ?? ""},
          callbackUrlScheme: 'baasmobile$appID');
    } else {
      throw AuthUtils.authErrorHandler(
        status: globals.ErrorMap[globals.ErrorCode.NOT_IMPLEMENT] ?? 999,
        message: AuthErrorMessageTemplates.METHOD_NOT_IMPLEMENTED,
        authType: config.authType.toUpperCase());
    }

    String codeVerifier = pkceResult["codeVerifier"];
    String codeChallenge = pkceResult["codeChallenge"];

    try {
      response = await socialPlugin.redirectLogin(codeVerifier,
       codeChallenge);
    } catch (e, stacktrace) {
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['login using the browser']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }
    response["codeVerifier"] = codeVerifier;
    return response;
  }
}

/// @nodoc
class ONPREMUserHelper {
  final FusabaseOptions? options;

  dynamic config;
  FusabaseApp? _app;

  globals.LogLevel __logLevel;

  ONPREMUserHelper(
      {required this.options,
      required this.config,
      required globals.LogLevel logLevel})
      : __logLevel = logLevel;

  void _setApp(FusabaseApp app) {
    _app = app;
  }

  Future<dynamic> refreshAccessToken(
      {required http.Client client, required String refreshToken}) async {
    dynamic response;
    dynamic result;

    final String reqURL =
        "${this.config.domainURL}${ONPREMConfig.AUTHENTICATE_REST_EP}?apiKey=${options?.appID}";
    final headers = <String, String>{};
    final body = json.encode({"refresh_token": refreshToken, 
    "grant_type": "refresh_token"});
    try {
      response =
          await client.post(Uri.parse(reqURL), headers: headers, body: body);

      AuthUtils.checkResponse(this.__logLevel, response);
      result = json.decode(response.body);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "POST request");
      AuthUtils.baasTrace(
          this.__logLevel, reqURL, headers, body, e, stacktrace);
      String errMessage = "";

      try {
        errMessage = json.decode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['refresh the access token']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
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

  Future<void> updatePasswordHelper(
      {required http.Client client,
      required User user,
      required String newPassword,
      required String oldPassword}) async {
    dynamic response;
    final reqURL =
        "${this.config.domainURL}${ONPREMConfig.UPDATE_PASSWORD_HELPER}?apiKey=${options?.appID}";
    String? idToken = await user.getIdToken();
    final headers = <String, String>{
      "X-AUTHZ": idToken ?? "",
    };
    final body = json.encode({
      "password": newPassword,
      "oldPassword": oldPassword,
    });

    try {
      response =
          await client.put(Uri.parse(reqURL), headers: headers, body: body);

      AuthUtils.checkResponse(this.__logLevel, response);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "PUT request");
      AuthUtils.baasTrace(
          this.__logLevel, reqURL, headers, body, e, stacktrace);
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
          stackTrace: stacktrace);
    }
  }

  Future<dynamic> updateProfileNameHelper(
      {required http.Client client,
      required User user,
      required String displayName}) async {
    dynamic response;
    final reqURL =
        "${this.config.domainURL}${ONPREMConfig.UPDATE_PROFILE_HELPER}?apiKey=${options?.appID}";
    String? accessToken = await user.getIdToken();
    final headers = <String, String>{
      "X-AUTHZ": accessToken ?? "",
    };
    final body = json.encode({
      "Operations": makeNameOperations(user, displayName),
    });

    try {
      response =
          await client.put(Uri.parse(reqURL), headers: headers, body: body);

      AuthUtils.checkResponse(this.__logLevel, response);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "PUT request");
      AuthUtils.baasTrace(
          this.__logLevel, reqURL, headers, body, e, stacktrace);
      String errMessage = "";

      try {
        errMessage = json.decode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['update the profile name of the user']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }

    return {"displayName": displayName};
  }

  Future<dynamic> updatePhoneNumberHelper(
      {required http.Client client,
      required User user,
      required String phoneNumber}) async {
    dynamic response;
    final reqURL =
        "${this.config.domainURL}${ONPREMConfig.UPDATE_PROFILE_HELPER}?apiKey=${options?.appID}";
    String? accessToken = await user.getIdToken();
    final headers = <String, String>{
      "X-AUTHZ": accessToken ?? "",
    };
    final body = json.encode({
      "Operations": makePhoneOperations(user, phoneNumber),
    });

    try {
      response =
          await client.put(Uri.parse(reqURL), headers: headers, body: body);

      AuthUtils.checkResponse(this.__logLevel, response);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "PUT request");
      AuthUtils.baasTrace(
          this.__logLevel, reqURL, headers, body, e, stacktrace);
      String errMessage = "";

      try {
        errMessage = json.decode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['update the phone number of the user']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }

    return {"phoneNumber": phoneNumber};
  }

  Future<dynamic> updatePhotoURLHelper(
      {required User user, required String photoURL}) async {
    String errMessage = AuthErrorMessageTemplates.METHOD_NOT_SUPPORTED_ONPREM;
    throw AuthUtils.authErrorHandler(
        status: globals.ErrorMap[globals.ErrorCode.NOT_IMPLEMENT] ?? 999,
        message: errMessage,
        authType: config.authType.toUpperCase());
  }

  List<dynamic> makeNameOperations(User user, String displayName) {
    List<dynamic> operations = [];
    if (user.displayName != displayName) {
      operations.add({
        "op": user.displayName != null
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
        "op": user.phoneNumber != null
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

  Future<dynamic> sendEmailVerificationHelper(
      {required http.Client client,
      required User user,
      required String email,
      required String id}) async {
    dynamic response;
    dynamic result;
    final reqURL =
        "${config.domainURL}${ONPREMConfig.SEND_EMAIL_VERIFICATION}?apiKey=${options?.appID}&email=${email}&requesttype=verifyemail";
    String? idToken = await user.getIdToken();
    final headers = <String, String>{
      "Content-Type": "application/json",
      "Authorization": "Bearer ${idToken}"
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
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['send verification email']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }

    return result;
  }

  Future<dynamic> fetchFusabaseToken(
      {required http.Client client, required User user, required String url}) async {
    String? idToken = await user.getIdToken();
    return idToken;
  }

  Future<dynamic> linkWithCredentialHelper ({required http.Client client,
      required User user, required dynamic credential}) async {
    dynamic response;
    dynamic result;
    Map<String,String> body = {
      "token":"",
      "password":""
    };
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
      "Authorization": "Bearer ${idToken}"
    };
    

    try {
      response = await client.post(Uri.parse(reqURL), headers: headers, body: jsonEncode(body));
      AuthUtils.checkResponse(__logLevel, response);
      result = json.decode(response.body);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(__logLevel, "GETrequest");
      AuthUtils.baasTrace(__logLevel, reqURL, headers, null, e, stacktrace);
      String errMessage = "";

      try {
        errMessage = json.decode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['link the user']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
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
          host: "${host}_/baas-services/idm/onprem/${options?.projectID}/socialidp",
          queryParameters: {"method": method, "app_id": appID, "link":"0", "device": "web",
          "apiKey": options?.appID ?? ""},
          callbackUrlScheme: 'baasmobile$appID');
    } else {
      socialPlugin = FusabaseDartPlugin(
          host: "${host}_/baas-services/idm/onprem/${options?.projectID}/socialidp",
          queryParameters: {"method": method, "app_id": appID, "link":"0", "device": "web",
          "apiKey": options?.appID ?? ""},
          callbackUrlScheme: 'baasmobile$appID');
    }

    try {
      response = await socialPlugin.generatePKCEVerifiers();
    } catch (e, stacktrace) {
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['generate verifiers']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }

    return response;
  }

  Future<dynamic> getTokensAfterRedirect(
      {required http.Client client,
      required String code,
      required String verifier}) async {
    dynamic response;
    dynamic result;

    final reqURL =
        "${options?.ordsHost}_/baas-services/idm/onprem/${options?.projectID}/${ONPREMConfig.REDIRECT_RESULT}?apiKey=${options?.appID}";

    String data = json.encode({
      "code_verifier": verifier,
      "code": code
    });
    final headers = <String, String>{"Content-Type": "application/json"};
    try {
      response =
          await client.post(Uri.parse(reqURL), headers: headers, body: data);
      AuthUtils.checkResponse(this.__logLevel, response);
      result = jsonDecode(response.body);
 
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "POST request");
      AuthUtils.baasTrace(
          this.__logLevel, reqURL, headers, data, e, stacktrace);
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['get tokens after redirect']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
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
          host: "${host}_/baas-services/idm/onprem/${options?.projectID}/socialidp",
          queryParameters: {"method": provider.providerId, "link":"1", "app_id": appID, "device": "web",
          "apiKey": options?.appID ?? ""},
          callbackUrlScheme: 'baasmobile$appID');
    } else {
      socialPlugin = FusabaseDartPlugin(
          host: "${host}_/baas-services/idm/onprem/${options?.projectID}/socialidp",
          queryParameters: {
            "method": provider.providerId,
            "app_id": appID,
            "device": "mobile",
            "link":"1",
            "apiKey": options?.appID ?? ""
          },
          callbackUrlScheme: 'baasmobile$appID');
    }

    try {
      response = await socialPlugin.socialLink(codeVerifier,
       codeChallenge);
      if (!kIsWeb) {
        fResponse = await getTokensAfterRedirect(client:
          createClient(_app), code: response, verifier: codeVerifier);
      } else {
        fResponse = response;
      }
      //response = jsonDecode(response);
    } catch (e, stacktrace) {
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["error"];
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


  Future<dynamic> unlinkHelper ({required http.Client client, required User user, dynamic providerId}) async {
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
      "Authorization": "Bearer ${idToken}"
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
          stackTrace: stacktrace);
    }

    return result;
  }

  Future<dynamic> linkWithRedirectHelper(dynamic provider, dynamic pkceResult) async {
    dynamic response;
    final String host = options?.ordsHost ?? "";
    final String appID = options?.appID.toLowerCase() ?? "";
    final String method = provider.providerId;

    dynamic socialPlugin;

    if (kIsWeb) {
      socialPlugin = FusabaseWeb(
          host: "${host}_/baas-services/idm/onprem/${options?.projectID}/socialidp",
          queryParameters: {"method": method, "app_id": appID, "link":"1", "device": "web",
          "apiKey": options?.appID ?? ""},
          callbackUrlScheme: 'baasmobile$appID');
    } else {
      throw AuthUtils.authErrorHandler(
        status: globals.ErrorMap[globals.ErrorCode.NOT_IMPLEMENT] ?? 999,
        message: AuthErrorMessageTemplates.METHOD_NOT_IMPLEMENTED,
        authType: config.authType.toUpperCase());
    }

    String codeVerifier = pkceResult["codeVerifier"];
    String codeChallenge = pkceResult["codeChallenge"];

    try {
      response = await socialPlugin.redirectLogin(codeVerifier,
       codeChallenge);
    } catch (e, stacktrace) {
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['login using the browser']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
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
