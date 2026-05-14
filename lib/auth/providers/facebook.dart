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

/// {@template facebook_auth_provider}
/// Provider for Facebook authentication.
///
/// This class provides credentials for Facebook sign-in.
/// {@endtemplate}
class FacebookAuthProvider extends AuthProvider {
  /// The sign-in method for Facebook.
  ///
  /// Returns the string "facebook".
  static var FACEBOOK_SIGN_IN_METHOD = "facebook";

  /// The provider ID for Facebook.
  ///
  /// Returns the string "facebook".
  static var PROVIDER_ID = "facebook";

  /// Constructs a [FacebookAuthProvider] with providerId 'facebook'.
  ///
  /// Returns a [FacebookAuthProvider] instance.
  ///
  /// Example:
  /// ```dart
  /// final provider = FacebookAuthProvider();
  /// ```
  FacebookAuthProvider()
      : super(providerId: FacebookAuthProvider.FACEBOOK_SIGN_IN_METHOD);

  /// Creates a [FacebookAuthCredential].
  ///
  /// [idToken] Optional ID token.
  /// [accessToken] Optional access token.
  ///
  /// At least one token must be provided.
  ///
  /// Returns a [FacebookAuthCredential] instance.
  ///
  /// Throws AssertionError if both tokens are null.
  ///
  /// Example:
  /// ```dart
  /// final cred = FacebookAuthProvider.credential(accessToken: 'fb_access_token');
  /// ```
  static FacebookAuthCredential credential({String? idToken, String? accessToken}) {
    assert(accessToken != null || idToken != null, 'Tokens cannot be null!');
    return FacebookAuthCredential(
        idToken: idToken,
        accessToken: accessToken);
  }
}
