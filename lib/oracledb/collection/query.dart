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

// collection/query.dart
part of '../../oracledb.dart';

/// Represents a query over the data at a particular location.
///
/// Queries can include constraints to filter the results, order the results,
/// and limit the number of results.
///
///
/// Parameters:
/// - [helper]: The helper for query operations.
/// - [oracledb]: The FusabaseOracledb instance.
/// - [path]: The path to the collection.
/// - [parent]: Optional parent object.
///
/// Returns:
/// An instance of [Query].
///
/// Example:
/// ```dart
/// var query = oracledb.collection('users').where('age', isGreaterThan: 18);
/// ```
class Query<T extends Object?> {
  final FusabaseOracledb _oracledb;
  QueryHelper _helper;
  int? _limit;
  globals.LogLevel __logLevel;
  List<String> _path;
  List<String> _ops;
  String type;
  dynamic fromConverter;
  dynamic toConverter;

  List<dynamic> _conditions = [];
  List<dynamic> _column = [];
  List<dynamic> _serverTimestamp = [];
  List<dynamic> _aggregate = [];
  List<dynamic> _explicitOrder = [];
  List<dynamic> _joins = [];
  String _col_group;
  int _rt;
  List<String> _brid;
  Map<String, dynamic>? _vectorSearch;

  /// Gets the parameters of the query.
  Map<String, dynamic> get parameters => {
    "conditions": _conditions,
    "aggregate": _aggregate,
    "explicitOrder": _explicitOrder,
    "joins": _joins,
    "col_group": _col_group,
    "limit": _limit,
    "path": _path,
  };

  /// Gets the FusabaseOracledb instance associated with this query.
  FusabaseOracledb get oracledb => _oracledb;

  /// Gets the path of the query.
  String get path => _path.join('/');

  Query({
    required QueryHelper helper,
    required FusabaseOracledb oracledb,
    required String path,
    dynamic parent,
  }) : _oracledb = oracledb,
       _limit = 0,
       type = "query",
       _ops = [],
       __logLevel = oracledb.app.logLevel,
       _col_group = "",
       _rt = 0,
       _helper = helper,
       _brid = [],
       _vectorSearch = null,
       _path = path.toString().trim().split('/');

  /// Recursively retrieves all where conditions from a Filter.
  ///
  /// Parameters:
  /// - [f]: The filter to process.
  ///
  /// Returns:
  /// A list of condition maps.
  ///
  /// Example:
  /// ```dart
  /// var conditions = query.getAllWhere(filter);
  /// ```
  /// @nodoc
  dynamic getAllWhere(Filter f) {
    var res = [];

    if (f._type == "BASE") {
      res.add({
        "field": f.cons["BASE"]![0]["field"],
        "op": whereOperators[f._operation],
        "value": f.cons["BASE"]![0][f._operation],
      });
    }

    if (f._type == "AND" && f.cons["AND"]!.isNotEmpty) {
      res.add({"field": null, "op": '(', "value": null});
      for (int i = 0; i < f.cons["AND"]!.length; i++) {
        var recRes = getAllWhere(f.cons["AND"]![i]);
        for (int j = 0; j < recRes.length; j++) {
          res.add(recRes[j]);
        }
        if (i != f.cons["AND"]!.length - 1) {
          res.add({"field": null, "op": 'AND', "value": null});
        }
      }
      res.add({"field": null, "op": ')', "value": null});
    }

    if (f._type == "OR" && f.cons["OR"]!.isNotEmpty) {
      res.add({"field": null, "op": '(', "value": null});
      for (int i = 0; i < f.cons["OR"]!.length; i++) {
        var recRes = getAllWhere(f.cons["OR"]![i]);
        for (int j = 0; j < recRes.length; j++) {
          res.add(recRes[j]);
        }
        if (i != f.cons["OR"]!.length - 1) {
          res.add({"field": null, "op": 'OR', "value": null});
        }
      }
      res.add({"field": null, "op": ')', "value": null});
    }

    return res;
  }

  /// Adds a filter constraint to the query.
  ///
  /// Parameters:
  /// - [field]: The field to filter on.
  /// - Various optional filter conditions like [isEqualTo], [isGreaterThan], etc.
  ///
  /// Returns:
  /// A new [Query] with the added filter.
  ///
  /// Example:
  /// ```dart
  /// query = query.where('age', isGreaterThan: 18);
  /// ```
  Query<T> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    if (field is Filter) {
      var filters = getAllWhere(field);
      dynamic res = this;
      for (int i = 0; i < filters.length; i++) {
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
      "isNull": isNull,
    };
    if (field is FieldPath) {
      field = field.getPath();
    }
    Query<T> newQuery = Query<T>(
      helper: QueryHelper(),
      oracledb: _oracledb,
      path: path,
    );
    _helper.dupQuery(newQuery, this);

    conds.forEach((key, value) {
      if (value != null && value != '') {
        newQuery._ops.add(key);
        if (key == "arrayContains") {
          for (int i = 0; i < newQuery._ops.length; i++) {
            if (newQuery._ops[i] == "arrayContainsAny") {
              throw Utils.oracledbErrorHandler(
                400,
                OracledbErrorMessages.invalidArrayContainsCombination,
                null,
              );
            }
          }
        }
        if (key == "arrayContainsAny") {
          for (int i = 0; i < newQuery._ops.length; i++) {
            if (newQuery._ops[i] == "arrayContains") {
              throw Utils.oracledbErrorHandler(
                400,
                OracledbErrorMessages.invalidArrayContainsCombination,
                null,
              );
            }
          }
        }
        if (("${whereOperators[key]}" == "in" ||
                "${whereOperators[key]}" == "not in") &&
            value is! List) {
          value = [value];
        }
        newQuery._conditions.add({
          "field": "$field",
          "op": "${whereOperators[key]}",
          "value": value,
        });
      }
    });

    return newQuery;
  }

  /// Returns a cloned query with vector-search metadata attached.
  ///
  /// [vectorSearch] (`Map<String, dynamic>`) describes the field, query
  /// vector, and optional search settings. Prefer [findNearest] when building
  /// a vector query directly.
  ///
  /// Returns a new [Query<T>] containing the vector-search configuration.
  ///
  /// Example:
  /// ```dart
  /// final nearest = query.withVectorSearch({
  ///   'field': 'embedding',
  ///   'query': FieldValue.denseVector([0.12, -0.4]),
  ///   'topK': 10,
  /// });
  /// ```
  Query<T> withVectorSearch(Map<String, dynamic> vectorSearch) {
    Query<T> newQuery = Query<T>(
      helper: QueryHelper(),
      oracledb: _oracledb,
      path: path,
    );
    _helper.dupQuery(newQuery, this);
    newQuery._vectorSearch = deepClone(vectorSearch) as Map<String, dynamic>;
    return newQuery;
  }

  /// Creates a vector similarity query.
  ///
  /// - [field] (`String`): Name of the vector field to search.
  /// - [query] (`Map<String, dynamic>`): Dense or sparse query-vector payload.
  /// - [metric] (`String?`): Optional similarity metric.
  /// - [topK] (`int?`): Optional positive maximum number of matches.
  /// - [threshold] (`num?`): Optional score threshold.
  ///
  /// Returns a new [Query<T>] configured for nearest-neighbour search.
  ///
  /// Example:
  /// ```dart
  /// final nearest = query.findNearest(
  ///   'embedding',
  ///   FieldValue.denseVector([0.12, -0.4]),
  ///   topK: 10,
  /// );
  /// ```
  Query<T> findNearest(
    String field,
    Map<String, dynamic> query, {
    String? metric,
    int? topK,
    num? threshold,
  }) {
    validateVectorSearchQuery(query);

    if (topK != null && topK <= 0) {
      throw Utils.oracledbErrorHandler(
        400,
        'findNearest topK must be a positive integer.',
        null,
      );
    }
    if (threshold != null && threshold.isNaN) {
      throw Utils.oracledbErrorHandler(
        400,
        'findNearest threshold must be a number.',
        null,
      );
    }

    return withVectorSearch({
      'field': field,
      'query': deepClone(query),
      'metric': metric,
      'topK': topK,
      'threshold': threshold,
    });
  }

  // /// Returns a cloned query with vector search metadata attached.
  // Query<T> withVectorSearch(Map<String, dynamic> vectorSearch) {
  //   Query<T> newQuery =
  //       Query<T>(helper: QueryHelper(), oracledb: _oracledb, path: path);
  //   _helper.dupQuery(newQuery, this);
  //   newQuery._vectorSearch = deepClone(vectorSearch) as Map<String, dynamic>;
  //   return newQuery;
  // }

  // /// Creates a v2 vector similarity query.
  // Query<T> findNearest(
  //   String field,
  //   Map<String, dynamic> query, {
  //   String? metric,
  //   int? topK,
  //   num? threshold,
  // }) {
  //   validateVectorSearchQuery(query);

  //   if (topK != null && topK <= 0) {
  //     throw Utils.oracledbErrorHandler(
  //       400,
  //       'findNearest topK must be a positive integer.',
  //       null,
  //     );
  //   }
  //   if (threshold != null && threshold.isNaN) {
  //     throw Utils.oracledbErrorHandler(
  //       400,
  //       'findNearest threshold must be a number.',
  //       null,
  //     );
  //   }

  //   return withVectorSearch({
  //     'field': field,
  //     'query': deepClone(query),
  //     'metric': metric,
  //     'topK': topK,
  //     'threshold': threshold,
  //   });
  // }

  /// Applies column selection to the query.
  ///
  /// Parameters:
  /// - [values] (`List<String>`): Names of the columns to return.
  ///
  /// Returns:
  /// A new [Query<T>] with the selected columns.
  ///
  /// Example:
  /// ```dart
  /// final names = query.column(['name', 'email']);
  /// ```
  ///
  column(List<String> values) {
    Query<T> newQuery = Query<T>(
      helper: QueryHelper(),
      oracledb: _oracledb,
      path: path,
    );
    _helper.dupQuery(newQuery, this);

    for (var i = 0; i < values.length; i++) {
      newQuery._column.add(values[i]);
    }

    return newQuery;
  }

  /// Starts the query results at the provided set of values.
  ///
  /// Parameters:
  /// - [values]: The values to start at.
  ///
  /// Returns:
  /// A new [Query] starting at the values.
  ///
  /// Example:
  /// ```dart
  /// query = query.startAt([20]);
  /// ```
  Query<T> startAt(Iterable<Object?> values) {
    Query<T> newQuery = Query<T>(
      helper: QueryHelper(),
      oracledb: _oracledb,
      path: path,
    );
    _helper.dupQuery(newQuery, this);

    for (var i = 0; i < values.length; i++) {
      newQuery._conditions.add({
        "field": newQuery._explicitOrder[i]["field"],
        "op": ">=",
        "value": values.elementAt(i),
      });
    }

    return newQuery;
  }

  /// Starts the query results at the document.
  ///
  /// Parameters:
  /// - [documentSnapshot]: The document to start at.
  ///
  /// Returns:
  /// A new [Query] starting at the document.
  ///
  /// Example:
  /// ```dart
  /// query = query.startAtDocument(snapshot);
  /// ```
  Query<T> startAtDocument(DocumentSnapshot documentSnapshot) {
    Query<T> newQuery = Query<T>(
      helper: QueryHelper(),
      oracledb: _oracledb,
      path: path,
    );
    _helper.dupQuery(newQuery, this);
    String fieldName = newQuery._explicitOrder[0]["field"];
    final dynamic data = documentSnapshot.data() ?? {};
    final value = data[fieldName];
    newQuery._conditions.add({"field": fieldName, "op": ">=", "value": value});
    return newQuery;
  }

  /// Starts the query results after the provided set of values.
  ///
  /// Parameters:
  /// - [values]: The values to start after.
  ///
  /// Returns:
  /// A new [Query] starting after the values.
  ///
  /// Example:
  /// ```dart
  /// query = query.startAfter([20]);
  /// ```
  Query<T> startAfter(Iterable<Object?> values) {
    Query<T> newQuery = Query<T>(
      helper: QueryHelper(),
      oracledb: _oracledb,
      path: path,
    );
    _helper.dupQuery(newQuery, this);

    for (var i = 0; i < values.length; i++) {
      newQuery._conditions.add({
        "field": newQuery._explicitOrder[i]["field"],
        "op": ">",
        "value": values.elementAt(i),
      });
    }

    return newQuery;
  }

  /// Starts the query results after the document.
  ///
  /// Parameters:
  /// - [documentSnapshot]: The document to start after.
  ///
  /// Returns:
  /// A new [Query] starting after the document.
  ///
  /// Example:
  /// ```dart
  /// query = query.startAfterDocument(snapshot);
  /// ```
  Query<T> startAfterDocument(DocumentSnapshot documentSnapshot) {
    Query<T> newQuery = Query<T>(
      helper: QueryHelper(),
      oracledb: _oracledb,
      path: path,
    );
    _helper.dupQuery(newQuery, this);
    String fieldName = newQuery._explicitOrder[0]["field"];
    final dynamic data = documentSnapshot.data() ?? {};
    final value = data[fieldName];
    newQuery._conditions.add({"field": fieldName, "op": ">", "value": value});
    return newQuery;
  }

  /// Ends the query results at the provided set of values.
  ///
  /// Parameters:
  /// - [values]: The values to end at.
  ///
  /// Returns:
  /// A new [Query] ending at the values.
  ///
  /// Example:
  /// ```dart
  /// query = query.endAt([30]);
  /// ```
  Query<T> endAt(Iterable<Object?> values) {
    Query<T> newQuery = Query<T>(
      helper: QueryHelper(),
      oracledb: _oracledb,
      path: path,
    );
    _helper.dupQuery(newQuery, this);

    for (var i = 0; i < values.length; i++) {
      newQuery._conditions.add({
        "field": newQuery._explicitOrder[i]["field"],
        "op": "<=",
        "value": values.elementAt(i),
      });
    }

    return newQuery;
  }

  /// Ends the query results at the document.
  ///
  /// Parameters:
  /// - [documentSnapshot]: The document to end at.
  ///
  /// Returns:
  /// A new [Query] ending at the document.
  ///
  /// Example:
  /// ```dart
  /// query = query.endAtDocument(snapshot);
  /// ```
  Query<T> endAtDocument(DocumentSnapshot documentSnapshot) {
    Query<T> newQuery = Query<T>(
      helper: QueryHelper(),
      oracledb: _oracledb,
      path: path,
    );
    _helper.dupQuery(newQuery, this);
    String fieldName = newQuery._explicitOrder[0]["field"];
    final dynamic data = documentSnapshot.data() ?? {};
    final value = data[fieldName];
    newQuery._conditions.add({"field": fieldName, "op": "<=", "value": value});
    return newQuery;
  }

  /// Ends the query results before the provided set of values.
  ///
  /// Parameters:
  /// - [values]: The values to end before.
  ///
  /// Returns:
  /// A new [Query] ending before the values.
  ///
  /// Example:
  /// ```dart
  /// query = query.endBefore([30]);
  /// ```
  Query<T> endBefore(Iterable<Object?> values) {
    Query<T> newQuery = Query<T>(
      helper: QueryHelper(),
      oracledb: _oracledb,
      path: path,
    );
    _helper.dupQuery(newQuery, this);

    for (var i = 0; i < values.length; i++) {
      newQuery._conditions.add({
        "field": newQuery._explicitOrder[i]["field"],
        "op": "<",
        "value": values.elementAt(i),
      });
    }

    return newQuery;
  }

  /// Ends the query results before the document.
  ///
  /// Parameters:
  /// - [documentSnapshot]: The document to end before.
  ///
  /// Returns:
  /// A new [Query] ending before the document.
  ///
  /// Example:
  /// ```dart
  /// query = query.endBeforeDocument(snapshot);
  /// ```
  Query<T> endBeforeDocument(DocumentSnapshot documentSnapshot) {
    Query<T> newQuery = Query<T>(
      helper: QueryHelper(),
      oracledb: _oracledb,
      path: path,
    );
    _helper.dupQuery(newQuery, this);
    String fieldName = newQuery._explicitOrder[0]["field"];
    final dynamic data = documentSnapshot.data() ?? {};
    final value = data[fieldName];
    newQuery._conditions.add({"field": fieldName, "op": "<", "value": value});
    return newQuery;
  }

  /// Limits the number of documents returned.
  ///
  /// Parameters:
  /// - [number]: The maximum number of documents.
  ///
  /// Returns:
  /// A new [Query] with the limit applied.
  ///
  /// Example:
  /// ```dart
  /// query = query.limit(10);
  /// ```
  Query<T> limit(int number) {
    if (number < 0) {
      throw Utils.oracledbErrorHandler(
        400,
        "Provided limit should be non negative.",
        null,
      );
    }

    Query<T> newQuery = Query<T>(
      helper: QueryHelper(),
      oracledb: _oracledb,
      path: path,
    );
    _helper.dupQuery(newQuery, this);
    newQuery._limit = number;

    return newQuery;
  }

  /// Limits the query to the last [limit] documents.
  ///
  /// Parameters:
  /// - [limit]: The number of documents to return from the end.
  ///
  /// Returns:
  /// A new [Query] with the limit to last applied.
  ///
  /// Example:
  /// ```dart
  /// query = query.limitToLast(5);
  /// ```
  Query<T> limitToLast(int limit) {
    Query<T> newQuery = Query<T>(
      helper: QueryHelper(),
      oracledb: _oracledb,
      path: path,
    );
    _helper.dupQuery(newQuery, this);

    for (var i = 0; i < this._explicitOrder.length; i++) {
      if (this._explicitOrder[i]["direction"] == 'asc') {
        newQuery._explicitOrder[i]["direction"] = 'desc';
      } else {
        newQuery._explicitOrder[i]["direction"] = 'asc';
      }
    }
    newQuery._limit = limit;
    return newQuery;
  }

  /// Orders the query results by a field.
  ///
  /// Parameters:
  /// - [field]: The field to order by.
  /// - [descending]: Whether to order descending (default: false).
  ///
  /// Returns:
  /// A new [Query] with the ordering applied.
  ///
  /// Example:
  /// ```dart
  /// query = query.orderBy('age', descending: true);
  /// ```
  Query<T> orderBy(Object field, {bool descending = false}) {
    if (field is FieldPath) {
      field = field.getPath();
    }
    Query<T> newQuery = Query<T>(
      helper: QueryHelper(),
      oracledb: _oracledb,
      path: path,
    );
    _helper.dupQuery(newQuery, this);

    newQuery._explicitOrder.add({
      "field": field,
      "direction": descending ? "desc" : "asc",
    });
    return newQuery;
  }

  /// Creates a count aggregation query.
  ///
  /// Returns:
  /// An [AggregateQuery] for counting documents.
  ///
  /// Example:
  /// ```dart
  /// var countQuery = query.count();
  /// ```
  AggregateQuery count() {
    Query<T> newQuery = Query<T>(
      helper: QueryHelper(),
      oracledb: _oracledb,
      path: path,
    );
    _helper.dupQuery(newQuery, this);
    dynamic obj;
    obj = {"func": "count", "field": "", "op_key": ""};
    newQuery._aggregate.add(obj);
    return AggregateQuery(query: newQuery);
  }

  /// Creates an aggregation query with the specified fields.
  ///
  /// Parameters:
  /// - [aggregateField1] to [aggregateField30]: Up to 30 aggregation fields.
  ///
  /// Returns:
  /// An [AggregateQuery] with the aggregations.
  ///
  /// Example:
  /// ```dart
  /// var aggQuery = query.aggregate(sum('sales'), average('price'));
  /// ```
  AggregateQuery aggregate(
    AggregateField aggregateField1, [
    AggregateField? aggregateField2,
    AggregateField? aggregateField3,
    AggregateField? aggregateField4,
    AggregateField? aggregateField5,
    AggregateField? aggregateField6,
    AggregateField? aggregateField7,
    AggregateField? aggregateField8,
    AggregateField? aggregateField9,
    AggregateField? aggregateField10,
    AggregateField? aggregateField11,
    AggregateField? aggregateField12,
    AggregateField? aggregateField13,
    AggregateField? aggregateField14,
    AggregateField? aggregateField15,
    AggregateField? aggregateField16,
    AggregateField? aggregateField17,
    AggregateField? aggregateField18,
    AggregateField? aggregateField19,
    AggregateField? aggregateField20,
    AggregateField? aggregateField21,
    AggregateField? aggregateField22,
    AggregateField? aggregateField23,
    AggregateField? aggregateField24,
    AggregateField? aggregateField25,
    AggregateField? aggregateField26,
    AggregateField? aggregateField27,
    AggregateField? aggregateField28,
    AggregateField? aggregateField29,
    AggregateField? aggregateField30,
  ]) {
    Query<T> newQuery = Query<T>(
      helper: QueryHelper(),
      oracledb: _oracledb,
      path: path,
    );
    _helper.dupQuery(newQuery, this);

    var temp_arr = [
      aggregateField1,
      aggregateField2,
      aggregateField3,
      aggregateField4,
      aggregateField5,
      aggregateField6,
      aggregateField7,
      aggregateField8,
      aggregateField9,
      aggregateField10,
      aggregateField11,
      aggregateField12,
      aggregateField13,
      aggregateField14,
      aggregateField15,
      aggregateField16,
      aggregateField17,
      aggregateField18,
      aggregateField19,
      aggregateField20,
      aggregateField21,
      aggregateField22,
      aggregateField23,
      aggregateField24,
      aggregateField25,
      aggregateField26,
      aggregateField27,
      aggregateField28,
      aggregateField29,
      aggregateField30,
    ];

    for (var i = 0; i < 30; i++) {
      if (temp_arr[i] != null) {
        AggregateField? t = temp_arr[i];

        newQuery._aggregate.add({
          "func": t?.aggregateType,
          "field": t?.field,
          "op_key": t?.field,
        });
      }
    }

    return AggregateQuery(query: newQuery);
  }

  /// Fetches the documents matching the query.
  ///
  /// Parameters:
  /// - [options]: Optional get options.
  ///
  /// Returns:
  /// A Future that resolves to a [QuerySnapshot].
  ///
  /// Example:
  /// ```dart
  /// var snapshot = await query.get();
  /// ```
  Future<QuerySnapshot<T>> get([GetOptions? options]) async {
    // needs to go to helper class
    FusabaseAuth auth = FusabaseAuth.instanceFor(app: this._oracledb.app);
    String? accessToken = await getAccessToken(auth);

    Map<String, dynamic> result;

    try {
      result = await _helper.get(
        createClient(_oracledb.app),
        options,
        this,
        this.__logLevel,
        accessToken,
        null,
      );
    } catch (e) {
      return QuerySnapshot<T>(
        [],
        this,
        SnapshotMetadata(hasPendingWrites: false, isFromCache: false),
      );
    }

    return QuerySnapshot<T>(
      result["ret"] ?? [],
      this,
      SnapshotMetadata(hasPendingWrites: false, isFromCache: false),
    );
  }

  /// Applies converters to the query results.
  ///
  /// Parameters:
  /// - [fromOracledb]: Converter from FusabaseOracledb data.
  /// - [toOracledb]: Converter to FusabaseOracledb data.
  ///
  /// Returns:
  /// A new [Query] with converters applied.
  ///
  /// Example:
  /// ```dart
  /// var convertedQuery = query.withConverter<User>(fromOracledb: User.fromMap, toOracledb: User.toMap);
  /// ```
  Query<R> withConverter<R>({
    required FromOracledb<R> fromOracledb,
    required ToOracledb<R> toOracledb,
  }) {
    Query<R> q = Query<R>(
      helper: QueryHelper(),
      oracledb: this.oracledb,
      path: this.path,
    );
    q.fromConverter = fromOracledb;
    q.toConverter = toOracledb;
    return q;
  }

  /// Returns a stream of snapshots for the query.
  ///
  /// Parameters:
  /// - [includeMetadataChanges]: Whether to include metadata changes.
  /// - [source]: The source for listening.
  ///
  /// Returns:
  /// A stream of [QuerySnapshot] events.
  ///
  /// Example:
  /// ```dart
  /// query.snapshots().listen((snapshot) { /* handle snapshot */ });
  /// ```
  Stream<QuerySnapshot<T>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    if (_joins.isNotEmpty || _aggregate.isNotEmpty || _vectorSearch != null) {
      throw Utils.oracledbErrorHandler(
        400,
        'snapshots does not support joins, aggregates, or vector search queries.',
        null,
      );
    }
    this._rt = 1;
    late StreamController<QuerySnapshot<T>> controller;
    Timer? _pollingTimer;

    var auth = FusabaseAuth.instanceFor(app: this._oracledb.app);
    var email = auth.currentUser?.email ?? "";
    // this query id is used to store in the cache (user level)
    int queryIdInt = createSnapshotCacheHash(
      options: this._oracledb.app.options,
      path: this._path,
      conditions: this._conditions,
      explicitOrder: this._explicitOrder,
      email: email,
    );
    String queryId = queryIdInt.toString();

    var socketPayload = {
      "path": this._path,
      "conditions": this._conditions,
    };

    // Keep the wire payload minimal, but use the full query identity for the
    // subscription ID so incoming events route to the correct listener.
    var subscriptionIdentity = {
      "type": this.type,
      "path": this._path,
      "conditions": this._conditions,
      "explicitOrder": this._explicitOrder,
      "limit": this._limit,
      "column": this._column,
    };

    // this query id is used to register listener (common for each query)
    int queryIdSocketInt = createSnapshotHashFromJson(subscriptionIdentity);
    String queryIdSocket = queryIdSocketInt.toString();

    // this query id is used to store the notifiers (unique each time)
    String localQueryId = generateRandomHash();

    Future<QuerySnapshot<T>> firstPoll() async {
      dynamic oldData = await this._oracledb._snapStore.getData(
        queryId,
        oracledb,
      );

      QuerySnapshot newSnap = await this.get();

      if (oldData == null) {
        //first snapshot
        await this._oracledb._snapStore.insertData({
          "queryId": queryId,
          "snap": newSnap,
          "type": "collection",
          "path": this.path,
        });
      } else {
        await this._oracledb._snapStore.updateData({
          "queryId": queryId,
          "snap": newSnap,
          "type": "collection",
          "path": this.path,
        });
      }
      return newSnap as QuerySnapshot<T>;
    }

    final uselongPolling =
        _oracledb.settings.webExperimentalForceLongPolling ?? true;

    //uselongPolling = false;

    if (uselongPolling) {
      controller = StreamController<QuerySnapshot<T>>.broadcast(
        onListen: () async {
          controller.add(await firstPoll());
        },
        onCancel: () {
          _pollingTimer?.cancel();
        },
      );

      final pollingInterval = _safeLongPollingInterval(this._oracledb.settings);

      Future<void> longPolling() async {
        dynamic oldData = await this._oracledb._snapStore.getData(
          queryId,
          oracledb,
        );
        QuerySnapshot newSnap = await this.get();
        if (oldData == null) {
          //first snapshot
          await this._oracledb._snapStore.insertData({
            "queryId": queryId,
            "snap": newSnap,
            "type": "collection",
            "path": this.path,
          });
          controller.add(newSnap as QuerySnapshot<T>);
          return;
        }

        //create version maps for old and new snapshot docs
        var oldVersionMap = {};
        var newVersionMap = {};

        //index map for old documents
        var oldIndexMap = {};

        for (var i = 0; i < newSnap._docs.length; i++) {
          newVersionMap[newSnap._docs[i].id] =
              newSnap._docs[i]._otherMetadata["ASOF"] != null
                  ? BigInt.parse(newSnap._docs[i]._otherMetadata["ASOF"])
                  : newSnap._docs[i]._otherMetadata["VERSION"];
        }
        for (var i = 0; i < oldData["snap"]._docs.length; i++) {
          oldVersionMap[oldData["snap"]._docs[i].id] =
              oldData["snap"]._docs[i]._otherMetadata["ASOF"] != null
                  ? BigInt.parse(
                    oldData["snap"]._docs[i]._otherMetadata["ASOF"],
                  )
                  : oldData["snap"]._docs[i]._otherMetadata["VERSION"];
          oldIndexMap[oldData["snap"]._docs[i].id] = i;
        }

        //create doc changes
        List<DocumentChange> docsChanged = [];
        for (var i = 0; i < newSnap._docs.length; i++) {
          if (oldVersionMap[newSnap._docs[i].id] != null &&
              newVersionMap[newSnap._docs[i].id] >
                  oldVersionMap[newSnap._docs[i].id]) {
            docsChanged.add(
              DocumentChange(
                doc: DocumentSnapshot(
                  {
                    "DOCUMENT": newSnap._docs[i]._data,
                    "OID": newSnap._docs[i].id,
                    "VERSION": newSnap._docs[i].version,
                  },
                  newSnap._docs[i]._reference,
                  newSnap._docs[i]._metadata,
                  newSnap._docs[i].rowID,
                ),
                type: DocumentChangeType.modified,
                oldIndex: oldIndexMap[newSnap._docs[i].id],
                newIndex: i,
              ),
            );
          } else if (oldVersionMap[newSnap._docs[i].id] == null) {
            docsChanged.add(
              DocumentChange(
                doc: DocumentSnapshot(
                  {
                    "DOCUMENT": newSnap._docs[i]._data,
                    "OID": newSnap._docs[i].id,
                    "VERSION": newSnap._docs[i].version,
                  },
                  newSnap._docs[i]._reference,
                  newSnap._docs[i]._metadata,
                  newSnap._docs[i].rowID,
                ),
                type: DocumentChangeType.added,
                oldIndex: -1,
                newIndex: i,
              ),
            );
          }
        }
        for (var i = 0; i < oldData["snap"]._docs.length; i++) {
          if (newVersionMap[oldData["snap"]._docs[i].id] == null) {
            docsChanged.add(
              DocumentChange(
                doc: DocumentSnapshot(
                  {
                    "DOCUMENT": oldData["snap"]._docs[i]._data,
                    "OID": oldData["snap"]._docs[i].id,
                    "VERSION": oldData["snap"]._docs[i].version,
                  },
                  oldData["snap"]._docs[i].reference,
                  oldData["snap"]._docs[i].metadata,
                  oldData["snap"]._docs[i].rowID,
                ),
                type: DocumentChangeType.removed,
                oldIndex: i,
                newIndex: -1,
              ),
            );
          }
        }

        newSnap._docChanges = docsChanged;

        await this._oracledb._snapStore.updateData({
          "queryId": queryId,
          "snap": newSnap,
          "type": "collection",
          "path": this.path,
        });

        if (docsChanged.isNotEmpty) {
          controller.add(newSnap as QuerySnapshot<T>);
        }
        return;
      }

      _pollingTimer = Timer(pollingInterval, () {
        longPolling();

        _pollingTimer = Timer.periodic(pollingInterval, (Timer timer) {
          longPolling();
        });
      });

      return controller.stream;
    } else {
      bool isCancelled = false;
      bool hasRegisteredRealtimeListener = false;
      dynamic payload = {
        "queryId": queryIdSocketInt,
        "status": 1,
        "payload": socketPayload,
      };

      void addToController(dynamic snap) {
        if (!controller.isClosed) {
          controller.add(snap as QuerySnapshot<T>);
        }
      }

      controller = StreamController<QuerySnapshot<T>>.broadcast(
        onListen: () async {
          isCancelled = false;
          await _oracledb.preSnapshot();
          if (isCancelled) {
            return;
          }
          this._oracledb._queryIdMap[queryIdSocket] = queryId;
          this._oracledb._initialSnapshotReady[queryIdSocket] = false;
          List<String> localQueryIds = this._oracledb._localQueryIdMap
              .putIfAbsent(queryId, () => []);
          if (!localQueryIds.contains(localQueryId)) {
            localQueryIds.add(localQueryId);
          }
          this._oracledb._snapshotControllerMap[localQueryId] = addToController;
          hasRegisteredRealtimeListener = true;
          this._oracledb.sendMessageSocket(payload);
          dynamic fsnap = await firstPoll();
          if (!isCancelled && !controller.isClosed) {
            controller.add(fsnap);
            this._oracledb.markInitialSnapshotReady(queryIdSocket);
          }
        },
        onCancel: () {
          isCancelled = true;
          if (!hasRegisteredRealtimeListener) {
            return;
          }
          hasRegisteredRealtimeListener = false;
          if (this._oracledb._snapshotControllerMap.containsKey(localQueryId)) {
            this._oracledb._snapshotControllerMap.remove(localQueryId);
          }
          if (this._oracledb._localQueryIdMap.containsKey(queryId) &&
              this._oracledb._localQueryIdMap[queryId]!.contains(
                localQueryId,
              )) {
            this._oracledb._localQueryIdMap[queryId]?.remove(localQueryId);
          }
          if (!this._oracledb._localQueryIdMap.containsKey(queryId) ||
              this._oracledb._localQueryIdMap[queryId]!.isEmpty) {
            this._oracledb._localQueryIdMap.remove(queryId);
            this._oracledb._queryIdMap.remove(queryIdSocket);
            this._oracledb._initialSnapshotReady.remove(queryIdSocket);
            this._oracledb._initialSnapshotEvents.remove(queryIdSocket);
            this._oracledb._realtimeEventTails.remove(queryIdSocket);
            dynamic unsubPayload = {
              "queryId": queryIdSocketInt,
              "status": 0,
              "payload": socketPayload,
            };
            this._oracledb.sendMessageSocket(unsubPayload);
          }
        },
      );

      return controller.stream;
    }
  }
}
