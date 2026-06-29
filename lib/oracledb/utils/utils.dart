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
Map<String, int> OracledbVersion = {"VERSION_1": 1, "VERSION_2": 2};

Map<String, dynamic> whereOperators = {
  "isEqualTo": "=",
  "isNotEqualTo": "!=",
  "isLessThan": "<",
  "isLessThanOrEqualTo": "<=",
  "isGreaterThan": ">",
  "isGreaterThanOrEqualTo": ">=",
  "arrayContains": "array-contains",
  "arrayContainsAny": "array-contains-any",
  "whereIn": "in",
  "whereNotIn": "not in",
  "isNull": "is NULL",
};

/// @nodoc
String identifyValueType(dynamic value) {
  if (value == null) {
    return "nullValue";
  } else if (value is bool) {
    return "booleanValue";
  } else if (value is int) {
    return "integerValue";
  } else if (value is double) {
    return "doubleValue";
  } else if (value is String) {
    final isoTimestampRegex = RegExp(
      r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}$',
    );
    return isoTimestampRegex.hasMatch(value) ? "timestampValue" : "stringValue";
  } else if (value is List) {
    return "arrayValue";
  } else if (value is Uint8List || value is ByteBuffer) {
    return "bytesValue";
  } else if (value is Map<String, dynamic>) {
    return "mapValue";
  } else {
    return "unknownValue";
  }
}

/// @nodoc
void validateDenseVector(
  dynamic values, [
  String message = 'Dense vector must be a numeric array.',
]) {
  if (values is! List ||
      values.any(
        (value) => value is! num || (value is double && value.isNaN),
      )) {
    throw Utils.oracledbErrorHandler(400, message, null);
  }
}

/// @nodoc
void validateSparseEmbedding(Map<String, dynamic> sparse) {
  final dimension = sparse['dimension'];
  final indices = sparse['indices'];
  final values = sparse['values'];

  if (dimension is! int || dimension <= 0) {
    throw Utils.oracledbErrorHandler(
      400,
      'Sparse embedding dimension must be an integer greater than 0.',
      null,
    );
  }

  validateDenseVector(
    indices,
    'Sparse embedding indices must be a numeric array.',
  );
  validateDenseVector(
    values,
    'Sparse embedding values must be a numeric array.',
  );

  if (indices.length != values.length) {
    throw Utils.oracledbErrorHandler(
      400,
      'Sparse embedding indices and values must have the same length.',
      null,
    );
  }
}

/// @nodoc
void validateVectorSearchQuery(Map<String, dynamic> query) {
  final hasDense = query['vector'] is List;
  final hasSparse = query['sparse'] is Map<String, dynamic>;

  if ((hasDense && hasSparse) || (!hasDense && !hasSparse)) {
    throw Utils.oracledbErrorHandler(
      400,
      'Vector search query must contain exactly one of query.vector or query.sparse.',
      null,
    );
  }

  if (hasDense) {
    validateDenseVector(
      query['vector'],
      'Vector search query.vector must be a numeric array.',
    );
  }

  if (hasSparse) {
    validateSparseEmbedding(Map<String, dynamic>.from(query['sparse']));
  }
}

/// @nodoc
bool checkOracledbApiVersion(FusabaseOptions options, int version) {
  return options.useOracledbVersion == version;
}

/// @nodoc
dynamic deepClone(dynamic value) {
  if (value == null ||
      value is num ||
      value is bool ||
      value is String ||
      value is FieldValue ||
      value is Timestamp) {
    return value;
  }
  if (value is List) {
    return value.map((e) => deepClone(e)).toList();
  }
  if (value is Map) {
    final Map<String, dynamic> out = {};
    for (final k in value.keys) {
      out[k] = deepClone(value[k]);
    }
    return out;
  }

  // Fallback: try JSON encode/decode for plain objects that are encodable.
  try {
    return jsonDecode(jsonEncode(value));
  } catch (e) {
    // As a last resort, return the original (can't deep clone unknown object).
    return value;
  }
}

/// @nodoc
bool isDualityView(dynamic obj) {
  return obj.type == "dualityviewdocument" ||
      obj.type == "dualityviewcollection";
}

dynamic rearrangeBodyOfVersion2(dynamic body) {
  dynamic res = [];

  for (int i = 0; i < body.length; i++) {
    if (body[i]['op'] == 'servertimestamp') {
      res.add(body[i]);
    }
  }

  for (int i = 0; i < body.length; i++) {
    if (body[i]['op'] != 'servertimestamp' &&
        body[i]['op'] != 'arrayUnion' &&
        body[i]['op'] != 'arrayRemove') {
      res.add(body[i]);
    }
  }

  for (int i = 0; i < body.length; i++) {
    if (body[i]['op'] == 'arrayUnion' || body[i]['op'] == 'arrayRemove') {
      res.add(body[i]);
    }
  }

  return res;
}

dynamic parseUint8ListToJson(Uint8List data) {
  String jsonString = utf8.decode(data);
  return jsonDecode(jsonString);
}

/// @nodoc
int getTotalBytesOfJson(Map<String, dynamic> jsonObject) {
  String jsonString = jsonEncode(jsonObject);
  Uint8List encodedData = utf8.encode(jsonString);
  return encodedData.lengthInBytes;
}

/// @nodoc
String generateRandomString(int len) {
  var r = Random();
  const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  return List.generate(len, (index) => _chars[r.nextInt(_chars.length)]).join();
}

/// @nodoc
int createHashFromJson(Map<String, dynamic> jsonObject) {
  var jsonString = jsonEncode(jsonObject);
  return jsonString.hashCode;
}

/// @nodoc
DateTime convertToDateTime(String dateStr) {
  return DateTime.parse(dateStr);
}

/// @nodoc
String generateRandomHash() {
  var random = Random.secure();
  var values = List<int>.generate(32, (i) => random.nextInt(256));
  return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// @nodoc
int? parseToInt(dynamic value) {
  if (value is int) {
    return value;
  } else if (value is double) {
    return value.toInt();
  } else if (value is String) {
    return int.tryParse(value);
  } else {
    return null;
  }
}

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
// String? getAccessTokenFast(dynamic auth) {
//   String? accessToken;
//   try {
//     accessToken = auth.currentUser?.getFUSABASETokenFast();
//   } catch (e) {
//     accessToken = null;
//   }
//   return accessToken;
// }

/// @nodoc
String escapeFieldName(String field) {
  if (field.startsWith('"') && field.endsWith('"')) {
    return field;
  }
  if (field.contains('.')) {
    return '"$field"';
  }
  return field;
}

/// @nodoc
List<dynamic> updateFieldsWithQuotes(List<dynamic> arr) {
  return arr.map((item) {
    if (item is Map && item.containsKey("field") && item["field"] is String) {
      return {...item, "field": escapeFieldName(item["field"])};
    }
    return item;
  }).toList();
}

/// @nodoc
dynamic parseTimestamp(dynamic obj) {
  if (obj == null) return null;

  if (obj is Timestamp) {
    return obj.toTimestampString();
  } else if (obj is List) {
    return obj.map((item) => parseTimestamp(item)).toList();
  } else if (obj is Map<String, dynamic>) {
    return obj.map((key, value) => MapEntry(key, parseTimestamp(value)));
  } else {
    return obj;
  }
}

/// @nodoc
dynamic parseTimeInDocument(dynamic obj) {
  if (obj == null) return null;

  // Match: YYYY-MM-DDTHH:MM:SS.ffffff OR YYYY-MM-DDTHH:MM:SS
  final timestampPatternFull = RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}$',
  );
  final timestampPatternNoFraction = RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$',
  );

  if (obj is String &&
      (timestampPatternFull.hasMatch(obj) ||
          timestampPatternNoFraction.hasMatch(obj))) {
    return Timestamp.fromTimestampString(obj);
  }

  if (obj is List) {
    return obj.map((item) => parseTimeInDocument(item)).toList();
  }

  if (obj is Map<String, dynamic>) {
    return obj.map((key, value) => MapEntry(key, parseTimeInDocument(value)));
  }

  return obj;
}

/// @nodoc
bool compareValues(dynamic x, dynamic y) {
  bool arraysEqual(List arr1, List arr2) {
    if (arr1.length != arr2.length) return false;
    for (int i = 0; i < arr1.length; i++) {
      if (!compareValues(arr1[i], arr2[i])) return false;
    }
    return true;
  }

  if (x is List && y is List) {
    return arraysEqual(x, y);
  }

  return x == y;
}

/// @nodoc
bool checkForFieldValue(dynamic obj, String method) {
  if (obj == null) {
    return false;
  }
  if (obj is FieldValue) {
    if (obj.operation == 'FieldValue:delete' && method == 'set') {
      throw Utils.oracledbErrorHandler(
        400,
        OracledbErrorMessages.deleteFieldNotAllowedInSet,
        null,
      );
    }
    return true;
  } else if (obj is Map) {
    for (final key in obj.keys) {
      if (checkForFieldValue(obj[key], method)) {
        return true;
      }
    }
  }
  return false;
}

/// @nodoc
Map<String, dynamic> convertMap(Map<Object, Object?> original) {
  final result = <String, dynamic>{};

  for (var entry in original.entries) {
    final key = entry.key;
    final value = entry.value;

    String stringKey;
    if (key is FieldPath) {
      stringKey = key.toString(); // Convert FieldPath to String
    } else if (key is String) {
      stringKey = key;
    } else {
      stringKey = key.toString(); // Fallback for other types
    }

    result[stringKey] = value;
  }

  return result;
}

/// @nodoc
Map<String, dynamic> updateNestedData(
  dynamic query,
  dynamic oldData,
  dynamic updates,
) {
  final newData = deepClone(oldData) as Map<String, dynamic>;

  final flatUpdates = flattenUpdates(updates);

  flatUpdates.forEach((rawKey, value) {
    var key = rawKey;

    if (key.contains(r'$FieldPath$')) {
      key = key.substring(11);
      setNestedValue(
        query,
        newData,
        oldData,
        key.split('#FieldPath#'),
        value,
        true,
      );
    } else {
      setNestedValue(query, newData, oldData, key.split('.'), value, true);
    }
  });

  return newData;
}

/// @nodoc
Map<String, dynamic> setWholeData(
  dynamic query,
  dynamic oldData,
  dynamic updates,
  bool flag,
) {
  final newData = deepClone(oldData) as Map<String, dynamic>;

  final flatUpdates = flattenUpdates(updates);

  flatUpdates.forEach((rawKey, value) {
    var key = rawKey;

    if (key.contains(r'$FieldPath$')) {
      key = key.substring(11);
      setNestedValue(
        query,
        newData,
        oldData,
        key.split('#FieldPath#'),
        value,
        flag,
      );
    } else {
      setNestedValue(query, newData, oldData, key.split('.'), value, flag);
    }
  });

  return newData;
}

/// @nodoc
Map<String, dynamic> flattenMixedUpdates(
  Map<String, dynamic> map, [
  String parentKey = '',
]) {
  final result = <String, dynamic>{};

  map.forEach((key, value) {
    final fullKey = parentKey.isEmpty ? key : '$parentKey.$key';

    if (value is Map<String, dynamic> &&
        !value.keys.any((k) => k.contains('.'))) {
      result.addAll(flattenMixedUpdates(value, fullKey));
    } else {
      result[fullKey] = value;
    }
  });

  return result;
}

/// @nodoc
void setNestedValue(
  dynamic query,
  dynamic obj,
  dynamic oldData,
  List<String> pathArray,
  dynamic value,
  bool flag,
) {
  dynamic current = obj;
  dynamic oldCurrent = oldData;

  // walk until second-last key
  for (int i = 0; i < pathArray.length - 1; i++) {
    final key = pathArray[i];

    if (!current.containsKey(key) || current[key] is! Map) {
      current[key] = <String, dynamic>{};
    }
    if (!oldCurrent.containsKey(key) || oldCurrent[key] is! Map) {
      oldCurrent[key] = <String, dynamic>{};
    }

    current = current[key];
    oldCurrent = oldCurrent[key];
  }

  final finalKey = pathArray.last;
  final existingValue = oldCurrent[finalKey];

  // JS-compatible sKey builder
  String sKey = finalKey;
  if (flag) {
    final buffer = StringBuffer();
    for (int i = 0; i < pathArray.length - 1; i++) {
      buffer.write(escapeFieldName(pathArray[i]));
      buffer.write('.');
    }
    buffer.write(escapeFieldName(finalKey));
    sKey = buffer.toString();
  }

  // FieldValue logic identical to JS
  if (value is FieldValue) {
    if (value.operation == 'FieldValue:delete') {
      current.remove(finalKey);
      return;
    }

    if (flag && value.operation == 'FieldValue:serverTimestamp') {
      if (query != null) {
        (query._serverTimestamp as List).add(sKey);
      }
    } else {
      current[finalKey] = updateUsingFieldValue(finalKey, oldCurrent, value);
    }

    return;
  }

  // primitive or list
  current[finalKey] = value;
}

/// @nodoc
Map<String, dynamic> _deepCopy(Map<String, dynamic> original) {
  final copy = <String, dynamic>{};

  original.forEach((key, value) {
    if (value is FieldValue) {
      copy[key] = value; // leave FieldValue untouched
    } else if (value is Map) {
      copy[key] = _deepCopy(Map<String, dynamic>.from(value));
    } else if (value is List) {
      copy[key] = _deepCopyList(value);
    } else {
      copy[key] = value;
    }
  });

  return copy;
}

/// @nodoc
List<dynamic> _deepCopyList(List<dynamic> original) {
  return original.map((item) {
    if (item is FieldValue) {
      return item; // leave FieldValue untouched
    } else if (item is Map) {
      return _deepCopy(Map<String, dynamic>.from(item));
    } else if (item is List) {
      return _deepCopyList(item);
    } else {
      return item;
    }
  }).toList();
}

/// @nodoc
List<String> flattenArray(List<String> arr) {
  return arr.fold<List<String>>([], (result, str) {
    result.addAll(str.split('.'));
    return result;
  });
}

/// @nodoc
dynamic updateUsingFieldValue(
  String key,
  Map<String, dynamic> oldData,
  FieldValue fieldValue,
) {
  final op = fieldValue.operation;
  dynamic oldValue = oldData[key];
  dynamic newValue;

  switch (op) {
    case 'FieldValue:arrayRemove':
      // JS: if old is NOT array → return []
      if (oldValue is! List) {
        return <dynamic>[];
      }

      newValue = <dynamic>[];
      try {
        for (var item in oldValue) {
          if (!(fieldValue.value as List).contains(item)) {
            newValue.add(item);
          }
        }
      } catch (e) {
        newValue = <dynamic>[];
      }
      break;

    case 'FieldValue:arrayUnion':
      // JS: if old is NOT array → return provided list
      if (oldValue is! List) {
        return List.from(fieldValue.value as List);
      }

      // JS: clone existing array first
      newValue = List.from(oldValue);

      // JS: append unique items
      for (var element in (fieldValue.value as List)) {
        if (!newValue.contains(element)) {
          newValue.add(element);
        }
      }
      break;

    case 'FieldValue:increment':
      // JS: only increment if old is integer
      if (oldValue is int) {
        newValue = oldValue + (fieldValue.value as int);
      } else {
        // JS: if old missing or not integer → set to increment value
        newValue = fieldValue.value;
      }
      break;

    default:
      newValue = null;
  }

  return newValue;
}

/// @nodoc
bool deepEqual(dynamic a, dynamic b) {
  if (identical(a, b)) return true;

  if (a.runtimeType != b.runtimeType) return false;

  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!deepEqual(a[i], b[i])) return false;
    }
    return true;
  }

  if (a is Map && b is Map) {
    if (a.length != b.length) return false;

    for (var key in a.keys) {
      if (!b.containsKey(key) || !deepEqual(a[key], b[key])) return false;
    }
    return true;
  }

  return a == b;
}

bool containsFieldValueDeep(dynamic value) {
  if (value is FieldValue) return true;
  if (value is Timestamp) return false;
  if (value is List) return false;
  if (value == null || value is! Map) return false;

  for (final v in value.values) {
    if (containsFieldValueDeep(v)) return true;
  }
  return false;
}

bool isDenseEmbeddingObject(dynamic value) {
  return value is Map<String, dynamic> &&
      value['type'] == 'dense' &&
      value['values'] is List;
}

bool isSparseEmbeddingObject(dynamic value) {
  return value is Map<String, dynamic> && value['type'] == 'sparse';
}

bool isEmbeddingInput(dynamic value) {
  return isDenseEmbeddingObject(value) || isSparseEmbeddingObject(value);
}

Map<String, dynamic> extractEmbeddingOps(Map<String, dynamic> input) {
  final setMap = <String, dynamic>{};
  final deleteKeys = <String>[];

  for (final entry in input.entries) {
    final key = entry.key;
    final value = entry.value;

    if (value is FieldValue && value.operation == 'FieldValue:deleteVector') {
      deleteKeys.add(key);
      continue;
    }

    if (!isEmbeddingInput(value)) {
      continue;
    }

    if (isDenseEmbeddingObject(value)) {
      validateDenseVector(
        value['values'],
        "Embedding '$key.values' must be a numeric array.",
      );
      setMap[key] = deepClone(value);
      continue;
    }

    if (isSparseEmbeddingObject(value)) {
      validateSparseEmbedding(Map<String, dynamic>.from(value));
      setMap[key] = deepClone(value);
    }
  }

  return {'setMap': setMap, 'deleteKeys': deleteKeys};
}

/// @nodoc
Map<String, dynamic> extractEmbeddingsMapForCreate(dynamic input) {
  final ops = extractEmbeddingOps(Map<String, dynamic>.from(input ?? {}));
  final deleteKeys = List<String>.from(ops['deleteKeys'] as List);
  if (deleteKeys.isNotEmpty) {
    throw Utils.oracledbErrorHandler(
      400,
      'deleteVector() is not supported in addDoc/set create payload. Use update/set merge contexts.',
      null,
    );
  }
  return Map<String, dynamic>.from(ops['setMap'] as Map);
}

/// @nodoc
List<Map<String, dynamic>> createPayloadForUpdateVersion2New(
  dynamic query,
  Map<String, dynamic> input,
  bool merge, [
  String parentKey = '',
]) {
  final List<Map<String, dynamic>> result = [];
  if (parentKey.isEmpty) {
    final ops = extractEmbeddingOps(Map<String, dynamic>.from(input));
    final setMap = Map<String, dynamic>.from(ops['setMap'] as Map);
    final deleteKeys = List<String>.from(ops['deleteKeys'] as List);

    if (setMap.isNotEmpty) {
      result.add({
        'field': r'$embeddings',
        'value': setMap,
        'op': 'set',
        'valueType': 'mapValue',
      });
    }
    if (deleteKeys.isNotEmpty) {
      result.add({
        'field': r'$embeddings',
        'value': deleteKeys,
        'op': 'delete',
        'valueType': 'arrayValue',
      });
    }

    input = Map<String, dynamic>.fromEntries(
      input.entries.where(
        (entry) =>
            !setMap.containsKey(entry.key) &&
            !(entry.value is FieldValue &&
                entry.value.operation == 'FieldValue:deleteVector'),
      ),
    );
  }
  final Set<String> seenParents = {};

  void walk(Map<String, dynamic> obj, String prefix) {
    for (final String key1 in obj.keys) {
      String key = key1;
      final dynamic value = obj[key];

      final bool containFieldPath = key.contains(r'$FieldPath$');
      key = key.replaceAll(r'$FieldPath$', '');

      final List<String> xx = key.split('#FieldPath#');

      String fullKey = '';
      for (int i = 0; i < xx.length - 1; i++) {
        fullKey += '${escapeFieldName(xx[i])}.';
      }

      fullKey += containFieldPath ? escapeFieldName(xx.last) : xx.last;

      fullKey = prefix.isNotEmpty ? '$prefix.$fullKey' : fullKey;
      final String wrappedKey = fullKey;

      final bool isFirstLevel = prefix == parentKey;

      // --------------------------------------------------
      // CASE 1: Object (map)
      // --------------------------------------------------
      if (value is Map<String, dynamic> && value is! Timestamp) {
        final bool hasFieldValue = containsFieldValueDeep(value);

        // ✅ FIRST LEVEL + NO FIELDVALUE → PUSH WHOLE OBJECT
        if (isFirstLevel && !hasFieldValue) {
          result.add({
            'field': wrappedKey,
            'value': value,
            'op': 'set',
            'valueType': 'mapValue',
          });
          continue;
        }

        // ✅ FIRST LEVEL + FIELDVALUE → EMPTY MAP ONCE
        if (isFirstLevel && hasFieldValue && !seenParents.contains(fullKey)) {
          seenParents.add(fullKey);
          result.add({
            'field': wrappedKey,
            'value': {},
            'op': 'set',
            'valueType': 'mapValue',
          });
        }

        // Recurse only if FieldValue exists
        if (hasFieldValue) {
          walk(value, fullKey);
        }

        continue;
      }

      // --------------------------------------------------
      // CASE 2: FieldValue
      // --------------------------------------------------
      if (value is FieldValue) {
        String op = value.operation.replaceAll('FieldValue:', '').trim();
        dynamic val = value.value;

        if (op == 'serverTimestamp') {
          op = 'servertimestamp';
        }

        if (op == 'servertimestamp' && merge) {
          query._serverTimestamp.add(fullKey);
          continue;
        }

        if (op == 'arrayUnion' || op == 'arrayRemove') {
          if (val is! List) {
            val = [val];
          }
        }

        if (op == 'delete') {
          val = null;
        }

        result.add({
          'field': wrappedKey,
          'value': val,
          'op': op,
          'valueType': identifyValueType(val),
        });

        continue;
      }

      // --------------------------------------------------
      // CASE 3: Primitive / List
      // --------------------------------------------------
      result.add({
        'field': wrappedKey,
        'value': value,
        'op': 'set',
        'valueType': identifyValueType(value),
      });
    }
  }

  walk(input, parentKey);
  return result;
}

/// @nodoc
List<Map<String, dynamic>> serializeVersion2(
  dynamic query,
  Map<String, dynamic> input,
  bool merge, [
  String parentKey = '',
]) {
  final List<Map<String, dynamic>> result = [];
  if (parentKey.isEmpty) {
    final ops = extractEmbeddingOps(Map<String, dynamic>.from(input));
    final setMap = Map<String, dynamic>.from(ops['setMap'] as Map);
    final deleteKeys = List<String>.from(ops['deleteKeys'] as List);

    if (setMap.isNotEmpty) {
      result.add({
        'field': r'$embeddings',
        'value': setMap,
        'op': 'set',
        'valueType': 'mapValue',
      });
    }
    if (deleteKeys.isNotEmpty) {
      result.add({
        'field': r'$embeddings',
        'value': deleteKeys,
        'op': 'delete',
        'valueType': 'arrayValue',
      });
    }

    input = Map<String, dynamic>.fromEntries(
      input.entries.where(
        (entry) =>
            !setMap.containsKey(entry.key) &&
            !(entry.value is FieldValue &&
                entry.value.operation == 'FieldValue:deleteVector'),
      ),
    );
  }

  for (final String key in input.keys) {
    final dynamic value = input[key];

    String fullKey = parentKey.isNotEmpty ? '$parentKey.$key' : key;

    // ---------------- FieldPath handling ----------------
    bool containFieldPath = fullKey.contains(r'$FieldPath$');
    fullKey = fullKey.replaceAll(r'$FieldPath$', '');

    final List<String> xx = fullKey.split('#FieldPath#');
    fullKey = '';

    for (int i = 0; i < xx.length - 1; i++) {
      fullKey += '${escapeFieldName(xx[i])}.';
    }

    if (containFieldPath) {
      fullKey += escapeFieldName(xx.last);
    } else {
      fullKey += xx.last;
    }

    // ---------------- null ----------------
    if (value == null) {
      result.add({
        'field': fullKey,
        'value': null,
        'op': 'set',
        'valueType': 'null',
      });
      continue;
    }

    // ---------------- FieldValue ----------------
    if (value is FieldValue) {
      String op = value.operation.replaceAll('FieldValue:', '');
      if (op == 'serverTimestamp') {
        op = 'servertimestamp';
      }

      dynamic val = value.value;

      if (op == 'servertimestamp' && !merge) {
        query._serverTimestamp.add(fullKey);
      } else {
        if (op == 'arrayUnion' || op == 'arrayRemove') {
          if (val is! List) {
            val = [val];
          }
        }

        if (op == 'servertimestamp' || op == 'delete') {
          val = null;
        }

        result.add({
          'field': fullKey,
          'value': val,
          'op': op,
          'valueType': identifyValueType(val),
        });
      }
      continue;
    }

    // ---------------- Timestamp ----------------
    if (value is Timestamp) {
      final String timestamp = value.toTimestampString();

      result.add({
        'field': fullKey,
        'value': timestamp,
        'op': 'set',
        'valueType': identifyValueType(timestamp),
      });
      continue;
    }

    // ---------------- Object (non-array) ----------------
    if (value is Map<String, dynamic>) {
      // Empty object
      if (value.isEmpty) {
        result.add({
          'field': fullKey,
          'value': <String, dynamic>{},
          'op': 'set',
          'valueType': 'object',
        });
        continue;
      }

      final Map<String, dynamic> normalFields = {};
      final List<Map<String, dynamic>> specialFields = [];

      for (final String innerKey in value.keys) {
        final dynamic innerValue = value[innerKey];

        if (innerValue is FieldValue) {
          String op = innerValue.operation.replaceAll('FieldValue:', '');
          dynamic val = innerValue.value;

          if (op == 'arrayUnion' || op == 'arrayRemove') {
            if (val is! List) {
              val = [val];
            }
          }

          if (op == 'servertimestamp' || op == 'delete') {
            val = null;
          }

          specialFields.add({
            'field': '$fullKey.$innerKey',
            'value': val,
            'op': op,
            'valueType': identifyValueType(val),
          });
        } else {
          normalFields[innerKey] = innerValue;
        }
      }

      if (normalFields.isNotEmpty) {
        result.add({
          'field': fullKey,
          'value': normalFields,
          'op': 'set',
          'valueType': identifyValueType(normalFields),
        });
      }

      result.addAll(specialFields);
      continue;
    }

    // ---------------- Primitive / Array ----------------
    result.add({
      'field': fullKey,
      'value': value,
      'op': 'set',
      'valueType': identifyValueType(value),
    });
  }

  return result;
}

/// @nodoc
// Map<String, dynamic> flattenUpdates(Map<String, dynamic> obj,
//     [String parentKey = '']) {
//   final result = <String, dynamic>{};

//   obj.forEach((key, value) {
//     final fullKey = parentKey.isEmpty ? key : '$parentKey.$key';

//     final isMap = value is Map<String, dynamic>;
//     final isFieldValue = value is FieldValue;
//     final isList = value is List;

//     if (value != null && isMap && !isFieldValue && !isList &&
//       value is! Timestamp) {
//       // recursion exactly like JS
//       result.addAll(flattenUpdates(value, fullKey));
//     } else {
//       // primitive, list, FieldValue
//       result[fullKey] = value;
//     }
//   });

//   return result;
// }

/// @nodoc
Map<String, dynamic> flattenUpdates(
  Map<String, dynamic> obj, [
  String parentKey = '',
]) {
  final Map<String, dynamic> result = {};
  bool hasKeys = false;

  obj.forEach((key, value) {
    hasKeys = true;
    final String fullKey = parentKey.isEmpty ? key : '$parentKey.$key';

    final bool isMap = value is Map<String, dynamic>;
    final bool isFieldValue = value is FieldValue;
    final bool isList = value is List;
    final bool isTimestamp = value is Timestamp;

    if (value != null && isMap && !isFieldValue && !isList && !isTimestamp) {
      // recurse
      final int beforeSize = result.length;
      result.addAll(flattenUpdates(value, fullKey));

      // ✅ preserve empty map
      if ((value as Map).isEmpty) {
        result[fullKey] = {};
      }
    } else {
      // primitive, list, FieldValue
      result[fullKey] = value;
    }
  });

  // ✅ root empty object support
  if (!hasKeys && parentKey.isNotEmpty) {
    result[parentKey] = {};
  }

  return result;
}

/// @nodoc
String getHostString(Settings settings) {
  String socketURL = settings.host ?? "";
  bool useSSL = settings.sslEnabled ?? true;
  if (useSSL) {
    socketURL = "wss://$socketURL";
  } else {
    socketURL = "ws://$socketURL";
  }
  return socketURL.substring(0, socketURL.length - 1);
}

/// @nodoc
String buildFullKey(String parentKey, String key) {
  String fullKey = parentKey.isEmpty ? key : '$parentKey.$key';

  final containFieldPath = fullKey.contains(r'$FieldPath$');
  fullKey = fullKey.replaceAll(r'$FieldPath$', '');

  final parts = fullKey.split('#FieldPath#');

  fullKey = '';

  // escape parts except last
  for (int i = 0; i < parts.length - 1; i++) {
    fullKey += escapeFieldName(parts[i]) + '.';
  }

  // last part:
  if (containFieldPath) {
    fullKey += escapeFieldName(parts.last);
  } else {
    fullKey += parts.last;
  }

  return fullKey;
}

/// @nodoc
class LoadBundleTaskHelper {
  LoadBundleTaskHelper();

  /// @nodoc
  static dynamic transformData(dynamic data) {
    var newData = [];

    for (var i = 0; i < data["queries"].length; i++) {
      final qObj = {
        "name": data["queries"][i]["name"],
        "documents": [],
        "bundleID": data["bundleID"],
        "metadata": data["metadata"],
      };

      for (var j = 0; j < data["queries"][i]["doucments"].length; j++) {
        var docPath = data["queries"][i]["doucments"][j];
        if (!data["documents"].containsKey(docPath)) {
          throw Exception(OracledbErrorMessages.documentDataNotPresent);
        }
        qObj["documents"].push({
          "path": docPath,
          "data": data["documents"][docPath],
        });
      }

      newData.add(qObj);
    }

    return newData;
  }
}

/// @nodoc
class Utils {
  static const String _redacted = '[REDACTED]';
  static final RegExp _sensitiveKeyPattern = RegExp(
    r'(authorization|authz|token|password|passwd|pwd|secret|credential|assertion|code_verifier|refresh_token|access_token|id_token|api[_-]?key|client[_-]?secret|apptrusttoken)',
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

  static void baasLogger(globals.LogLevel logLevel, dynamic data) {
    if ((logLevel == globals.LogLevel.error ||
            logLevel == globals.LogLevel.debug) ||
        (logLevel == globals.LogLevel.error ||
            logLevel == globals.LogLevel.debug)) {
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
    if (logLevel == globals.LogLevel.error ||
        logLevel == globals.LogLevel.error) {
      print(_redactForLog(reqUrl));
      print(_redactForLog(headers));
      print(_redactPayloadForLog(data));
      print(_redactForLog(e));
      print(_redactForLog(stackTrace.toString()));
    }
  }

  static dynamic getObjectProperty(dynamic object, dynamic path) {
    if (object == null || path == null) {
      return null;
    }
    var parts = path.split('.');
    for (var i = 0; i < parts.length; ++i) {
      if (object == null) {
        return null;
      }
      var key = parts[i];
      if (key.length > 14 && key.startsWith("__fusabaseindex__")) {
        key = key.substring(14);
        key = int.parse(key);
      }
      object = object[key];
    }
    return object;
  }

  static void checkResponse(globals.LogLevel logLevel, http.Response response) {
    if (response.statusCode < 200 || response.statusCode > 299) {
      Utils.baasLogger(logLevel, response);
      throw Exception('Invalid Response! -> ${response.statusCode}');
    }
  }

  static FusabaseException oracledbErrorHandler(
    int status,
    String message,
    StackTrace? stackTrace,
  ) {
    dynamic code = "oracledb/";

    if (status == 400) {
      code += 'invalid-argument';
    } else if (status == 401) {
      code += 'unauthenticated';
    } else if (status == 404) {
      code += 'not-found';
    } else if (status == 403) {
      code += 'permission-denied';
    } else if (status == 500) {
      code += 'internal';
    } else {
      code += 'unknown';
    }
    FusabaseException e = FusabaseException(
      code: code,
      message: message,
      name: "OracledbError",
      stackTrace: stackTrace,
    );
    return e;
  }
}
