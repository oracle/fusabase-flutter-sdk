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

part of "../../storage.dart";

/// A reference to a specific storage location.
///
/// This class points to a location in the storage bucket.
/// It provides methods to upload, download, delete, and manage metadata for objects at that location.
class Reference {
  String _bucket;
  String _name;
  Reference? _parent;
  late Reference _root;
  final FusabaseStorage storage;
  globals.LogLevel __logLevel;

  /// Constructs a new [Reference] instance.
  ///
  /// Parameters:
  /// - [storage]: The associated storage instance (required).
  /// - [fullPath]: The full path to the object.
  /// - [parent]: Optional parent reference.
  ///
  /// Throws: Error if the path is invalid (starts or ends with '/').
  ///
  /// Returns: A new [Reference] instance.
  ///
  /// Example:
  /// ```dart
  /// var ref = Reference(storage: myStorage, fullPath: 'images/stars.jpg');
  /// ```
  Reference({
    required this.storage,
    required String fullPath,
    Reference? parent,
  }) : _bucket = storage.bucket,
       _name = "",
       __logLevel = storage.app.logLevel,
       _parent = parent {
    fullPath = fullPath.trim();
    if (fullPath.isNotEmpty &&
        (fullPath[0] == '/' || fullPath[fullPath.length - 1] == '/')) {
      throw Utils.storageErrorHandler(
        400,
        StorageErrorMessages.format(StorageErrorMessages.INCORRECT_PATH, [
          fullPath,
        ]),
        null,
      );
    }

    List<String> tokens = fullPath.split('/');
    _name = tokens.removeAt(tokens.length - 1);

    _parent =
        (tokens.isEmpty && _name == "")
            ? null
            : Reference(
              storage: storage,
              fullPath: tokens.join("/"),
              parent: _parent,
            );

    _root = ((_parent == null) ? this : _parent?._root)!;
  }

  /// Gets the bucket name for this reference.
  ///
  /// Returns: The bucket string.
  String get bucket {
    return _bucket;
  }

  /// Overrides the hash code based on storage and full path.
  @override
  int get hashCode => Object.hash(storage, bucket, fullPath);

  /// Gets the parent reference.
  ///
  /// Returns: The parent [Reference] or null if root.
  Reference? get parent => _parent;

  /// Gets the name of the object at this reference.
  ///
  /// Returns: The object name string.
  String get name {
    return _name;
  }

  /// Gets the full path of this reference.
  ///
  /// Returns: The full path string.
  String get fullPath {
    //  return "CDAB.jpg";
    if (_name == "") return "";
    return (_parent?.fullPath == "") ? "$_name" : "${_parent?.fullPath}/$_name";
  }

  /// Gets the root reference.
  ///
  /// Returns: The root [Reference].
  Reference get root {
    return _root;
  }

  /// Creates a child reference from the given path.
  ///
  /// Parameters:
  /// - [path]: The child path.
  ///
  /// Returns: A new child [Reference].
  ///
  ///
  /// Example:
  /// ```dart
  /// var childRef = ref.child('subfolder/image.jpg');
  /// ```
  Reference child(String path) {
    if (path == "") return this;
    var childPath = "$fullPath/$path";
    if (fullPath == "") {
      childPath = "$path";
    }
    return Reference(storage: storage, fullPath: childPath, parent: this);
  }

  /// Retrieves the download URL for the object.
  ///
  /// Returns: A Future that resolves to the download URL string.
  ///
  ///
  /// Example:
  /// ```dart
  /// String url = await ref.getDownloadURL();
  /// ```
  Future<String> getDownloadURL() async {
    FusabaseAuth auth = FusabaseAuth.instanceFor(app: storage.app);
    String? accessToken = await getAccessToken(auth);

    Map<String, dynamic> data = await StorageHelper.getDownloadUrlHelper(
      createClient(storage.app),
      storage._config,
      storage._maxOperationRetryTime,
      _bucket,
      __logLevel,
      accessToken,
      fullPath,
    );

    return data["URL"];
  }

  /// Lists items and prefixes under this reference (non-recursive).
  ///
  /// Parameters:
  /// - [options]: Optional listing options.
  ///
  /// Returns: A Future that resolves to a [ListResult].
  ///
  ///
  /// Example:
  /// ```dart
  /// ListResult result = await ref.list(ListOptions(maxResults: 10));
  /// ```
  Future<ListResult> list([ListOptions? options]) async {
    FusabaseAuth auth = FusabaseAuth.instanceFor(app: this.storage.app);
    String? accessToken = await getAccessToken(auth);

    Map<String, dynamic> data = await StorageHelper.getlists(
      createClient(storage.app),
      storage._config,
      storage._maxOperationRetryTime,
      false,
      _bucket,
      __logLevel,
      fullPath,
      options,
      accessToken,
    );

    Map<String, List<Reference>> ref_map = Map<String, List<Reference>>();
    ref_map["items"] = [];
    ref_map["prefixes"] = [];

    for (var e in data["items"]) {
      Reference t_ref = Reference(
        storage: storage,
        fullPath: e,
        parent: _parent,
      );
      ref_map["items"]?.add(t_ref);
    }

    for (var e in data["prefixes"]) {
      Reference t_ref = Reference(
        storage: storage,
        fullPath: e,
        parent: _parent,
      );
      ref_map["prefixes"]?.add(t_ref);
    }

    return ListResult(storage, ref_map, data["nextPageToken"]);
  }

  /// Lists all items and prefixes under this reference (recursive).
  ///
  /// Returns: A Future that resolves to a [ListResult].
  ///
  ///
  /// Example:
  /// ```dart
  /// ListResult all = await ref.listAll();
  /// ```
  Future<ListResult> listAll() async {
    FusabaseAuth auth = FusabaseAuth.instanceFor(app: this.storage.app);
    String? accessToken = await getAccessToken(auth);

    Map<String, dynamic> data_res = await StorageHelper.getlists(
      createClient(storage.app),
      storage._config,
      storage._maxOperationRetryTime,
      true,
      _bucket,
      this.__logLevel,
      fullPath,
      null,
      accessToken,
    );

    Map<String, List<Reference>> ref_map = Map<String, List<Reference>>();
    ref_map["items"] = [];
    ref_map["prefixes"] = [];

    for (var e in data_res["items"]) {
      Reference t_ref = Reference(
        storage: storage,
        fullPath: e,
        parent: _parent,
      );
      ref_map["items"]?.add(t_ref);
    }

    for (var e in data_res["prefixes"]) {
      Reference t_ref = Reference(
        storage: storage,
        fullPath: e,
        parent: _parent,
      );
      ref_map["prefixes"]?.add(t_ref);
    }

    return ListResult(storage, ref_map, data_res["nextPageToken"]);
  }

  /// Deletes the object at this reference.
  ///
  /// Returns: A Future that completes when deletion is done.
  ///
  ///
  /// Example:
  /// ```dart
  /// await ref.delete();
  /// ```
  Future<void> delete() async {
    FusabaseAuth auth = FusabaseAuth.instanceFor(app: this.storage.app);
    String? accessToken = await getAccessToken(auth);

    await StorageHelper.deleteObject(
      createClient(storage.app),
      storage._config,
      storage._maxOperationRetryTime,
      _bucket,
      this.__logLevel,
      fullPath,
      accessToken,
    );
  }

  /// Uploads a file to this reference.
  ///
  /// Parameters:
  /// - [file]: The file to upload.
  /// - [metadata]: Optional metadata.
  ///
  /// Returns: An [UploadTask] to manage the upload.
  ///
  ///
  /// Example:
  /// ```dart
  /// UploadTask task = ref.putFile(myFile);
  /// ```
  UploadTask putFile(dynamic file, [SettableMetadata? metadata]) {
    metadata ??= SettableMetadata();
    metadata.contentType ??= "application/octet-stream";
    return UploadTask(file, storage, metadata, this);
  }

  /// Uploads data to this reference.
  ///
  /// Parameters:
  /// - [data]: The data to upload.
  /// - [metadata]: Optional metadata.
  ///
  /// Returns: An [UploadTask] to manage the upload.
  ///
  ///
  /// Example:
  /// ```dart
  /// UploadTask task = ref.putData(myData);
  /// ```
  UploadTask putData(Uint8List data, [SettableMetadata? metadata]) {
    metadata ??= SettableMetadata();
    metadata.contentType ??= "application/octet-stream";
    return UploadTask(data, storage, metadata, this);
  }

  /// Retrieves metadata for the object.
  ///
  /// Returns: A Future that resolves to [FullMetadata].
  ///
  ///
  /// Example:
  /// ```dart
  /// FullMetadata meta = await ref.getMetadata();
  /// ```
  Future<FullMetadata> getMetadata() async {
    FusabaseAuth auth = FusabaseAuth.instanceFor(app: this.storage.app);
    String? accessToken = await getAccessToken(auth);

    return await StorageHelper.fetchMetadata(
      client: createClient(storage.app),
      ref: this,
      config: storage._config,
      maxOperationRetryTime: storage._maxOperationRetryTime,
      logLevel: this.__logLevel,
      accessToken: accessToken,
    );
  }

  /// Downloads the data at this reference.
  ///
  /// Parameters:
  /// - [maxSize]: Optional maximum size in bytes (default 10MB).
  ///
  /// Returns: A Future that resolves to the data as [Uint8List] or null.
  ///
  /// Example:
  /// ```dart
  /// Uint8List? data = await ref.getData();
  /// ```
  Future<Uint8List?> getData([int maxSize = 10485760]) async {
    assert(maxSize > 0);
    if (maxSize <= 0) {
      throw Utils.storageErrorHandler(
        400,
        StorageErrorMessages.format(StorageErrorMessages.EXPECTED_TYPE, [
          'positive maxSize',
          maxSize.toString(),
        ]),
        null,
      );
    }

    final metadata = await getMetadata();
    final objectSize = metadata.size;
    if (objectSize == null) {
      throw Utils.storageErrorHandler(
        400,
        StorageErrorMessages.UNKNOWN_DOWNLOAD_SIZE,
        null,
      );
    }
    if (objectSize > maxSize) {
      throw Utils.storageErrorHandler(
        400,
        StorageErrorMessages.format(
          StorageErrorMessages.DOWNLOAD_EXCEEDS_MAX_SIZE,
          [objectSize, maxSize],
        ),
        null,
      );
    }

    FusabaseAuth auth = FusabaseAuth.instanceFor(app: this.storage.app);
    String? accessToken = await getAccessToken(auth);

    String url =
        "${StorageHelper.get_url(storage._config)}${globals.downloadObjRESTEP}";
    // if (StorageHelper.isPrem(storage._config)) {
    //   final_url = StorageHelper._PARequestURL(storage._config) + url;
    // } else {
    //   final_url = url;
    // }
    return StorageHelper.getDataHelper(
      createClient(storage.app),
      url,
      fullPath,
      bucket,
      storage._config,
      storage._maxDownloadRetryTime,
      __logLevel,
      accessToken,
    );
  }

  /// Downloads the object to a local file.
  ///
  /// Parameters:
  /// - [file]: The destination file.
  ///
  /// Returns: A [DownloadTask] to manage the download.
  ///
  /// Example:
  /// ```dart
  /// DownloadTask task = ref.writeToFile(myLocalFile);
  /// ```
  DownloadTask writeToFile(dynamic file) {
    return DownloadTask(file, storage, this);
  }

  /// Returns a string representation of this reference.
  @override
  String toString() =>
      '$Reference(app: ${storage.app.name}, fullPath: $fullPath)';

  /// Checks equality with another [Reference].
  @override
  bool operator ==(Object other) =>
      other is Reference &&
      other.fullPath == fullPath &&
      other.bucket == bucket &&
      other.storage == storage;
}
