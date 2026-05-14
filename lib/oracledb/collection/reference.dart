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

// collection/reference.dart
part of '../../oracledb.dart';

/// Represents a reference to a collection of documents.
///
///
/// Parameters:
/// - [helper]: The query helper.
/// - [oracledb]: The FusabaseOracledb instance.
/// - [path]: The path to the collection.
/// - [parent_]: Optional parent reference.
///
/// Returns:
/// An instance of [CollectionReference].
///
/// Example:
/// ```dart
/// var collection = oracledb.collection('users');
/// ```
class CollectionReference<T extends Object?> extends Query<T> {
String _id; // oid
dynamic _parent;

/// Gets the ID of the collection.
String get id => _id;

/// Gets the parent document reference, if any.
DocumentReference<T>? get parent => _parent;

CollectionReference(
    {required QueryHelper helper,
    required FusabaseOracledb oracledb,
    required String path,
    dynamic parent_})
    : _id = "",
      super(
          helper: helper, oracledb: oracledb, path: path, parent: parent_) {
  path = path.toString().trim();
  List<String> tokens = path.split('/');

  _id = tokens.removeAt(tokens.length - 1);
  type = "collection";

  // if (_id == "") {
  //   throw Utils.oracledbErrorHandler(
  //       400, OracledbErrorMessages.incorrectDocumentId, null);
  // }
  if (parent_ != null) {
    _parent = parent_;
  } else {
    if (tokens.isEmpty) {
      _parent = null;
    } else {
      _parent = oracledb.doc(tokens.join('/'));
    }
  }
  _path = (_parent != null) ? [..._parent._path] : [];
  _path.add(_id);

  if (_path.length % 2 == 0) {
    throw Utils.oracledbErrorHandler(
        400, OracledbErrorMessages.incorrectCollectionPath, null);
  }

  if (_parent is CollectionReference) {
    throw Utils.oracledbErrorHandler(
        400, OracledbErrorMessages.notCollectionReference, null);
  }
}

/// Adds a new document to the collection with the given data.
///
/// Parameters:
/// - [data]: The data to add to the new document.
///
/// Returns:
/// A Future that resolves to the new [DocumentReference].
///
/// Example:
/// ```dart
/// var newDoc = await collection.add({'name': 'John'});
/// ```
Future<DocumentReference<T>> add(T data) async {
  if (data is! Map && toConverter != null) {
    data = toConverter(data);
  }
  dynamic document = null;
  FusabaseAuth auth = FusabaseAuth.instanceFor(app: super._oracledb.app);
  String? accessToken = await getAccessToken(auth);

  if (checkOracledbApiVersion(oracledb.app.options, OracledbVersion["VERSION_1"] ?? 1)) {
    document = setWholeData(this, {}, data, true);
    document = parseTimestamp(document);
  } else if (checkOracledbApiVersion(oracledb.app.options, OracledbVersion["VERSION_2"] ?? 2)) {
    document = setWholeData(this, {}, data, true);
    final embeddings = extractEmbeddingsMapForCreate(document);
    if (embeddings.isNotEmpty) {
      document.removeWhere((key, _) => embeddings.containsKey(key));
      document[r'$embeddings'] = embeddings;
    }
    document = parseTimestamp(document);
  }

  Map<String, dynamic> result = await _helper.createdoc(
      createClient(_oracledb.app), this, document, __logLevel, accessToken);

  if (result['OID'] == null) {
    throw Utils.oracledbErrorHandler(404, OracledbErrorMessages.docIdNotReturned, null);
  }
  DocumentReference<T> newDoc = DocumentReference<T>(
      helper: QueryHelper(),
      oracledb: _oracledb,
      path: "${_path.join('/')}/${result['OID']}",
      parent_: this);
  newDoc.fromConverter = fromConverter;
  newDoc.toConverter = toConverter;
  return newDoc;
}

/// Gets a [DocumentReference] for the document at the specified path.
///
/// Parameters:
/// - [path]: Optional path for the document (auto-generated if null).
///
/// Returns:
/// A [DocumentReference] instance.
///
/// Example:
/// ```dart
/// var docRef = collection.doc('user1');
/// ```
DocumentReference<T> doc([String? path]) {
  path ??= generateRandomString(15);
  DocumentReference<T> doc = DocumentReference(
      helper: QueryHelper(),
      oracledb: _oracledb,
      path: "${_path.join('/')}/$path",
      parent_: this);
  doc.toConverter = toConverter;
  doc.fromConverter = fromConverter;
  return doc;
}

/// Applies converters to the collection.
///
/// Parameters:
/// - [fromOracledb]: Converter from FusabaseOracledb data.
/// - [toOracledb]: Converter to FusabaseOracledb data.
///
/// Returns:
/// A new [CollectionReference] with converters applied.
///
/// Example:
/// ```dart
/// var convertedCol = collection.withConverter<User>(fromOracledb: User.fromMap, toOracledb: User.toMap);
/// ```
@override
CollectionReference<R> withConverter<R extends Object?>({
  required FromOracledb<R> fromOracledb,
  required ToOracledb<R> toOracledb,
}) {
  CollectionReference<R> col = CollectionReference<R> (helper:QueryHelper(),oracledb:this.oracledb,path:this.path);
  col.fromConverter = fromOracledb;
  col.toConverter = toOracledb;
  return col;
}
}
