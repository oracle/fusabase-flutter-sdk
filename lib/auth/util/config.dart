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

  static String UPDATE_PROFILE_HELPER = "profile";

  static String REVOKE_REFRESH_TOKEN = "rf/revoke";

  static String SEND_EMAIL_VERIFICATION = "sendemail";

  static String SEND_PASSWORD_RESET_EMAIL = "sendemail";

  static String CONFIRM_PASSWORD_RESET = "resetpwd";

  static String VERIFY_PASSWORD_RESET_CODE = "verifycode";

  static String SIGN_IN_WITH_CREDENTIAL = "getcredential";

  static String REDIRECT_RESULT = "redirectResult";

  ONPREMConfig({
    required String domainURL,
    required String authID,
    required String projectID,
    required String authType,
  }) : this.domainURL = domainURL,
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
class IDCSConfig extends ONPREMConfig {
  String idcsDomainURL;

  static String LOGOUT_REST_EP = "/oauth2/v1/userlogout";

  IDCSConfig({
    required String domainURL,
    required String authID,
    required String projectID,
    required String authType,
    required String idcsDomainURL,
  }) : idcsDomainURL = idcsDomainURL.replaceAll(RegExp(r'/+$'), ''),
       super(
         domainURL: domainURL,
         authID: authID,
         projectID: projectID,
         authType: authType,
       ) {
    if (this.idcsDomainURL.isEmpty) {
      throw AuthUtils.authErrorHandler(
        status: globals.ErrorMap[globals.ErrorCode.INVALID_ARGS] ?? 999,
        message: "IDCS domain URL is not provided.",
        authType: "IDCS",
      );
    }
  }
}
