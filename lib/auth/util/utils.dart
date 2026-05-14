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

part of "../../auth.dart";

/// @nodoc
String NOT_IMPLEMENTED_ERROR =
    AuthErrorMessageTemplates.METHOD_NOT_SUPPORTED_ONPREM;

/// @nodoc
String NOT_IMPLEMENTED_ERROR_IDCS =
    AuthErrorMessageTemplates.METHOD_NOT_SUPPORTED_IDCS;

/// @nodoc
dynamic parseToInt(dynamic input) {
  if (input is double) {
    return input.toInt();
  } else if (input is int) {
    return input;
  } else {
    throw ArgumentError(
      AuthErrorMessageTemplates.format(
        AuthErrorMessageTemplates.INVALID_TYPE_PARAM,
        ['input', 'int, double', input.runtimeType.toString()],
      ),
    );
  }
}

/// @nodoc
BigInt customMod(BigInt value, BigInt modulus) {
  BigInt result = value % modulus;
  if (result < BigInt.zero) {
    result += modulus;
  }
  return result;
}

/// @nodoc
BigInt modPow(BigInt base, BigInt exponent, BigInt modulus) {
  if (modulus == BigInt.one) return BigInt.zero;

  BigInt result = BigInt.one;
  base = customMod(base, modulus);

  while (exponent > BigInt.zero) {
    if (customMod(exponent, BigInt.two) == BigInt.one) {
      result = customMod(result * base, modulus);
    }
    exponent = exponent >> 1;
    base = customMod(base * base, modulus);
  }

  return result;
}

/// @nodoc
String convertIatToTimestamp(dynamic timestamp) {
  timestamp = parseToInt(timestamp);
  // Convert to a DateTime object
  final date = DateTime.fromMillisecondsSinceEpoch(
    timestamp * 1000,
    isUtc: true,
  );

  // Format the date components
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hours = date.hour.toString().padLeft(2, '0');
  final minutes = date.minute.toString().padLeft(2, '0');
  final seconds = date.second.toString().padLeft(2, '0');
  final milliseconds = date.millisecond.toString().padLeft(3, '0');
  final microseconds = '000000'; // Dart DateTime does not support microseconds

  // Combine the components into the desired format
  return '$year-$month-${day}T${hours}:${minutes}:${seconds}.${milliseconds}${microseconds}';
}

/// @nodoc
String convertOCITimeToTimestampString(String timestampString) {
  // Convert to a DateTime object
  final date = DateTime.parse(timestampString).toUtc();

  // Format the date components
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hours = date.hour.toString().padLeft(2, '0');
  final minutes = date.minute.toString().padLeft(2, '0');
  final seconds = date.second.toString().padLeft(2, '0');
  final milliseconds = date.millisecond.toString().padLeft(3, '0');
  final microseconds = '000000'; // Dart DateTime does not support microseconds

  // Combine the components into the desired format
  return '$year-$month-${day}T${hours}:${minutes}:${seconds}.${milliseconds}${microseconds}';
}

/// @nodoc
DateTime parseIntToDateTime(dynamic n) {
  n = parseToInt(n);
  return DateTime.fromMillisecondsSinceEpoch(n * 1000, isUtc: true);
}

/// @nodoc
DateTime? parseTimestampString(String? timestampString) {
  if (timestampString == null || timestampString.length < 27) {
    return null;
  }
  timestampString = timestampString.substring(0, timestampString.length - 1);
  final datePart = timestampString.substring(0, 10);
  final timePart = timestampString.substring(11, 19);
  final microsecondsPart = timestampString.substring(20);
  final dateTime = DateTime.parse('$datePart $timePart');
  final microseconds = int.parse(microsecondsPart);
  return dateTime.add(Duration(microseconds: microseconds));
}

/// @nodoc
class AuthUtils {
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

  static FusabaseAuthException authErrorHandler({
    required int status,
    required String message,
    String? authType,
    dynamic stackTrace,
  }) {
    String code = "auth/";

    if (status == globals.ErrorMap[globals.ErrorCode.INVALID_ARGS]) {
      code += 'argument-error';
    } else if (status == globals.ErrorMap[globals.ErrorCode.INVALID_USER_TOK]) {
      code += 'invalid-user-token';
    } else if (status == globals.ErrorMap[globals.ErrorCode.NOT_FOUND]) {
      code += 'user-not-found';
    } else if (status == globals.ErrorMap[globals.ErrorCode.WRONG_PASSWORD]) {
      code += 'wrong-password';
    } else if (status == globals.ErrorMap[globals.ErrorCode.POPUP_BLOCKED]) {
      code += 'popup-blocked';
    } else if (status == globals.ErrorMap[globals.ErrorCode.SERVER_ERROR]) {
      code += 'internal';
    } else if (status == globals.ErrorMap[globals.ErrorCode.NOT_IMPLEMENT]) {
      code += 'not-implemented';
    } else if (status == globals.ErrorMap[globals.ErrorCode.UNAVAILABLE]) {
      code += 'unavailable';
    } else if (status == globals.ErrorMap[globals.ErrorCode.OPR_NOT_ALLOWED]) {
      code += 'operation-not-allowed';
    } else {
      code += 'unknown';
    }

    FusabaseAuthException error = FusabaseAuthException(
      code: code,
      message: message,
      authType: authType,
      stackTrace: stackTrace,
      name: "AuthError",
    );

    return error;
  }

  static void baasLogger(globals.LogLevel logLevel, dynamic data) {
    if (logLevel == globals.LogLevel.error) {
      print(_redactForLog(data));
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
      print(_redactForLog(reqUrl));
      print(_redactForLog(headers));
      print(_redactPayloadForLog(data));
      print(_redactForLog(e));
      print(_redactForLog(stackTrace.toString()));
    }
  }

  static Map<String, dynamic> parseJwt(String token) {
    List<String> segments = token.split('.');

    if (segments.length != 3) {
      String errMessage = AuthErrorMessageTemplates.format(
        AuthErrorMessageTemplates.INVALID_PARAM,
        ['JWT token'],
      );
      throw AuthUtils.authErrorHandler(
        status: globals.ErrorMap[globals.ErrorCode.INVALID_ARGS] ?? 999,
        message: errMessage,
      );
    }

    String body = _btoa(segments[1]);
    dynamic bodyMap = json.decode(body);

    if (bodyMap is! Map<String, dynamic>) {
      String errMessage = AuthErrorMessageTemplates.format(
        AuthErrorMessageTemplates.INVALID_PARAM,
        ['body'],
      );
      throw AuthUtils.authErrorHandler(
        status: globals.ErrorMap[globals.ErrorCode.INVALID_ARGS] ?? 999,
        message: errMessage,
      );
    }
    return bodyMap;
  }

  static String _btoa(String val) {
    String out = val.replaceAll('-', '+').replaceAll('_', '/');

    if (out.length % 4 == 2) {
      out += '==';
    } else if (out.length % 4 == 3) {
      out += '=';
    } else if (out.length % 4 != 0) {
      String errMessage = AuthErrorMessageTemplates.format(
        AuthErrorMessageTemplates.INVALID_PARAM,
        ['base64url string'],
      );
      throw AuthUtils.authErrorHandler(
        status: globals.ErrorMap[globals.ErrorCode.INVALID_ARGS] ?? 999,
        message: errMessage,
      );
    }

    return utf8.decode(base64Url.decode(out));
  }

  static void checkResponse(globals.LogLevel logLevel, http.Response response) {
    if (response.statusCode < 200 || response.statusCode > 299) {
      AuthUtils.baasLogger(logLevel, response);
      throw Exception(
        AuthErrorMessageTemplates.format(
              AuthErrorMessageTemplates.INVALID_PARAM,
              ['response'],
            ) +
            ' -> ${response.statusCode}',
      );
    }
  }
}

/// @nodoc
Future<String> generateHash(String input) async {
  final bytes = utf8.encode(input);
  final base64Str = base64Url.encode(bytes);
  return base64Str;
}

/// @nodoc
Future<BigInt> encodeToBigInt(String text) async {
  final hex = await generateHash(text);
  return BigInt.parse('0x$hex');
}

/// @nodoc
String generateSalt() {
  final lengthInBytes = 128 ~/ 8;
  final random = Random.secure();
  final array = List<int>.generate(lengthInBytes, (_) => random.nextInt(256));
  return array.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}

/// @nodoc
BigInt generateRandomBigInteger(int bits) {
  final bytes = bits ~/ 8;
  final random = Random.secure();
  final buffer = List<int>.generate(bytes, (_) => random.nextInt(256));
  return BigInt.parse(
    buffer.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(),
    radix: 16,
  );
}
