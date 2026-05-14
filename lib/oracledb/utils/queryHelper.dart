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

part of '../../oracledb.dart';

/// @nodoc
class QueryHelper {
  String _module;

  QueryHelper() : _module = "database";

/// @nodoc
  List<String> makePath(List<String> paths) {
    List<String> newPath = List.from(paths);
    for (int i = 1; i < newPath.length; i += 2) {
      newPath[i] = "${newPath[i]}";
    }
    return newPath;
  }

/// @nodoc
  String constructUrl(FusabaseOptions? options) {
    return "${options?.ordsHost}_/baas-services/${_module}/${options?.projectID}";
  }

/// @nodoc
  Future<Map<String, dynamic>> get(
      http.Client client,
      GetOptions? options,
      dynamic query,
      globals.LogLevel logLevel,
      String? accessToken,
      dynamic transObj) async {
    dynamic response;
    dynamic result;
    
    FusabaseOptions? initializeOptions = query.oracledb.app.options;
    bool jCon = false;
    bool isAgg = false;
    if ((query is! DocumentReference) && query._joins.length>0) {
      jCon = true;
    }

    dynamic body = {
      "conditions": query is DocumentReference ? [] : query._conditions,
      "column": query is DocumentReference ? [] : query._column,
      "explicitOrder": query is DocumentReference ? [] : query._explicitOrder,
      "joins": !jCon ? [] : query._joins[0],
      "col_group": query is DocumentReference ? [] : query._col_group,
      "limit": query is DocumentReference ? 0 : query._limit,
      "aggregate": query is DocumentReference ? [] : query._aggregate,
      "snapshot": query._rt,
      "options": {}
    };
    if (checkOracledbApiVersion(
          query.oracledb.app.options,
          OracledbVersion["VERSION_2"] ?? 2,
        ) &&
        query._vectorSearch != null) {
      body["vectorSearch"] = query._vectorSearch;
    }
    if (body["aggregate"].length>0) {
      isAgg = true;
    }

    Map<String, String> headers = Map<String, String>();
    headers["Content-Type"] = "application/json";
    headers["x-transaction"] = jsonEncode(<String, dynamic>{
      "begin_trans": transObj == null ? 0 : transObj["start"],
      "end_trans": transObj == null ? 0 : transObj["end"],
      "trans_name": transObj == null ? "" : transObj["name"]
    });
    if (accessToken != null) {
      headers["Authorization"] = "Bearer ${accessToken}";
    }
    String reqUrl;
    if (checkOracledbApiVersion(query.oracledb.app.options, OracledbVersion["VERSION_2"] ?? 2)) {
        reqUrl =
        "${constructUrl(initializeOptions)}/${globals.getRESTEP_V2}?apiKey=${initializeOptions?.appID}";
    } else {
      reqUrl =
        "${constructUrl(initializeOptions)}/${globals.getRESTEP_V1}?apiKey=${initializeOptions?.appID}";
    }

    if (isDualityView(query)) {
        var tokens = makePath(query._path);
        body["dv_name"] = tokens[0];
        if (tokens.length>1) {
            body["oid"] = tokens[1]; 
        }
    } else {
        body["path"] = query is DocumentReference || query._col_group == ""
          ? makePath(query._path)
          : [];
    }
    if (jCon) {
        body["path"] = [];
    }

    try {
      response = await client.post(Uri.parse(reqUrl),
          headers: headers, body: json.encode(body));

      Utils.checkResponse(logLevel, response);
      result = jsonDecode(response.body);
      // dynamic newResult = {"ret": []};
      // if (result is Map && transObj!=null && transObj["name"]!="") {
      //   for (int i=0;i<result["ret"].length;i++) {
      //     newResult["ret"].add({
      //       "osons": result["ret"][i]["osons"]["data"]
      //     });
      //   }
      //   result = newResult;
      // }
    } catch (e, stacktrace) {
      Utils.baasLogger(logLevel, "POST request");
      Utils.baasTrace(logLevel, reqUrl, headers, null, e, stacktrace);
      String errMessage = OracledbErrorMessages.unknownError;
      int statusCode = 0;
      if (response != null) {
        statusCode = response.statusCode;
        try {
          errMessage = jsonDecode(response.body)["error"];
        } catch (jsonErr) {
          // ignore
        }
      } else if (e is Exception) {
        errMessage = e.toString();
      }
      throw Utils.oracledbErrorHandler(
          statusCode, errMessage, stacktrace);
    }
    if (result != null) {
      if (jCon) {
        for (var i = 0; i < result["ret"].length; i++) {
          final item = result["ret"][i];
          final data = item["data"] as Map<String, dynamic>;
          final relResult = <String, dynamic>{};

          data.forEach((key, value) {
            if (key != "OID") {
              relResult[key] = value;
            }
          });

          item["osons"] = {
            "DOCUMENT": relResult,
            "CREATED": null,
            "LAST_MODIFIED": null,
            "VERSION": null,
            "SUBCOLLECTION": null,
            "PARENT_OID": null,
            "OID":data["OID"]
          };
        }
      } else if (!isAgg) {
        for (var i = 0; i < result["ret"].length; i++) {
          final item = result["ret"][i];
          final osons = item["osons"];

          if (osons != null && !osons.containsKey("DOCUMENT")) {
            final relResult = <String, dynamic>{};

            osons.forEach((key, value) {
              if (key != "OID" &&
                  key != "parent_oid" &&
                  key != "_metadata") {
                relResult[key] = value;
              }
            });

            osons["DOCUMENT"] = relResult;
            osons["CREATED"] = null;
            osons["LAST_MODIFIED"] = null;
            osons["VERSION"] = osons["_metadata"]["etag"];
            osons["ASOF"] = osons["_metadata"]["asof"];
            osons["SUBCOLLECTION"] = osons["subcollection"];
            osons["PARENT_OID"] = osons["parent_oid"];
          }
        }
      }

      if (body["snapshot"] == 1) {
        for (var i = 0; i < result["ret"].length; i++) {
          result["ret"][i]["osons"]["ROWID"] = result["ret"][i]["rid"];
        }
      }
    }
    result ??= Map<String, dynamic>();
    return result;
  }

/// @nodoc
  Future<Map<String, dynamic>> createdoc(http.Client client, dynamic colRef,
      dynamic data, globals.LogLevel logLevel, String? accessToken) async {
    dynamic response;
    dynamic result;

    FusabaseOptions? options = colRef._oracledb.app.options;

    dynamic body = {
      "data": data,
      "servertimestamp": colRef._serverTimestamp
    };

    Map<String, String> headers = Map<String, String>();
    headers["x-transaction"] = jsonEncode(
        <String, dynamic>{"begin_trans": 0, "end_trans": 0, "trans_name": ""});
    if (accessToken != null) {
      headers["Authorization"] = "Bearer ${accessToken}";
    }
    
    String reqUrl =
        constructUrl(options);
    if (checkOracledbApiVersion(colRef.oracledb.app.options, OracledbVersion["VERSION_2"] ?? 2)) {
        reqUrl += "/v2";
    } else {
      reqUrl += "/v1";
    }
    reqUrl += "/${globals.setRESTEP}?apiKey=${options?.appID}";

    if (isDualityView(colRef)) {
        var tokens = makePath(colRef._path);
        body["dv_name"] = tokens[0];
        if (tokens.length>1) {
            body["oid"] = tokens[1]; 
        }
    } else {
        body["path"] = makePath(colRef._path);
    }

    try {
      response = await client.post(Uri.parse(reqUrl),
          headers: headers, body: json.encode(body));
      Utils.checkResponse(logLevel, response);
      result = jsonDecode(response.body);
    } catch (e, stacktrace) {
      Utils.baasLogger(logLevel, "POST request");
      Utils.baasTrace(logLevel, reqUrl, headers, data, e, stacktrace);
      String errMessage = OracledbErrorMessages.unknownError;
      int statusCode = 0;
      if (response != null) {
        statusCode = response.statusCode;
        try {
          errMessage = jsonDecode(response.body)["error"];
        } catch (jsonErr) {
          // ignore
        }
      } else if (e is Exception) {
        errMessage = e.toString();
      }
      throw Utils.oracledbErrorHandler(
          statusCode, errMessage, stacktrace);
    }
    return result;
  }

/// @nodoc
  Future<Map<String, dynamic>> updatedoc(
      http.Client client,
      dynamic docRef,
      dynamic data,
      globals.LogLevel logLevel,
      String? accessToken,
      dynamic transObj) async {
    dynamic response;
    dynamic result;

    FusabaseOptions? options = docRef._oracledb.app.options;

    dynamic body = {"data": data};

    Map<String, String> headers = Map<String, String>();
    headers["x-transaction"] = jsonEncode(<String, dynamic>{
      "begin_trans": transObj == null ? 0 : transObj["start"],
      "end_trans": transObj == null ? 0 : transObj["end"],
      "trans_name": transObj == null ? "" : transObj["name"]
    });

    if (accessToken != null) {
      headers["Authorization"] = "Bearer ${accessToken}";
    }
   
    String reqUrl = constructUrl(options);
    if (checkOracledbApiVersion(docRef.oracledb.app.options, OracledbVersion["VERSION_2"] ?? 2)) {
        reqUrl += "/v2";
    } else {
      reqUrl += "/v1";
    }
    reqUrl += "/${globals.updateRESTEP}?apiKey=${options?.appID}";

    if (transObj != null && transObj['version']!=null) {
      body["version"] = transObj['version'];
    }

    if (isDualityView(docRef)) {
        var tokens = makePath(docRef._path);
        body["dv_name"] = tokens[0];
        if (tokens.length>1) {
            body["oid"] = tokens[1]; 
        }
    } else {
        body["path"] = makePath(docRef._path);
    }
    if (!isDualityView(docRef) && body["path"].length%2==1) {
      body["path"].add("*");
    }
    body["conditions"] = docRef is BulkUpdate ? docRef._conditions : [];

    try {
      response = await client.put(Uri.parse(reqUrl),
          headers: headers, body: json.encode(body));
      Utils.checkResponse(logLevel, response);
      result = jsonDecode(response.body);
    } catch (e, stacktrace) {
      Utils.baasLogger(logLevel, "PUT request");
      Utils.baasTrace(logLevel, reqUrl, headers, data, e, stacktrace);
      String errMessage = OracledbErrorMessages.unknownError;
      int statusCode = 0;
      if (response != null) {
        statusCode = response.statusCode;
        try {
          errMessage = jsonDecode(response.body)["error"];
        } catch (jsonErr) {
          // ignore
        }
      } else if (e is Exception) {
        errMessage = e.toString();
      }
      throw Utils.oracledbErrorHandler(
          statusCode, errMessage, stacktrace);
    }
    return result;
  }

/// @nodoc
  Future<Map<String, dynamic>> deletedoc(http.Client client, dynamic docRef,
      globals.LogLevel logLevel, String? accessToken, dynamic transObj) async {
    dynamic response;
    dynamic result;

    FusabaseOptions? options = docRef._oracledb.app.options;

    dynamic body = {};

    Map<String, String> headers = Map<String, String>();
    headers["x-transaction"] = jsonEncode(<String, dynamic>{
      "begin_trans": transObj == null ? 0 : transObj["start"],
      "end_trans": transObj == null ? 0 : transObj["end"],
      "trans_name": transObj == null ? "" : transObj["name"]
    });

    if (accessToken != null) {
      headers["Authorization"] = "Bearer ${accessToken}";
    }
    String reqUrl =
        "${constructUrl(options)}/${globals.deleteRESTEP}?apiKey=${options?.appID}";

    if (transObj != null && transObj['version']!=null) {
      body["version"] = transObj['version'];
    }

    if (isDualityView(docRef)) {
        var tokens = makePath(docRef._path);
        body["dv_name"] = tokens[0];
        if (tokens.length>1) {
            body["oid"] = tokens[1]; 
        }
    } else {
        body["path"] = makePath(docRef._path);
    }

    try {
      response = await client.put(Uri.parse(reqUrl),
          headers: headers, body: json.encode(body));
      Utils.checkResponse(logLevel, response);
      result = jsonDecode(response.body);
    } catch (e, stacktrace) {
      Utils.baasLogger(logLevel, "DELETE request");
      Utils.baasTrace(logLevel, reqUrl, headers, {}, e, stacktrace);
      String errMessage = OracledbErrorMessages.unknownError;
      int statusCode = 0;
      if (response != null) {
        statusCode = response.statusCode;
        try {
          errMessage = jsonDecode(response.body)["error"];
        } catch (jsonErr) {
          // ignore
        }
      } else if (e is Exception) {
        errMessage = e.toString();
      }
      throw Utils.oracledbErrorHandler(
          statusCode, errMessage, stacktrace);
    }
    return result;
  }

/// @nodoc
  Future<Map<String, dynamic>> setdoc(
      {required http.Client client,
      dynamic docRef,
      dynamic data,
      required globals.LogLevel logLevel,
      String? accessToken,
      SetOptions? options,
      dynamic transObj}) async {
    dynamic response;
    dynamic result;

    FusabaseOptions? fOptions = docRef._oracledb.app.options;

    dynamic body = {
      "data": data,
      "options": {"merge": false},
      "servertimestamp": docRef._serverTimestamp
    };

    if (options != null) {
      final dynamic opt = options;
      body["options"] = {"merge": opt.merge};
    }
    Map<String, String> headers = Map<String, String>();
    headers["Content-Type"] = "application/json";
    headers["x-transaction"] = jsonEncode(<String, dynamic>{
      "begin_trans": transObj == null ? 0 : transObj["start"],
      "end_trans": transObj == null ? 0 : transObj["end"],
      "trans_name": transObj == null ? "" : transObj["name"]
    });

    if (accessToken != null) {
      headers["Authorization"] = "Bearer ${accessToken}";
    }
    String reqUrl = constructUrl(fOptions);
    if (checkOracledbApiVersion(docRef.oracledb.app.options, OracledbVersion["VERSION_2"] ?? 2)) {
        reqUrl += "/v2";
    } else {
      reqUrl += "/v1";
    }
    reqUrl += "/${globals.setRESTEP}?apiKey=${fOptions?.appID}";

    if (transObj != null && transObj['version']!=null) {
      body["version"] = transObj['version'];
    }

    if (isDualityView(docRef)) {
        var tokens = makePath(docRef._path);
        body["dv_name"] = tokens[0];
        if (tokens.length>1) {
            body["oid"] = tokens[1]; 
        }
    } else {
        body["path"] = makePath(docRef._path);
    }

    try {
      response = await client.post(Uri.parse(reqUrl),
          headers: headers, body: json.encode(body));

      Utils.checkResponse(logLevel, response);
      result = jsonDecode(response.body);
    } catch (e, stacktrace) {
      Utils.baasLogger(logLevel, "POST request");
      Utils.baasTrace(logLevel, reqUrl, headers, body, e, stacktrace);
      String errMessage = OracledbErrorMessages.unknownError;
      int statusCode = 0;
      if (response != null) {
        statusCode = response.statusCode;
        try {
          errMessage = jsonDecode(response.body)["error"];
        } catch (jsonErr) {
          // ignore
        }
      } else if (e is Exception) {
        errMessage = e.toString();
      }
      throw Utils.oracledbErrorHandler(
          statusCode, errMessage, stacktrace);
    }
    return result;
  }

/// @nodoc
  void dupQuery(Query dest, Query origin) {
    dest._path = [];
    for (var i = 0; i < origin._path.length; i++) {
      dest._path.add(origin._path[i]);
    }
    dest._column = [];
    for (var i = 0; i < origin._column.length; i++) {
      dest._column.add(origin._column[i]);
    }
    dest._serverTimestamp = [];
    for (var i = 0; i < origin._serverTimestamp.length; i++) {
      dest._serverTimestamp.add(origin._serverTimestamp[i]);
    }
    dest._ops = [];
    for (var i = 0; i < origin._ops.length; i++) {
      dest._ops.add(origin._ops[i]);
    }
    dest._col_group = origin._col_group;
    dest._conditions = [];
    for (var i = 0; i < origin._conditions.length; i++) {
      dest._conditions.add(origin._conditions[i]);
    }
    dest._explicitOrder = [];
    for (var i = 0; i < origin._explicitOrder.length; i++) {
      dest._explicitOrder.add(origin._explicitOrder[i]);
    }
    dest._joins = [];
    for (var i = 0; i < origin._joins.length; i++) {
      dest._joins.add(origin._joins[i]);
    }
    dest._limit = origin._limit;
    dest._aggregate = [];
    for (var i = 0; i < origin._aggregate.length; i++) {
      dest._aggregate.add(origin._aggregate[i]);
    }
    for (var i = 0; i < origin._brid.length; i++) {
      dest._brid.add(origin._brid[i]);
    }
    dest._rt = origin._rt;
    dest._vectorSearch = origin._vectorSearch == null
        ? null
        : deepClone(origin._vectorSearch) as Map<String, dynamic>;
    dest.type = origin.type;
  }
}
