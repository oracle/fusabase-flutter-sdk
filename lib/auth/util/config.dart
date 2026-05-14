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

part of "../../auth.dart";


class Config {
  String authType;

  String projectID;

  Config({required this.authType, required this.projectID});
}

class ONPREMConfig extends Config {

  String authID;

  String domainURL;

  static String AUTHENTICATE_REST_EP = "authenticate";

  static String SELF_REGISTER_EP = "useradd";

  static String UPDATE_PASSWORD_HELPER = "changePassword";

  static String UPDATE_PROFILE_HELPER = "updateProfile";

  static String REVOKE_REFRESH_TOKEN = "rf/revoke";

  static String SEND_EMAIL_VERIFICATION = "sendemail";

  static String SEND_PASSWORD_RESET_EMAIL = "sendemail";

  static String CONFIRM_PASSWORD_RESET = "resetpwd";

  static String VERIFY_PASSWORD_RESET_CODE = "verifycode";

  static String SIGN_IN_WITH_CREDENTIAL = "getcredential";

  static String REDIRECT_RESULT = "redirectResult";


  ONPREMConfig(
      {required String domainURL,
      required String authID,
      required String projectID,
      required String authType})
      : this.domainURL = domainURL,
        this.authID = authID,
        super(authType: authType, projectID: projectID);
}


// class ONPREMSRPConfig extends ONPREMConfig {
//   static String GET_SHARED_KEY = "srp/getsharedkey";

//   static String SRP_AUTHENTICATE_USER = "srp/authenticate";

//   static String SRP_ADD_USER = "srp/useradd";

//   ONPREMSRPConfig(
//       {required super.domainURL,
//       required super.authID,
//       required super.authType,
//       required super.projectID});
// }

/// @nodoc
class IDCSConfig extends Config {
  String domainURL;

  String clientID;

  String clientSecret;

  String? selfRegistrationProfile;

  static String AUTHENTICATE_REST_EP = "/sso/v1/sdk/authenticate";

  static String OAUTH_TOKEN_REST_EP = "/oauth2/v1/token";

  static String SELF_ME_REST_EP = "/admin/v1/Me";

  static String FETCH_FUSABASE_TOKEN = "tokenExchange";

  static String LOGOUT_REST_EP = "/oauth2/v1/userlogout";

  static String REVOKE_REFRESH_TOKEN_REST_EP = "/oauth2/v1/revoke";

  static String SEND_PASSWORD_RESET_EMAIL =
      "/admin/v1/MePasswordResetRequestor";

  static String CONFIRM_PASSWORD_RESET = "/admin/v1/MePasswordResetter";

  static String VERIFY_PASSWORD_RESET_CODE = "/admin/v1/UserTokenValidator";

  static String UPDATE_PASSWORD_HELPER = "/admin/v1/MePasswordChanger";

  static String SEND_EMAIL_VERIFICATION = '/admin/v1/MeEmailVerifier';

  static String REDIRECT_RESULT = 'redirectResult';

  static String ADD_USER_REST_EP = "useradd";

  IDCSConfig(
      {required this.domainURL,
      required String projectID,
      required this.clientID,
      required this.clientSecret,
      this.selfRegistrationProfile})
      : super(authType: "idcs", projectID: projectID) {
    if (domainURL.isEmpty) {
      throw AuthUtils.authErrorHandler(
          status: globals.ErrorMap[globals.ErrorCode.INVALID_ARGS] ?? 999,
          message: "Domain URL is not provided.",
          authType: "IDCS");
    }
    if (clientID.isEmpty) {
      throw AuthUtils.authErrorHandler(
          status: globals.ErrorMap[globals.ErrorCode.INVALID_ARGS] ?? 999,
          message: "Client ID is not provided.",
          authType: "IDCS");
    }
    if (clientSecret.isEmpty) {
      throw AuthUtils.authErrorHandler(
          status: globals.ErrorMap[globals.ErrorCode.INVALID_ARGS] ?? 999,
          message: "Client Secret is not provided.",
          authType: "IDCS");
    }
  }
}
