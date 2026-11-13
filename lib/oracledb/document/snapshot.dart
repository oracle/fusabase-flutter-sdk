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

// document/snapshot.dart
part of '../../oracledb.dart';

/// Represents a snapshot of a document.
///
///
/// Parameters:
/// - [data]: The document data.
/// - [reference]: The reference to the document.
/// - [metadata]: Snapshot metadata.
/// - [rowID]: Optional row ID.
///
/// Returns:
/// An instance of [DocumentSnapshot].
///
/// Example:
/// ```dart
/// var snapshot = DocumentSnapshot(data, ref, metadata, rowID);
/// ```
class DocumentSnapshot<T extends Object?> {
  final dynamic _data;
  dynamic _parsedData;
  final SnapshotMetadata _metadata; // Snapshot Metadata
  final DocumentReference<T> _reference;
  final bool _exists;
  final Map<String, dynamic> _otherMetadata;
  final String id;
  final dynamic version;
  final String? rowID;

  /// Accesses a field in the document data.
  ///
  /// Parameters:
  /// - [field]: The field to access.
  ///
  /// Returns:
  /// The value of the field.
  ///
  /// Example:
  /// ```dart
  /// var value = snapshot['fieldName'];
  /// ```
  dynamic operator [](Object field) {
    return get(field);
  }

  DocumentReference<T> get reference => _reference;
  bool get exists => _exists;
  SnapshotMetadata get metadata => _metadata;


  DocumentSnapshot(Map<String, dynamic> data, this._reference, this._metadata, this.rowID)
      : _data = parseTimeInDocument(jsonDecode(jsonEncode(data["DOCUMENT"]))),
        _parsedData = null,
        _exists = data["DOCUMENT"] != null,
        _otherMetadata = {
          "LAST_MODIFIED": data["LAST_MODIFIED"],
          "CREATED": data["CREATED"],
          "SUBCOLLECTION": data["SUBCOLLECTION"],
          "PARENT_OID": data["PARENT_OID"],
          "VERSION": data["VERSION"] ?? data["BAAS_VERSION"],
          "ASOF": data["ASOF"]
        },
        id = data["OID"],
        version = data["VERSION"] ?? data["BAAS_VERSION"] {
          if (this._reference.fromConverter != null) {
            this._parsedData = this._reference.fromConverter(this);
          }

        }

  /// Creates a [DocumentSnapshot] from JSON data.
  ///
  /// Parameters:
  /// - [jsonString]: The JSON data to parse.
  /// - [db]: The database instance that owns the restored reference.
  ///
  /// Returns:
  /// A [DocumentSnapshot] instance.
  ///
  /// Example:
  /// ```dart
  /// var snapshot = DocumentSnapshot.fromJson(jsonData);
  /// ```
  factory DocumentSnapshot.fromJson(dynamic jsonString, dynamic db) {
    dynamic data = jsonString;
    return DocumentSnapshot(
      {
        "DOCUMENT": data["data"],
        "OID": data["id"],
        "CREATED": data["otherMetadata"]["CREATED"],
        "LAST_MODIFIED": data["otherMetadata"]["LAST_MODIFIED"],
        "SUBCOLLECTION": data["otherMetadata"]["SUBCOLLECTION"],
        "PARENT_OID": data["otherMetadata"]["PARENT_OID"],
        "ASOF": data["otherMetadata"]["ASOF"],
        "VERSION": data["version"],
      },
      data["type"] == "dualityviewdocument"
          ? DualityViewDocReference(
              helper: QueryHelper(),
              oracledb: db,
              path: data["path"])
          : DocumentReference(
              helper: QueryHelper(),
              oracledb: db,
              path: data["path"]),
      SnapshotMetadata(hasPendingWrites: false, isFromCache: false),
      data["rowid"],
    );
  }

  /// Gets the data of the document.
  ///
  /// Applies converter if available.
  ///
  /// Returns:
  /// The document data.
  ///
  /// Example:
  /// ```dart
  /// var data = snapshot.data();
  /// ```
  T? data() {
    if (_parsedData != null) {
      return _parsedData as T?;
    }
    return _data as T?;
  }

  /// Gets the value of a specific field.
  ///
  /// Parameters:
  /// - [field]: The field to get (string or FieldPath).
  ///
  /// Returns:
  /// The field value.
  ///
  /// Example:
  /// ```dart
  /// var value = snapshot.get('fieldName');
  /// ```
  dynamic get(Object field) {
    final dynamic data = this._data ?? {};
    if (field is FieldPath) {
      field = field.getPath();
      return Utils.getObjectProperty(data, field);
    }
    return data[field];
  }

  /// Converts the snapshot to JSON.
  ///
  /// Returns:
  /// A JSON map representation.
  ///
  /// Example:
  /// ```dart
  /// var json = snapshot.toJson();
  /// ```
  dynamic toJson() {
    Map<String, dynamic> json = {
      'exists': _exists,
      'id': id,
      'version': version,
      'rowid': rowID,
      'otherMetadata': _otherMetadata,
      'data': parseTimestamp(_data),
      'type': _reference.type,
      'path': _reference.path
    };
    return json;
  }
}

/// Represents a snapshot of a document from a query.
///
/// Extends [DocumentSnapshot] for query results.
///
/// Parameters:
/// - [data]: The document data.
/// - [query]: The query reference.
/// - [metadata]: Snapshot metadata.
/// - [rowID]: Optional row ID.
///
/// Returns:
/// An instance of [QueryDocumentSnapshot].
///
/// Example:
/// ```dart
/// var querySnapshot = QueryDocumentSnapshot(data, query, metadata, rowID);
/// ```
class QueryDocumentSnapshot<T extends Object?> extends DocumentSnapshot<T> {
  @override
  final dynamic _data; // Override to make it T, but since super has dynamic, we can cast in data()

  QueryDocumentSnapshot(
      Map<String, dynamic> data, dynamic query, dynamic metadata, dynamic rowID)
      : _data = parseTimeInDocument(jsonDecode(jsonEncode(data["DOCUMENT"]))),
        super(data,
            query.type == "dualityviewcollection"
                ? DualityViewDocReference(
                    helper: QueryHelper(),
                    oracledb: query._oracledb,
                    path: "${query._path.join('/')}/${data["OID"]}")
                : DocumentReference(
                    helper: QueryHelper(),
                    oracledb: query._oracledb,
                    path: "${query._path.join('/')}/${data["OID"]}"),
            metadata, rowID);

  /// Creates a [QueryDocumentSnapshot] from JSON data.
  ///
  /// Parameters:
  /// - [jsonString]: The JSON data to parse.
  /// - [db]: The database instance that owns the restored reference.
  ///
  /// Returns:
  /// A [QueryDocumentSnapshot] instance.
  ///
  /// Example:
  /// ```dart
  /// var snapshot = QueryDocumentSnapshot.fromJson(jsonData, database);
  /// ```
  factory QueryDocumentSnapshot.fromJson(dynamic jsonString, dynamic db) {
    dynamic data = jsonString;
    return QueryDocumentSnapshot(
      {
        "DOCUMENT": data["data"],
        "OID": data["id"],
        "CREATED": data["otherMetadata"]["CREATED"],
        "LAST_MODIFIED": data["otherMetadata"]["LAST_MODIFIED"],
        "SUBCOLLECTION": data["otherMetadata"]["SUBCOLLECTION"],
        "PARENT_OID": data["otherMetadata"]["PARENT_OID"],
        "VERSION": data["otherMetadata"]["VERSION"],
        "ASOF": data["otherMetadata"]["ASOF"]
      },
      data["ref_type"] == "dualityviewdocument"
          ? DualityViewDocReference(
                  helper: QueryHelper(),
                  oracledb: db,
                  path: data["path"])
              .parent
          : DocumentReference(
                  helper: QueryHelper(),
                  oracledb: db,
                  path: data["path"])
              .parent,
      SnapshotMetadata(hasPendingWrites: false, isFromCache: false),
      data["rowid"],
    );
  }

  @override
  /// Gets the data of the document.
  ///
  /// Returns:
  /// The document data.
  ///
  /// Example:
  /// ```dart
  /// var data = querySnapshot.data();
  /// ```
  T data() {
    if (_parsedData == null && _reference.fromConverter != null) {
      _parsedData = _reference.fromConverter(_data);
    }
    return (_parsedData ?? _data) as T;
  }

  @override
  /// Converts the snapshot to JSON.
  ///
  /// Returns:
  /// A JSON map representation.
  ///
  /// Example:
  /// ```dart
  /// var json = querySnapshot.toJson();
  /// ```
  dynamic toJson() {
    Map<String, dynamic> json = {
      'exists': _exists,
      'id': id,
      'rowid': rowID,
      'version': version,
      'otherMetadata': _otherMetadata,
      'data': parseTimestamp(_data),
      'ref_type': _reference.type,
      'path': _reference.path
    };
    return json;
  }
}
