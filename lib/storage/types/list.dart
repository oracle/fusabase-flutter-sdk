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

/// Represents the result of a list operation on a storage reference.
///
/// This class holds the items, prefixes, and pagination token from a listing.
class ListResult {
  List<Reference> _items;
  dynamic _nextPageToken;
  List<Reference> _prefixes;
  final FusabaseStorage storage;

  /// Constructs a [ListResult] from the given data.
  ///
  /// Parameters:
  /// - [storage]: The associated storage instance.
  /// - [data]: A map containing 'items', 'prefixes', and 'nextPageToken'.
  ///
  /// Returns: A new [ListResult] instance.
  ///
  /// Example:
  /// ```dart
  /// var result = ListResult(myStorage, {'items': [...], 'prefixes': [...], 'nextPageToken': 'token'});
  /// ```
  ListResult(
    FusabaseStorage storage,
    Map<String, List<Reference>> data,
    dynamic token,
  ) : _items = data["items"] ?? [],
      _prefixes = data["prefixes"] ?? [],
      _nextPageToken = token,
      storage = storage;

  /// Gets the list of references to objects.
  ///
  /// Returns: A list of [Reference] objects.
  List<Reference> get items {
    return _items;
  }

  /// Gets the list of references to prefixes (directories).
  ///
  /// Returns: A list of [Reference] objects for prefixes.
  List<Reference> get prefixes {
    return _prefixes;
  }

  /// Gets the token for the next page of results.
  ///
  /// Returns: The next page token string or null.
  String? get nextPageToken {
    return _nextPageToken.toString();
  }
}

/// Represents the full metadata of a storage object.
///
/// This class provides access to all metadata fields.
class FullMetadata {
  Map<String, dynamic> _metadata;

  /// Constructs a [FullMetadata] from the given metadata map.
  ///
  /// Parameters:
  /// - [_metadata]: The metadata map.
  ///
  /// Returns: A new [FullMetadata] instance.
  ///
  /// Example:
  /// ```dart
  /// var meta = FullMetadata({'bucket': 'my-bucket', 'name': 'file.txt'});
  /// ```
  FullMetadata(this._metadata);

  /// Gets the bucket name.
  ///
  /// Returns: The bucket string or null.
  String? get bucket {
    return this._metadata["bucket"];
  }

  /// Gets the cache control header.
  ///
  /// Returns: The cache control string or null.
  String? get cacheControl {
    return this._metadata["cacheControl"];
  }

  /// Gets the content disposition header.
  ///
  /// Returns: The content disposition string or null.
  String? get contentDisposition {
    return this._metadata["contentDisposition"];
  }

  /// Gets the content encoding header.
  ///
  /// Returns: The content encoding string or null.
  String? get contentEncoding {
    return this._metadata["contentEncoding"];
  }

  /// Gets the content language header.
  ///
  /// Returns: The content language string or null.
  String? get contentLanguage {
    return this._metadata["contentLanguage"];
  }

  /// Gets the content type header.
  ///
  /// Returns: The content type string or null.
  String? get contentType {
    return this._metadata["contentType"];
  }

  /// Gets the generation number.
  ///
  /// Returns: The generation string or null.
  String? get generation {
    return this._metadata["generation"];
  }

  /// Gets the metadata generation number.
  ///
  /// Returns: The metadata generation string or null.
  String? get metadataGeneration {
    return this._metadata["metadataGeneration"];
  }

  /// Gets the metageneration number.
  ///
  /// Returns: The metageneration string or null.
  String? get metageneration {
    return this._metadata["metageneration"];
  }

  /// Gets the MD5 hash.
  ///
  /// Returns: The MD5 hash string or null.
  String? get md5Hash {
    return this._metadata["md5Hash"];
  }

  /// Gets the custom metadata map.
  ///
  /// Returns: A map of custom metadata or null.
  Map<String, String>? get customMetadata {
    return this._metadata["customMetadata"];
  }

  /// Gets the full path of the object.
  ///
  /// Returns: The full path string.
  String get fullPath {
    return this._metadata["fullPath"];
  }

  /// Gets the name of the object.
  ///
  /// Returns: The name string.
  String get name {
    return this._metadata["name"];
  }

  /// Gets the size of the object in bytes.
  ///
  /// Returns: The size integer or null.
  int? get size {
    final raw = this._metadata["size"];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  /// Gets the creation time.
  ///
  /// Returns: The creation [DateTime] or null.
  DateTime? get timeCreated {
    final raw = _metadata["timeCreated"];
    if (raw == null) return null;

    // Try standard ISO8601
    try {
      return DateTime.parse(raw);
    } catch (_) {}

    // Try HTTP Date
    try {
      return HttpDate.parse(raw);
    } catch (_) {}

    // Try Oracle
    return parseOracleTimestamp(raw);
  }

  /// Gets the last updated time.
  ///
  /// Returns: The updated [DateTime] or null.
  DateTime? get updated {
    final raw = _metadata["updated"];
    if (raw == null) return null;

    // Try standard ISO8601
    try {
      return DateTime.parse(raw);
    } catch (_) {}

    // Try HTTP Date
    try {
      return HttpDate.parse(raw);
    } catch (_) {}

    // Try Oracle
    return parseOracleTimestamp(raw);
  }

  /// Internal method to set metadata values.
  ///
  /// Parameters:
  /// - [name]: The metadata key.
  /// - [value]: The value to set.
  void __setMetaData(String name, dynamic value) {
    if (value == null) {
      return;
    }
    this._metadata[name] = value;
  }
}

/// Metadata that can be set on an upload.
///
/// This class allows setting various metadata fields for uploads.
class SettableMetadata {
  final String? cacheControl;
  final String? contentDisposition;
  final String? contentEncoding;
  final String? contentLanguage;
  String? contentType;
  final Map<String, String>? customMetadata;

  /// Constructs a [SettableMetadata] instance.
  ///
  /// Parameters:
  /// - [cacheControl]: Optional cache control.
  /// - [contentDisposition]: Optional content disposition.
  /// - [contentEncoding]: Optional content encoding.
  /// - [contentLanguage]: Optional content language.
  /// - [contentType]: Optional content type.
  /// - [customMetadata]: Optional custom metadata map.
  ///
  /// Returns: A new [SettableMetadata] instance.
  ///
  /// Example:
  /// ```dart
  /// var meta = SettableMetadata(contentType: 'image/jpeg');
  /// ```
  SettableMetadata({
    String? cacheControl,
    String? contentDisposition,
    String? contentEncoding,
    String? contentLanguage,
    String? contentType,
    Map<String, String>? customMetadata,
  }) : cacheControl = cacheControl,
       contentDisposition = contentDisposition,
       contentEncoding = contentEncoding,
       contentLanguage = contentLanguage,
       contentType = contentType,
       customMetadata = customMetadata;

  /// Converts this metadata to a map.
  ///
  /// Returns: A map representation of the metadata.
  Map<String, dynamic> asMap() {
    return <String, dynamic>{
      'cacheControl': cacheControl,
      'contentDisposition': contentDisposition,
      'contentEncoding': contentEncoding,
      'contentLanguage': contentLanguage,
      'contentType': contentType,
      'customMetadata': customMetadata,
    };
  }
}

/// Options for listing operations.
///
/// This class specifies options like max results and page token for listing
class ListOptions {
  final int? maxResults;
  final String? pageToken;

  /// Constructs a [ListOptions] instance.
  ///
  /// Parameters:
  /// - [maxResults]: Optional maximum number of results.
  /// - [pageToken]: Optional page token for pagination.
  ///
  /// Returns: A new [ListOptions] instance.
  ///
  /// Example:
  /// ```dart
  /// var options = ListOptions(maxResults: 10, pageToken: 'token');
  /// ```
  ListOptions({this.maxResults, this.pageToken});
}

/// Checks if a string is in ISO 8601 format.
///
/// Parameters:
/// - [input]: The string to check.
///
/// Returns: True if it's ISO 8601, false otherwise.
///
/// Example:
/// ```dart
/// bool isIso = checkIso8601('2023-01-01T00:00:00Z');
/// ```
/// @nodoc
bool checkIso8601(String? input) {
  if (input == null) {
    return false;
  }
  final iso8601Regex = RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$',
  );

  if (iso8601Regex.hasMatch(input)) {
    return true;
  }
  return false;
}

/// Parses an ISO 8601 string to DateTime if valid.
///
/// Parameters:
/// - [input]: The ISO 8601 string.
///
/// Returns: The parsed [DateTime] or null if invalid.
///
/// Example:
/// ```dart
/// DateTime? dt = parseIso8601IfValid('2023-01-01T00:00:00Z');
/// ```
/// @nodoc
DateTime? parseIso8601IfValid(String input) {
  if (checkIso8601(input)) {
    try {
      return DateTime.parse(input);
    } catch (e) {
      return null; // Parsing failed despite matching pattern
    }
  }

  return null; // Not ISO 8601 format
}
