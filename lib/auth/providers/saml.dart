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

/// {@template saml_auth_provider}
/// Provider for SAML authentication.
///
/// This class provides credentials for SAML-based sign-in.
/// {@endtemplate}
class SAMLAuthProvider extends AuthProvider {

  /// Constructs a [SAMLAuthProvider].
  ///
  /// [providerId] The provider ID, which will be prefixed with "saml_" (required).
  ///
  /// Returns a [SAMLAuthProvider] instance.
  ///
  /// Example:
  /// ```dart
  /// final provider = SAMLAuthProvider('saml_provider');
  /// ```
  SAMLAuthProvider(String providerId) : super(providerId: "saml_$providerId");

  /// Creates an [OAuthCredential] for SAML.
  ///
  /// [idToken] Optional ID token.
  /// [accessToken] Optional access token.
  ///
  /// At least one token must be provided.
  ///
  /// Returns an [OAuthCredential] instance.
  ///
  /// Throws AssertionError if both tokens are null.
  ///
  /// Example:
  /// ```dart
  /// final cred = provider.credential(accessToken: 'saml_access_token');
  /// ```
  OAuthCredential credential({String? idToken, String? accessToken}) {
    assert(accessToken != null || idToken != null, 'Tokens cannot be null!');
    return OAuthCredential(providerId: providerId,
      signInMethod: providerId, accessToken: accessToken,
      idToken: idToken);
  }

}
