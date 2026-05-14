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

// Common utility functions for storage
part of '../../storage.dart';

/// @nodoc
Future<http.Response> fetchWithRetry(
  http.Client client,
  String url, {
  Map<String, String>? headers,
  int maxRetryTime = 10000,
}) async {
  final start = DateTime.now();
  int delay = 200; // Initial delay
  int retries = 0;
  var response;

  Future<http.Response> fetchWithExponentialBackoff() async {
    try {
      response = await client.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return response;
      } else {
        throw Exception(
          StorageErrorMessages.format(StorageErrorMessages.EXPECTED_TYPE, [
            '200',
            response.statusCode.toString(),
          ]),
        );
      }
    } catch (error) {
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      if (elapsed > maxRetryTime) {
        return response;
      } else {
        await Future.delayed(Duration(milliseconds: delay));
        return await fetchWithExponentialBackoff();
      }
    }
  }

  return await fetchWithExponentialBackoff();
}

/// @nodoc
Future<http.Response> deleteWithRetry(
  http.Client client,
  String url, {
  Map<String, String>? headers,
  int maxRetryTime = 10000,
}) async {
  final start = DateTime.now();
  int delay = 200; // Initial delay
  int retries = 0;
  var response;

  Future<http.Response> deleteWithExponentialBackoff() async {
    try {
      response = await client.delete(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return response;
      } else {
        throw Exception(
          StorageErrorMessages.format(StorageErrorMessages.EXPECTED_TYPE, [
            '200',
            response.statusCode.toString(),
          ]),
        );
      }
    } catch (error) {
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      if (elapsed > maxRetryTime) {
        return response;
      } else {
        await Future.delayed(Duration(milliseconds: delay));
        return await deleteWithExponentialBackoff();
      }
    }
  }

  return await deleteWithExponentialBackoff();
}

/// @nodoc
Future<http.Response> postWithRetry(
  http.Client client,
  String url, {
  Map<String, String>? headers,
  Object? body,
  int maxRetryTime = 10000,
}) async {
  final start = DateTime.now();
  int delay = 200; // Initial delay
  int retries = 0;
  var response;

  Future<http.Response> postWithExponentialBackoff() async {
    try {
      response = await client.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      if (response.statusCode == 200) {
        return response;
      } else {
        throw Exception(
          StorageErrorMessages.format(StorageErrorMessages.EXPECTED_TYPE, [
            '200',
            response.statusCode.toString(),
          ]),
        );
      }
    } catch (error) {
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      if (elapsed > maxRetryTime) {
        return response;
      } else {
        await Future.delayed(Duration(milliseconds: delay));
        return await postWithExponentialBackoff();
      }
    }
  }

  return await postWithExponentialBackoff();
}

/// @nodoc
Future<http.Response> putWithRetry(
  http.Client client,
  String url, {
  Map<String, String>? headers,
  Object? body,
  int maxRetryTime = 10000,
}) async {
  final start = DateTime.now();
  int delay = 200; // Initial delay
  int retries = 0;
  var response;

  Future<http.Response> putWithExponentialBackoff() async {
    try {
      response = await client.put(Uri.parse(url), headers: headers, body: body);
      if (response.statusCode == 200) {
        return response;
      } else {
        throw Exception(
          StorageErrorMessages.format(StorageErrorMessages.EXPECTED_TYPE, [
            '200',
            response.statusCode.toString(),
          ]),
        );
      }
    } catch (error) {
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      if (elapsed > maxRetryTime) {
        return response;
      } else {
        await Future.delayed(Duration(milliseconds: delay));
        return await putWithExponentialBackoff();
      }
    }
  }

  return await putWithExponentialBackoff();
}

/// @nodoc
DateTime? parseOracleTimestamp(String input) {
  try {
    // Example: 12-DEC-25 08.53.38.107030 AM

    final regex = RegExp(
      r'^(\d{2})-([A-Z]{3})-(\d{2}) (\d{2})\.(\d{2})\.(\d{2})\.(\d{6}) (AM|PM)$',
      caseSensitive: false,
    );

    final match = regex.firstMatch(input);
    if (match == null) return null;

    final day = int.parse(match.group(1)!);
    final monthName = match.group(2)!.toUpperCase();
    final year2 = int.parse(match.group(3)!);
    final hourRaw = int.parse(match.group(4)!);
    final minute = int.parse(match.group(5)!);
    final second = int.parse(match.group(6)!);
    final micro = int.parse(match.group(7)!);
    final period = match.group(8)!.toUpperCase();

    // Convert year: 25 → 2025 (or choose rules you prefer)
    final year = 2000 + year2;

    // Convert month name to number
    const months = {
      "JAN": 1,
      "FEB": 2,
      "MAR": 3,
      "APR": 4,
      "MAY": 5,
      "JUN": 6,
      "JUL": 7,
      "AUG": 8,
      "SEP": 9,
      "OCT": 10,
      "NOV": 11,
      "DEC": 12,
    };

    final month = months[monthName];
    if (month == null) return null;

    // Convert 12-hour to 24-hour
    int hour = hourRaw % 12;
    if (period == "PM") hour += 12;

    return DateTime(year, month, day, hour, minute, second, 0, micro);
  } catch (e) {
    return null;
  }
}

/// @nodoc
DateTime? parseTimestamp(String timestamp) {
  try {
    return DateTime.parse(timestamp);
  } catch (e) {
    try {
      return HttpDate.parse(timestamp);
    } catch (e) {
      return null;
    }
  }
}

/// @nodoc
class Utils {
  static const String _redacted = '[REDACTED]';
  static final RegExp _sensitiveKeyPattern = RegExp(
    r'(authorization|authz|token|password|passwd|pwd|secret|credential|assertion|code_verifier|refresh_token|access_token|id_token|api[_-]?key|client[_-]?secret|apptrusttoken|appchecktoken)',
    caseSensitive: false,
  );
  static final RegExp _authorizationValuePattern = RegExp(
    r'\b(Basic|Bearer)\s+[-._~+/=A-Za-z0-9]+',
    caseSensitive: false,
  );
  static final RegExp _jwtPattern = RegExp(
    r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]*',
  );

  static bool _isSensitiveKey(dynamic key) {
    return key != null && _sensitiveKeyPattern.hasMatch(key.toString());
  }

  static dynamic _redactForLog(dynamic value, [dynamic key]) {
    if (_isSensitiveKey(key)) {
      return _redacted;
    }
    if (value == null || value is num || value is bool) {
      return value;
    }
    if (value is http.Response) {
      return <String, dynamic>{
        'statusCode': value.statusCode,
        'reasonPhrase': value.reasonPhrase,
        'headers': _redactForLog(value.headers),
        'body': _redacted,
      };
    }
    if (value is Map) {
      return value.map((dynamic mapKey, dynamic mapValue) {
        return MapEntry(mapKey, _redactForLog(mapValue, mapKey));
      });
    }
    if (value is List<int>) {
      return '[REDACTED ${value.length} bytes]';
    }
    if (value is Iterable) {
      return value.map((dynamic item) => _redactForLog(item)).toList();
    }
    if (value is Uri) {
      return _redactString(value.toString());
    }
    if (value is String) {
      return _redactString(value);
    }
    return _redactString(value.toString());
  }

  static String _redactString(String value) {
    dynamic decoded;
    try {
      decoded = jsonDecode(value);
    } catch (_) {
      decoded = null;
    }
    if (decoded is Map || decoded is List) {
      return jsonEncode(_redactForLog(decoded));
    }

    var redacted = value.replaceAllMapped(_authorizationValuePattern, (match) {
      return '${match.group(1)} $_redacted';
    });
    redacted = redacted.replaceAllMapped(_jwtPattern, (_) => _redacted);
    redacted = redacted.replaceAllMapped(
      RegExp(
        r'(?i)\b(authorization|authz|token|password|passwd|pwd|secret|credential|assertion|code_verifier|refresh_token|access_token|id_token|apiKey|api_key|client_secret)=([^&\s,}]+)',
      ),
      (match) => '${match.group(1)}=$_redacted',
    );
    return redacted;
  }

  static dynamic _redactPayloadForLog(dynamic data) {
    if (data == null) {
      return null;
    }
    if (data is List<int>) {
      return '[REDACTED payload: ${data.length} bytes]';
    }
    return '[REDACTED payload]';
  }

  static FusabaseException storageErrorHandler(
    int status,
    String message,
    StackTrace? stacktrace,
  ) {
    dynamic code = "storage/";
    if (status == 999) {
      code += 'AbortError';
    } else if (status == 400) {
      code += 'invalid-argument';
    } else if (status == 401) {
      code += 'unauthenticated';
    } else if (status == 404) {
      code += 'not-found';
    } else if (status == 403) {
      code += 'permission-denied';
    } else if (status == 500) {
      code += 'internal';
    } else if (status == 501) {
      code += 'not-implemented';
    } else if (status == 499) {
      code += 'aborted';
    } else {
      code += 'unknown';
    }
    FusabaseException e = FusabaseException(
      code: code,
      message: message,
      name: "FusabaseStorageError",
      stackTrace: stacktrace,
    );
    return e;
  }

  static void baasLogger(globals.LogLevel logLevel, dynamic data) {
    if (logLevel == globals.LogLevel.error) {
      inspect(_redactForLog(data));
    }
  }

  static void baasTrace(
    globals.LogLevel logLevel,
    dynamic reqUrl,
    dynamic headers,
    dynamic data,
    dynamic e,
    dynamic stackTrace,
  ) {
    if (logLevel == globals.LogLevel.error) {
      inspect(_redactForLog(reqUrl));
      inspect(_redactForLog(headers));
      inspect(_redactPayloadForLog(data));
      inspect(_redactForLog(e));
      inspect(_redactForLog(stackTrace.toString()));
    }
  }

  static void checkResponse(globals.LogLevel logLevel, http.Response response) {
    if (response == null) {
      throw Exception(StorageErrorMessages.VALUE_CANNOT_BE_NULL);
    }
    if (response.statusCode < 200 || response.statusCode > 299) {
      Utils.baasLogger(logLevel, response);
      throw Exception(
        StorageErrorMessages.format(StorageErrorMessages.EXPECTED_TYPE, [
          '200-299',
          response.statusCode.toString(),
        ]),
      );
    }
  }
}
