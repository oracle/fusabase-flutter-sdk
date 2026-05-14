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

// field/path.dart
part of '../../oracledb.dart';

/// Represents a path to a field in a document.
///
///
/// Parameters:
/// - [components]: List of field names forming the path.
///
/// Returns:
/// An instance of [FieldPath].
///
/// Example:
/// ```dart
/// var path = FieldPath(['user', 'address', 'city']);
/// ```
class FieldPath {
  final List<String> components;

  FieldPath(this.components)
      : assert(components.isNotEmpty),
        assert(
          components.where((component) => component.isEmpty).isEmpty,
          'All components should be non-null',
        );

  /// Creates a FieldPath from a dot-separated string.
  ///
  /// Parameters:
  /// - [path]: The dot-separated path string.
  ///
  /// Returns:
  /// A [FieldPath] instance.
  ///
  /// Example:
  /// ```dart
  /// var path = FieldPath.fromString('user.address.city');
  /// ```
  FieldPath.fromString(String path) : components = path.split('.');

  /// A special FieldPath to refer to the ID of the document.
  ///
  /// Returns:
  /// A [FieldPath] for the document ID.
  ///
  /// Example:
  /// ```dart
  /// query.where(FieldPath.documentId, isEqualTo: 'doc1');
  /// ```
  static FieldPath get documentId {
    List<String> newComponents = ['OID'];
    return FieldPath(newComponents);
  }

  @override
  String toString() {
    return getPathSec();
  }

  @override
  int get hashCode => Object.hashAll(components);

  @override
  bool operator ==(Object other) =>
      other is FieldPath &&
      const ListEquality().equals(other.components, components);

  /// Gets the dot-separated path string.
  ///
  /// Returns:
  /// The path as a string.
  ///
  /// Example:
  /// ```dart
  /// print(path.getPath()); // 'user.address.city'
  /// ```
  /// @nodoc
  String getPath() {
    String res = "";
    components.forEach((element) {
      res += element;
      res += ".";
    });
    if (res.isNotEmpty) {
      res = res.substring(0, res.length - 1);
    }
    return res;
  }

  /// Gets a special formatted path string.
  ///
  /// Returns:
  /// The formatted path.
  ///
  /// Example:
  /// ```dart
  /// print(path.getPathSec()); // '$FieldPath$user#FieldPath#address#FieldPath#city'
  /// ```
  /// @nodoc
  String getPathSec() {
    String res = "\$FieldPath\$";
    bool flag = false;
    components.forEach((element) {
      flag = true;
      res += element;
      res += "#FieldPath#";
    });
    if (flag) {
      res = res.substring(0, res.length - 11);
    }
    return res;
  }
}
