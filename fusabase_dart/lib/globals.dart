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

library fusabase.globals;

const authenticateRESTEP = "/sso/v1/sdk/authenticate";
const oauthTokenRESTEP = "/oauth2/v1/token";
const selfMeRESTEP = "/admin/v1/Me";
const logoutRESTEP = "/oauth2/v1/userlogout";
const revokeRefreshTokenRESTEP = "/oauth2/v1/revoke";
const addRESTEP = "adddoc/";
const getRESTEP = "getdocs/";
const updateRESTEP = "upddoc/";
const deleteRESTEP = "deldoc/";
const setRESTEP = "setdoc/";
const listRESTEP = "listallobj/";
const getpreauthRESTEP = "getpreauth/";
const putobjectRESTEP = "putobject/";

const defaultAppName = "OracleDefaultApp";