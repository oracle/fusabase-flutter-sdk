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

// types/filter.dart
part of '../../oracledb.dart';

/// Represents a filter for queries.
///
///
/// Use to create conditions for where clauses in queries.
///
/// Parameters:
/// - [field]: The field to filter on.
/// - Various optional comparison parameters like [isEqualTo], etc.
///
/// Returns:
/// A [Filter] instance.
///
/// Example:
/// ```dart
/// var filter = Filter('age', isGreaterThan: 18);
/// query.where(filter);
/// ```
class Filter {
  Map<String, List<dynamic>> cons = {};
  String _type;
  String _operation;

  Filter(Object field,
      {Object? isEqualTo,
      Object? isNotEqualTo,
      Object? isLessThan,
      Object? isLessThanOrEqualTo,
      Object? isGreaterThan,
      Object? isGreaterThanOrEqualTo,
      Object? arrayContains,
      Iterable<Object?>? arrayContainsAny,
      Iterable<Object?>? whereIn,
      Iterable<Object?>? whereNotIn,
      bool? isNull}) : _type="BASE",
      _operation = "NONE" {
    cons["AND"] = [];
    cons["OR"] = [];
    cons["BASE"] = [];
    if (field == "__NULL__") {
      return;
    }

    if (field is FieldPath) {
      field = field.getPath();
    }

    Map<String, dynamic> conds = {
      "isEqualTo": isEqualTo,
      "isNotEqualTo": isNotEqualTo,
      "isLessThan": isLessThan,
      "isLessThanOrEqualTo": isLessThanOrEqualTo,
      "isGreaterThan": isGreaterThan,
      "isGreaterThanOrEqualTo": isGreaterThanOrEqualTo,
      "arrayContains": arrayContains,
      "arrayContainsAny": arrayContainsAny,
      "whereIn": whereIn,
      "whereNotIn": whereNotIn,
      "isNull": isNull
    };

    conds.forEach((key, value) {
        if (value != null && value != '' ) {
          if (("${whereOperators[key]}" == "in" || "${whereOperators[key]}" == "not in") && value is! List) {
            value = [value];
          }
          _operation = key;
        }
    });
    
    cons["BASE"]?.add({
      "field": field,
      "isEqualTo": isEqualTo,
      "isNotEqualTo": isNotEqualTo,
      "isLessThan": isLessThan,
      "isLessThanOrEqualTo": isLessThanOrEqualTo,
      "isGreaterThan": isGreaterThan,
      "isGreaterThanOrEqualTo": isGreaterThanOrEqualTo,
      "arrayContains": arrayContains,
      "arrayContainsAny": arrayContainsAny,
      "whereIn": whereIn,
      "whereNotIn": whereNotIn,
      "isNull": isNull
    });

  }

  /// Converts the filter to JSON.
  ///
  /// Returns:
  /// A Map representing the filter.
  ///
  /// Example:
  /// ```dart
  /// var json = filter.toJson();
  /// ```
  Map<String, Object?> toJson() {
    return cons;
  }

  /// Creates a composite AND filter.
  ///
  /// Parameters:
  /// - [filter1], [filter2], and optional additional filters.
  ///
  /// Returns:
  /// A composite [Filter] with AND logic.
  ///
  /// Example:
  /// ```dart
  /// var andFilter = Filter.and(Filter('age', isGreaterThan: 18), Filter('country', isEqualTo: 'USA'));
  /// ```
  static Filter and(
    Filter filter1,
    Filter filter2, [
    Filter? filter3,
    Filter? filter4,
    Filter? filter5,
    Filter? filter6,
    Filter? filter7,
    Filter? filter8,
    Filter? filter9,
    Filter? filter10,
    Filter? filter11,
    Filter? filter12,
    Filter? filter13,
    Filter? filter14,
    Filter? filter15,
    Filter? filter16,
    Filter? filter17,
    Filter? filter18,
    Filter? filter19,
    Filter? filter20,
    Filter? filter21,
    Filter? filter22,
    Filter? filter23,
    Filter? filter24,
    Filter? filter25,
    Filter? filter26,
    Filter? filter27,
    Filter? filter28,
    Filter? filter29,
    Filter? filter30,
  ]) {
    Filter newFilter = Filter("__NULL__");
    newFilter._type = "AND";
    newFilter.cons["AND"] = [];
    var arr = [
      filter1,
      filter2,
      filter3,
      filter4,
      filter5,
      filter6,
      filter7,
      filter8,
      filter9,
      filter10,
      filter11,
      filter12,
      filter13,
      filter14,
      filter15,
      filter16,
      filter17,
      filter18,
      filter19,
      filter20,
      filter21,
      filter22,
      filter23,
      filter24,
      filter25,
      filter26,
      filter27,
      filter28,
      filter29,
      filter30
    ];
    for (var i = 0; i < arr.length; i++) {
      if (arr[i] != null) {
        newFilter.cons["AND"]?.add(arr[i]);
      }
    }
    return newFilter;
  }

  /// Creates a composite OR filter.
  ///
  /// Parameters:
  /// - [filter1], [filter2], and optional additional filters.
  ///
  /// Returns:
  /// A composite [Filter] with OR logic.
  ///
  /// Example:
  /// ```dart
  /// var orFilter = Filter.or(Filter('age', isGreaterThan: 18), Filter('age', isLessThan: 13));
  /// ```
  static Filter or(
    Filter filter1,
    Filter filter2, [
    Filter? filter3,
    Filter? filter4,
    Filter? filter5,
    Filter? filter6,
    Filter? filter7,
    Filter? filter8,
    Filter? filter9,
    Filter? filter10,
    Filter? filter11,
    Filter? filter12,
    Filter? filter13,
    Filter? filter14,
    Filter? filter15,
    Filter? filter16,
    Filter? filter17,
    Filter? filter18,
    Filter? filter19,
    Filter? filter20,
    Filter? filter21,
    Filter? filter22,
    Filter? filter23,
    Filter? filter24,
    Filter? filter25,
    Filter? filter26,
    Filter? filter27,
    Filter? filter28,
    Filter? filter29,
    Filter? filter30,
  ]) {
    Filter newFilter = Filter("__NULL__");
    newFilter._type = "OR";
    newFilter.cons["OR"] = [];
    var arr = [
      filter1,
      filter2,
      filter3,
      filter4,
      filter5,
      filter6,
      filter7,
      filter8,
      filter9,
      filter10,
      filter11,
      filter12,
      filter13,
      filter14,
      filter15,
      filter16,
      filter17,
      filter18,
      filter19,
      filter20,
      filter21,
      filter22,
      filter23,
      filter24,
      filter25,
      filter26,
      filter27,
      filter28,
      filter29,
      filter30
    ];
    for (var i = 0; i < arr.length; i++) {
      if (arr[i] != null) {
        newFilter.cons["OR"]?.add(arr[i]);
      }
    }
    return newFilter;
  }
}
