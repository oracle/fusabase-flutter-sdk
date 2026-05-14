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

// dualityview/reference.dart
part of '../../oracledb.dart';

/// Represents a reference to a collection in a duality view.
///
/// Extends [CollectionReference] for duality view specific behavior.
///
/// Parameters:
/// - [helper]: The query helper.
/// - [oracledb]: The FusabaseOracledb instance.
/// - [path]: The path to the collection.
/// - [parent]: Optional parent.
///
/// Returns:
/// An instance of [DualityViewColReference].
///
/// Example:
/// ```dart
/// var colRef = oracledb.dualityViewCollection('viewName');
/// ```
class DualityViewColReference<T extends Object?> extends CollectionReference<T> {

  @override
  DualityViewDocReference<T>? get parent => _parent;

  DualityViewColReference(
      {required super.helper,
      required super.oracledb,
      required super.path,
      super.parent_}) {

    type = "dualityviewcollection";

    if (_path.length > 1) {
      throw Utils.oracledbErrorHandler(
          400, OracledbErrorMessages.incorrectDualityViewPath, null);
    }
  }

  @override
  /// Adds a new document to the collection.
  ///
  /// Parameters:
  /// - [data]: The data to add.
  ///
  /// Returns:
  /// A Future that resolves to the new document reference.
  ///
  /// Example:
  /// ```dart
  /// var newDoc = await colRef.add({'name': 'New Item'});
  /// ```
  Future<DualityViewDocReference<T>> add(T data) async {
    FusabaseAuth auth = FusabaseAuth.instanceFor(app: super._oracledb.app);
    String? accessToken = await getAccessToken(auth);
    dynamic document = null;

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
        createClient(_oracledb.app), this, document, this.__logLevel, accessToken);

    if (result['OID'] == null) {
      throw Utils.oracledbErrorHandler(404, OracledbErrorMessages.docIdNotReturned, null);
    }
    return DualityViewDocReference<T>(
        helper: QueryHelper(),
        oracledb: _oracledb,
        path: "${_path.join('/')}/${result['OID']}",
        parent_: this);
  }

  @override
  /// Gets a reference to a document in the collection.
  ///
  /// Parameters:
  /// - [path]: Optional path to the document.
  ///
  /// Returns:
  /// A [DualityViewDocReference].
  ///
  /// Example:
  /// ```dart
  /// var docRef = colRef.doc('docId');
  /// ```
  DualityViewDocReference<T> doc([String? path]) {
    path ??= generateRandomString(15);
    DualityViewDocReference<T> newDoc = DualityViewDocReference(
        helper: QueryHelper(),
        oracledb: _oracledb,
        path: "${_path.join('/')}/$path",
        parent_: this);
    newDoc.toConverter = toConverter;
    newDoc.fromConverter = fromConverter;
    return newDoc;
  }

  @override
  /// Applies converters to the collection reference.
  ///
  /// Parameters:
  /// - [fromOracledb]: Converter from FusabaseOracledb data.
  /// - [toOracledb]: Converter to FusabaseOracledb data.
  ///
  /// Returns:
  /// A new [DualityViewColReference] with converters.
  ///
  /// Example:
  /// ```dart
  /// var convertedCol = colRef.withConverter<User>(fromOracledb: User.fromMap, toOracledb: User.toMap);
  /// ```
  DualityViewColReference<R> withConverter<R extends Object?>({
    required FromOracledb<R> fromOracledb,
    required ToOracledb<R> toOracledb,
  }) {
    DualityViewColReference<R> col = DualityViewColReference<R> (helper:QueryHelper(),oracledb:this.oracledb,path:this.path);
    col.fromConverter = fromOracledb;
    col.toConverter = toOracledb;
    return col;
  }
}

/// Represents a reference to a document in a duality view.
///
/// Extends [DocumentReference] for duality view specific behavior.
///
/// Parameters:
/// - [helper]: The query helper.
/// - [oracledb]: The FusabaseOracledb instance.
/// - [path]: The path to the document.
/// - [parent_]: Optional parent.
///
/// Returns:
/// An instance of [DualityViewDocReference].
///
/// Example:
/// ```dart
/// var docRef = oracledb.dualityViewCollection('viewName').doc('docId');
/// ```
class DualityViewDocReference<T extends Object?> extends DocumentReference<T> {

  @override
  DualityViewColReference<T> get parent => _parent as DualityViewColReference<T>;

  DualityViewDocReference(
      {required super.helper,
      required FusabaseOracledb oracledb,
      required String path,
      dynamic parent_})
      : super(oracledb: oracledb, path: path) {

    path = path.toString().trim();
    List<String> tokens = path.split('/');
    type = "dualityviewdocument";

    if (tokens.length > 2) {
      throw Utils.oracledbErrorHandler(
          400, OracledbErrorMessages.incorrectDualityViewDocPath, null);
    }

    _id = tokens.removeAt(tokens.length - 1);
    if (_id == "") {
      throw Utils.oracledbErrorHandler(
          400, OracledbErrorMessages.incorrectDualityViewDocId, null);
    }
    _path = [];
    if (parent_ != null) {
      _parent = parent_;
    } else {
      if (tokens.isEmpty) {
        _parent = null;
      } else {
        _parent = oracledb.dualityViewCollection(tokens.join('/'));
      }
    }
    _path = (_parent != null) ? [...(_parent?._path ?? [])] : [];
    _path.add(_id);

    if (_parent == null) {
      throw Utils.oracledbErrorHandler(
          400, OracledbErrorMessages.parentCollectionCannotBeNull, null);
    }
  }

  @override
  /// Gets a subcollection reference. Throws error as subcollections not supported in duality view.
  ///
  /// Parameters:
  /// - [collectionPath]: The path to the subcollection.
  ///
  /// Returns:
  /// Throws an error.
  ///
  /// Example:
  /// ```dart
  /// // This will throw an error
  /// docRef.collection('subcol');
  /// ```
  DualityViewColReference<Map<String, dynamic>> collection(String collectionPath) {
    throw Utils.oracledbErrorHandler(
          400, "Subcollections are not supported in duality view.", null);
  }

  @override
  /// Applies converters to the document reference.
  ///
  /// Parameters:
  /// - [fromOracledb]: Converter from FusabaseOracledb data.
  /// - [toOracledb]: Converter to FusabaseOracledb data.
  ///
  /// Returns:
  /// A new [DualityViewDocReference] with converters.
  ///
  /// Example:
  /// ```dart
  /// var convertedDoc = docRef.withConverter<User>(fromOracledb: User.fromMap, toOracledb: User.toMap);
  /// ```
  DualityViewDocReference<R> withConverter<R>({
    required FromOracledb<R> fromOracledb,
    required ToOracledb<R> toOracledb,
  }) {
    DualityViewDocReference<R> doc = DualityViewDocReference<R> (helper:QueryHelper(),oracledb:this.oracledb,path:this.path);
    doc.fromConverter = fromOracledb;
    doc.toConverter = toOracledb;
    return doc;
  }
}
