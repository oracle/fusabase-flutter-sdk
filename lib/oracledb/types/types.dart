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

// types/types.dart - Enums, typedefs, and small classes for OracleDB SDK

part of '../../oracledb.dart';

/// Defines sources for getting data.
enum Source { server }

/// Defines sources for aggregate queries.
enum AggregateSource { server }

/// Defines sources for listening.
enum ListenSource { defaultSource }

/// Configuration for array operations.
enum ArrayConfig { contains }

/// Scope for queries (collection or collection group).
enum QueryScope { collection, collectionGroup}

/// Behavior for server timestamps in snapshots.
enum ServerTimestampBehavior { none, estimate, previous }

/// Types of document changes.
enum DocumentChangeType { added, modified, removed }

/// States of a load bundle task.
/// @nodoc
enum LoadBundleTaskState { running, success, error }

/// Order directions for queries.
enum Order { ascending, descending }

/// Function type for converting data to FusabaseOracledb format.
///
/// Parameters:
/// - [value]: The value to convert.
/// - [options]: Optional set options.
///
/// Returns:
/// A Map for FusabaseOracledb.
typedef ToOracledb<T> = Map<String, Object?> Function(
  T value,
  SetOptions? options,
);

/// Function type for converting FusabaseOracledb snapshot to custom type.
///
/// Parameters:
/// - [snapshot]: The document snapshot.
/// - [options]: Optional snapshot options.
///
/// Returns:
/// The converted object.
typedef FromOracledb<T> = T Function(
  DocumentSnapshot<Map<String, dynamic>> snapshot,
  SnapshotOptions? options,
);

/// Handler function for transactions.
///
/// Parameters:
/// - [transaction]: The transaction object.
///
/// Returns:
/// A Future with the result.
typedef TransactionHandler<T> = Future<T> Function(Transaction transaction);

/// Options for snapshots, including server timestamp behavior.
///
/// Example:
/// ```dart
/// var options = SnapshotOptions();
/// options.serverTimestamps = ServerTimestampBehavior.estimate;
/// ```
class SnapshotOptions {
  ServerTimestampBehavior serverTimestamps;

  SnapshotOptions () : serverTimestamps = ServerTimestampBehavior.none;
}

/// Equality checker for lists.
///
/// Parameters:
/// - [elEquality]: Optional equality for elements.
///
/// Example:
/// ```dart
/// var eq = ListEquality();
/// eq.equals([1,2], [1,2]);
/// ```
class ListEquality <E> {
  final Equality<E> _eleInternal;

  const ListEquality(
    [Equality<E> elEquality = const DefaultEquality<Never>()])
    : _eleInternal = elEquality;

  @override
  bool equals(List<E>? ele1, List<E>? ele2) {
    if (ele1 == null || ele2 == null) {
      return false;
    }
    var l1 = ele1.length;
    var l2 = ele2.length;
    if (l1 != l2) {
      return false;
    }
    if (identical(ele1, ele2)) {
      return true;
    }
    for (var j = 0; j < l1; j++) {
      if (!_eleInternal.equals(ele1[j], ele2[j])) {
        return false;
      }
    }
    return true;
  }

  @override
  int hash(List<E>? other) {
    if (other == null) {
      return null.hashCode;
    } 
    var hash = 0;
    for (var j = 0; j < other.length; j++) {
      hash = (hash + _eleInternal.hash(other[j]));
      hash = hash & hashCode;
      hash ^= (((hash + (hash << 10)) & hashCode) >> 6);
    }
    hash ^= (((hash + (hash << 3)) & hashCode) >> 11);
    return (hash + (hash << 15)) & hashCode;
  }

  @override
  bool isValidKey(Object? key) {
    return key is List<E>;
  }
}

/// Extension for DocumentChangeType with string conversion.
extension DocumentChangeTypeExtension on DocumentChangeType {
  String get asString => toString().split('.').last;

  /// Converts string to DocumentChangeType.
  ///
  /// Parameters:
  /// - [value]: The string value.
  ///
  /// Returns:
  /// The corresponding DocumentChangeType or null.
  static DocumentChangeType? fromString(String value) {
    switch (value) {
      case 'added':
        return DocumentChangeType.added;
      case 'modified':
        return DocumentChangeType.modified;
      case 'removed':
        return DocumentChangeType.removed;
      default:
        return null;  // Return null if the string does not match any enum value
    }
  }
}

/// Options for long polling in web experimental mode.
///
/// Parameters:
/// - [timeoutDuration]: Optional timeout duration.
///
/// Example:
/// ```dart
/// var options = WebExperimentalLongPollingOptions(timeoutDuration: Duration(seconds: 30));
/// ```
class WebExperimentalLongPollingOptions {
  final Duration? timeoutDuration;

  const WebExperimentalLongPollingOptions({
    this.timeoutDuration,
  });

  /// Gets the options as a map.
  Map<String, dynamic> get asMap {
    return {'timeoutDuration': timeoutDuration?.inSeconds};
  }
  @override
  int get hashCode => Object.hash(runtimeType, timeoutDuration);

  @override
  bool operator ==(Object other) =>
      other is WebExperimentalLongPollingOptions &&
      other.timeoutDuration == timeoutDuration;
}

/// Settings for FusabaseOracledb configuration.
///
/// Parameters:
/// Various optional parameters like persistenceEnabled, host, etc.
///
/// Example:
/// ```dart
/// db.settings = db.settings.copyWith(
///   webExperimentalForceLongPolling: true,
///   webExperimentalLongPollingOptions: const WebExperimentalLongPollingOptions(
///     timeoutDuration: Duration(seconds: 15),
///   ),
/// );
/// ```
class Settings {
  final bool? webExperimentalAutoDetectLongPolling;
  final bool? webExperimentalForceLongPolling;
  bool ignoreUndefinedProperties;
  final String? host;
  final bool? persistenceEnabled;
  final int? cacheSizeBytes;
  final bool? sslEnabled;
  final WebExperimentalLongPollingOptions? webExperimentalLongPollingOptions;

  Settings({
    this.persistenceEnabled = false,
    this.host,
    this.sslEnabled,
    this.cacheSizeBytes = 0,
    this.webExperimentalForceLongPolling = true,
    this.webExperimentalAutoDetectLongPolling = true,
    this.webExperimentalLongPollingOptions,
    this.ignoreUndefinedProperties = false,
  });

  /// Gets the settings as a map.
  Map<String, dynamic> get asMap {
    return {
      'persistenceEnabled': persistenceEnabled,
      'host': host,
      'sslEnabled': sslEnabled,
      'cacheSizeBytes': cacheSizeBytes,
      'webExperimentalForceLongPolling': webExperimentalForceLongPolling,
      'webExperimentalAutoDetectLongPolling': webExperimentalAutoDetectLongPolling,
      'webExperimentalLongPollingOptions': webExperimentalLongPollingOptions?.asMap,
      'ignoreUndefinedProperties': ignoreUndefinedProperties,
    };
  }

  @override
  int get hashCode => Object.hash(
        runtimeType,
        webExperimentalAutoDetectLongPolling,
        ignoreUndefinedProperties,
      );

  @override
  String toString() => 'Settings($asMap)';

  @override
  bool operator ==(Object other) =>
      other is Settings &&
      other.runtimeType == runtimeType &&
      other.webExperimentalAutoDetectLongPolling == webExperimentalAutoDetectLongPolling && 
      other.ignoreUndefinedProperties == ignoreUndefinedProperties;

  /// Creates a copy with modified fields.
  ///
  /// Parameters:
  /// Optional parameters to override.
  ///
  /// Returns:
  /// A new [Settings] instance.
  Settings copyWith({
    bool? persistenceEnabled,
    String? host,
    bool? sslEnabled,
    int? cacheSizeBytes,
    bool? webExperimentalForceLongPolling,
    bool? webExperimentalAutoDetectLongPolling,
    bool? ignoreUndefinedProperties,
    WebExperimentalLongPollingOptions? webExperimentalLongPollingOptions,
  }) {
    assert(cacheSizeBytes == null || cacheSizeBytes > 0,'Offline persistence is not supported.');
    return Settings(
      persistenceEnabled: persistenceEnabled ?? this.persistenceEnabled,
      host: host ?? this.host,
      sslEnabled: sslEnabled ?? this.sslEnabled,
      cacheSizeBytes: cacheSizeBytes ?? this.cacheSizeBytes,
      webExperimentalForceLongPolling: webExperimentalForceLongPolling ?? this.webExperimentalForceLongPolling,
      webExperimentalAutoDetectLongPolling: webExperimentalAutoDetectLongPolling ?? this.webExperimentalAutoDetectLongPolling,
      webExperimentalLongPollingOptions: webExperimentalLongPollingOptions ?? this.webExperimentalLongPollingOptions,
      ignoreUndefinedProperties: ignoreUndefinedProperties ?? this.ignoreUndefinedProperties,
    );
  }
}

/// Options for get operations.
///
/// Parameters:
/// - [source]: The data source.
/// - [serverTimestampBehavior]: Timestamp behavior.
///
/// Example:
/// ```dart
/// var options = GetOptions(source: Source.server);
/// ```
class GetOptions {
  final ServerTimestampBehavior serverTimestampBehavior;
  final Source source;

  const GetOptions({
    this.source = Source.server,
    this.serverTimestampBehavior = ServerTimestampBehavior.none,
  });
}

/// Options for set operations.
///
/// Parameters:
/// - [merge]: Whether to merge.
/// - [mergeFields]: Fields to merge.
///
/// Example:
/// ```dart
/// var options = SetOptions(merge: true);
/// ```
class SetOptions {
  final bool? merge;
  final List<FieldPath>? mergeFields;

  SetOptions({
    this.merge,
    List<Object>? mergeFields,
  })  : assert(
          (merge != null) ^ (mergeFields != null),
          "options must provide either 'merge' or 'mergeFields'",
        ),
        mergeFields = mergeFields?.map((field) {
          assert(
            field is String || field is FieldPath,
            '[mergeFields] can only contain Strings or FieldPaths but got $field',
          );
          if (field is String) return FieldPath.fromString(field);
          return field as FieldPath;
        }).toList(growable: false);
}

/// Metadata for snapshots.
///
/// Parameters:
/// - [isFromCache]: Whether from cache.
/// - [hasPendingWrites]: Whether has pending writes.
///
/// Example:
/// ```dart
/// var meta = SnapshotMetadata(isFromCache: true, hasPendingWrites: false);
/// ```
class SnapshotMetadata {
  bool _isFromCache;
  bool _hasPendingWrites;

  SnapshotMetadata({required bool isFromCache, required bool hasPendingWrites})
      : _isFromCache = isFromCache,
        _hasPendingWrites = hasPendingWrites;

  bool get isFromCache => _isFromCache;
  bool get hasPendingWrites => _hasPendingWrites;
}

/// Snapshot of a load bundle task progress.
///
/// Parameters:
/// - [totalBytes]: Total bytes.
/// - [totalDocuments]: Total documents.
///
/// Example:
/// ```dart
/// var snap = LoadBundleTaskSnapshot(1000, 10);
/// ```
/// @nodoc
class LoadBundleTaskSnapshot {
  int _bytesLoaded;
  int _documentsLoaded;
  LoadBundleTaskState _taskState;
  int _totalBytes;
  int _totalDocuments;

  LoadBundleTaskSnapshot (int totalBytes, int totalDocuments) : 
    _bytesLoaded = 0,
    _documentsLoaded = 0,
    _taskState = LoadBundleTaskState.running,
    _totalBytes = totalBytes,
    _totalDocuments = totalDocuments;

  /// @nodoc
  int get bytesLoaded => _bytesLoaded;
  /// @nodoc
  int get documentsLoaded => _documentsLoaded;
  /// @nodoc
  LoadBundleTaskState get taskState => _taskState;
  /// @nodoc
  int get totalBytes => _totalBytes;
  /// @nodoc
  int get totalDocuments => _totalDocuments;
}
