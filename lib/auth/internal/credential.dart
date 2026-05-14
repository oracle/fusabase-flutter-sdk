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

/// {@template email_auth_credential}
/// Credential for email authentication.
///
/// Represents the credentials used for email and password authentication.
/// {@endtemplate}
class EmailAuthCredential extends AuthCredential {
  /// The user's email.
  final String email;

  /// The email link (optional).
  final String? emailLink;

  /// The user's password (optional).
  final String? password;

  /// Constructs an [EmailAuthCredential].
  ///
  /// [providerId] The provider ID.
  /// [email] The email address.
  /// [signInMethod] The sign-in method.
  /// [accessToken] Optional access token.
  ///
  /// Returns an [EmailAuthCredential] instance.
  ///
  /// Example:
  /// ```dart
  /// final credential = EmailAuthCredential(
  ///   providerId: 'email',
  ///   email: 'user@example.com',
  ///   signInMethod: 'password',
  /// );
  /// ```
  EmailAuthCredential(
      {required super.providerId,
      required this.email,
      this.password,
      required super.signInMethod, super.accessToken})
      : emailLink = null;

  @override
  /// Converts the credential to a map.
  ///
  /// Returns a [Map<String, String?>] representation of the credential.
  Map<String, String?> asMap() {
    return <String, String?>{
      'providerId': providerId,
      'signInMethod': signInMethod,
      'email': email,
      'emailLink': emailLink,
      'secret': password,
    };
  }
}

/// {@template auth_credential}
/// Represents the authentication credentials of the user.
///
/// This is the base class for all authentication credentials.
/// {@endtemplate}
class AuthCredential {
  /// The provider ID.
  final String providerId;

  /// The access token (optional).
  final String? accessToken;

  /// The sign-in method.
  final String signInMethod;

  /// The token (optional).
  final int? token;

  /// Constructs an [AuthCredential].
  ///
  /// [providerId] The provider ID.
  /// [signInMethod] The sign-in method.
  /// [token] Optional token.
  /// [accessToken] Optional access token.
  ///
  /// Returns an [AuthCredential] instance.
  ///
  /// Example:
  /// ```dart
  /// final credential = AuthCredential(
  ///   providerId: 'custom',
  ///   signInMethod: 'custom',
  /// );
  /// ```
  AuthCredential({required this.providerId, required this.signInMethod, this.token,
  this.accessToken});

  /// Converts the credential to a map.
  ///
  /// Returns a [Map<String, dynamic>] representation of the credential.
  Map<String, dynamic> asMap() {
    return <String, dynamic>{
      'providerId': providerId,
      'token': token,
      'accessToken': accessToken,
      'signInMethod': signInMethod
    };
  }

  @override
  /// Returns a string representation of the credential.
  String toString() =>
      'AuthCredential(providerId: $providerId, signInMethod: $signInMethod)';
}

/// {@template oauth_credential}
/// Represents the OAuth credentials for the user.
///
/// This extends [AuthCredential] for OAuth-specific fields.
/// {@endtemplate}
class OAuthCredential extends AuthCredential {
  /// The access token (optional).
  final String? accessToken;

  /// The ID token (optional).
  final String? idToken;

  /// The raw nonce (optional).
  final String? rawNonce;

  /// Constructs an [OAuthCredential].
  ///
  /// [providerId] The provider ID.
  /// [signInMethod] The sign-in method.
  /// [accessToken] Optional access token.
  /// [idToken] Optional ID token.
  ///
  /// Returns an [OAuthCredential] instance.
  ///
  /// Example:
  /// ```dart
  /// final credential = OAuthCredential(
  ///   providerId: 'oauth',
  ///   signInMethod: 'oauth',
  ///   accessToken: 'access_token',
  /// );
  /// ```
  OAuthCredential(
      {required super.providerId,
      required super.signInMethod,
      String? accessToken,
      String? idToken})
      : accessToken = accessToken,
        rawNonce = null,
        idToken = idToken;

  @override
  /// Converts the credential to a map.
  ///
  /// Returns a [Map<String, String?>] representation of the credential.
  Map<String, String?> asMap() {
    return <String, String?>{
      'providerId': providerId,
      'signInMethod': signInMethod,
      'idToken': idToken,
      "rawNonce": rawNonce,
      'accessToken': accessToken
    };
  }
}

/// {@template facebook_auth_credential}
/// Credential for Facebook authentication.
///
/// Extends [OAuthCredential].
/// {@endtemplate}
class FacebookAuthCredential extends OAuthCredential {
  /// Constructs a [FacebookAuthCredential].
  ///
  /// [accessToken] Optional access token.
  /// [idToken] Optional ID token.
  ///
  /// Returns a [FacebookAuthCredential] instance.
  ///
  /// Example:
  /// ```dart
  /// final credential = FacebookAuthCredential(accessToken: 'fb_token');
  /// ```
  FacebookAuthCredential(
      { String? accessToken,
      String? idToken}) : super(providerId: FacebookAuthProvider.PROVIDER_ID,
      signInMethod: FacebookAuthProvider.FACEBOOK_SIGN_IN_METHOD, accessToken: accessToken,
      idToken: idToken); 
}

/// {@template google_auth_credential}
/// Credential for Google authentication.
///
/// Extends [OAuthCredential].
/// {@endtemplate}
class GoogleAuthCredential extends OAuthCredential {
  /// Constructs a [GoogleAuthCredential].
  ///
  /// [accessToken] Optional access token.
  /// [idToken] Optional ID token.
  ///
  /// Returns a [GoogleAuthCredential] instance.
  ///
  /// Example:
  /// ```dart
  /// final credential = GoogleAuthCredential(accessToken: 'google_token');
  /// ```
  GoogleAuthCredential(
      { String? accessToken,
      String? idToken}) : super(providerId: GoogleAuthProvider.PROVIDER_ID,
      signInMethod: GoogleAuthProvider.GOOGLE_SIGN_IN_METHOD, accessToken: accessToken,
      idToken: idToken); 
}

/// {@template github_auth_credential}
/// Credential for GitHub authentication.
///
/// Extends [OAuthCredential].
/// {@endtemplate}
class GithubAuthCredential extends OAuthCredential {
  /// Constructs a [GithubAuthCredential].
  ///
  /// [accessToken] Optional access token.
  /// [idToken] Optional ID token.
  ///
  /// Returns a [GithubAuthCredential] instance.
  ///
  /// Example:
  /// ```dart
  /// final credential = GithubAuthCredential(accessToken: 'github_token');
  /// ```
  GithubAuthCredential(
      { String? accessToken,
      String? idToken}) : super(providerId: GithubAuthProvider.PROVIDER_ID,
      signInMethod: GithubAuthProvider.GITHUB_SIGN_IN_METHOD, accessToken: accessToken,
      idToken: idToken); 
}

/// {@template idcs_auth_credential}
/// Credential for IDCS authentication.
///
/// Extends [OAuthCredential].
///
/// See: Relevant IDCS documentation.
/// {@endtemplate}
class IDCSAuthCredential extends OAuthCredential {
  /// Constructs an [IDCSAuthCredential].
  ///
  /// [accessToken] Optional access token.
  /// [idToken] Optional ID token.
  ///
  /// Returns an [IDCSAuthCredential] instance.
  ///
  /// Example:
  /// ```dart
  /// final credential = IDCSAuthCredential(accessToken: 'idcs_token');
  /// ```
  IDCSAuthCredential(
      { String? accessToken,
      String? idToken}) : super(providerId: IDCSAuthProvider.PROVIDER_ID,
      signInMethod: IDCSAuthProvider.IDCS_SIGN_IN_METHOD, accessToken: accessToken,
      idToken: idToken); 
}
