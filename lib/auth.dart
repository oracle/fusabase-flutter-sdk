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

/// The authentication module for the Oracle Backend for Firebase Flutter SDK.
/// {@category auth}

library fusabase.auth;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:fusabase_dart/fusabase_dart.dart';
import 'package:fusabase_web/fusabase_web.dart';

import './core.dart';
import './globals.dart' as globals;
import './auth/util/persistence/persistence_manager_none.dart'
    if (dart.library.io) './auth/util/persistence/persistence_manager_android.dart'
    if (dart.library.html) './auth/util/persistence/persistence_manager_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

export './auth/util/persistence/persistence_manager_none.dart' 
    if (dart.library.io) './auth/util/persistence/persistence_manager_android.dart' 
    if (dart.library.html) './auth/util/persistence/persistence_manager_web.dart';

// Main index file for the authentication module.
// This file imports necessary dependencies and includes all part files
// that define the authentication functionality.

part './auth/internal/core.dart';
part './auth/internal/credential.dart';
part './auth/providers/email.dart';
part './auth/providers/facebook.dart';
part './auth/providers/google.dart';
part './auth/providers/github.dart';
part './auth/providers/oidc.dart';
part './auth/providers/provider.dart';
part './auth/providers/saml.dart';
part './auth/providers/idcs.dart';
part './auth/types/token.dart';
part './auth/types/user.dart';
part './auth/util/helpers/authHelper.dart';
part './auth/util/config.dart';
part './auth/util/helpers/userHelper.dart';
part './auth/util/const.dart';
part './auth/util/utils.dart';
part './auth/errors.dart';
