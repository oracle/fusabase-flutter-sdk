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

/// {@template id_token_result}
/// Result of parsing an ID token.
///
/// This class holds the token and its parsed claims.
/// {@endtemplate}
class IdTokenResult {
  /// The raw token string.
  final String _token;

  /// The parsed JWT claims.
  final Map<String, dynamic> _parsedJwt;

  /// Gets the claims from the token.
  Map<String, dynamic>? get claims => _parsedJwt;

  /// Gets the sign-in provider (hardcoded to "password").
  String? get signInProvider => "password";

  /// Gets the raw token.
  String get token => _token;

  /// Gets the issued at time.
  DateTime? get issuedAtTime => parseIntToDateTime(_parsedJwt['iat']);

  /// Gets the expiration time.
  DateTime? get expirationTime => parseIntToDateTime(_parsedJwt['exp']);

  /// Gets the auth time (uses iat).
  DateTime? get authTime => parseIntToDateTime(_parsedJwt['iat']);

  /// Constructs an [IdTokenResult].
  ///
  /// [token] The ID token string.
  ///
  /// Parses the JWT and validates it's not empty.
  ///
  /// Throws [AuthUtils.authErrorHandler] if token is empty.
  ///
  /// Example:
  /// ```dart
  /// final result = IdTokenResult(token: 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...');
  /// ```
  IdTokenResult({
    required String token,
  })  : _parsedJwt = AuthUtils.parseJwt(token),
        _token = token {
    if (token.isEmpty) {
      throw AuthUtils.authErrorHandler(
          status: globals.ErrorMap[globals.ErrorCode.INVALID_ARGS] ?? 999,
          message: AuthErrorMessageTemplates.EMPTY_TOKEN);
    }
  }

  @override
  /// Returns a non-sensitive summary of the token result.
  ///
  /// The raw token and claims are intentionally excluded to prevent accidental
  /// disclosure through diagnostics or application logs.
  String toString() {
    return '$IdTokenResult(authTime: $authTime, '
        'expirationTime: $expirationTime, issuedAtTime: $issuedAtTime, '
        'signInProvider: $signInProvider)';
  }
}
