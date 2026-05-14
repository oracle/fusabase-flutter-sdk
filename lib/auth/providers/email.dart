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

/// {@template email_auth_provider}
/// Provider for email/password authentication.
///
/// This class provides credentials for email-based sign-in methods.
/// {@endtemplate}
class EmailAuthProvider extends AuthProvider {
  /// Constructs an [EmailAuthProvider] with providerId 'password'.
  ///
  /// Returns an [EmailAuthProvider] instance.
  ///
  /// Example:
  /// ```dart
  /// final provider = EmailAuthProvider();
  /// ```
  EmailAuthProvider() : super(providerId: 'password');

  /// The provider ID for email authentication.
  ///
  /// Returns the string 'password'.
  static String get PROVIDER_ID {
    return 'password';
  }

  /// The sign-in method for email link.
  ///
  /// Returns the string "email/link".
  static String get EMAIL_LINK_SIGN_IN_METHOD {
    return "email/link";
  }

  /// The sign-in method for email/password.
  ///
  /// Returns the string "email/password".
  static String get EMAIL_PASSWORD_SIGN_IN_METHOD {
    return "password";
  }

  /// Creates an [AuthCredential] for email/password sign-in.
  ///
  /// [email] The user's email (required).
  /// [password] Optional password.
  ///
  /// Returns an [EmailAuthCredential] for signing in with email and password.
  ///
  /// Example:
  /// ```dart
  /// final cred = EmailAuthProvider.credential(email: 'user@example.com', password: 'pass123');
  /// ```
  static AuthCredential credential({
    required String email,
    String? password,
  }) {
    return EmailAuthCredential(
        providerId: EmailAuthProvider.PROVIDER_ID,
        email: email,
        password: password,
        signInMethod: EmailAuthProvider.EMAIL_PASSWORD_SIGN_IN_METHOD);
  }

  /// Creates an [AuthCredential] for email link sign-in.
  ///
  /// [email] The user's email (required).
  /// [emailLink] The email link (required).
  ///
  /// Returns an [EmailAuthCredential] for signing in with email link.
  ///
  /// Example:
  /// ```dart
  /// final cred = EmailAuthProvider.credentialWithLink(email: 'user@example.com', emailLink: 'link');
  /// ```
  static AuthCredential credentialWithLink({
    required String email,
    required String emailLink,
  }) {
    return EmailAuthCredential(
        providerId: EmailAuthProvider.PROVIDER_ID,
        email: email,
        password: null,
        signInMethod: EmailAuthProvider.EMAIL_LINK_SIGN_IN_METHOD);
  }
}
