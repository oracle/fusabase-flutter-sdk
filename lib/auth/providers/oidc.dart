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

/// {@template oauth_provider}
/// Provider for OAuth (OIDC) authentication.
///
/// This class allows configuring custom OAuth providers with scopes and parameters.
/// {@endtemplate}
class OAuthProvider extends AuthProvider {
  /// Custom parameters for the provider.
  Map<String, String> _parameters;

  /// Scopes for the provider.
  List<String> _scopes;

  /// Constructs an [OAuthProvider].
  ///
  /// [providerId] The provider ID, which will be prefixed with "oidc_".
  ///
  /// Initializes empty parameters and scopes.
  ///
  /// Returns an [OAuthProvider] instance.
  ///
  /// Example:
  /// ```dart
  /// final provider = OAuthProvider('custom_oidc');
  /// ```
  OAuthProvider(String providerId) : _scopes = [],
                                     _parameters = {}, 
                                     super(providerId: "oidc_$providerId");

  /// Gets the custom parameters.
  ///
  /// Returns the map of custom parameters.
  Map<String, String> get parameters {
    return _parameters;
  }

  /// Gets the scopes.
  ///
  /// Returns the list of scopes.
  List<String> get scopes {
    return _scopes;
  }

  /// Adds a scope to the provider.
  ///
  /// [scope] The scope to add.
  ///
  /// Returns this [OAuthProvider] for chaining.
  ///
  /// Example:
  /// ```dart
  /// provider.addScope('email');
  /// ```
  OAuthProvider addScope(String scope) {
    _scopes.add(scope);
    return this;
  }

  /// Sets custom parameters for the provider.
  ///
  /// [customParameters] The map of custom parameters to set.
  ///
  /// Returns this [OAuthProvider] for chaining.
  ///
  /// Example:
  /// ```dart
  /// provider.setCustomParameters({'key': 'value'});
  /// ```
  OAuthProvider setCustomParameters( Map<String, String> customParameters ) {
    _parameters = customParameters;
    return this;
  }

  /// Sets the scopes for the provider.
  ///
  /// [scopes] The list of scopes to set.
  ///
  /// Returns this [OAuthProvider] for chaining.
  ///
  /// Example:
  /// ```dart
  /// provider.setScopes(['email', 'profile']);
  /// ```
  OAuthProvider setScopes(List<String> scopes) {
    _scopes = scopes;
    return this;
  }

  /// Creates an [OAuthCredential].
  ///
  /// [accessToken] Optional access token.
  /// [secret] Optional secret.
  /// [idToken] Optional ID token.
  /// [rawNonce] Optional raw nonce.
  /// [signInMethod] Optional sign-in method (defaults to "oauth_").
  ///
  /// Returns an [OAuthCredential] instance.
  ///
  /// Example:
  /// ```dart
  /// final cred = provider.credential(accessToken: 'token');
  /// ```
  OAuthCredential credential({String? accessToken, String? secret, 
    String? idToken, String? rawNonce, String? signInMethod }) {
    return OAuthCredential(
      providerId: providerId,
      signInMethod: signInMethod ?? "oauth_",
      accessToken: accessToken,
      idToken: idToken
    );
  }
}
