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

/// Configuration values used by the storage service.
///
/// This class holds the necessary configuration parameters
///
/// Parameters:
/// - [host] (`String?`): Host URL for the storage service.
/// - [schema] (`String?`): Schema name.
/// - [projectID] (`String`): Project identifier.
/// - [module] (`String?`): Storage module name.
/// - [appID] (`String?`): Application identifier.
///
/// Returns: An instance of [FusabaseStorageConfig].
///
/// Example:
/// ```dart
/// var config = FusabaseStorageConfig(
///   host: 'example.com',
///   schema: 'https',
///   projectID: 'my-project',
///   module: 'storage',
///   appID: 'app-123',
/// );
/// ```
class FusabaseStorageConfig {
  String? host;
  String? schema;
  String? module;
  String projectID;
  String? appID;

  FusabaseStorageConfig({
    required this.host,
    required this.schema,
    required this.projectID,
    required this.module,
    required this.appID,
  });
}

class _StorageReferenceUrlParts {
  final String bucket;
  final String fullPath;

  const _StorageReferenceUrlParts({
    required this.bucket,
    required this.fullPath,
  });
}

/// The main entry point for accessing a storage bucket.
///
/// This class provides methods to interact with storage. It allows creating references, setting retry times, etc.
class FusabaseStorage {
  FusabaseApp app;
  FusabaseOptions? _options;
  FusabaseStorageConfig _config;
  String bucket;
  int _maxDownloadRetryTime;
  int _maxOperationRetryTime;
  int _maxUploadRetryTime;
  globals.LogLevel __logLevel;

  /// Overrides the hash code based on app name and bucket.
  @override
  int get hashCode => Object.hash(app.name, bucket);

  /// Creates or retrieves a storage instance for the given app.
  ///
  /// Parameters:
  /// - [app] ([FusabaseApp]): Application that owns the storage instance.
  ///
  /// Returns: An [FusabaseStorage] instance.
  ///
  /// Example:
  /// ```dart
  /// var storage = FusabaseStorage.instanceFor(app: myApp);
  /// ```
  static FusabaseStorage instanceFor({required FusabaseApp app}) {
    app.storage ??= FusabaseStorage(app: app);
    return app.storage ?? FusabaseStorage(app: app);
  }

  /// Gets the default storage instance for the default app.
  ///
  /// Returns: The default [FusabaseStorage] instance.
  ///
  /// Example:
  /// ```dart
  /// var storage = FusabaseStorage.instance;
  /// ```
  static FusabaseStorage get instance {
    return FusabaseStorage.instanceFor(app: Fusabase.app());
  }

  /// Constructs a new [FusabaseStorage] instance.
  ///
  /// Parameters:
  /// - [app] ([FusabaseApp]): Associated application.
  /// - [bucket] (`String?`): Optional bucket name. The configured bucket is
  ///   used when this is omitted.
  /// - [maxDownloadRetryTime] ([Duration?]): Maximum retry time for downloads.
  /// - [maxOperationRetryTime] ([Duration?]): Maximum retry time for other
  ///   operations.
  /// - [maxUploadRetryTime] ([Duration?]): Maximum retry time for uploads.
  ///
  /// Returns: A new [FusabaseStorage] instance.
  ///
  /// Example:
  /// ```dart
  /// var storage = FusabaseStorage(app: myApp, bucket: 'my-bucket');
  /// ```
  FusabaseStorage({
    required this.app,
    String? bucket,
    Duration? maxDownloadRetryTime,
    Duration? maxOperationRetryTime,
    Duration? maxUploadRetryTime,
  }) : bucket = app.options.storageBucket,
       _maxDownloadRetryTime = maxDownloadRetryTime?.inMilliseconds ?? 10000,
       _maxOperationRetryTime = maxOperationRetryTime?.inMilliseconds ?? 10000,
       _maxUploadRetryTime = maxUploadRetryTime?.inMilliseconds ?? 10000,
       _options = app.options,
       __logLevel = app.logLevel,
       _config = FusabaseStorageConfig(
         host: app.options.ordsHost,
         schema: app.options.schema,
         projectID: app.options.projectID,
         module: app.options.objsType,
         appID: app.options.appID,
       );

  /// Creates a new [Reference] from the given path.
  ///
  /// Parameters:
  /// - [path]: Optional path string; defaults to root.
  ///
  /// Returns: A [Reference] object.
  ///
  ///
  /// Example:
  /// ```dart
  /// var ref = storage.ref('images/stars.jpg');
  /// ```
  Reference ref([String? path]) {
    return Reference(storage: this, fullPath: path ?? "");
  }

  /// Creates a new [Reference] from a URL.
  ///
  /// Parameters:
  /// - [url]: The full URL to the object.
  ///
  /// Returns: A [Reference] object.
  ///
  ///
  /// Example:
  /// ```dart
  /// var ref = storage.refFromURL('https://objectstorage.region.oraclecloud.com/n/ns/b/bucket/o/images/stars.jpg');
  /// ```
  Reference refFromURL(String url) {
    final parts = _parseReferenceURL(url);
    final ref = Reference(storage: this, fullPath: parts.fullPath);
    ref._bucket = parts.bucket;
    return ref;
  }

  _StorageReferenceUrlParts _parseReferenceURL(String url) {
    final trimmedUrl = url.trim();
    final uri = Uri.tryParse(trimmedUrl);
    if (trimmedUrl.isEmpty ||
        uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        uri.host.isEmpty) {
      throw _invalidReferenceUrl();
    }

    final dbfsParts = _parseDbfsReferenceURL(uri);
    if (dbfsParts != null) {
      return dbfsParts;
    }

    final ociParts = _parseOciReferenceURL(uri);
    if (ociParts != null) {
      return ociParts;
    }

    throw _invalidReferenceUrl();
  }

  _StorageReferenceUrlParts? _parseDbfsReferenceURL(Uri uri) {
    final configHost = Uri.tryParse(_config.host ?? '');
    if (configHost == null ||
        configHost.host.isEmpty ||
        !_hasSameOrigin(uri, configHost)) {
      if (_looksLikeDbfsURL(uri)) {
        throw _invalidReferenceUrl(
          StorageErrorMessages.REFERENCE_URL_HOST_MISMATCH,
        );
      }
      return null;
    }

    final configSegments = configHost.pathSegments;
    final segments = uri.pathSegments;
    if (!_segmentsStartWith(segments, configSegments)) {
      if (_looksLikeDbfsURL(uri)) {
        throw _invalidReferenceUrl(
          StorageErrorMessages.REFERENCE_URL_HOST_MISMATCH,
        );
      }
      return null;
    }

    final start = configSegments.length;
    if (segments.length < start + 12 ||
        segments[start] != '_' ||
        segments[start + 1] != 'baas-services' ||
        segments[start + 2] != 'dbfs' ||
        segments[start + 3] != 'par') {
      return null;
    }

    if (segments[start + 4] != _config.projectID) {
      throw _invalidReferenceUrl(
        StorageErrorMessages.REFERENCE_URL_PROJECT_MISMATCH,
      );
    }

    if (segments[start + 5] != 'accessuri' ||
        segments[start + 6].isEmpty ||
        segments[start + 7] != 'r' ||
        segments[start + 8] != 'b' ||
        segments[start + 10] != 'o') {
      throw _invalidReferenceUrl();
    }

    return _referencePartsFromBucketAndPath(
      segments[start + 9],
      segments.sublist(start + 11),
    );
  }

  _StorageReferenceUrlParts? _parseOciReferenceURL(Uri uri) {
    final hostSegments = uri.host.toLowerCase().split('.');
    if (!hostSegments.contains('objectstorage')) {
      return null;
    }

    return _referencePartsFromBucketObjectSegments(uri.pathSegments);
  }

  _StorageReferenceUrlParts? _referencePartsFromBucketObjectSegments(
    List<String> segments,
  ) {
    for (var i = 0; i <= segments.length - 4; i++) {
      if (segments[i] == 'b' && segments[i + 2] == 'o') {
        return _referencePartsFromBucketAndPath(
          segments[i + 1],
          segments.sublist(i + 3),
        );
      }
    }
    return null;
  }

  _StorageReferenceUrlParts _referencePartsFromBucketAndPath(
    String bucket,
    List<String> pathSegments,
  ) {
    if (bucket.isEmpty ||
        pathSegments.isEmpty ||
        pathSegments.any((segment) => segment.isEmpty)) {
      throw _invalidReferenceUrl();
    }

    return _StorageReferenceUrlParts(
      bucket: bucket,
      fullPath: pathSegments.join('/'),
    );
  }

  bool _looksLikeDbfsURL(Uri uri) {
    final segments = uri.pathSegments;
    for (var i = 0; i <= segments.length - 4; i++) {
      if (segments[i] == '_' &&
          segments[i + 1] == 'baas-services' &&
          segments[i + 2] == 'dbfs' &&
          segments[i + 3] == 'par') {
        return true;
      }
    }
    return false;
  }

  bool _hasSameOrigin(Uri uri, Uri other) {
    return uri.scheme.toLowerCase() == other.scheme.toLowerCase() &&
        uri.host.toLowerCase() == other.host.toLowerCase() &&
        uri.port == other.port;
  }

  bool _segmentsStartWith(List<String> segments, List<String> prefix) {
    if (segments.length < prefix.length) {
      return false;
    }
    for (var i = 0; i < prefix.length; i++) {
      if (segments[i] != prefix[i]) {
        return false;
      }
    }
    return true;
  }

  FusabaseException _invalidReferenceUrl([String? message]) {
    return Utils.storageErrorHandler(
      400,
      message ?? StorageErrorMessages.INVALID_REFERENCE_URL,
      null,
    );
  }

  /// Gets the maximum time to retry operations other than uploads or downloads.
  ///
  /// Returns: The maximum retry time as [Duration].
  Duration get maxOperationRetryTime {
    return Duration(milliseconds: _maxOperationRetryTime);
  }

  /// Sets the maximum time to retry operations other than uploads or downloads.
  ///
  /// [time] ([Duration]) is the non-negative retry interval to use.
  ///
  /// Returns `void` after updating the retry limit.
  ///
  /// Example:
  /// ```dart
  /// storage.setMaxOperationRetryTime(const Duration(seconds: 20));
  /// ```
  void setMaxOperationRetryTime(Duration time) {
    assert(!time.isNegative);
    _maxOperationRetryTime = time.inMilliseconds;
  }

  /// Returns a string representation of this storage instance.
  @override
  String toString() => '$FusabaseStorage(app: ${app.name}, bucket: $bucket)';

  /// Checks equality with another [FusabaseStorage] instance.
  @override
  bool operator ==(Object other) =>
      other is FusabaseStorage &&
      other.app.name == app.name &&
      other.bucket == bucket;

  /// Gets the maximum time to retry upload operations.
  ///
  /// Returns: The maximum upload retry time as [Duration].
  Duration get maxUploadRetryTime {
    return Duration(milliseconds: _maxUploadRetryTime);
  }

  /// Sets the maximum time to retry upload operations.
  ///
  /// [time] ([Duration]) is the non-negative retry interval to use.
  ///
  /// Returns `void` after updating the retry limit.
  ///
  /// Example:
  /// ```dart
  /// storage.setMaxUploadRetryTime(const Duration(seconds: 30));
  /// ```
  void setMaxUploadRetryTime(Duration time) {
    assert(!time.isNegative);
    _maxUploadRetryTime = time.inMilliseconds;
  }

  /// Gets the maximum time to retry download operations.
  ///
  /// Returns: The maximum download retry time as [Duration].
  Duration get maxDownloadRetryTime {
    return Duration(milliseconds: _maxDownloadRetryTime);
  }

  /// Sets the maximum time to retry download operations.
  ///
  /// [time] ([Duration]) is the non-negative retry interval to use.
  ///
  /// Returns `void` after updating the retry limit.
  ///
  /// Example:
  /// ```dart
  /// storage.setMaxDownloadRetryTime(const Duration(seconds: 30));
  /// ```
  void setMaxDownloadRetryTime(Duration time) {
    assert(!time.isNegative);
    _maxDownloadRetryTime = time.inMilliseconds;
  }
}
