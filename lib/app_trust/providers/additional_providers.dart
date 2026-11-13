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

/// Web attestation provider backed by reCAPTCHA Enterprise.
class ReCaptchaEnterpriseProvider implements WebProvider {
  /// The reCAPTCHA Enterprise site key.
  final String siteKey;

  /// Creates a reCAPTCHA Enterprise provider.
  ///
  /// Parameters:
  /// - [siteKey] ([String]): Public site key issued for the web application.
  ///
  /// Returns: a [ReCaptchaEnterpriseProvider].
  ReCaptchaEnterpriseProvider(this.siteKey);

  @override
  /// Obtains a token for [action].
  ///
  /// Parameters: [action] ([String]), the provider action.
  /// Returns: a [Future<String>] containing the token.
  Future<String> getAttestationToken(String action) {
    return attestation.getReCaptchaEnterpriseToken(siteKey, action);
  }
}

/// Web attestation provider backed by Cloudflare Turnstile.
///
/// Example:
/// ```dart
/// await trust.activate(webProvider: TurnstileProvider('site-key'));
/// ```
class TurnstileProvider implements WebProvider {
  /// The Turnstile site key.
  final String siteKey;

  /// Optional action value sent to Turnstile.
  final String? action;

  /// Optional custom data sent to Turnstile.
  final String? cData;

  Future<String>? _inFlight;

  /// Creates a Turnstile provider.
  ///
  /// Parameters:
  /// - [siteKey] ([String]): Public Turnstile site key.
  /// - [action] ([String?]): Optional provider action override.
  /// - [cData] ([String?]): Optional custom provider data.
  ///
  /// Returns: a [TurnstileProvider].
  TurnstileProvider(this.siteKey, {this.action, this.cData});

  @override
  /// Obtains a shared in-flight or new token for [action].
  ///
  /// Parameters: [action] ([String]), used unless the configured action wins.
  /// Returns: a [Future<String>] containing the token.
  Future<String> getAttestationToken(String action) {
    _inFlight ??= attestation
        .getTurnstileToken(siteKey, action: this.action ?? action, cData: cData)
        .whenComplete(() => _inFlight = null);
    return _inFlight!;
  }
}

/// Deprecated alias for [TurnstileProvider].
@Deprecated('Use TurnstileProvider instead.')
class CloudflareTurnstileProvider extends TurnstileProvider {
  /// Creates a deprecated Turnstile provider alias.
  ///
  /// Parameters: [siteKey] ([String]), [action] ([String?]), and
  /// [cData] ([String?]) are forwarded to [TurnstileProvider].
  /// Returns: a [CloudflareTurnstileProvider].
  CloudflareTurnstileProvider(super.siteKey, {super.action, super.cData});
}

/// Web attestation provider backed by hCaptcha.
class HCaptchaProvider implements WebProvider {
  /// The hCaptcha site key.
  final String siteKey;

  /// Creates an hCaptcha provider.
  ///
  /// Parameters:
  /// - [siteKey] ([String]): Public hCaptcha site key.
  ///
  /// Returns: an [HCaptchaProvider].
  HCaptchaProvider(this.siteKey);

  @override
  /// Obtains a token for [action].
  ///
  /// Parameters: [action] ([String]), the provider action.
  /// Returns: a [Future<String>] containing the token.
  Future<String> getAttestationToken(String action) {
    return attestation.getHCaptchaToken(siteKey, action);
  }
}
