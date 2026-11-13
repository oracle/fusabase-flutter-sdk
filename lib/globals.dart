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

/// @nodoc
library fusabase.globals;

const addRESTEP = "setDocument";
const getRESTEP_V1 = "v1/runQuery";
const getRESTEP_V2 = "v2/runQuery";
const updateRESTEP = "updateDocument";
const deleteRESTEP = "deleteDocument";
const setRESTEP = "setDocument";
const listRESTEP = "listallobj";
const getpreauthRESTEP = "genpreauth";
const deleteObjRESTEP = "o/operation";
const downloadObjRESTEP = "o/operation";
const putobjectRESTEP = "o/operation";
const getMetaData = 'getmetadata';
const defaultAppName = "OracleDefaultApp";
const accessTokenKey = 'accessToken';
const refreshTokenKey = 'refreshToken';
const idTokenHintKey = 'idTokenHint';
const codeKey = 'redirectCode';
const codeVerifierKey = 'redirectCodeVerifier';
const providerKey = 'redirectProvider';
const loginKey = 'loginKey';
const redirectKey = 'redirectInitiated';
const getTokenORDS = 'oauth/token';
const getConfig = "config/initializeapp/";

enum LogLevel { error, silent, debug }

enum ErrorCode {
  INVALID_ARGS,
  INVALID_USER_TOK,
  NOT_FOUND,
  WRONG_PASSWORD,
  POPUP_BLOCKED,
  SERVER_ERROR,
  NOT_IMPLEMENT,
  UNAVAILABLE,
  OPR_NOT_ALLOWED,
}

Map<ErrorCode, int> ErrorMap = {
  ErrorCode.INVALID_ARGS: 400,
  ErrorCode.INVALID_USER_TOK: 401,
  ErrorCode.NOT_FOUND: 404,
  ErrorCode.WRONG_PASSWORD: 403,
  ErrorCode.POPUP_BLOCKED: 498,
  ErrorCode.SERVER_ERROR: 500,
  ErrorCode.NOT_IMPLEMENT: 501,
  ErrorCode.UNAVAILABLE: 502,
  ErrorCode.OPR_NOT_ALLOWED: 599,
};
