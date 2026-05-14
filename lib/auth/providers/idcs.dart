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

/// {@template idcs_auth_provider}
/// Provider for IDCS (Oracle Identity Cloud Service) authentication.
///
/// This class provides credentials for IDCS sign-in.
/// {@endtemplate}
class IDCSAuthProvider extends AuthProvider {
  /// The sign-in method for IDCS.
  ///
  /// Returns the string "idcs".
  static var IDCS_SIGN_IN_METHOD = "idcs";

  /// The provider ID for IDCS.
  ///
  /// Returns the string "idcs".
  static var PROVIDER_ID = "idcs";

  /// Constructs an [IDCSAuthProvider] with providerId 'idcs'.
  ///
  /// Returns an [IDCSAuthProvider] instance.
  ///
  /// Example:
  /// ```dart
  /// final provider = IDCSAuthProvider();
  /// ```
  IDCSAuthProvider()
      : super(providerId: IDCSAuthProvider.IDCS_SIGN_IN_METHOD);

  /// Creates an [IDCSAuthCredential].
  ///
  /// [idToken] Optional ID token.
  /// [accessToken] Optional access token.
  ///
  /// At least one token must be provided.
  ///
  /// Returns an [IDCSAuthCredential] instance.
  ///
  /// Throws AssertionError if both tokens are null.
  ///
  /// Example:
  /// ```dart
  /// final cred = IDCSAuthProvider.credential(accessToken: 'idcs_access_token');
  /// ```
  static IDCSAuthCredential credential({String? idToken, String? accessToken}) {
    assert(accessToken != null || idToken != null, 'Tokens cannot be null!');
    return IDCSAuthCredential(
        idToken: idToken,
        accessToken: accessToken);
  }
}
