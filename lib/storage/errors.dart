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

part of "../storage.dart";

/// Contains error message constants for storage operations.
///
/// This class provides static strings for various error messages and a method to format them.
/// @nodoc
class StorageErrorMessages {
  // 🔹 Error message constants
  /// Unknown error occurred.
  static const UNKNOWN = 'Unknown error occurred.';

  /// Value cannot be null or undefined.
  static const VALUE_CANNOT_BE_NULL = 'Value cannot be null or undefined.';

  /// Expected one of {0} but got {1}.
  static const EXPECTED_TYPE = 'Expected one of {0} but got {1}.';

  /// Upload aborted.
  static const UPLOAD_ABORTED = 'Upload aborted.';

  /// Upload size exceeds the configured maximum.
  static const UPLOAD_EXCEEDS_MAX_SIZE =
      'Upload size {0} exceeds maximum allowed size {1}.';

  /// Upload size must be known before buffering file data.
  static const UNKNOWN_UPLOAD_SIZE =
      'Upload size could not be determined before reading file data.';

  /// Zero-byte uploads are not supported.
  static const ZERO_BYTE_UPLOAD_NOT_SUPPORTED =
      'Zero-byte uploads are not supported.';

  /// Download size exceeds the requested maximum.
  static const DOWNLOAD_EXCEEDS_MAX_SIZE =
      'Download size {0} exceeds maximum allowed size {1}.';

  /// Download metadata did not include a usable object size.
  static const UNKNOWN_DOWNLOAD_SIZE =
      'Download size could not be determined from object metadata.';

  /// Incorrect path: {0}.
  static const INCORRECT_PATH = 'Incorrect path: {0}.';

  /// Only contentType is supported in metadata and it should be a valid string.
  static const INVALID_METADATA =
      'Only contentType is supported in metadata and it should be a valid string.';

  /// Invalid upload format! Upload as Blob, ArrayBuffer or Uint8Array.
  static const INVALID_UPLOAD_FORMAT =
      'Invalid upload format! Upload as Blob, ArrayBuffer or Uint8Array.';

  /// Multipart not initialized properly.
  static const MULTIPART_NOT_INITIALIZED =
      'Multipart not initialized properly.';

  /// PAR URL creation failed.
  static const PAR_URL_CREATION_FAILED = 'PAR URL creation failed.';

  /// Commit failed.
  static const COMMIT_FAILED = 'Commit failed.';

  /// Failed to get object downloadURL for {0}.
  static const FAILED_DOWNLOAD_URL =
      'Failed to get object downloadURL for {0}.';

  /// Failed to delete object {0}.
  static const FAILED_DELETE = 'Failed to delete object {0}.';

  /// Failed to fetch metadata for {0}.
  static const FAILED_FETCH_METADATA = 'Failed to fetch metadata for {0}.';

  /// Invalid child path
  static const INVALID_CHILD_PATH = 'Invalid child path';

  /// Invalid options object
  static const INVALID_OPTIONS_OBJECT = 'Invalid options object';

  /// Invalid event passed
  static const INVALID_EVENT_PASSED = 'Invalid event passed';

  /// Invalid next callback
  static const INVALID_NEXT_CALLBACK = 'Invalid next callback';

  /// Invalid error callback
  static const INVALID_ERROR_CALLBACK = 'Invalid error callback';

  /// Invalid complete callback
  static const INVALID_COMPLETE_CALLBACK = 'Invalid complete callback';

  /// Invalid success callback
  static const INVALID_SUCCESS_CALLBACK = 'Invalid success callback';

  /// Invalid callback
  static const INVALID_CALLBACK = 'Invalid callback';

  /// Invalid reference path
  static const INVALID_REFERENCE_PATH = 'Invalid reference path';

  /// Invalid reference url
  static const INVALID_REFERENCE_URL = 'Invalid reference url';

  /// Reference URL host does not match storage configuration.
  static const REFERENCE_URL_HOST_MISMATCH =
      'Reference URL host does not match storage configuration.';

  /// Reference URL project ID does not match storage configuration.
  static const REFERENCE_URL_PROJECT_MISMATCH =
      'Reference URL project ID does not match storage configuration.';

  /// Invalid reference object
  static const INVALID_REFERENCE = 'Invalid reference object';

  /// Invalid app instance
  static const INVALID_APP = 'Invalid app instance';

  /// Invalid storage instance
  static const INVALID_STORAGE = 'Invalid storage instance';

  /// Url reference cannot be created above another reference
  static const INVALID_URL_REFERENCE =
      'Url reference cannot be created above another reference';

  /// Formats a template string with arguments.
  ///
  /// Parameters:
  /// - [template]: The template string with {0}, {1}, etc.
  /// - [args]: List of arguments to replace.
  ///
  /// Returns: The formatted string.
  ///
  /// Example:
  /// ```dart
  /// String msg = StorageErrorMessages.format('Expected {0}', ['type']);
  /// ```
  /// @nodoc
  static String format(String template, [List<dynamic> args = const []]) {
    final regex = RegExp(r'\{(\d+)\}');
    return template.replaceAllMapped(regex, (match) {
      final index = int.tryParse(match.group(1) ?? '');
      if (index != null && index < args.length) {
        return args[index].toString();
      }
      return match.group(0) ?? '';
    });
  }
}
