// Copyright (c) 2015, 2026, Oracle and/or its affiliates.

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
// 


part of '../../app_trust.dart';

/// Available Android attestation-provider selections.
///
/// These values are accepted by [FusabaseAppTrust.activate]. Native activation
/// is currently not performed by this package.
enum AndroidProvider { playIntegrity, debug, safetyNet }

/// Available Apple attestation-provider selections.
///
/// These values are accepted by [FusabaseAppTrust.activate]. Native activation
/// is currently not performed by this package.
enum AppleProvider { appAttest, deviceCheck }

/// Contract implemented by web attestation providers.
abstract class WebProvider {
  /// Obtains an attestation token for an action.
  ///
  /// Parameters:
  /// - [action] ([String]): Provider action, such as `attest`.
  ///
  /// Returns: a [Future<String>] containing the provider token.
  Future<String> getAttestationToken(String action);
}
