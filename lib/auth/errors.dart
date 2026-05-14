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

part of "../auth.dart";

// Errors and exceptions for auth

/// {@template auth_error_message_templates}
/// Templates for authentication error messages.
///
/// This class provides string templates for common authentication errors
///
/// {@endtemplate}
/// @nodoc
class AuthErrorMessageTemplates {
  /// Error message for invalid null values.
  static const INVALID_NULL = 'Invalid %s: value cannot be null or undefined';

  /// Error message for invalid type parameters.
  static const INVALID_TYPE_PARAM = 'Invalid %s: expected one of %s but got %s';

  /// Error message for invalid parameters.
  static const INVALID_PARAM = 'Invalid %s';

  /// Message prompting reauthentication.
  static const PLEASE_REAUTHENTICATE = 'Please reauthenticate!';

  /// Message for unimplemented methods.
  static const METHOD_NOT_IMPLEMENTED = 'Method not implemented!';

  /// Message indicating user needs to reauthenticate.
  static const USER_REAUTHENTICATE = 'User needs to reauthenticate!';

  /// Error for empty token.
  static const EMPTY_TOKEN = 'Empty token provided';

  /// Error for invalid tokens.
  static const INVALID_TOKENS = 'Invalid tokens!';

  /// Error for invalid provider.
  static const INVALID_PROVIDER = 'Invalid provider specified';

  /// Error for invalid credential.
  static const INVALID_CREDENTIAL = 'Invalid credential';

  /// Error for unknown provider ID after redirect.
  static const UNKNOWN_PROVIDER_ID = 'Unknown providerId encountered after redirect';

  /// Error for invalid user instance.
  static const INVALID_USER_INSTANCE = 'Invalid user instance passed';

  /// Error for failed request.
  static const REQUEST_FAILED = 'Request failed';

  /// Error for invalid persistence.
  static const INVALID_PERSISTENCE = 'Invalid persistence passed';

  /// Error for invalid provider ID in SAML.
  static const INVALID_PROVIDER_ID_SAML = 'Invalid providerId provided to SAMLAuthProvider';

  /// Error for invalid credentials in credential().
  static const INVALID_CREDENTIALS = 'Invalid credentials provided to credential()';

  /// Error for no token provided.
  static const NO_TOKEN = 'No Token provided';

  /// Simple error for invalid credentials.
  static const INVALID_CREDENTIALS_SIMPLE = 'Invalid credentials';

  /// Error for method not supported in IDCS.
  static const METHOD_NOT_SUPPORTED_IDCS = 'Method is not supported in IDCS authentication';

  /// Error for method not supported in onprem.
  static const METHOD_NOT_SUPPORTED_ONPREM = 'This method is not supported in onprem';

  /// Error for method not supported in base or ldap.
  static const METHOD_NOT_SUPPORTED_BASE_LDAP = 'Method is not supported in base or ldap authentication';

  /// Error for null token.
  static const NULL_TOKEN = 'Null token!';

  /// Error for failed password reset.
  static const PASSWORD_RESET_FAILED = 'Password reset failed';

  /// Error for unsupported auth type.
  static const UNSUPPORTED_AUTHTYPE = 'Unsupported authType: %s';

  /// Error for domain URL not provided.
  static const DOMAIN_URL_NOT_PROVIDED = 'Domain URL is not provided';

  /// Error for client ID not provided.
  static const CLIENT_ID_NOT_PROVIDED = 'Client ID is not provided';

  /// Error for client secret not provided.
  static const CLIENT_SECRET_NOT_PROVIDED = 'Client Secret is not provided';

  /// Error for no operation to perform.
  static const NO_OPERATION = 'No operation to perform';

  /// Error for failed password update.
  static const PASSWORD_UPDATE_FAILED = 'Password update failed';

  /// Error for invalid auth instance.
  static const INVALID_AUTH_INSTANCE = 'Invalid authentication instance';

  /// Error for invalid app instance.
  static const INVALID_APP_INSTANCE = 'Invalid app instance';

  /// Error for invalid user.
  static const INVALID_USER = 'Invalid user instance';

  /// Error for failed request with placeholder.
  static const FAILED_REQUEST = 'Failed to %s';

  /// Error for invalid JWT token.
  static const INVALID_JWT_TOKEN = 'Provided JWT token is invalid.';

  /// Error for invalid body.
  static const INVALID_BODY = 'Invalid body!';

  /// Error for illegal base64url string.
  static const ILLEGAL_BASE64URL = 'Illegal base64url string!';

  /// Error for invalid response with placeholder.
  static const INVALID_RESPONSE = 'Invalid Response! -> %s';

  /// Error for invalid provider in IDCS.
  static const INVALID_PROVIDER_IDCS = 'Invalid provider for IDCS';

  /// Error for set persistence only available in web.
  static const PERSISTENCE_WEB_ONLY = 'Set persistence is only available in web';

  /// Formats an error message template with arguments.
  ///
  /// [template] The message template with %s placeholders.
  /// [args] Optional list of arguments to replace placeholders.
  ///
  /// Replaces each %s in the template with the corresponding arg.
  ///
  /// Returns the formatted string.
  ///
  /// Example:
  /// ```dart
  /// final msg = AuthErrorMessageTemplates.format('Invalid %s', ['email']);
  /// ```
  static String format(String template, [List<dynamic> args = const []]) {
    var result = template;
    for (final arg in args) {
      result = result.replaceFirst('%s', arg.toString());
    }
    return result;
  }
}

/// {@template fusabase_auth_exception}
/// Exception class for authentication errors.
///
/// Extends [FusabaseException] with additional auth-specific fields
///
/// {@endtemplate}
class FusabaseAuthException extends FusabaseException {
  /// The authentication type.
  String? authType;

  /// The tenant ID.
  final dynamic tenantId;

  /// Constructs an [FusabaseAuthException].
  ///
  /// [message] Optional error message.
  /// [code] Required error code.
  /// [name] Optional error name.
  /// [authType] Optional authentication type.
  /// [stackTrace] Optional stack trace.
  ///
  /// Sets tenantId to null.
  ///
  /// Returns an [FusabaseAuthException] instance.
  ///
  /// Example:
  /// ```dart
  /// throw FusabaseAuthException(code: 'auth/invalid-user', message: 'Invalid user');
  /// ```
  FusabaseAuthException(
      {String? message,
      required String code,
      String? name,
      this.authType,
      StackTrace? stackTrace})
      : tenantId = null,
        super(message: message, code: code, name: name, stackTrace: stackTrace);
}
