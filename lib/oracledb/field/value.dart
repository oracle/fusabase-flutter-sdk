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

// field/value.dart
part of '../../oracledb.dart';

/// Represents sentinel values that can be used when writing document fields.
///
/// Use static methods to create instances for operations like arrayUnion, delete, etc.
class FieldValue {
  final dynamic _value;
  final String _operation;

  FieldValue._(this._operation, this._value);

  /// Gets the value associated with this FieldValue.
  dynamic get value => _value;

  /// Gets the operation type of this FieldValue.
  String get operation => _operation;

  @override
  /// Checks equality with another FieldValue.
  bool operator ==(Object other) {
    return other is FieldValue &&
        compareValues(value, other.value) &&
        _operation == other._operation;
  }

  @override
  /// Returns a string representation of this FieldValue.
  String toString() => '$FieldValue($_value)($operation)';

  /// Creates a FieldValue for removing elements from an array.
  ///
  /// Parameters:
  /// - [elements]: The elements to remove.
  ///
  /// Returns:
  /// A [FieldValue] for array remove operation.
  ///
  /// Example:
  /// ```dart
  /// doc.update({'arrayField': FieldValue.arrayRemove([1, 2])});
  /// ```
  static FieldValue arrayRemove(List<dynamic> elements) {
    return FieldValue._('FieldValue:arrayRemove', elements);
  }

  /// Creates a FieldValue for adding elements to an array (union).
  ///
  /// Parameters:
  /// - [elements]: The elements to add.
  ///
  /// Returns:
  /// A [FieldValue] for array union operation.
  ///
  /// Example:
  /// ```dart
  /// doc.update({'arrayField': FieldValue.arrayUnion([3, 4])});
  /// ```
  static FieldValue arrayUnion(List<dynamic> elements) {
    return FieldValue._('FieldValue:arrayUnion', elements);
  }

  /// Creates a FieldValue for deleting a field.
  ///
  /// Returns:
  /// A [FieldValue] for delete operation.
  ///
  /// Example:
  /// ```dart
  /// doc.update({'fieldToDelete': FieldValue.delete()});
  /// ```
  static FieldValue delete() {
    return FieldValue._('FieldValue:delete', null);
  }

  /// Creates a dense-vector payload for an embedding field.
  ///
  /// [values] ([List<dynamic>]) is a non-empty list of numeric dimensions.
  ///
  /// Returns a `Map<String, dynamic>` accepted by vector write operations.
  ///
  /// Example:
  /// ```dart
  /// await doc.update({'embedding': FieldValue.denseVector([0.12, -0.4])});
  /// ```
  static Map<String, dynamic> denseVector(List<dynamic> values) {
    validateDenseVector(
      values,
      'denseVector values must be a numeric array.',
    );
    return {'type': 'dense', 'values': List<dynamic>.from(values)};
  }

  /// Creates a sparse-vector payload for an embedding field.
  ///
  /// - [dimension] (`int`): Total number of dimensions; must be positive.
  /// - [indices] (`List<dynamic>`): Sorted dimension indices.
  /// - [values] (`List<dynamic>`): Numeric values corresponding to [indices].
  ///
  /// Returns a `Map<String, dynamic>` accepted by vector write operations.
  ///
  /// Example:
  /// ```dart
  /// await doc.update({
  ///   'embedding': FieldValue.sparseVector(8, [1, 5], [0.25, -0.75]),
  /// });
  /// ```
  static Map<String, dynamic> sparseVector(
    int dimension,
    List<dynamic> indices,
    List<dynamic> values,
  ) {
    final sparse = {
      'type': 'sparse',
      'dimension': dimension,
      'indices': List<dynamic>.from(indices),
      'values': List<dynamic>.from(values),
    };
    validateSparseEmbedding(sparse);
    return sparse;
  }

  /// Creates a sentinel that removes an embedding entry from the document.
  ///
  /// Returns a [FieldValue] used by [DocumentReference.update].
  ///
  /// Example:
  /// ```dart
  /// await doc.update({'embedding': FieldValue.deleteVector()});
  /// ```
  static FieldValue deleteVector() {
    return FieldValue._('FieldValue:deleteVector', null);
  }

  /// Creates a FieldValue for incrementing a numeric field.
  ///
  /// Parameters:
  /// - [value]: The amount to increment by.
  ///
  /// Returns:
  /// A [FieldValue] for increment operation.
  ///
  /// Example:
  /// ```dart
  /// doc.update({'counter': FieldValue.increment(1)});
  /// ```
  static FieldValue increment(num value) {
    return FieldValue._('FieldValue:increment', value);
  }

  /// Creates a FieldValue for setting a server timestamp.
  ///
  /// Returns:
  /// A [FieldValue] for server timestamp operation.
  ///
  /// Example:
  /// ```dart
  /// doc.update({'timestamp': FieldValue.serverTimestamp()});
  /// ```
  static FieldValue serverTimestamp() {
    return FieldValue._('FieldValue:serverTimestamp', 'servertimestamp');
  }
}
