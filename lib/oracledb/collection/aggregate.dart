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

// collection/aggregate.dart
part of '../../oracledb.dart';

/// A class that represents the result of an aggregation query.
/// 
/// This snapshot provides access to the aggregated data such as count, sum, or average.
/// 
/// 
/// Parameters:
/// - [query]: The query whose aggregation results are in this snapshot.
/// - [data]: The raw aggregation data (optional).
/// 
/// Returns:
/// An instance of [AggregateQuerySnapshot].
/// 
/// Example:
/// ```dart
/// var snapshot = await aggregateQuery.get();
/// print(snapshot.count);
/// ```
class AggregateQuerySnapshot {
  int? count;
  final Query query;
  dynamic data;

  AggregateQuerySnapshot({required this.query, this.data})
      : count = data != null ? data["count"] : null;

  /// Retrieves the average value for the specified field from the aggregation data.
  /// 
  /// Parameters:
  /// - [field]: The field name to get the average for.
  /// 
  /// Returns:
  /// The average value as a double, or null if not available.
  /// 
  /// Example:
  /// ```dart
  /// double? avg = snapshot.getAverage('price');
  /// ```
  double? getAverage(String field) {
    return data[field].toDouble();
  }

  /// Retrieves the sum value for the specified field from the aggregation data.
  /// 
  /// Parameters:
  /// - [field]: The field name to get the sum for.
  /// 
  /// Returns:
  /// The sum value as a double, or null if not available.
  /// 
  /// Example:
  /// ```dart
  /// double? total = snapshot.getSum('price');
  /// ```
  double? getSum(String field) {
    return data[field].toDouble();
  }
}

/// A class that represents an aggregation query over a [Query].
/// 
/// Use this to perform aggregations like count, sum, or average on the results of a query.
/// 
/// 
/// Parameters:
/// - [query]: The base query to aggregate over.
/// 
/// Returns:
/// An instance of [AggregateQuery].
/// 
/// Example:
/// ```dart
/// var aggQuery = query.aggregate(count());
/// ```
class AggregateQuery {
  final Query query;

  AggregateQuery({required this.query});

  /// Configures the aggregation to perform a count.
  /// 
  /// Returns:
  /// The same [AggregateQuery] instance configured for counting.
  /// 
  /// Example:
  /// ```dart
  /// var countQuery = aggregateQuery.count();
  /// ```
  AggregateQuery count() {
    return query.count();
  }

  /// Executes the aggregation query and returns the results.
  /// 
  /// Parameters:
  /// - [source]: The source to fetch the aggregation from (default: server).
  /// 
  /// Returns:
  /// A Future that resolves to an [AggregateQuerySnapshot] containing the results.
  /// 
  /// Example:
  /// ```dart
  /// var snapshot = await aggregateQuery.get(source: AggregateSource.server);
  /// ```
  Future<AggregateQuerySnapshot> get({
    AggregateSource source = AggregateSource.server,
  }) async {
    // needs to go to helper class
    FusabaseAuth auth = FusabaseAuth.instanceFor(app: query.oracledb.app);
    String? accessToken = await getAccessToken(auth);
    Map<String, dynamic> result;

    try {
      result = await query._helper.get(
          createClient(query.oracledb.app), null, query, query.__logLevel, accessToken, null);
    } catch (e) {
      return AggregateQuerySnapshot(query: query, data: null);
    }

    AggregateQuerySnapshot res = AggregateQuerySnapshot(
        query: query, data: result["ret"][0]["result"]);
    return res;
  }
}

/// A base class representing an aggregation field for queries like sum or average.
/// 
/// 
/// Parameters:
/// - [field]: The field to aggregate.
/// - [aggregateType]: The type of aggregation (e.g., 'avg', 'sum').
/// 
/// Returns:
/// An instance of [AggregateField].
/// 
/// Example:
/// ```dart
/// var avgField = average('price');
/// ```
class AggregateField {
  final String field;
  String aggregateType;

  AggregateField({required this.field, required this.aggregateType});
}

/// Represents an average aggregation over a field.
/// 
/// Extends [AggregateField] for average calculations.
/// 
/// Parameters:
/// - [field]: The field to compute the average for.
/// 
/// Returns:
/// An instance of [average].
/// 
/// Example:
/// ```dart
/// var avg = average('score');
/// ```
class average extends AggregateField {
  average(field) : super(field: field, aggregateType: "avg");
}

/// Represents a sum aggregation over a field.
/// 
/// Extends [AggregateField] for sum calculations.
/// 
/// Parameters:
/// - [field]: The field to compute the sum for.
/// 
/// Returns:
/// An instance of [sum].
/// 
/// Example:
/// ```dart
/// var total = sum('amount');
/// ```
class sum extends AggregateField {
  sum(field) : super(field: field, aggregateType: "sum");
}

/// Represents a count aggregation.
/// 
/// Extends [AggregateField] for counting documents.
/// 
/// Returns:
/// An instance of [count].
/// 
/// Example:
/// ```dart
/// var docCount = count();
/// ```
class count extends AggregateField {
  count() : super(field: "", aggregateType: "count");
}
