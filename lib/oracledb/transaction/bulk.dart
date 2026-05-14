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

// document/reference.dart

part of '../../oracledb.dart';

/// A class for performing bulk update operations on OracleDB documents.
///
/// This class allows building complex queries with conditions using the [where] method
/// and then performing updates on multiple documents that match those conditions
/// using the [update] method.
///
/// The class supports chaining multiple where conditions and handles various
/// comparison operators including equality, inequality, range comparisons,
/// array operations, and null checks.
///
/// Example:
/// ```dart
/// var bulkUpdate = BulkUpdate(
///   helper: queryHelper,
///   oracledb: oracledbInstance,
///   path: 'collection/document'
/// );
///
/// await bulkUpdate
///   .where('age', isGreaterThan: 18)
///   .where('status', isEqualTo: 'active')
///   .update({'lastUpdated': DateTime.now()});
/// ```
class BulkUpdate<T extends Object?> {
  FusabaseOracledb _oracledb;
  globals.LogLevel __logLevel;
  QueryHelper _helper;
  List<String> _path = [];
  List<dynamic> _conditions = [];
  List<String> _ops = [];
  String type;

  /// The FusabaseOracledb instance associated with this bulk update operation.
  FusabaseOracledb get oracledb => _oracledb;

  /// The document path for this bulk update operation, constructed from the path segments.
  String get path => _path.join('/');

  /// @nodoc
  BulkUpdate(
      {required QueryHelper helper,
      required FusabaseOracledb oracledb,
      required String path})
      : _helper = helper,
        type = "bulkUpdate",
        __logLevel = oracledb.app.logLevel,
        _oracledb = oracledb {
    path = path.toString().trim();
    List<String> tokens = path.split('/');
    _path = [];
   
    _path = tokens;

    if (_path.length%2 == 0) {
      throw Utils.oracledbErrorHandler(
          400, "Incorrect path.", null);
    }
  }

  /// @nodoc
  dynamic getAllWhere(Filter f) {
    var res = [];

    if (f._type == "BASE") {
      res.add({"field": f.cons["BASE"]![0]["field"], 
      "op": whereOperators[f._operation], 
      "value": f.cons["BASE"]![0][f._operation]});
    }

    if (f._type == "AND" && f.cons["AND"]!.isNotEmpty) {
      res.add({"field": null, "op": '(', "value": null});
      for (int i =0;i<f.cons["AND"]!.length;i++) {
        var recRes = getAllWhere(f.cons["AND"]![i]);
        for (int j=0;j<recRes.length;j++) {
          res.add(recRes[j]);
        }
        if (i!=f.cons["AND"]!.length-1) {
          res.add({"field": null, "op": 'AND', "value": null});
        }
      }
      res.add({"field": null, "op": ')', "value": null});
    }

    if (f._type == "OR" && f.cons["OR"]!.isNotEmpty) {
      res.add({"field": null, "op": '(', "value": null});
      for (int i =0;i<f.cons["OR"]!.length;i++) {
        var recRes = getAllWhere(f.cons["OR"]![i]);
        for (int j=0;j<recRes.length;j++) {
          res.add(recRes[j]);
        }
        if (i!=f.cons["OR"]!.length-1) {
          res.add({"field": null, "op": 'OR', "value": null});
        }
      }
      res.add({"field": null, "op": ')', "value": null});
    }

    return res;
  }

  /// Adds a condition to filter documents for the bulk update operation.
  ///
  /// This method allows chaining multiple conditions to specify which documents
  /// should be updated. Only one comparison operator can be specified per call.
  ///
  /// Parameters:
  /// - [field]: The field to filter on. Can be a String field name, FieldPath,
  ///   or a Filter object for complex conditions.
  /// - [isEqualTo]: Filters documents where the field equals this value.
  /// - [isNotEqualTo]: Filters documents where the field does not equal this value.
  /// - [isLessThan]: Filters documents where the field is less than this value.
  /// - [isLessThanOrEqualTo]: Filters documents where the field is less than or equal to this value.
  /// - [isGreaterThan]: Filters documents where the field is greater than this value.
  /// - [isGreaterThanOrEqualTo]: Filters documents where the field is greater than or equal to this value.
  /// - [arrayContains]: Filters documents where the array field contains this exact value.
  /// - [arrayContainsAny]: Filters documents where the array field contains any of the values in this iterable.
  /// - [whereIn]: Filters documents where the field is equal to any value in this iterable.
  /// - [whereNotIn]: Filters documents where the field is not equal to any value in this iterable.
  /// - [isNull]: If true, filters documents where the field is null.
  ///
  /// Returns:
  /// A [BulkUpdate] instance for chaining additional conditions.
  ///
  /// Example:
  /// ```dart
  /// bulkUpdate
  ///   .where('age', isGreaterThan: 18)
  ///   .where('status', isEqualTo: 'active')
  ///   .where('tags', arrayContains: 'important');
  /// ```
  BulkUpdate<T> where(Object field,
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
      bool? isNull
      }) {
    if (field is Filter) {
      var filters = getAllWhere(field);
      dynamic res = this;
      for (int i = 0;i<filters.length;i++) {
        res._conditions.add(filters[i]);
      }
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

    if (field is FieldPath) {
      field = field.getPath();
    }

    BulkUpdate<T> newQuery = this;

    conds.forEach((key, value) {
        if (value != null && value != '') {
          newQuery._ops.add(key);
          if (key == "arrayContains") {
            for (int i=0;i<newQuery._ops.length;i++) {
              if (newQuery._ops[i] == "arrayContainsAny") {
                throw Utils.oracledbErrorHandler(
                  400, OracledbErrorMessages.invalidArrayContainsCombination, null);
              }
            }
          }
          if (key == "arrayContainsAny") {
            for (int i=0;i<newQuery._ops.length;i++) {
              if (newQuery._ops[i] == "arrayContains") {
                throw Utils.oracledbErrorHandler(
                  400, OracledbErrorMessages.invalidArrayContainsCombination, null);
              }
              }
            }
          if (("${whereOperators[key]}" == "in" || "${whereOperators[key]}" == "not in") && value is! List) {
            value = [value];
          }
          newQuery._conditions
              .add({"field": "$field", "op": "${whereOperators[key]}", "value": value});
        }
      }
    );

    return newQuery;
  }

  /// Updates fields in multiple documents.
  ///
  /// Parameters:
  /// - [data]: The data to update.
  /// - [transObj]: Optional transaction object.
  ///
  /// Returns:
  /// A Future that completes when the update is done.
  ///
  /// Example:
  /// ```dart
  /// await docRef.update({'age': 30});
  /// ```
  Future<void> update(Map<Object, Object?> data, [dynamic transObj]) async {
    if (transObj == null) {
      transObj = {
        "name":"",
        "start":0,
        "end":0
      };
    };
    FusabaseAuth auth = FusabaseAuth.instanceFor(app: this._oracledb.app);
    dynamic finalData = convertMap(data);
    String? accessToken = await getAccessToken(auth);

    finalData = createPayloadForUpdateVersion2New(this, finalData, true);
    finalData = parseTimestamp(finalData);
    finalData = rearrangeBodyOfVersion2(finalData);

    dynamic result = await _helper.updatedoc(createClient(_oracledb.app), this, finalData,
        this.__logLevel, accessToken, transObj);

    return;
  }

}
