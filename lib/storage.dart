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

/// The main entry file for the FUSABASE Storage library.
/// {@category fusabase-storage}
///

/// This file imports necessary dependencies and parts in the implementation files
library fusabase.storage;

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:developer';
import "dart:typed_data";

import './auth.dart';
import './globals.dart' as globals;
import './core.dart';
import "./storage/utils/utils_none.dart"
    if (dart.library.html) "./storage/utils/utils_web.dart"
    if (dart.library.io) "./storage/utils/utils_native.dart";

part "./storage/utils/utils_common.dart";
part "./storage/types/taskState.dart";
part "./storage/types/storage.dart";
part "./storage/types/ref.dart";
part "./storage/types/upload.dart";
part "./storage/types/list.dart";
part "./storage/utils/implementation/storageImpl.dart";
part "./storage/utils/implementation/taskController.dart";
part "./storage/errors.dart";
