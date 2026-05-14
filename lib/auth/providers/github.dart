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

/// {@template github_auth_provider}
/// Provider for GitHub authentication.
///
/// This class provides credentials for GitHub sign-in.
/// {@endtemplate}
class GithubAuthProvider extends AuthProvider {
  /// The sign-in method for GitHub.
  ///
  /// Returns the string "github".
  static var GITHUB_SIGN_IN_METHOD = "github";

  /// The provider ID for GitHub.
  ///
  /// Returns the string "github".
  static var PROVIDER_ID = "github";

  /// Constructs a [GithubAuthProvider] with providerId 'github'.
  ///
  /// Returns a [GithubAuthProvider] instance.
  ///
  /// Example:
  /// ```dart
  /// final provider = GithubAuthProvider();
  /// ```
  GithubAuthProvider()
      : super(providerId: GithubAuthProvider.GITHUB_SIGN_IN_METHOD);

  /// Creates a [GithubAuthCredential].
  ///
  /// [idToken] Optional ID token.
  /// [accessToken] Optional access token.
  ///
  /// At least one token must be provided.
  ///
  /// Returns a [GithubAuthCredential] instance.
  ///
  /// Throws AssertionError if both tokens are null.
  ///
  /// Example:
  /// ```dart
  /// final cred = GithubAuthProvider.credential(accessToken: 'github_access_token');
  /// ```
  static GithubAuthCredential credential({String? idToken, String? accessToken}) {
    assert(accessToken != null || idToken != null, 'Tokens cannot be null!');
    return GithubAuthCredential(
        idToken: idToken,
        accessToken: accessToken);
  }
}
