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

// collection/snapshot.dart

part of '../../oracledb.dart';

/// Represents a change to a document in a query result.
///
///
/// Parameters:
/// - [doc]: The changed document snapshot.
/// - [newIndex]: The index of the document in the new snapshot.
/// - [oldIndex]: The index of the document in the old snapshot.
/// - [type]: The type of change (added, modified, removed).
///
/// Returns:
/// An instance of [DocumentChange].
///
/// Example:
/// ```dart
/// var change = DocumentChange(doc: snapshot, newIndex: 1, oldIndex: 0, type: DocumentChangeType.modified);
/// ```
class DocumentChange {
  DocumentSnapshot _doc;
  int _newIndex;
  int _oldIndex;
  DocumentChangeType _type;

  DocumentChange(
      {required DocumentSnapshot doc,
      required int newIndex,
      required int oldIndex,
      required DocumentChangeType type})
      : _doc = doc,
        _newIndex = newIndex,
        _oldIndex = oldIndex,
        _type = type;

  /// Creates a [DocumentChange] from JSON data.
  ///
  /// Parameters:
  /// - [jsonString]: The JSON data to parse.
  ///
  /// Returns:
  /// A [DocumentChange] instance.
  ///
  /// Example:
  /// ```dart
  /// var change = DocumentChange.fromJson(jsonData);
  /// ```
  factory DocumentChange.fromJson(dynamic jsonString, dynamic db) {
    dynamic data = jsonString;
    return DocumentChange(
      doc: DocumentSnapshot.fromJson(data["doc"], db),
      newIndex : data["newIndex"],
      oldIndex : data["oldIndex"],
      type: DocumentChangeTypeExtension.fromString(data["ctype"])
       ?? DocumentChangeType.added
    );
  }

  /// Gets the changed document snapshot.
  DocumentSnapshot get doc => _doc;

  /// Gets the new index of the document.
  int get newIndex => _newIndex;

  /// Gets the old index of the document.
  int get oldIndex => _oldIndex;

  /// Gets the type of change.
  DocumentChangeType get type => _type;

  /// Converts the [DocumentChange] to JSON.
  ///
  /// Returns:
  /// A JSON map representation.
  ///
  /// Example:
  /// ```dart
  /// var json = change.toJson();
  /// ```
  dynamic toJson() {
    Map<String, dynamic> json = {
      'doc': _doc.toJson(),
      'newIndex': _newIndex,
      'oldIndex': _oldIndex,
      'ctype': _type.asString
    };
    return json;
  }
}

QuerySnapshot<Map<String, dynamic>> copyAsMapSnapshot(
  QuerySnapshot<Object?> source,
) {
  final List<dynamic> res = [];

  for (final doc in source.docs) {
    dynamic data = doc.data();

    res.add({
      "osons": {
        "DOCUMENT":data,
        "LAST_MODIFIED":doc._otherMetadata["LAST_MODIFIED"],
        "CREATED":doc._otherMetadata["CREATED"],
        "SUBCOLLECTION":doc._otherMetadata["SUBCOLLECTION"],
        "PARENT_OID":doc._otherMetadata["PARENT_OID"],
        "VERSION":doc._otherMetadata["VERSION"],
        "ASOF":doc._otherMetadata["ASOF"],
        "OID":doc.id
        },
      "brid": doc.rowID,
    });
  }

  QuerySnapshot<Map<String, dynamic>> newSnap = QuerySnapshot<Map<String, dynamic>>(
    res,
    source.query,
    source.metadata,
  );
  newSnap._docChanges = source.docChanges;
  return newSnap;
}


/// Represents a snapshot of the results of a query.
///
///
/// Parameters:
/// - [res]: The list of result documents.
/// - [query]: The query that produced this snapshot.
/// - [_metadata]: Metadata about the snapshot.
///
/// Returns:
/// An instance of [QuerySnapshot].
///
/// Example:
/// ```dart
/// var snapshot = QuerySnapshot(results, query, metadata);
/// ```
class QuerySnapshot<T extends Object?> {
  SnapshotMetadata _metadata;
  List<DocumentChange> _docChanges;
  dynamic query;
  List<QueryDocumentSnapshot<T>> _docs = [];
  int _size = 0;

  QuerySnapshot(List<dynamic> res, this.query, SnapshotMetadata _metadata)
      : _metadata = _metadata,
        _docChanges = [] {
    for (int i = 0; i < res.length; i++) {
      _docs.add(QueryDocumentSnapshot(res[i]["osons"], query, _metadata, res[i]["rid"]));
      DocumentReference docRef = DocumentReference(
                helper: QueryHelper(),
                oracledb: query._oracledb,
                parent_: null,
                path: "${query._path.join('/')}/${res[i]["osons"]["OID"]}");
      docRef.fromConverter = query.fromConverter;
      docRef.toConverter = query.toConverter;
      _docChanges.add(DocumentChange(
          doc: DocumentSnapshot(res[i]["osons"], docRef, _metadata, res[i]["rid"]),
          newIndex: _docs.length - 1,
          oldIndex: -1,
          type: DocumentChangeType.added));
    }

    _size = res.length;
  }

  /// Creates a [QuerySnapshot] from JSON data.
  ///
  /// Parameters:
  /// - [jsonString]: The JSON data to parse.
  ///
  /// Returns:
  /// A [QuerySnapshot] instance.
  ///
  /// Example:
  /// ```dart
  /// var snapshot = QuerySnapshot.fromJson(jsonData);
  /// ```
  factory QuerySnapshot.fromJson(dynamic jsonString, dynamic db) {
    dynamic data = jsonString;
    QuerySnapshot qSnap = QuerySnapshot([],
    data["type"] == "dualityviewcollection" ? DualityViewColReference(helper: QueryHelper(),
        oracledb: db,
        path: data["path"]) : CollectionReference(
        helper: QueryHelper(),
        oracledb: db,
        path: data["path"])
    ,SnapshotMetadata(hasPendingWrites: false,isFromCache: false));

    List<DocumentChange> docCh = [];
    List<QueryDocumentSnapshot<T>> docsList = [];
    
    for (var i =0;i<data["docChanges"].length;i++) {
      docCh.add(DocumentChange.fromJson(data["docChanges"][i], db));
    }
  
    for (var i =0;i<data["docs"].length;i++) {
      docsList.add(QueryDocumentSnapshot.fromJson(data["docs"][i]));
    }

    qSnap._docChanges = docCh;
    qSnap._docs = docsList;
    qSnap._size = data["size"];

    qSnap.query._conditions = data["conditions"];
    qSnap.query._aggregate = data["aggregate"];
    qSnap.query._explicitOrder = data["explicitOrder"];
    qSnap.query._joins = data["joins"];
    qSnap.query._col_group = data["col_group"];
    qSnap.query._limit = data["limit"];
    qSnap.query.type = data["type"];
    return qSnap as QuerySnapshot<T>;
  }

  /// Gets the metadata for this snapshot.
  SnapshotMetadata get metadata => _metadata;

  /// Gets the list of document changes since the last snapshot.
  List<DocumentChange> get docChanges => _docChanges;

  /// Gets the list of document snapshots.
  List<QueryDocumentSnapshot<T>> get docs => _docs;

  /// Gets the number of documents in the snapshot.
  int get size => _size;

  /// Converts the [QuerySnapshot] to JSON.
  ///
  /// Returns:
  /// A JSON map representation.
  ///
  /// Example:
  /// ```dart
  /// var json = snapshot.toJson();
  /// ```
  dynamic toJson() {
    List<dynamic> docCh = [];
    for (var i =0;i<docChanges.length;i++) {
      docCh.add(docChanges[i].toJson());
    }
    List<dynamic> docsList = [];
    for (var i =0;i<_docs.length;i++) {
      docsList.add(_docs[i].toJson());
    }
    Map<String, dynamic> json = {
      'docChanges': docCh,
      'docs': docsList,
      "size":_size,
      "conditions": query._conditions,
      "aggregate": query._aggregate,
      "explicitOrder": query._explicitOrder,
      "joins": query._joins,
      "col_group": query._col_group,
      "limit": query._limit,
      "path": query.path,
      "type": query.type
    };
    return json;
  }
}
