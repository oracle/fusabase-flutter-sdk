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

/// The Oracle Database module for the Oracle Backend for Firebase Flutter SDK.
/// {@category oracledb}
library fusabase.oracledb;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import './auth.dart';
import './client/socket/socket_client_none.dart'
    if (dart.library.io) './client/socket/socket_client.dart'
    if (dart.library.html) './client/socket/socket_client_web.dart';
import './core.dart';
import './globals.dart' as globals;
import './oracledb/utils/storage/snapshot_storage.dart';
import './oracledb/utils/storage/storage_manager.dart';

part "./oracledb/collection/aggregate.dart";
part "./oracledb/collection/query.dart";
part "./oracledb/collection/reference.dart";
part "./oracledb/collection/snapshot.dart";
part "./oracledb/document/reference.dart";
part "./oracledb/document/snapshot.dart";
part "./oracledb/dualityview/reference.dart";
part "./oracledb/field/path.dart";
part "./oracledb/field/value.dart";
part "./oracledb/internal/bundle.dart";
part "./oracledb/internal/core.dart";
part "./oracledb/transaction/batch.dart";
part "./oracledb/transaction/bulk.dart";
part "./oracledb/transaction/transaction.dart";
part "./oracledb/types/filter.dart";
part "./oracledb/types/timestamp.dart";
part "./oracledb/types/types.dart";
part "./oracledb/utils/queryHelper.dart";
part "./oracledb/utils/utils.dart";
part "./oracledb/errors.dart";
