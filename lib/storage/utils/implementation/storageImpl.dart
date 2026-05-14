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

part of "../../../storage.dart";

/// @nodoc
class StorageHelper {
  /// @nodoc
  static bool isPrem(FusabaseStorageConfig config) {
    //ask about this
    return config.module == 'dbfs';
  }

  /// @nodoc
  static String get_url(FusabaseStorageConfig config) {
    return "${config.host}_/baas-services/${config.module}/${config.projectID}/";
  }

  /// @nodoc
  static String _PARequestURL(FusabaseStorageConfig config) {
    if (!isPrem(config)) {
      throw Utils.storageErrorHandler(
        403,
        StorageErrorMessages.PAR_URL_CREATION_FAILED,
        null,
      );
    }
    return "${config.host}_/baas-services/${config.module}/par/${config.projectID}/";
  }

  /// @nodoc
  static Future<Map<String, dynamic>> getlists(
    http.Client client,
    FusabaseStorageConfig config,
    int maxOperationRetryTime,
    bool recurse,
    String bucket,
    globals.LogLevel logLevel,
    String path,
    ListOptions? options,
    String? accessToken,
  ) async {
    dynamic response;
    dynamic result;

    dynamic customHeader = <String, dynamic>{"path": path, "recurse": recurse};

    if (options != null && options.maxResults != null) {
      customHeader["maxResults"] = options.maxResults;
    }
    if (options != null && options.pageToken != null) {
      customHeader["pageToken"] = options.pageToken;
    }

    Map<String, String> _headers = Map<String, String>();
    _headers["x-dbfs-list-opts"] = jsonEncode(customHeader);
    if (accessToken != null) {
      _headers["Authorization"] = "Bearer ${accessToken}";
    }
    String reqUrl =
        "${get_url(config)}${globals.listRESTEP}/b/${bucket}?apiKey=${config.appID}";
    try {
      response = await fetchWithRetry(
        client,
        reqUrl,
        headers: _headers,
        maxRetryTime: maxOperationRetryTime,
      );

      Utils.checkResponse(logLevel, response);
      result = jsonDecode(response.body);
    } catch (e, stacktrace) {
      Utils.baasLogger(logLevel, "GET request");
      Utils.baasTrace(logLevel, reqUrl, _headers, null, e, stacktrace);
      String errMessage = "";
      try {
        errMessage =
            StorageHelper.isPrem(config)
                ? jsonDecode(response.body)["error"]
                : jsonDecode(response.body)["message"];
      } catch (jsonErr) {
        errMessage = StorageErrorMessages.UNKNOWN;
      }
      throw Utils.storageErrorHandler(
        response.statusCode ?? 500,
        errMessage,
        stacktrace,
      );
    }
    result ??= {};

    // Check if onPrem DBFS is being used, if yes
    // the returned response is with '/' prefix

    if (isPrem(config)) {
      Map<String, dynamic> final_res = Map<String, dynamic>();

      final_res["items"] = [];
      final_res["prefixes"] = [];
      final_res["nextPageToken"] = result["nextPageToken"];

      for (var e in result["items"]) {
        String path = e['name'].substring(1);
        final_res['items'].add(path);
      }

      for (var e in result["prefixes"]) {
        String path = e['name'].substring(1);
        final_res['prefixes'].add(path);
      }

      result = final_res;
    } else {
      Map<String, dynamic> final_res = Map<String, dynamic>();

      final_res["items"] = [];
      final_res["prefixes"] = [];
      final_res["nextPageToken"] = result["nextPageToken"];

      for (var e in result["items"]) {
        String path = e['name'];
        final_res['items'].add(path);
      }

      for (var e in result["prefixes"]) {
        String path = e;
        final_res['prefixes'].add(path.substring(0, path.length - 1));
      }

      result = final_res;
    }
    return result;
  }

  /// @nodoc
  static Future<void> deleteObject(
    http.Client client,
    FusabaseStorageConfig config,
    int maxOperationRetryTime,
    String bucket,
    globals.LogLevel logLevel,
    String path,
    String? accessToken,
  ) async {
    dynamic response;

    dynamic customHeader = <String, dynamic>{"path": path, "bucket": bucket};

    String listOp = jsonEncode(customHeader);

    Map<String, String> _headers = new Map<String, String>();
    _headers["x-object-path"] = listOp;

    if (accessToken != null) {
      _headers["Authorization"] = "Bearer ${accessToken}";
    }
    String baseURI = get_url(config);
    String reqUrl =
        "${baseURI}${globals.deleteObjRESTEP}?apiKey=${config.appID}";
    try {
      response = await deleteWithRetry(
        client,
        reqUrl,
        headers: _headers,
        maxRetryTime: maxOperationRetryTime,
      );

      Utils.checkResponse(logLevel, response);
    } catch (e, stacktrace) {
      Utils.baasLogger(logLevel, "DELETE request");
      Utils.baasTrace(logLevel, reqUrl, _headers, null, e, stacktrace);
      String errMessage = "";
      try {
        errMessage =
            StorageHelper.isPrem(config)
                ? jsonDecode(response.body)["error"]
                : jsonDecode(response.body)["message"];
      } catch (jsonErr) {
        errMessage = StorageErrorMessages.UNKNOWN;
      }
      throw Utils.storageErrorHandler(
        response.statusCode,
        errMessage,
        stacktrace,
      );
    }
  }

  /// @nodoc
  static Future<Map<String, dynamic>> getDownloadUrlHelper(
    http.Client client,
    FusabaseStorageConfig config,
    int maxOperationRetryTime,
    String bucket,
    globals.LogLevel logLevel,
    String? accessToken, [
    String path = "",
  ]) async {
    dynamic response;
    dynamic result;

    String baseURI = get_url(config);
    Map<String, String> headers = Map<String, String>();
    if (accessToken != null) {
      headers["Authorization"] = "Bearer ${accessToken}";
    }
    String reqUrl =
        "${baseURI}${globals.getpreauthRESTEP}?apiKey=${config.appID}";
    final body = jsonEncode({
      "bucket": bucket,
      "path": path, //fullPath
      "metadata": {},
      "access_type": "ObjectRead", //for getDownloadURL
    });
    try {
      response = await postWithRetry(
        client,
        reqUrl,
        headers: headers,
        body: body,
        maxRetryTime: maxOperationRetryTime,
      );
      Utils.checkResponse(logLevel, response);
      result = jsonDecode(response.body);
    } catch (e, stacktrace) {
      Utils.baasLogger(logLevel, "POST request");
      Utils.baasTrace(logLevel, reqUrl, headers, body, e, stacktrace);
      String errMessage = "";
      try {
        errMessage =
            StorageHelper.isPrem(config)
                ? jsonDecode(response.body)["error"]
                : jsonDecode(response.body)["message"];
      } catch (jsonErr) {
        errMessage = StorageErrorMessages.format(
          StorageErrorMessages.FAILED_DOWNLOAD_URL,
          [path],
        );
      }
      throw Utils.storageErrorHandler(
        response.statusCode,
        errMessage,
        stacktrace,
      );
    }
    result ??= {};

    if (isPrem(config)) {
      result["URL"] = StorageHelper._PARequestURL(config) + result['URL'];
    }

    return result;
  }

  /// @nodoc
  static Future<Uint8List?> getDataHelper(
    http.Client client,
    String reqUrl,
    String path,
    String bucket,
    FusabaseStorageConfig config,
    int maxDownloadRetryTime,
    globals.LogLevel logLevel,
    String? accessToken,
  ) async {
    dynamic response;
    dynamic result;

    Map<String, String> headers = Map<String, String>();
    if (accessToken != null) {
      headers["Authorization"] = "Bearer ${accessToken}";
    }
    headers["x-object-path"] = jsonEncode({"path": path, "bucket": bucket});
    try {
      response = await fetchWithRetry(
        client,
        reqUrl + "?apiKey=${config.appID}",
        headers: headers,
        maxRetryTime: maxDownloadRetryTime,
      );
      Utils.checkResponse(logLevel, response);
    } catch (e, stacktrace) {
      Utils.baasLogger(logLevel, "GET request");
      Utils.baasTrace(logLevel, reqUrl, headers, null, e, stacktrace);
      String errMessage = "";
      try {
        errMessage =
            StorageHelper.isPrem(config)
                ? jsonDecode(response.body)["error"]
                : jsonDecode(response.body)["message"];
      } catch (jsonErr) {
        errMessage = StorageErrorMessages.UNKNOWN;
      }
      throw Utils.storageErrorHandler(
        response.statusCode,
        errMessage,
        stacktrace,
      );
    }
    return response.bodyBytes;
  }

  /// @nodoc
  static fetchMetadata({
    required http.Client client,
    required Reference ref,
    required FusabaseStorageConfig config,
    required int maxOperationRetryTime,
    required globals.LogLevel logLevel,
    String? accessToken,
  }) async {
    dynamic response;
    dynamic result;
    String reqUrl;

    Map<String, String> attributeList = new Map<String, String>();

    attributeList["cache-control"] = "cacheControl";
    attributeList["content-disposition"] = "contentDisposition";
    attributeList["content-encoding"] = "contentEncoding";
    attributeList["content-language"] = "content-language";
    attributeList["content-length"] = "size";
    attributeList["last-modified"] = "updated";

    dynamic temp = [
      "cache-control",
      "content-disposition",
      "content-encoding",
      "content-language",
      "content-length",
      "last-modified",
    ];

    reqUrl =
        "${get_url(config)}${globals.getMetaData}/b/${ref._bucket}?apiKey=${config.appID}";

    // For OnPrem endpoint, getmetadata endpoint and request-response formats
    // are different altogether.
    if (isPrem(config)) {
      Map<String, String> customheader = new Map<String, String>();
      customheader["bucket"] = ref._bucket;
      customheader["path"] = ref.fullPath;

      Map<String, String> headers = Map<String, String>();
      headers["x-object-path"] = jsonEncode(customheader);
      if (accessToken != null) {
        headers["Authorization"] = "Bearer ${accessToken}";
      }

      try {
        response = await fetchWithRetry(
          client,
          reqUrl,
          headers: headers,
          maxRetryTime: maxOperationRetryTime,
        );
        Utils.checkResponse(logLevel, response);
        result = jsonDecode(response.body);

        for (var entry in response.headers.entries) {
          dynamic t1 = entry.key;
          dynamic t2 = entry.value;

          if (temp.indexOf(t1) != -1) {
            t1 = attributeList[t1] ?? "";
            result[t1] = t2;
          }
        }
      } catch (e, stacktrace) {
        Utils.baasLogger(logLevel, "GET request");
        Utils.baasTrace(logLevel, reqUrl, headers, null, e, stacktrace);
        String errMessage = "";
        try {
          errMessage =
              StorageHelper.isPrem(config)
                  ? jsonDecode(response.body)["error"]
                  : jsonDecode(response.body)["message"];
        } catch (jsonErr) {
          errMessage = StorageErrorMessages.format(
            StorageErrorMessages.FAILED_FETCH_METADATA,
            [ref.fullPath],
          );
        }
        throw Utils.storageErrorHandler(
          response.statusCode,
          errMessage,
          stacktrace,
        );
      }
      result['customMetadata'] = <String, String>{};
      result['name'] = ref.name;
      if (result.containsKey("opc-multipart-md5")) {
        result["md5Hash"] = result["opc-multipart-md5"];
      }
      FullMetadata onprem_fullMetadata = FullMetadata(result);
      return onprem_fullMetadata;
    }

    Map<String, dynamic> _metadata = {};

    _metadata["bucket"] = ref._bucket;
    _metadata["fullPath"] = ref.fullPath;
    _metadata["name"] = ref._name;

    Map<String, String> customheader = {};
    customheader["bucket"] = ref._bucket;
    customheader["path"] = ref.fullPath;
    final headers = <String, String>{};
    headers["x-object-path"] = jsonEncode(customheader);
    if (accessToken != null) {
      headers["Authorization"] = "Bearer ${accessToken}";
    }
    try {
      response = await fetchWithRetry(
        client,
        reqUrl,
        headers: headers,
        maxRetryTime: maxOperationRetryTime,
      );
      Utils.checkResponse(logLevel, response);
      result = jsonDecode(response.body);
    } catch (e, stacktrace) {
      Utils.baasLogger(logLevel, "HEAD request");
      Utils.baasTrace(logLevel, reqUrl, headers, null, e, stacktrace);
      String errMessage = "";
      try {
        errMessage =
            StorageHelper.isPrem(config)
                ? jsonDecode(response.body)["error"]
                : jsonDecode(response.body)["message"];
      } catch (jsonErr) {
        errMessage = StorageErrorMessages.UNKNOWN;
      }
      throw Utils.storageErrorHandler(
        response.statusCode,
        errMessage,
        stacktrace,
      );
    }

    Map<String, String> _customMetadata = {};
    Iterable<MapEntry<String, String>> entries = response.headers.entries;
    for (var entry in entries) {
      dynamic t1 = entry.key;
      dynamic t2 = entry.value;

      if (temp.indexOf(t1) != -1) {
        t1 = attributeList[t1] ?? "";
        _metadata[t1] = t2;
      } else if (t1.startsWith("opc-meta-")) {
        t2 = t1.substring(8);
        _customMetadata[t2] = t2;
      }
    }

    _metadata["customMetadata"] = _customMetadata;
    _metadata["bucket"] = result["bucket"];
    _metadata["size"] = result["size"];
    _metadata["fullPath"] = result["fullPath"];
    _metadata['name'] = ref.name;
    _metadata["timeCreated"] = result["updated"];
    _metadata["updated"] = result["updated"];
    if (result.containsKey("opc-multipart-md5")) {
      _metadata["md5Hash"] = result["opc-multipart-md5"];
    } else {
      _metadata["md5Hash"] = result["md5Hash"];
    }
    _metadata["contentType"] = result["contentType"];
    FullMetadata fullMetadata = FullMetadata(_metadata);

    return fullMetadata;
  }
}
