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

  final String encodedSecret;

  IdTokenResult? bearerToken;

  globals.LogLevel __logLevel;

  IDCSAuthHelper(
      {required this.options,
      required this.config,
      required globals.LogLevel logLevel})
      : __logLevel = logLevel,
        encodedSecret = base64
            .encode(("${config.clientID}:${config.clientSecret}").codeUnits);

  void _setApp(FusabaseApp app) {
    _app = app;
  }

  Future<IdTokenResult?> getBearerToken(http.Client client) async {
    dynamic response;
    dynamic result;

    final reqUrl = "${this.config.domainURL}${IDCSConfig.OAUTH_TOKEN_REST_EP}";
    final body = "grant_type=client_credentials&scope=urn:opc:idm:__myscopes__";
    final headers = <String, String>{
      "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
      "Authorization": "Basic $encodedSecret"
    };
    try {
      response =
          await client.post(Uri.parse(reqUrl), headers: headers, body: body);
      AuthUtils.checkResponse(this.__logLevel, response);
      result = jsonDecode(response.body);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "POST request");
      AuthUtils.baasTrace(
          this.__logLevel, reqUrl, headers, body, e, stacktrace);
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["message"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['get the access token']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }
    bearerToken = IdTokenResult(token: result['access_token']);
    return bearerToken;
  }

  Future<dynamic> getAuthForm(
      {required http.Client client, required IdTokenResult? bearerToken}) async {
    dynamic form;
    dynamic formResult;

    final reqUrl = "${this.config.domainURL}${IDCSConfig.AUTHENTICATE_REST_EP}";
    final headers = <String, String>{
      "Content-Type": "application/json",
      "Authorization": "Bearer ${bearerToken?.token}",
    };
    try {
      form = await client.get(Uri.parse(reqUrl), headers: headers);
      AuthUtils.checkResponse(this.__logLevel, form);
      formResult = jsonDecode(form.body);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "GET request");
      AuthUtils.baasTrace(
          this.__logLevel, reqUrl, headers, null, e, stacktrace);

      String errMessage = "";

      try {
        errMessage = jsonDecode(form.body)["message"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['get the auth form']);
      }

      throw AuthUtils.authErrorHandler(
          status: form.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }

    return formResult;
  }

  Future<dynamic> authenticateAndGetDetails(
      {required String email, required String password}) async {
    final IdTokenResult authnToken = await authenticateUser(
        client: createClient(_app), email: email, password: password);

    final tokens =
        await getAccessToken(client: createClient(_app), authnToken: authnToken);

    final userDetails =
        await getUserDetails(accessToken: tokens["access_token"]);

    return {
      "userDetails": userDetails,
      "authnToken": authnToken,
      "accessToken": tokens["access_token"],
      "refreshToken": tokens["refresh_token"]
    };
  }

  Future<IdTokenResult> authenticateUser({
    required http.Client client,
    required String email,
    required String password,
  }) async {
    dynamic formResult;
    dynamic response;
    dynamic result;

    bearerToken = (bearerToken != null)
        ? bearerToken
        : await getBearerToken(createClient(_app));
    formResult =
        await getAuthForm(client: createClient(_app), bearerToken: bearerToken);

    final reqUrl = "${config.domainURL}${IDCSConfig.AUTHENTICATE_REST_EP}";
    final headers = <String, String>{
      "Content-Type": "application/json",
      "Authorization": "Bearer ${bearerToken?.token}",
    };
    final body = json.encode({
      "op": "credSubmit",
      "credentials": {
        "username": email,
        "password": password,
      },
      "requestState": formResult["requestState"],
    });
    try {
      response =
          await client.post(Uri.parse(reqUrl), headers: headers, body: body);
      AuthUtils.checkResponse(__logLevel, response);
      result = jsonDecode(response.body);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(__logLevel, "GET request");
      AuthUtils.baasTrace(__logLevel, reqUrl, headers, body, e, stacktrace);

      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["message"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['authenticate the user']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }
    return IdTokenResult(token: result["authnToken"]);
  }

  Future<dynamic> getAccessToken(
      {required http.Client client, required IdTokenResult authnToken}) async {
    dynamic response;
    dynamic result;

    final String reqURL =
        "${this.config.domainURL}${IDCSConfig.OAUTH_TOKEN_REST_EP}";
    final headers = <String, String>{
      "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
      "Authorization": "Basic $encodedSecret",
    };
    final body =
        "grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&scope=urn:opc:idm:__myscopes__+offline_access&assertion=${authnToken.token}";

    try {
      response =
          await client.post(Uri.parse(reqURL), headers: headers, body: body);
      AuthUtils.checkResponse(this.__logLevel, response);
      result = jsonDecode(response.body);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "POST request");
      AuthUtils.baasTrace(
          this.__logLevel, reqURL, headers, body, e, stacktrace);

      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["message"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['get the access token']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }
    var data = {
      "access_token": IdTokenResult(token: "${result['access_token']}"),
      "refresh_token": "${result['refresh_token']}",
    };
    return data;
  }

  Future<dynamic> reloadUser({required User user}) async {
    IdTokenResult accessToken = await user.getIdTokenResult(true);
    final res = await getUserDetails(accessToken: accessToken);
    return res;
  }

  Future<dynamic> getUserDetails({required IdTokenResult accessToken}) async {
    return fetchUserDetails(client: createClient(_app), accessToken: accessToken);
  }

  Future<dynamic> fetchUserDetails(
      {required http.Client client, required IdTokenResult accessToken}) async {
    dynamic response;
    dynamic result;
    dynamic tokenData = AuthUtils.parseJwt(accessToken.token);
    final reqURL = "${this.config.domainURL}${IDCSConfig.SELF_ME_REST_EP}";
    final headers = <String, String>{
      "Content-Type": "application/scim+json",
      "Authorization": "Bearer ${accessToken.token}",
    };
    try {
      response = await client.get(Uri.parse(reqURL), headers: headers);
      AuthUtils.checkResponse(this.__logLevel, response);
      result = jsonDecode(response.body);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "GET request");
      AuthUtils.baasTrace(
          this.__logLevel, reqURL, headers, null, e, stacktrace);

      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["message"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['get the user details']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }
    result["emailVerified"] = tokenData["email_verified"];
    result["idp_name"] = tokenData["idp_name"];
    result["idp_type"] = tokenData["idp_type"];
    result["meta"]["lastSignIn"] = convertIatToTimestamp(tokenData["iat"]);
    result["meta"]["created"] =
        convertOCITimeToTimestampString(result["meta"]["created"]);
    return result;
  }

  Future<void> performSignOut(String refreshToken) async {
    await signOutFromIDCS(
      createClient(_app),
    );
    await revokeRefreshToken(
        client: createClient(_app), refreshToken: refreshToken);
  }

  Future<void> signOutFromIDCS(http.Client client) async {
    dynamic response;

    final reqURL = "${config.domainURL}${IDCSConfig.LOGOUT_REST_EP}";
    final headers = <String, String>{
      "Content-Type": "application/scim+json",
    };
    try {
      response = await client.get(Uri.parse(reqURL), headers: headers);
      AuthUtils.checkResponse(this.__logLevel, response);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "GET request");
      AuthUtils.baasTrace(
          this.__logLevel, reqURL, headers, null, e, stacktrace);

      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["message"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['sign out the user']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }
  }

  Future<void> revokeRefreshToken(
      {required http.Client client, required String? refreshToken}) async {
    dynamic response;

    final String reqURL =
        "${this.config.domainURL}${IDCSConfig.REVOKE_REFRESH_TOKEN_REST_EP}";
    final headers = <String, String>{
      "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
      "Authorization": "Basic $encodedSecret",
      "Cache-Control": "no-cache, no-store, must-revalidate",
      "Accept": "*/*",
    };
    final body = "token=$refreshToken";
    try {
      response =
          await client.post(Uri.parse(reqURL), headers: headers, body: body);
      AuthUtils.checkResponse(this.__logLevel, response);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "POST request");
      AuthUtils.baasTrace(
          this.__logLevel, reqURL, headers, body, e, stacktrace);

      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["message"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['revoke the refresh token']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }
  }

  Future<dynamic> registerUser(
      {required http.Client client,
      required String email,
      required String password,
      required String url}) async {
    bearerToken = (bearerToken != null)
        ? bearerToken
        : await getBearerToken(createClient(_app));
    dynamic response;
    final reqURL = "${this.config.domainURL}${IDCSConfig.SELF_ME_REST_EP}";

    String data = json.encode({
      "email":email,
      "password":password,
      "first_name":"-",
      "last_name":"-"
    });
    final headers = <String, String>{
      "Content-Type": "application/scim+json",
      "Authorization": "Bearer ${bearerToken?.token}",
    };
    try {
      response = await client.post(Uri.parse(url), headers: headers, body: data);

      AuthUtils.checkResponse(this.__logLevel, response);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "POST request");
      AuthUtils.baasTrace(
          this.__logLevel, reqURL, headers, data, e, stacktrace);
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["message"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['register the user']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }
  }

  Future<dynamic> signInWithBrowserHelper(dynamic provider) async {
    if (provider.providerId != "idcs") {
      String errMessage = AuthErrorMessageTemplates.INVALID_PROVIDER_IDCS;
      throw AuthUtils.authErrorHandler(
          status: globals.ErrorMap[globals.ErrorCode.INVALID_ARGS] ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase());
    }
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

  Future<dynamic> sendPasswordResetEmailHelper(
      {required http.Client client, required String email}) async {
    bearerToken = (bearerToken != null)
        ? bearerToken
        : await getBearerToken(
            createClient(_app),
          );
    dynamic response;
    final reqURL =
        "${this.config.domainURL}${IDCSConfig.SEND_PASSWORD_RESET_EMAIL}";

    String copy_email = email;

    String email_domain = copy_email.split('@')[1];
    final headers = <String, String>{
      "Content-Type": "application/scim+json",
      "Authorization": "Bearer ${bearerToken?.token}",
      "Accept": "application/json"
    };
    final body = json.encode({
      "userName": email,
      "notificationType": "email",
      "notificationEmailAddress": '****@${email_domain}',
      "schemas": [
        "urn:ietf:params:scim:schemas:oracle:idcs:MePasswordResetRequestor"
      ]
    });
    try {
      response =
          await client.post(Uri.parse(reqURL), headers: headers, body: body);
      AuthUtils.checkResponse(this.__logLevel, response);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "POST request");
      AuthUtils.baasTrace(
          this.__logLevel, reqURL, headers, body, e, stacktrace);
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["message"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['send password reset email']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }

    return response;
  }

  Future<String> verifyPasswordResetCodeHelper(
      {required http.Client client, required String code}) async {
    bearerToken = (bearerToken != null)
        ? bearerToken
        : await getBearerToken(
            createClient(_app),
          );
    dynamic response;
    dynamic result;
    final reqURL =
        "${this.config.domainURL}${IDCSConfig.VERIFY_PASSWORD_RESET_CODE}";
    final headers = <String, String>{
      "Content-Type": "application/scim+json",
      "Authorization": "Bearer ${bearerToken?.token}",
    };
    final body = json.encode({
      "token": code,
      "schemas": ["urn:ietf:params:scim:schemas:oracle:idcs:UserTokenValidator"]
    });
    try {
      response =
          await client.post(Uri.parse(reqURL), headers: headers, body: body);
      AuthUtils.checkResponse(this.__logLevel, response);
      result = jsonDecode(response.body);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "POST request");
      AuthUtils.baasTrace(
          this.__logLevel, reqURL, headers, body, e, stacktrace);
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["message"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['verify the password reset code']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }

    return result["userName"];
  }

  Future<void> confirmPasswordResetHelper(
      {required http.Client client,
      required String code,
      required String newPassword}) async {
    bearerToken = (bearerToken != null)
        ? bearerToken
        : await getBearerToken(
            createClient(_app),
          );
    dynamic response;
    final reqURL =
        "${this.config.domainURL}${IDCSConfig.CONFIRM_PASSWORD_RESET}";
    final headers = <String, String>{
      "Content-Type": "application/scim+json",
      "Authorization": "Bearer ${bearerToken?.token}",
      "Accept": "application/json"
    };
    final body = json.encode({
      "token": code,
      "password": newPassword,
      "schemas": ["urn:ietf:params:scim:schemas:oracle:idcs:MePasswordResetter"]
    });
    try {
      response =
          await client.post(Uri.parse(reqURL), headers: headers, body: body);
      AuthUtils.checkResponse(this.__logLevel, response);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "POST request");
      AuthUtils.baasTrace(
          this.__logLevel, reqURL, headers, body, e, stacktrace);
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["message"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.PASSWORD_RESET_FAILED;
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }
  }

  Future <dynamic> signInWithCredentialHelper ({required http.Client client,
   dynamic credential}) async {
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

  Future<dynamic> signInWithRedirectHelper(dynamic provider, dynamic pkceResult) async {
    dynamic response;
    final String host = options?.ordsHost ?? "";
    final String appID = options?.appID.toLowerCase() ?? "";

    dynamic socialPlugin;

    if (kIsWeb) {
      socialPlugin = FusabaseWeb(
          host: "${host}_/baas-services/idm/idcs/${options?.projectID}/social",
          queryParameters: {"app_id": appID, "link":"0", "device": "web",
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

  Future<dynamic> getTokensAfterRedirect(
      {required http.Client client,
      required String code,
      required String verifier}) async {
    dynamic response;
    dynamic result;

    final reqURL =
        "${options?.ordsHost}_/baas-services/idm/idcs/${options?.projectID}/${IDCSConfig.REDIRECT_RESULT}?apiKey=${options?.appID}";

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

  Future<String> getCodeFromURL() async {
    dynamic response;
    dynamic socialPlugin;

    final String host = options?.ordsHost ?? "";
    final String appID = options?.appID.toLowerCase() ?? "";
    final String method = "";

    socialPlugin = FusabaseWeb(
          host: "${host}_/baas-services/idm/idcs/${options?.projectID}/social",
          queryParameters: {"app_id": appID, "link":"0", "device": "web",
          "apiKey": options?.appID ?? ""},
          callbackUrlScheme: 'baasmobile$appID');

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
          stackTrace: stacktrace);
    }

    return response;
  }

  dynamic getProvider (String id) {
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

  void removeCodeParamFromUrl() {
    dynamic response;
    dynamic socialPlugin;

    final String host = options?.ordsHost ?? "";
    final String appID = options?.appID.toLowerCase() ?? "";
    final String method = "";

    socialPlugin = FusabaseWeb(
          host: "${host}_/baas-services/idm/idcs/${options?.projectID}/social",
          queryParameters: {"app_id": appID, "link":"0", "device": "web",
          "apiKey": options?.appID ?? ""},
          callbackUrlScheme: 'baasmobile$appID');

    try {
      socialPlugin.removeCodeParamFromUrl();
    } catch (e, stacktrace) {
    }
  }

}

/// @nodoc
class ONPREMAuthHelper {
  final FusabaseOptions? options;

  dynamic config;
  FusabaseApp? _app;

  globals.LogLevel __logLevel;

  ONPREMAuthHelper(
      {required this.options,
      required this.config,
      required globals.LogLevel logLevel})
      : __logLevel = logLevel;

  void _setApp(FusabaseApp app) {
    _app = app;
  }

  Future<IdTokenResult?> getBearerToken() async {
    String errMessage = NOT_IMPLEMENTED_ERROR;
    throw AuthUtils.authErrorHandler(
        status: globals.ErrorMap[globals.ErrorCode.NOT_IMPLEMENT] ?? 999,
        message: errMessage,
        authType: config.authType.toUpperCase());
  }

  Future<dynamic> getAuthForm({required IdTokenResult? bearerToken}) async {
    String errMessage = NOT_IMPLEMENTED_ERROR;
    throw AuthUtils.authErrorHandler(
        status: globals.ErrorMap[globals.ErrorCode.NOT_IMPLEMENT] ?? 999,
        message: errMessage,
        authType: config.authType.toUpperCase());
  }

  Future<dynamic> authenticateAndGetDetails(
      {required String email, required String password}) async {
    final tok_res = await this.authenticateUser(
        client: createClient(_app), email: email, password: password);
    IdTokenResult accessToken = tok_res["access_token"];
    String refreshToken = tok_res["refresh_token"];
    final userDetails = await this.getUserDetails(accessToken: accessToken);

    return {
      "userDetails": userDetails,
      "authnToken": null,
      "accessToken": accessToken,
      "refreshToken": refreshToken
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
      response =
          await client.post(Uri.parse(reqURL), headers: headers, body: body);
      AuthUtils.checkResponse(this.__logLevel, response);
      result = jsonDecode(response.body);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "POST request");
      AuthUtils.baasTrace(
          this.__logLevel, reqURL, headers, body, e, stacktrace);
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['authenticate the user']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }
    return {
      "access_token": IdTokenResult(token: result["access_token"]),
      "refresh_token": result["refresh_token"]
    };
  }

  Future<dynamic> getAccessToken({required IdTokenResult authnToken}) async {
    String errMessage = NOT_IMPLEMENTED_ERROR;
    throw AuthUtils.authErrorHandler(
        status: globals.ErrorMap[globals.ErrorCode.NOT_IMPLEMENT] ?? 999,
        message: errMessage,
        authType: config.authType.toUpperCase());
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
        {"value": data["sub"]}
      ],
      "meta": {
        "created": data["creation_time"],
        "lastSignIn": convertIatToTimestamp(data["iat"])
      },
      "id": data["user_id"],
      "idcsCreatedBy": data["iss"],
      "schemas": null,
      'phoneNumbers': [
        {"value": data["user_phonenumber"]}
      ],
      'photos': [
        {"value": data["photo_url"]}
      ],
      'ocid': null,
      "idp_name": data["idp_name"],
      "idp_type": data["idp_type"],
      'emailVerified': data["email_verified"]
    };
    return result;
  }

  Future<void> performSignOut(String refreshToken) async {
    await revokeRefreshToken(
        client: createClient(_app), refreshToken: refreshToken);
  }

  Future<void> signOutFromIDCS() async {
    String errMessage = NOT_IMPLEMENTED_ERROR;
    throw AuthUtils.authErrorHandler(
        status: globals.ErrorMap[globals.ErrorCode.NOT_IMPLEMENT] ?? 999,
        message: errMessage,
        authType: config.authType.toUpperCase());
  }

  Future<void> revokeRefreshToken(
      {required http.Client client, required String? refreshToken}) async {
    dynamic response;
    final reqURL =
        "${this.config.domainURL}${ONPREMConfig.REVOKE_REFRESH_TOKEN}?apiKey=${options?.appID}";
    final headers = <String, String>{};
    dynamic body = json.encode({"token": refreshToken});
    try {
      response =
          await client.put(Uri.parse(reqURL), headers: headers, body: body);
      AuthUtils.checkResponse(this.__logLevel, response);
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "DELETE request");
      AuthUtils.baasTrace(
          this.__logLevel, reqURL, headers, null, e, stacktrace);
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['revoke the refresh token']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }
  }

  Future<dynamic> registerUser(
      {required http.Client client,
      required String email,
      required String password,
      required String url}) async {
    dynamic response;
    dynamic result;

    final reqURL =
        "${this.config.domainURL}${ONPREMConfig.SELF_REGISTER_EP}?apiKey=${options?.appID}";

    String data = json.encode({
      "first_name": "-",
      "last_name": "-",
      "email": email,
      "password": password
    });
    final headers = <String, String>{"Content-Type": "application/json"};
    try {
      response = await client.post(Uri.parse(reqURL), headers: headers, body: data);

      AuthUtils.checkResponse(this.__logLevel, response);
 
    } catch (e, stacktrace) {
      AuthUtils.baasLogger(this.__logLevel, "POST request");
      AuthUtils.baasTrace(
          this.__logLevel, reqURL, headers, data, e, stacktrace);
      String errMessage = "";

      try {
        errMessage = jsonDecode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['add the user']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
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
          host: "${host}_/baas-services/idm/onprem/${options?.projectID}/socialidp",
          queryParameters: {"method": provider.providerId,"link":"0", "app_id": appID, "device": "web",
          "apiKey": options?.appID ?? ""},
          callbackUrlScheme: 'baasmobile$appID');
    } else {
      socialPlugin = FusabaseDartPlugin(
          host: "${host}_/baas-services/idm/onprem/${options?.projectID}/socialidp",
          queryParameters: {
            "method": provider.providerId,
            "app_id": appID,
            "link":"0",
            "device": "mobile",
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

  Future<dynamic> signInWithRedirectHelper(dynamic provider, dynamic pkceResult) async {
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
    return response;
  }

  Future<dynamic> getTokensAfterRedirect(
      {required http.Client client,
      required String code,
      required String verifier}) async {
    dynamic response;
    dynamic result;

    final reqURL =
        "${this.config.domainURL}${ONPREMConfig.REDIRECT_RESULT}?apiKey=${options?.appID}";

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

  Future<String> getCodeFromURL() async {
    dynamic response;
    dynamic socialPlugin;

    final String host = options?.ordsHost ?? "";
    final String appID = options?.appID.toLowerCase() ?? "";
    final String method = "";

    socialPlugin = FusabaseWeb(
        host: "${host}_/baas-services/idm/onprem/${options?.projectID}/socialidp",
        queryParameters: {"method": method, "app_id": appID, "device": "web",
        "apiKey": options?.appID ?? ""},
        callbackUrlScheme: 'baasmobile$appID');

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
          stackTrace: stacktrace);
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
        host: "${host}_/baas-services/idm/onprem/${options?.projectID}/socialidp",
        queryParameters: {"method": method, "app_id": appID, "device": "web",
        "apiKey": options?.appID ?? ""},
        callbackUrlScheme: 'baasmobile$appID');

    try {
      socialPlugin.removeCodeParamFromUrl();
    } catch (e, stacktrace) {
    }
  }

  dynamic getProvider (String id) {
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

  Future<void> sendPasswordResetEmailHelper(
      {required http.Client client, required String email}) async {
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
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['send password reset email']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }

    return result;
  }

  Future<String> verifyPasswordResetCodeHelper(
      {required http.Client client, required String code}) async {
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
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['verify password reset code']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }
    if (result!=null && result["username"]!=null) {
      return result["username"];
    }

    return result;
  }

  Future<void> confirmPasswordResetHelper(
      {required http.Client client,
      required String code,
      required String newPassword}) async {
    dynamic response;
    dynamic result;

    final reqURL =
        "${this.config.domainURL}${ONPREMConfig.CONFIRM_PASSWORD_RESET}?apiKey=${options?.appID}&requestType=resetpwd";

    String data = json.encode({"password": newPassword, "code":code});
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
        errMessage = AuthErrorMessageTemplates.PASSWORD_RESET_FAILED;
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
    }
  }

  Future <dynamic> signInWithCredentialHelper ({required http.Client client,
   dynamic credential}) async {
    dynamic response;
    dynamic result;

    final reqURL =
        "${config.domainURL}${ONPREMConfig.SIGN_IN_WITH_CREDENTIAL}?apiKey=${options?.appID}&method=${credential.providerId}&link=0";

    String data = json.encode({"token": credential.idToken});
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
        errMessage = AuthErrorMessageTemplates.format(AuthErrorMessageTemplates.FAILED_REQUEST, ['sign in with credential']);
      }

      throw AuthUtils.authErrorHandler(
          status: response.statusCode ?? 999,
          message: errMessage,
          authType: config.authType.toUpperCase(),
          stackTrace: stacktrace);
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
