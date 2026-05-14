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

part of '../../oracledb.dart';

/// The main FusabaseOracledb class, providing access to collections, documents, transactions, etc.
///
///
/// Parameters:
/// - [app]: The associated FusabaseApp instance.
///
/// Returns:
/// An instance of [FusabaseOracledb].
///
/// Example:
/// ```dart
/// var db = FusabaseOracledb(app: myApp);
/// ```
class FusabaseOracledb {
  FusabaseApp app;
  SnapshotStorage _snapStore;
  BundleStore _bundleStore;
  Settings settings;
  globals.LogLevel __logLevel;
  late WebSocketManager? _socketManager;
  List<String> _messageQueue;
  Map <String, String> _queryIdMap;
  Map <String, List<String>> _localQueryIdMap;
  Map <String, dynamic > _snapshotControllerMap;
  

  FusabaseOracledb({required this.app}) : this.__logLevel = app.logLevel, 
    settings = Settings(host:"",sslEnabled: false,webExperimentalLongPollingOptions: WebExperimentalLongPollingOptions(timeoutDuration: Duration(seconds: 29))),
    _snapStore = SnapshotStorage("${app.options.appID}_BAAS_SNAPS", "snapshots"),
    _queryIdMap = {},
    _messageQueue = [],
    _localQueryIdMap = {},
    _snapshotControllerMap = {},
    _bundleStore = BundleStore("${app.options.appID}_BAAS_BUNDLES", "bundles") {
      String socketURL = app.options.ordsHost;
      String cert = socketURL.split("://")[0];
      bool useSSL = true;
      if (cert == "http") {
        useSSL = false;
      }
      socketURL = socketURL.split("://")[1];
      String schemaName = socketURL.split("ords")[1];
      socketURL = socketURL.split("ords")[0];
      socketURL = "${socketURL}ords/baas-realtime$schemaName";
  
      settings = Settings(host:socketURL, sslEnabled: useSSL,
       webExperimentalForceLongPolling: !app.options.useSocket, webExperimentalAutoDetectLongPolling: app.options.useSocket,
       webExperimentalLongPollingOptions: WebExperimentalLongPollingOptions(timeoutDuration: Duration(seconds: app.options.longPollingInterval)));

      bool uselongPolling = settings.webExperimentalForceLongPolling ?? true;
      if (settings.webExperimentalForceLongPolling ?? true) {
        uselongPolling = true;
      }
      _socketManager = null;
      // if (!uselongPolling) {
      //   createSocketClient(app.auth).then((sManager) {
      //     _socketManager = sManager;
      //   });
      // } else {
      //   _socketManager = null;
      // }
      preSnapshot();
      
    }

  /// Gets a hash code for this FusabaseOracledb instance.
  @override
  int get hashCode => Object.hash(app.name, app.options);

  /// Creates or retrieves an FusabaseOracledb instance for the given app.
  ///
  /// Parameters:
  /// - [app]: The FusabaseApp instance.
  ///
  /// Returns:
  /// An [FusabaseOracledb] instance.
  ///
  /// Example:
  /// ```dart
  /// var db = FusabaseOracledb.instanceFor(app: myApp);
  /// ```
  static FusabaseOracledb instanceFor({required FusabaseApp app}) {
    app.store ??= FusabaseOracledb(app: app);
    
    return app.store ?? FusabaseOracledb(app: app);
  }

  /// Gets the default FusabaseOracledb instance for the default app.
  ///
  /// Returns:
  /// The default [FusabaseOracledb] instance.
  ///
  /// Example:
  /// ```dart
  /// var db = FusabaseOracledb.instance;
  /// ```
  static FusabaseOracledb get instance {
    return FusabaseOracledb.instanceFor(
      app: Fusabase.app(),
    );
  }

  /// Sends a message via the WebSocket.
  ///
  /// Parameters:
  /// - [message]: The message to send.
  ///
  /// Example:
  /// ```dart
  /// db.sendMessageSocket({'type': 'query', 'id': 1});
  /// ```
  /// @nodoc
  void sendMessageSocket (dynamic message) {
    // if (message.containsKey("payload")) {
    //   message["payload"] = jsonEncode(message["payload"]);
    // } 
    String messageString = jsonEncode(message);
    if (_socketManager == null) {
      return ;
    }
    if (!_socketManager!.sendMessage(messageString)) {
      _messageQueue.add(messageString);
    }
  }

  /// Prepares for snapshot listening by initializing WebSocket if needed.
  /// @nodoc
  Future<void> preSnapshot() async {
    bool uselongPolling = settings.webExperimentalForceLongPolling ?? true;

    if (!uselongPolling && (_socketManager == null || !_socketManager!.isConnected())) {
      _socketManager = await createSocketClient(app.auth);
    }
  }

  /// @nodoc
  Future<String> getSnapshotToken (http.Client client, String reqUrl,
   String accessToken, globals.LogLevel logLevel) async {
    dynamic response;
    dynamic result;

    Map<String, String> headers = Map<String, String>();
    if (accessToken != null) {
      headers["Authorization"] = "Bearer ${accessToken}";
    }

    try {
      response = await client.get(Uri.parse(reqUrl),
          headers: headers);
      Utils.checkResponse(logLevel, response);
      result = jsonDecode(response.body);
    } catch (e, stacktrace) {
      Utils.baasLogger(logLevel, "GET request");
      Utils.baasTrace(logLevel, reqUrl, headers, null, e, stacktrace);
      String errMessage = "";
      try {
        errMessage = jsonDecode(response.body)["error"];
      } catch (jsonErr) {
        errMessage = "$e";
      }
      throw Utils.oracledbErrorHandler(
          response.statusCode, errMessage, stacktrace);
    }
    return result["access_token"];
  }

  /// Creates and configures a WebSocket client.
  ///
  /// Parameters:
  /// - [auth]: The authentication object.
  ///
  /// Returns:
  /// A configured [WebSocketManager].
  /// @nodoc
  Future<WebSocketManager?> createSocketClient(dynamic auth) async {
    WebSocketManager _socketManager;
    String token = "";
    if (auth != null) {
      token = await getAccessToken(auth) ?? "";
    }
    String snapToken = "";
    if (token != null && token != "") {
      try {
        snapToken = await getSnapshotToken(createClient(app),'${app.options.ordsHost}_/baas-services/idm/onprem/${app.options.projectID}/authorizeSnapshot?apiKey=${app.options.appID}', token, app.logLevel);
      } catch (e) {
        return null;
      }
    }
    String host = getHostString(settings);
    _socketManager = WebSocketManager(url: "$host?authToken=$snapToken");

    _socketManager.onOpen = () {
      for (int i = 0; i<_messageQueue.length; i++) {
        _socketManager.sendMessage(_messageQueue[i]);
      }
    };

    _socketManager.onMessage = (message) async {
      dynamic data = jsonDecode(message);
      if (!data.containsKey("queryId")) {
        return ;
      }
      if (data.containsKey("success") || !data.containsKey("changedData")) {
        return ;
      }
      String dataQueryId = data["queryId"].toString();

      if (!_queryIdMap.containsKey(dataQueryId)) {
        return ; // return because we are not listenting to this query
      }

      String userLevelQueryId = _queryIdMap[dataQueryId] ?? "";
      
      if (userLevelQueryId == "") {
        return ;
      }

      dynamic oldData = await _snapStore.getData(userLevelQueryId, this);

      if (oldData == null) {
        // end stream (cleanout)
        _queryIdMap.remove(dataQueryId);
        if (_localQueryIdMap.containsKey(userLevelQueryId)) {
          for (int i=0;i<_localQueryIdMap[userLevelQueryId]!.length;i++) {
            _snapshotControllerMap.remove(_localQueryIdMap[userLevelQueryId]![i]);
          }
        }
        _localQueryIdMap.remove(userLevelQueryId);
        return ;
      }

      String rowId = data["rowId"];
      dynamic changedData = data["changedData"];
      String? oid = data["changedData"]["OID"];
      dynamic opr = data["operations"];
      dynamic query = oldData["snap"].query;
      
      changedData.remove("OID");
      
      if (oldData["snap"] is DocumentSnapshot) {
        DocumentSnapshot newSnap;
        if (opr[opr.length-1] == "DELETE") {
          changedData = oldData["snap"]._data;
        }
        var ver = null;
        var asof = null;
        var lastmod = null;
        if (changedData!=null && changedData["_metadata"]!=null) {
          ver = changedData["_metadata"]["etag"];
          asof = changedData["_metadata"]["asof"];
          changedData.remove("_metadata");
        }
        if (changedData!=null && changedData["LAST_MODIFIED"]!=null) {
          lastmod = changedData["LAST_MODIFIED"];
          changedData.remove("LAST_MODIFIED");
        }
        if (changedData!=null && changedData["VERSION"]!=null) {
          ver = changedData["VERSION"];
          changedData.remove("VERSION");
        }
        if (oldData["type"] == "dualityviewdocument") {
          DualityViewDocReference<Map<String, dynamic>> newDoc = dualityViewDoc(query.path);
          Map<String, dynamic> newData = {
            "DOCUMENT":changedData,
            "VERSION":ver,
            "ROWID":rowId,
            "CREATED":null,
            "LAST_MODIFIED":lastmod,
            "SUBCOLLECTION":null,
            "PARENT_OID":null,
            "OID":oid,
            "ASOF":asof
          };
          newSnap = DocumentSnapshot(newData,
            newDoc, SnapshotMetadata(hasPendingWrites: false, isFromCache: false),
          rowId);

        } else {
          DocumentReference<Map<String, dynamic>> newDoc = doc(query.path);
          Map<String, dynamic> newData = {
            "DOCUMENT":changedData,
            "VERSION":ver,
            "ROWID":rowId,
            "CREATED":null,
            "LAST_MODIFIED":lastmod,
            "SUBCOLLECTION":null,
            "PARENT_OID":null,
            "OID":oid,
            "ASOF":asof
          };
          newSnap = DocumentSnapshot(newData,
            newDoc, SnapshotMetadata(hasPendingWrites: false, isFromCache: false),
          rowId);
        }
       
        // now we have the new snapshot ready
        // update cache
        oldData["snap"] = newSnap;
        await _snapStore.updateData(oldData);

        //run the notifiers
        List<String> localQueryIds = _localQueryIdMap[userLevelQueryId] ?? [];
        for (int i =0;i<localQueryIds.length;i++) {
          dynamic controller = _snapshotControllerMap[localQueryIds[i]];
          controller(newSnap);
        }
      }
      else {
        // query level
        query._rt = 1;

        QuerySnapshot<dynamic> newSnap;
        QueryDocumentSnapshot qDocSnap;

        if (opr[opr.length-1]=='DELETE') {
          changedData = null;
          if (oid == null) {
            for (int i =0;i<oldData["snap"]._docs.length;i++) {
              if (oldData["snap"]._docs[i].rowID == rowId) {
                oid = oldData["snap"]._docs[i].id;
                changedData = oldData["snap"]._docs[i]._data;
                break;
              }
            }
          }
        }

        var ver = null;
        var asof = null;
        var lastmod = null;
        if (changedData!=null && changedData["_metadata"]!=null) {
          ver = changedData["_metadata"]["etag"];
          asof = changedData["_metadata"]["asof"];
          changedData.remove("_metadata");
        }
        if (changedData!=null && changedData["VERSION"]!=null) {
          ver = changedData["VERSION"];
          changedData.remove("VERSION");
        }
        if (changedData!=null && changedData["LAST_MODIFIED"]!=null) {
          lastmod = changedData["LAST_MODIFIED"];
          changedData.remove("LAST_MODIFIED");
        }

        if (oldData["type"] == "dualityviewcollection") {
          DualityViewColReference<Map<String, dynamic>> newCol = dualityViewCollection(query.path);
          query._helper.dupQuery(newCol, query);
          Map<String, dynamic> newData = {
            "DOCUMENT":changedData,
            "VERSION":ver,
            "ROWID":rowId,
            "CREATED":null,
            "LAST_MODIFIED":lastmod,
            "SUBCOLLECTION":null,
            "PARENT_OID":null,
            "OID":oid,
            "ASOF":asof
          };
          newSnap = QuerySnapshot([], newCol, 
            SnapshotMetadata(hasPendingWrites: false, isFromCache: false));
          qDocSnap = QueryDocumentSnapshot(newData, newCol, SnapshotMetadata(hasPendingWrites: false, isFromCache: false), rowId);

        } else {
          CollectionReference<Map<String, dynamic>> newCol = collection(query.path);
          query._helper.dupQuery(newCol, query);
          Map<String, dynamic> newData = {
            "DOCUMENT":changedData,
            "VERSION":ver,
            "ROWID":rowId,
            "CREATED":null,
            "LAST_MODIFIED":lastmod,
            "SUBCOLLECTION":null,
            "PARENT_OID":null,
            "OID":oid,
            "ASOF":asof
          };
          newSnap = QuerySnapshot([], newCol, 
            SnapshotMetadata(hasPendingWrites: false, isFromCache: false));
          qDocSnap = QueryDocumentSnapshot(newData, newCol, SnapshotMetadata(hasPendingWrites: false, isFromCache: false), rowId);
        }

        List<DocumentChange> docChanges = [];
        List<QueryDocumentSnapshot<dynamic>> docs = oldData["snap"]._docs;

        Map<String, int> indexMap = {};
        for (int i=0;i<docs.length;i++) {
          indexMap[docs[i].id] = i;
        }

        for (int i=opr.length-1;i>=0;i--) {
          if (opr[i] == "INSERT") {
            docs.add(qDocSnap);
            docChanges.add( DocumentChange(doc: qDocSnap, newIndex: docs.length-1,
                oldIndex: -1, type: DocumentChangeType.added));
          } else if (opr[i] == "UPDATE") {
            docs[indexMap[oid] ?? -1] = qDocSnap;
            docChanges.add(DocumentChange(doc: qDocSnap, newIndex: indexMap[oid] ?? -1,
                oldIndex: indexMap[oid] ?? -1, type: DocumentChangeType.modified));
          } else if (opr[i] == "DELETE") {
            docs.removeAt(indexMap[oid] ?? -1);
            docChanges.add(DocumentChange(doc: qDocSnap, newIndex: -1,
                oldIndex: indexMap[oid] ?? -1, type: DocumentChangeType.removed));
          }
          break;
        }
        
        newSnap._docs = docs;
        newSnap._docChanges = docChanges;
        newSnap._size = docs.length;
      
        oldData["snap"] = newSnap;
        await _snapStore.updateData(oldData);

        //run the notifiers
        List<String> localQueryIds = _localQueryIdMap[userLevelQueryId] ?? [];
        for (int i =0;i<localQueryIds.length;i++) {
          dynamic controller = _snapshotControllerMap[localQueryIds[i]];
          controller(copyAsMapSnapshot(newSnap));
        }
      }

    };
    _socketManager.onError = (error) => {};
    _socketManager.onClose = (code, reason) => {};
    _socketManager.connect();
    return _socketManager;
  }

  /// Terminates the FusabaseOracledb instance, clearing the app's store reference.
  ///
  /// Returns:
  /// A Future that completes when termination is done.
  ///
  /// Example:
  /// ```dart
  /// await db.terminate();
  /// ```
  Future<void> terminate() async {
    app.store = null;
  }

  @override
  /// Returns a string representation of this FusabaseOracledb instance.
  String toString() => '$FusabaseOracledb(app: ${app.name})';

  /// Checks equality with another FusabaseOracledb instance based on app name.
  @override
  bool operator ==(Object other) =>
      other is FusabaseOracledb && other.app.name == app.name;

  /// Gets a reference to a collection.
  ///
  /// Parameters:
  /// - [collectionPath]: The path to the collection.
  ///
  /// Returns:
  /// A [CollectionReference].
  ///
  /// Example:
  /// ```dart
  /// var col = db.collection('users');
  /// ```
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {

    return CollectionReference(
        helper: QueryHelper(),
        oracledb: instanceFor(app: app),
        path: collectionPath);
  }

  /// Gets a reference to a collection to do bulk update.
  ///
  /// Parameters:
  /// - [collectionPath]: The path to the collection.
  ///
  /// Returns:
  /// A [BulkUpdate].
  ///
  /// Example:
  /// ```dart
  /// var col = db.updateDocs('users');
  /// ```
  BulkUpdate updateDocs(String collectionPath) {

    return BulkUpdate(helper: QueryHelper(), oracledb: this, path: collectionPath);
  }

  /// Creates  a join query.
  ///
  /// Parameters:
  /// - [name]: The name of the view to join.
  ///
  /// Returns
  /// A new [Query] with the join added.
  ///
  /// Example:
  /// ```dart
  /// query = db.join('userDetails');
  /// ```
  Query join(String name) {
    Query newQuery =
        Query(helper: QueryHelper(), oracledb: this, path: name);
    newQuery._joins
        .add({"view_name": name});

    return newQuery;
  }

  /// Gets a reference to a duality view collection.
  ///
  /// Parameters:
  /// - [name]: The name of the duality view.
  ///
  /// Returns:
  /// A [DualityViewColReference].
  ///
  /// Example:
  /// ```dart
  /// var viewCol = db.dualityViewCollection('userView');
  /// ```
  DualityViewColReference<Map<String, dynamic>> dualityViewCollection(String name) {
    // Change the assertion message
    assert(
      name.isNotEmpty,
      'a collectionPath path must be a non-empty string',
    );
    assert(
      !name.contains('//'),
      'a collection path must not contain "//"',
    );

    return DualityViewColReference(
        helper: QueryHelper(),
        oracledb: instanceFor(app: app),
        path: name);
  }

  /// Gets a query over all collections with the given name (collection group query).
  ///
  /// Parameters:
  /// - [name]: The collection name.
  ///
  /// Returns:
  /// A [Query] for the collection group.
  ///
  /// Example:
  /// ```dart
  /// var groupQuery = db.collectionGroup('posts');
  /// ```
  Query<Map<String, dynamic>> collectionGroup(String name) {
    assert(
      name.isNotEmpty,
      'a collection path must be a non-empty string',
    );
    assert(
      !name.contains('/'),
      'a collection path passed to collectionGroup() cannot contain "/"',
    );

    Query<Map<String, dynamic>> newQuery = Query<Map<String, dynamic>>(
        helper: QueryHelper(), oracledb: this, path: name);

    newQuery._col_group = name;
    return newQuery;
  }

  /// Gets a reference to a document.
  ///
  /// Parameters:
  /// - [documentPath]: The path to the document.
  ///
  /// Returns:
  /// A [DocumentReference].
  ///
  /// Example:
  /// ```dart
  /// var docRef = db.doc('users/user1');
  /// ```
  DocumentReference<Map<String, dynamic>> doc(String documentPath) {
    // Change the assertion message
    assert(
      documentPath.isNotEmpty,
      'a document path must be a non-empty string',
    );
    assert(
      !documentPath.contains('//'),
      'a collection path must not contain "//"',
    );

    return DocumentReference(
        helper: QueryHelper(),
        oracledb: instanceFor(app: app),
        path: documentPath);
  }

  /// Gets a reference to a duality view document.
  ///
  /// Parameters:
  /// - [documentPath]: The path to the document.
  ///
  /// Returns:
  /// A [DualityViewDocReference].
  ///
  /// Example:
  /// ```dart
  /// var viewDoc = db.dualityViewDoc('viewName/doc1');
  /// ```
  DualityViewDocReference<Map<String, dynamic>> dualityViewDoc(String documentPath) {
    // Change the assertion message
    assert(
      documentPath.isNotEmpty,
      'a document path must be a non-empty string',
    );
    assert(
      !documentPath.contains('//'),
      'a collection path must not contain "//"',
    );

    return DualityViewDocReference(
        helper: QueryHelper(),
        oracledb: instanceFor(app: app),
        path: documentPath);
  }

  /// Runs a transaction.
  ///
  /// Parameters:
  /// - [transactionHandler]: The handler function for the transaction.
  /// - [timeout]: Optional timeout duration.
  /// - [maxAttempts]: Maximum retry attempts.
  ///
  /// Returns:
  /// A Future with the transaction result.
  ///
  /// Example:
  /// ```dart
  /// await db.runTransaction((transaction) async {
  ///   // transaction operations
  /// });
  /// ```
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    late T res;

    String transName = generateRandomString(25);
    Transaction trans = Transaction(name: transName);
    dynamic tempRes;
    bool success = false;
    int retry = maxAttempts;

    while (!success && retry > 0) {
      try {
        if (retry < maxAttempts) {
          trans.__reset();
        }

        res = await transactionHandler(trans);
        tempRes = await trans.__makeOperations();
        success = true;
      } catch (e) {
        if (retry == 1) {
          rethrow;
        }

        retry--;
        success = false;

        const int baseDelay = 50;
        const int maxDelay = 10000;
        final int delay = min(baseDelay * (1 << (maxAttempts - retry)), maxDelay);
        final double jitter = Random().nextDouble() * delay * 0.5;
        final int waitTime = (delay + jitter).round();
        await Future.delayed(Duration(milliseconds: waitTime));
      }
    }

    if (res != null) {
      return res;
    }

    return tempRes;
  }

  /// Creates a write batch for batch operations.
  ///
  /// Returns:
  /// A [WriteBatch] instance.
  ///
  /// Example:
  /// ```dart
  /// var batch = db.batch();
  /// batch.set(docRef, data);
  /// await batch.commit();
  /// ```
  WriteBatch batch() {
    String transName = generateRandomString(25);
    WriteBatch wBatch = WriteBatch(name: transName);
    return wBatch;
  }

  // LoadBundleTask loadBundle(Uint8List data) {
  //   LoadBundleTask task = LoadBundleTask(this, 10, data);
  //   task._initLoad();
  //   return task;
  // }

  // Future<QuerySnapshot<Map<String, dynamic>>> namedQueryGet(
  //   String name, {
  //   GetOptions options = const GetOptions(),
  // }) async {
  //   Query query = Query(helper:QueryHelper(), oracledb:this, path:name);
  //   query.type = "namedquery";

  //   dynamic data = await _bundleStore.getData(name);

  //   List<QueryDocumentSnapshot> docs = [];
  //   List<DocumentChange> docsChanged = [];
  //   for (var i =0;i<data["documents"].length;i++) {
  //     var path = data["documents"][i]["path"];
  //     var id = path.removeAt(path.length -1);
  //     docs.add(QueryDocumentSnapshot({
  //       "DOCUMENT":data["documents"][i]["data"],
  //       "OID":id
  //     }, CollectionReference(helper:
  //      QueryHelper(), oracledb:this, path: path), SnapshotMetadata(isFromCache:true, hasPendingWrites:false), null));

  //     docsChanged.add(DocumentChange(
  //         doc: DocumentSnapshot({
  //       "DOCUMENT":data["documents"][i]["data"],
  //       "OID":id
  //     }, DocumentReference(
  //               helper: QueryHelper(),
  //               oracledb: this,
  //               parent_: null,
  //               path: "$path/$id"),SnapshotMetadata(isFromCache:true, hasPendingWrites:false), null),
  //         newIndex: i,
  //         oldIndex: -1,
  //         type: DocumentChangeType.added));
      
  //   }
    

  //   QuerySnapshot querSnap = QuerySnapshot([], query, SnapshotMetadata(isFromCache:true, hasPendingWrites:false));
  //   querSnap._docs = docs;
  //   querSnap._docChanges = docsChanged;
  //   querSnap._size = docs.length;

  //   return querSnap as QuerySnapshot<Map<String, dynamic>>;
  // }

  // Future<QuerySnapshot<T>> namedQueryWithConverterGet<T>(
  //   String name, {
  //   GetOptions options = const GetOptions(),
  //   required FromOracledb<T> fromOracledb,
  //   required ToOracledb<T> toOracledb,
  // }) async {
  //   Query query = Query(helper:QueryHelper(), oracledb:this, path:name);
  //   query.type = "namedquery";
  //   query.fromConverter = fromOracledb;
  //   query.toConverter = toOracledb;

  //   dynamic data = await _bundleStore.getData(name);

  //   List<QueryDocumentSnapshot> docs = [];
  //   List<DocumentChange> docsChanged = [];
  //   for (var i =0;i<data["documents"].length;i++) {
  //     var path = data["documents"][i]["path"];
  //     var id = path.removeAt(path.length -1);

  //     CollectionReference colRef = CollectionReference(helper:
  //      QueryHelper(), oracledb:this, path: path);
  //     colRef.fromConverter = fromOracledb;
  //     colRef.toConverter = toOracledb;

  //     DocumentReference docRef = DocumentReference(
  //               helper: QueryHelper(),
  //               oracledb: this,
  //               parent_: null,
  //               path: "${path}/${id}");
  //     docRef.fromConverter = fromOracledb;
  //     docRef.toConverter = toOracledb;

  //     docs.add(QueryDocumentSnapshot({
  //       "DOCUMENT":data["documents"][i]["data"],
  //       "OID":id
  //     }, colRef, SnapshotMetadata(isFromCache:true, hasPendingWrites:false), null));

  //     docsChanged.add(DocumentChange(
  //         doc: DocumentSnapshot({
  //       "DOCUMENT":data["documents"][i]["data"],
  //       "OID":id
  //     }, docRef,SnapshotMetadata(isFromCache:true, hasPendingWrites:false), null),
  //         newIndex: i,
  //         oldIndex: -1,
  //         type: DocumentChangeType.added));
      
  //   }
    

  //   QuerySnapshot querSnap = QuerySnapshot([], query, SnapshotMetadata(isFromCache:true, hasPendingWrites:false));
  //   querSnap._docs = docs;
  //   querSnap._docChanges = docsChanged;
  //   querSnap._size = docs.length;

  //   return querSnap as QuerySnapshot<T>;
  // }
}
