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

/// {@template fusabase.core}
/// Initializes and manages named application instances.
///
/// Use [Fusabase.initializeApp] once before accessing other service modules.
///
/// Example:
/// ```dart
/// final app = Fusabase.initializeApp(
///   options: FusabaseOptions({
///     'ords_host': 'https://example.com',
///     'app_id': 'my-app-id',
///     'project_id': 'my-project',
///     'schema': 'my_schema',
///     'objs_type': 'oci-objs',
///     'backend_type': 'COLLECTION',
///     'storage_bucket': 'my-bucket',
///     'auth_type': 'idcs',
///   }),
/// );
/// ```
/// {@endtemplate}
/// {@category core}

library fusabase.core;

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math';

import 'globals.dart' as globals;
import 'core/browser_instance_none.dart'
    if (dart.library.html) 'core/browser_instance_web.dart'
    as browser_instance;

part "core/core_impl.dart";
