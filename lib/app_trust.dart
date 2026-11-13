// Copyright (c) 2015, 2026, Oracle and/or its affiliates.
//
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

/// Public App Trust APIs for the Fusabase Flutter SDK.
///
/// Activate an [FusabaseAppTrust] instance with a provider before requesting
/// tokens for protected operations.
///
/// Example:
/// ```dart
/// await FusabaseAppTrust.instance.activate(
///   webProvider: ReCaptchaV3Provider('site-key'),
/// );
/// ```
/// {@category app-trust}
library fusabase.app_trust;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;

import './core.dart';
import './app_trust/internal/attestation_none.dart'
    if (dart.library.html) './app_trust/internal/attestation_web.dart'
    as attestation;
import './app_trust/internal/indexeddb_none.dart'
    if (dart.library.html) './app_trust/internal/indexeddb_web.dart'
    as apptrustdb;

part './app_trust/internal/core.dart';
part './app_trust/providers/provider.dart';
part './app_trust/providers/recaptcha_v3.dart';
part './app_trust/providers/additional_providers.dart';
