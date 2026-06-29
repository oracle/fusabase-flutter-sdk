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
Future<String?> getAccessToken(dynamic auth) async {
  if (auth == null || auth.currentUser == null) {
    return null;
  }

  String? accessToken;
  try {
    accessToken = await auth.currentUser?.getFUSABASEToken();
  } catch (e) {
    accessToken = null;
  }

  if (accessToken != null && accessToken.isNotEmpty) {
    return accessToken;
  }

  try {
    accessToken = await auth.currentUser?.getIdToken();
  } catch (e) {
    accessToken = null;
  }

  return accessToken != null && accessToken.isNotEmpty ? accessToken : null;
}

/// @nodoc
class MultiPart {
  /// @nodoc
  int totalSize;

  /// @nodoc
  int totalChunks;

  /// @nodoc
  int toSend;

  /// @nodoc
  String baseURL;

  MultiPart({
    required TaskSnapshot snapshot,
    required this.totalChunks,
    required this.toSend,
    required this.baseURL,
  }) : totalSize = snapshot._totalBytes;
}

/// @nodoc
class UploadTaskController {
  var _client;
  SettableMetadata? _metadata;
  MultiPart? isMultipart;
  dynamic dataToSend;
  globals.LogLevel __logLevel;
  int retryTime;
  int chunkSize;
  int maxUploadSize;
  final FusabaseApp app;

  UploadTaskController({
    SettableMetadata? metadata,
    required this.app,
    required this.retryTime,
    required this.chunkSize,
    required this.maxUploadSize,
    required globals.LogLevel logLevel,
  }) : _client = createClient(app),
       _metadata = metadata,
       isMultipart = null,
       __logLevel = logLevel,
       dataToSend = null;

  /// @nodoc
  Future<void> initUpload({
    required TaskSnapshot snapshot,
    required dynamic data,
    SettableMetadata? metadata,
  }) async {
    if (chunkSize <= 0 || maxUploadSize <= 0) {
      throw Utils.storageErrorHandler(
        400,
        StorageErrorMessages.format(StorageErrorMessages.EXPECTED_TYPE, [
          'positive upload size configuration',
          '$chunkSize/$maxUploadSize',
        ]),
        null,
      );
    }

    int size;
    if (data is Uint8List) {
      dataToSend = data;
      size = data.lengthInBytes;
    } else {
      try {
        size = await getUploadSize(data);
      } catch (e, stacktrace) {
        throw Utils.storageErrorHandler(
          400,
          StorageErrorMessages.UNKNOWN_UPLOAD_SIZE,
          stacktrace,
        );
      }
      dataToSend = data;
    }

    if (size > maxUploadSize) {
      throw Utils.storageErrorHandler(
        400,
        StorageErrorMessages.format(
          StorageErrorMessages.UPLOAD_EXCEEDS_MAX_SIZE,
          [size, maxUploadSize],
        ),
        null,
      );
    }

    if (size == 0) {
      throw Utils.storageErrorHandler(
        400,
        StorageErrorMessages.ZERO_BYTE_UPLOAD_NOT_SUPPORTED,
        null,
      );
    }

    snapshot._totalBytes = size;

    int totalChunks = ((size + chunkSize - 1) ~/ chunkSize);

    if (size > 2 * chunkSize) {
      isMultipart = MultiPart(
        snapshot: snapshot,
        totalChunks: totalChunks,
        toSend: 0,
        baseURL: "",
      );
    }
  }

  Future<Uint8List> _readUploadChunk(int start, int end) async {
    final source = dataToSend;
    if (source is Uint8List) {
      return Uint8List.sublistView(source, start, end);
    }
    return readFileChunk(source, start, end);
  }

  /// @nodoc
  Future<void> abortTask(
    http.Client client,
    FusabaseStorageConfig config,
  ) async {
    final _isMultipart = this.isMultipart;
    _client.close();
    _client = client;
    dynamic response;
    dynamic result;

    if (_isMultipart != null && _isMultipart.baseURL != "") {
      String reqUrl = _isMultipart.baseURL;
      final headers = <String, String>{};
      try {
        response = await deleteWithRetry(
          _client,
          reqUrl,
          headers: headers,
          maxRetryTime: retryTime,
        );
        Utils.checkResponse(this.__logLevel, response);
      } catch (e, stacktrace) {
        Utils.baasLogger(this.__logLevel, "DELETE request");
        Utils.baasTrace(this.__logLevel, reqUrl, headers, null, e, stacktrace);
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
          response != null ? response.statusCode : 999,
          errMessage,
          stacktrace,
        );
      }
    }
  }

  /// @nodoc
  Future<Map<String, dynamic>> putDataHelper(
    dynamic data,
    FusabaseStorageConfig config,
    Reference ref,
    String? accessToken,
  ) async {
    dynamic response;
    dynamic result;

    String reqUrl =
        "${StorageHelper.get_url(config)}${globals.putobjectRESTEP}?apiKey=${config.appID}";

    Map<String, String> customheader = new Map<String, String>();

    customheader["bucket"] = ref._bucket;
    customheader["path"] = ref.fullPath;

    Uint8List newData;
    if (data is Uint8List) {
      newData = data;
    } else if (data is ByteBuffer) {
      newData = Uint8List.view(data);
    } else {
      newData = Uint8List.fromList(data);
    }

    Map<String, String> headers = Map<String, String>();
    headers["x-object-path"] = jsonEncode(customheader);
    headers["Content-Type"] = _metadata?.contentType ?? "";
    if (accessToken != null) {
      headers["Authorization"] = "Bearer ${accessToken}";
    }

    try {
      response = await postWithRetry(
        _client,
        reqUrl,
        headers: headers,
        body: newData,
        maxRetryTime: retryTime,
      );

      Utils.checkResponse(this.__logLevel, response);
      result = jsonDecode(response.body);
    } catch (e, stacktrace) {
      Utils.baasLogger(this.__logLevel, "POST request");
      Utils.baasTrace(this.__logLevel, reqUrl, headers, newData, e, stacktrace);
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
        response != null ? response.statusCode : 999,
        errMessage,
        stacktrace,
      );
    }

    return result;
  }

  /// @nodoc
  Future<void> indexedUpload(
    int toSend,
    dynamic chunk,
    FusabaseStorageConfig config,
  ) async {
    dynamic response = null;
    dynamic result = null;

    String reqUrl = "";
    String _toSend = toSend.toString();
    final _isMultipart = this.isMultipart;
    if (_isMultipart != null) {
      reqUrl = _isMultipart.baseURL + _toSend;
    }
    final headers = <String, String>{
      'Content-Type': 'application/octet-stream',
      'Content-Length': chunk.length.toString(),
    };
    try {
      response = await putWithRetry(
        _client,
        reqUrl,
        headers: headers,
        body: chunk,
        maxRetryTime: retryTime,
      );

      Utils.checkResponse(this.__logLevel, response);
    } catch (e, stacktrace) {
      this.isMultipart?.toSend--;
      Utils.baasLogger(this.__logLevel, "PUT request");
      Utils.baasTrace(this.__logLevel, reqUrl, headers, chunk, e, stacktrace);
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
        response != null ? response.statusCode : 999,
        errMessage,
        stacktrace,
      );
    }
  }

  /// @nodoc
  Future<Map<String, dynamic>> continueTask({
    required TaskSnapshot snapshot,
    required FusabaseStorageConfig config,
    String? accessToken,
  }) async {
    Reference ref = snapshot._ref;
    dynamic result = null;

    if (this.isMultipart == null) {
      try {
        final bytes = await _readUploadChunk(0, snapshot._totalBytes);
        result = await this.putDataHelper(bytes, config, ref, accessToken);

        var timeC = result["metadata"]["timeCreated"];
        if (timeC == null) {
          timeC = result["metadata"]["updated"];
        }
        return <String, dynamic>{
          "state": TaskState.success,
          "bytesTransferred": snapshot._totalBytes,
          "md5sum": result["metadata"]["md5sum"],
          "size": result["metadata"]["size"],
          "contentType": result["metadata"]["contentType"],
          "updated": result["metadata"]["updated"],
          "timeCreated": timeC,
        };
      } catch (e) {
        int totalChunks = ((snapshot._totalBytes + chunkSize - 1) ~/ chunkSize);

        this.isMultipart = MultiPart(
          snapshot: snapshot,
          totalChunks: totalChunks,
          toSend: 0,
          baseURL: "",
        );
      }
    }

    dynamic response = null;
    String reqUrl = "";

    if (this.isMultipart?.toSend == 0) {
      reqUrl =
          "${StorageHelper.get_url(config)}${globals.getpreauthRESTEP}?apiKey=${config.appID}";

      Map<String, String> headers = Map<String, String>();
      if (accessToken != null) {
        headers["Authorization"] = "Bearer ${accessToken}";
      }
      final body = jsonEncode(<String, dynamic>{
        "bucket": ref._bucket,
        "path": ref.fullPath,
        "access_type": "ObjectWrite",
        "metadata": {"contentType": _metadata?.contentType ?? ""},
      });
      try {
        response = await postWithRetry(
          _client,
          reqUrl,
          headers: headers,
          body: body,
          maxRetryTime: retryTime,
        );

        Utils.checkResponse(this.__logLevel, response);
        result = jsonDecode(response.body);
      } catch (e, stacktrace) {
        Utils.baasLogger(this.__logLevel, "POST request");
        Utils.baasTrace(this.__logLevel, reqUrl, headers, body, e, stacktrace);
        String errMessage = "";
        try {
          errMessage =
              StorageHelper.isPrem(config)
                  ? jsonDecode(response.body)["error"]
                  : jsonDecode(response.body)["message"];
        } catch (jsonErr) {
          errMessage = StorageErrorMessages.MULTIPART_NOT_INITIALIZED;
        }
        throw Utils.storageErrorHandler(
          response != null ? response.statusCode : 999,
          errMessage,
          stacktrace,
        );
      }

      String objectStoreURL = "";

      objectStoreURL =
          StorageHelper.isPrem(config)
              ? StorageHelper._PARequestURL(config)
              : result["URL"].substring(0, result["URL"].indexOf('/', 9));

      isMultipart?.baseURL = objectStoreURL + result["accessUri"];
    }

    this.isMultipart?.toSend++;
    int chunkIdx = this.isMultipart?.toSend ?? 0;

    // get chunk to upload

    int offBegin = (chunkIdx - 1) * chunkSize;
    int offEnd =
        chunkIdx != this.isMultipart?.totalChunks
            ? offBegin + chunkSize
            : snapshot._totalBytes;

    dynamic chunkToSend = await _readUploadChunk(offBegin, offEnd);

    await indexedUpload(chunkIdx, chunkToSend, config);

    if (chunkIdx == this.isMultipart?.totalChunks) {
      final _isMultipart = this.isMultipart;
      if (_isMultipart != null) {
        reqUrl = _isMultipart.baseURL;
      }
      final headers_3 = <String, String>{};
      try {
        response = await postWithRetry(
          _client,
          reqUrl,
          headers: headers_3,
          maxRetryTime: retryTime,
        );

        Utils.checkResponse(this.__logLevel, response);
      } catch (e, stacktrace) {
        Utils.baasLogger(this.__logLevel, "PUT request");
        Utils.baasTrace(
          this.__logLevel,
          reqUrl,
          headers_3,
          null,
          e,
          stacktrace,
        );
        String errMessage = "";
        try {
          errMessage =
              StorageHelper.isPrem(config)
                  ? jsonDecode(response.body)["error"]
                  : StorageHelper.isPrem(config)
                  ? jsonDecode(response.body)["error"]
                  : jsonDecode(response.body)["message"];
        } catch (jsonErr) {
          errMessage = StorageErrorMessages.COMMIT_FAILED;
        }
        throw Utils.storageErrorHandler(
          response != null ? response.statusCode : 999,
          errMessage,
          stacktrace,
        );
      }

      return <String, dynamic>{
        "state": TaskState.success,
        "bytesTransferred": snapshot._totalBytes,
        "md5sum": response.headers["opc-multipart-md5"],
        "updated": response.headers["last-modified"],
        "timeCreated": response.headers["last-modified"],
        "contentType": snapshot._metadata?.contentType,
        "size": snapshot._totalBytes,
      };
    }

    return <String, dynamic>{
      "state": snapshot.state,
      "bytesTransferred": chunkIdx * chunkSize,
    };
  }
}

/// @nodoc
class DownloadTaskController {
  var _client;
  SettableMetadata? _metadata;
  globals.LogLevel __logLevel;
  int retryTime;
  final FusabaseApp app;

  DownloadTaskController({
    SettableMetadata? metadata,
    required this.app,
    required this.retryTime,
    required globals.LogLevel logLevel,
  }) : _client = createClient(app),
       __logLevel = logLevel,
       _metadata = metadata;

  /// @nodoc
  Future<void> initDownload({
    required TaskSnapshot snapshot,
    required dynamic data,
    required Reference ref,
    required DownloadTask task,
    required FusabaseStorageConfig config,
  }) async {
    dynamic response;

    String url = await ref.getDownloadURL();
    String final_url = url;
    // if (StorageHelper.isPrem(config)) {
    //   final_url = StorageHelper._PARequestURL(config) + url;
    // } else {
    //   final_url = url;
    // }
    final headers = <String, String>{};
    try {
      response = await fetchWithRetry(
        _client,
        final_url,
        headers: headers,
        maxRetryTime: retryTime,
      );
      Utils.checkResponse(this.__logLevel, response);
      await data.writeAsBytes(response.bodyBytes);
    } catch (e, stacktrace) {
      await task.__makeStateChange(TaskState.error);
      Utils.baasLogger(this.__logLevel, "GET request");
      Utils.baasTrace(this.__logLevel, final_url, headers, null, e, stacktrace);
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

    task.__makeStateChange(TaskState.success);
  }

  /// @nodoc
  Future<void> abortTask() async {
    _client.close();
  }
}
