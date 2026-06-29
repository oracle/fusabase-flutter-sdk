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

/// Represents a reference to a specific document.
///
///
/// Parameters:
/// - [helper]: The query helper.
/// - [oracledb]: The FusabaseOracledb instance.
/// - [path]: The path to the document.
/// - [parent_]: Optional parent reference.
///
/// Returns:
/// An instance of [DocumentReference].
///
/// Example:
/// ```dart
/// var docRef = oracledb.doc('users/user1');
/// ```
class DocumentReference<T extends Object?> {
  FusabaseOracledb _oracledb;
  globals.LogLevel __logLevel;
  List<dynamic> _serverTimestamp = [];
  QueryHelper _helper;
  String _id; // oid
  String type;
  dynamic _parent; // Need to make it non nullable ow we have null safety issues
  List<String> _path = [];
  int _rt;
  final _controller = StreamController<DocumentSnapshot<T>>();
  dynamic fromConverter;
  dynamic toConverter;
  Map<String, dynamic>? _vectorSearch;

  /// Gets the ID of the document.
  String get id => _id;

  /// Gets the FusabaseOracledb instance.
  FusabaseOracledb get oracledb => _oracledb;

  /// Gets the path of the document.
  String get path => _path.join('/');

  /// Gets the parent collection reference.
  CollectionReference<T> get parent => _parent;

  DocumentReference({
    required QueryHelper helper,
    required FusabaseOracledb oracledb,
    required String path,
    dynamic parent_,
  }) : _id = "",
       _helper = helper,
       _rt = 0,
       __logLevel = oracledb.app.logLevel,
       type = "document",
       _vectorSearch = null,
       _oracledb = oracledb {
    path = path.toString().trim();
    List<String> tokens = path.split('/');

    this._id = tokens.removeAt(tokens.length - 1);

    if (_id == "") {
      throw Utils.oracledbErrorHandler(
        400,
        OracledbErrorMessages.incorrectDocumentId,
        null,
      );
    }
    _path = [];
    if (parent_ != null) {
      _parent = parent_;
    } else {
      if (tokens.isEmpty) {
        _parent = null;
      } else {
        _parent = oracledb.collection(tokens.join('/'));
      }
    }

    _path = (_parent != null) ? [...(_parent?._path ?? [])] : [];
    _path.add(_id);

    if (_path.length % 2 != 0) {
      throw Utils.oracledbErrorHandler(400, "Incorrect document path.", null);
    }

    if (_parent == null) {
      throw Utils.oracledbErrorHandler(
        400,
        OracledbErrorMessages.parentCollectionCannotBeNull,
        null,
      );
    }

    if (_parent is DocumentReference) {
      throw Utils.oracledbErrorHandler(400, "Parent can't be a document", null);
    }
  }

  /// Updates fields in the document.
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
      transObj = {"name": "", "start": 0, "end": 0};
    }
    ;
    FusabaseAuth auth = FusabaseAuth.instanceFor(app: this._oracledb.app);
    dynamic finalData = convertMap(data);
    String? accessToken = await getAccessToken(auth);

    if (checkOracledbApiVersion(
      _oracledb.app.options,
      OracledbVersion["VERSION_1"] ?? 1,
    )) {
      dynamic docData;
      dynamic transData = null;
      if (transObj != null) {
        transData = {
          "name": transObj["name"],
          "start": transObj["start"],
          "end": 0,
          "version": transObj["version"],
        };
      }
      try {
        docData = await this.get(null, transData);
        if (transObj != null && transObj["start"] == 1) {
          transObj["start"] = 0;
        }
      } catch (e) {
        throw Utils.oracledbErrorHandler(
          404,
          OracledbErrorMessages.noSuchDocument,
          null,
        );
      }
      finalData = updateNestedData(this, docData._data, finalData);
      finalData = parseTimestamp(finalData);
    } else if (checkOracledbApiVersion(
      _oracledb.app.options,
      OracledbVersion["VERSION_2"] ?? 2,
    )) {
      finalData = createPayloadForUpdateVersion2New(this, finalData, false);
      finalData = parseTimestamp(finalData);
      finalData = rearrangeBodyOfVersion2(finalData);
    }

    dynamic result = await _helper.updatedoc(
      createClient(_oracledb.app),
      this,
      finalData,
      this.__logLevel,
      accessToken,
      transObj,
    );
    if (result["OID"] == null) {
      throw Utils.oracledbErrorHandler(
        500,
        OracledbErrorMessages.errorFetchingDocumentUpdate,
        null,
      );
    }
    return;
  }

  /// Gets a [CollectionReference] for the nested collection.
  ///
  /// Parameters:
  /// - [collectionPath]: The path to the collection.
  ///
  /// Returns:
  /// A [CollectionReference] instance.
  ///
  /// Example:
  /// ```dart
  /// var subCollection = docRef.collection('orders');
  /// ```
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    CollectionReference<Map<String, dynamic>> col =
        CollectionReference<Map<String, dynamic>>(
          helper: QueryHelper(),
          oracledb: _oracledb,
          path: "${_path.join('/')}/$collectionPath",
          parent_: this,
        );
    col.toConverter = this.toConverter;
    col.fromConverter = this.fromConverter;
    return col;
  }

  /// Deletes the document.
  ///
  /// Parameters:
  /// - [transObj]: Optional transaction object.
  ///
  /// Returns:
  /// A Future that completes when the delete is done.
  ///
  /// Example:
  /// ```dart
  /// await docRef.delete();
  /// ```
  Future<void> delete([dynamic transObj]) async {
    if (transObj == null) {
      transObj = {"name": "", "start": 0, "end": 0};
    }
    ;
    FusabaseAuth auth = FusabaseAuth.instanceFor(app: this._oracledb.app);
    String? accessToken = await getAccessToken(auth);

    await _helper.deletedoc(
      createClient(_oracledb.app),
      this,
      this.__logLevel,
      accessToken,
      transObj,
    );
    return;
  }

  /// Sets the data for the document, optionally merging.
  ///
  /// Parameters:
  /// - [data]: The data to set.
  /// - [options]: Optional set options (merge, etc.).
  /// - [transObj]: Optional transaction object.
  ///
  /// Returns:
  /// A Future that completes when the set is done.
  ///
  /// Example:
  /// ```dart
  /// await docRef.set({'name': 'John'}, SetOptions(merge: true));
  /// ```
  Future<void> set(T data, [SetOptions? options, dynamic transObj]) async {
    if (toConverter != null) {
      data = toConverter(data);
    }
    if (options == null) {
      options = SetOptions(merge: false);
    }
    if (transObj == null) {
      transObj = {"name": "", "start": 0, "end": 0};
    }
    ;
    FusabaseAuth auth = FusabaseAuth.instanceFor(app: this._oracledb.app);
    dynamic finalData = convertMap(data as Map<Object, Object?>);

    String? accessToken = await getAccessToken(auth);

    if (checkOracledbApiVersion(
      _oracledb.app.options,
      OracledbVersion["VERSION_1"] ?? 1,
    )) {
      if (options != null &&
          (options.merge == true ||
              (options.mergeFields != null &&
                  options.mergeFields!.isNotEmpty))) {
        dynamic docData;
        try {
          docData = await get(null, {
            "name": transObj["name"],
            "start": transObj["start"],
            "end": 0,
            "version": transObj["version"],
          });
          if (transObj["start"] == 1) {
            transObj["start"] = 0;
          }
        } catch (e) {
          final error = Exception("No such doc exists!");
          throw error;
        }
        finalData = updateNestedData(
          this,
          docData._data,
          convertMap(finalData),
        );
      } else {
        finalData = setWholeData(this, {}, convertMap(finalData), false);
      }
      finalData = parseTimestamp(finalData);
    } else if (checkOracledbApiVersion(
      _oracledb.app.options,
      OracledbVersion["VERSION_2"] ?? 2,
    )) {
      if (options != null && options.merge == true) {
        finalData = createPayloadForUpdateVersion2New(
          this,
          finalData,
          options.merge ?? true,
        );
      } else {
        finalData = setWholeData(this, {}, convertMap(finalData), true);
        finalData = serializeVersion2(this, finalData, false);
      }
      finalData = parseTimestamp(finalData);
      finalData = rearrangeBodyOfVersion2(finalData);
    }

    dynamic result = await _helper.setdoc(
      client: createClient(_oracledb.app),
      docRef: this,
      data: finalData,
      logLevel: this.__logLevel,
      accessToken: accessToken,
      options: options,
      transObj: transObj,
    );
    if (result["OID"] == null) {
      throw Utils.oracledbErrorHandler(500, "setDoc failed!", null);
    }
    return;
  }

  /// Gets the document snapshot.
  ///
  /// Parameters:
  /// - [options]: Optional get options.
  /// - [transObj]: Optional transaction object.
  ///
  /// Returns:
  /// A Future that resolves to the [DocumentSnapshot].
  ///
  /// Example:
  /// ```dart
  /// var snapshot = await docRef.get();
  /// ```
  Future<DocumentSnapshot<T>> get([
    GetOptions? options,
    dynamic transObj,
  ]) async {
    FusabaseAuth auth = FusabaseAuth.instanceFor(app: this._oracledb.app);
    String? accessToken = await getAccessToken(auth);
    if (transObj == null) {
      transObj = {"name": "", "start": 0, "end": 0};
    }
    ;

    Map<String, dynamic> result;
    try {
      result = await _helper.get(
        createClient(_oracledb.app),
        options,
        this,
        __logLevel,
        accessToken,
        transObj,
      );
    } catch (e) {
      return DocumentSnapshot<T>(
        {"DOCUMENT": null, "OID": this._id, "VERSION": 0},
        this,
        SnapshotMetadata(hasPendingWrites: false, isFromCache: false),
        null,
      ); // If Path doesn't exist Check it..
    }
    if (result["ret"].length == 0) {
      return DocumentSnapshot<T>(
        {"DOCUMENT": null, "OID": this._id, "VERSION": 0},
        this,
        SnapshotMetadata(hasPendingWrites: false, isFromCache: false),
        null,
      );
    }

    return DocumentSnapshot<T>(
      result["ret"][0]["osons"],
      this,
      SnapshotMetadata(hasPendingWrites: false, isFromCache: false),
      result["ret"][0]["brid"],
    ); // If Path doesn't exist Check it..
  }

  /// Applies converters to the document reference.
  ///
  /// Parameters:
  /// - [fromOracledb]: Converter from FusabaseOracledb data.
  /// - [toOracledb]: Converter to FusabaseOracledb data.
  ///
  /// Returns:
  /// A new [DocumentReference] with converters applied.
  ///
  /// Example:
  /// ```dart
  /// var convertedDoc = docRef.withConverter<User>(fromOracledb: User.fromMap, toOracledb: User.toMap);
  /// ```
  DocumentReference<R> withConverter<R>({
    required FromOracledb<R> fromOracledb,
    required ToOracledb<R> toOracledb,
  }) {
    DocumentReference<R> doc = DocumentReference<R>(
      helper: QueryHelper(),
      oracledb: this.oracledb,
      path: this.path,
    );
    doc.fromConverter = fromOracledb;
    doc.toConverter = toOracledb;
    return doc;
  }

  /// Returns a stream of snapshots for the document.
  ///
  /// Parameters:
  /// - [includeMetadataChanges]: Whether to include metadata changes.
  /// - [source]: The source for listening.
  ///
  /// Returns:
  /// A stream of [DocumentSnapshot] events.
  ///
  /// Example:
  /// ```dart
  /// docRef.snapshots().listen((snapshot) { /* handle snapshot */ });
  /// ```
  Stream<DocumentSnapshot<T>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    late StreamController<DocumentSnapshot<T>> controller;
    this._rt = 1;
    var lastDocUpdate = null;
    Timer? _pollingTimer;

    bool uselongPolling =
        _oracledb.settings.webExperimentalForceLongPolling ?? true;
    if (_oracledb.settings.webExperimentalForceLongPolling ?? true) {
      uselongPolling = true;
    }

    //uselongPolling = false;

    if (uselongPolling) {
      controller = StreamController<DocumentSnapshot<T>>.broadcast(
        onListen: () async {
          controller.add(await this.get());
        },
        onCancel: () {
          _pollingTimer?.cancel();
        },
      );

      final pollingInterval = _safeLongPollingInterval(_oracledb.settings);

      Future<void> longPolling() async {
        DocumentSnapshot newSnap = await this.get();
        var newVer = null;
        if (newSnap._otherMetadata["ASOF"] != null) {
          newVer = BigInt.from(newSnap._otherMetadata["ASOF"]);
        } else {
          newVer = newSnap._otherMetadata["VERSION"];
        }
        if (lastDocUpdate == null ||
            (newVer != null && lastDocUpdate < newVer)) {
          controller.add(newSnap as DocumentSnapshot<T>);
        }

        lastDocUpdate = newVer;
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
      FusabaseAuth auth = FusabaseAuth.instanceFor(app: _oracledb.app);
      var email = auth.currentUser?.email ?? "";
      var userLvlPayload = {
        "path": this._path,
        "conditions": [],
        "explicitOrder": [],
        "access_token": email,
      };

      // this query id is used to store in the cache (user level)
      int queryIdInt = createHashFromJson(userLvlPayload);
      String queryId = queryIdInt.toString();

      var socketPayload = {
        "path": this._path,
        "conditions": [],
        "explicitOrder": [],
      };

      // this query id is used to register listener (common for each query)
      int queryIdSocketInt = createHashFromJson(socketPayload);
      String queryIdSocket = queryIdSocketInt.toString();

      // this query id is used to store the notifiers (unique each time)
      String localQueryId = generateRandomHash();

      Future<DocumentSnapshot<T>> firstPoll() async {
        dynamic oldData = await oracledb._snapStore.getData(queryId, oracledb);

        DocumentSnapshot newSnap = await get();

        if (oldData == null) {
          //first snapshot
          await oracledb._snapStore.insertData({
            "queryId": queryId,
            "snap": newSnap,
            "type": "document",
            "path": path,
          });
        } else {
          await oracledb._snapStore.updateData({
            "queryId": queryId,
            "snap": newSnap,
            "type": "document",
            "path": path,
          });
        }
        return newSnap as DocumentSnapshot<T>;
      }

      dynamic payload = {
        "queryId": queryIdSocketInt,
        "status": 1,
        "payload": socketPayload,
      };

      void addToController(dynamic snap) {
        if (!controller.isClosed) {
          controller.add(snap as DocumentSnapshot<T>);
        }
      }

      controller = StreamController<DocumentSnapshot<T>>.broadcast(
        onListen: () async {
          isCancelled = false;
          await _oracledb.preSnapshot();
          if (isCancelled) {
            return;
          }
          _oracledb._queryIdMap[queryIdSocket] = queryId;
          List<String> localQueryIds = _oracledb._localQueryIdMap.putIfAbsent(
            queryId,
            () => [],
          );
          if (!localQueryIds.contains(localQueryId)) {
            localQueryIds.add(localQueryId);
          }
          _oracledb._snapshotControllerMap[localQueryId] = addToController;
          hasRegisteredRealtimeListener = true;
          _oracledb.sendMessageSocket(payload);
          dynamic fsnap = await firstPoll();
          if (!isCancelled && !controller.isClosed) {
            controller.add(fsnap);
          }
        },
        onCancel: () {
          isCancelled = true;
          if (!hasRegisteredRealtimeListener) {
            return;
          }
          hasRegisteredRealtimeListener = false;
          if (_oracledb._snapshotControllerMap.containsKey(localQueryId)) {
            _oracledb._snapshotControllerMap.remove(localQueryId);
          }
          if (_oracledb._localQueryIdMap.containsKey(queryId) &&
              _oracledb._localQueryIdMap[queryId]!.contains(localQueryId)) {
            _oracledb._localQueryIdMap[queryId]?.remove(localQueryId);
          }
          if (!_oracledb._localQueryIdMap.containsKey(queryId) ||
              _oracledb._localQueryIdMap[queryId]!.isEmpty) {
            _oracledb._localQueryIdMap.remove(queryId);
            _oracledb._queryIdMap.remove(queryIdSocket);
            dynamic unsubPayload = {
              "queryId": queryIdSocketInt,
              "status": 0,
              "payload": socketPayload,
            };
            _oracledb.sendMessageSocket(unsubPayload);
          }
        },
      );

      return controller.stream;
    }
  }
}
