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

/// reCAPTCHA Enterprise provider for web.
class ReCaptchaEnterpriseProvider implements WebProvider {
  /// The reCAPTCHA Enterprise site key.
  final String siteKey;

  /// Creates a web provider backed by reCAPTCHA Enterprise.
  ReCaptchaEnterpriseProvider(this.siteKey);

  @override
  Future<String> getAttestationToken(String action) {
    return attestation.getReCaptchaEnterpriseToken(siteKey, action);
  }
}

/// Cloudflare Turnstile provider for web.
class TurnstileProvider implements WebProvider {
  /// The Turnstile site key.
  final String siteKey;

  /// Optional action value sent to Turnstile.
  final String? action;

  /// Optional custom data sent to Turnstile.
  final String? cData;

  Future<String>? _inFlight;

  /// Creates a web provider backed by Cloudflare Turnstile.
  TurnstileProvider(this.siteKey, {this.action, this.cData});

  @override
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
  CloudflareTurnstileProvider(super.siteKey, {super.action, super.cData});
}

/// hCaptcha provider for web.
class HCaptchaProvider implements WebProvider {
  /// The hCaptcha site key.
  final String siteKey;

  /// Creates a web provider backed by hCaptcha.
  HCaptchaProvider(this.siteKey);

  @override
  Future<String> getAttestationToken(String action) {
    return attestation.getHCaptchaToken(siteKey, action);
  }
}
