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

import 'dart:html' as html;
import 'dart:typed_data';

// Web-specific utility functions for storage
Future<int> getUploadSize(dynamic file) async {
  if (file is html.Blob) {
    return file.size;
  }

  try {
    final size = file.size;
    if (size is int) return size;
    if (size is num) return size.toInt();
  } catch (_) {}

  throw UnsupportedError(
    'Unable to determine upload size for ${file.runtimeType}',
  );
}

Future<Uint8List> _readBlobBytes(html.Blob blob) async {
  final reader = html.FileReader();
  reader.readAsArrayBuffer(blob);
  await reader.onLoadEnd.first;
  final result = reader.result;
  if (result is ByteBuffer) {
    return Uint8List.view(result);
  }
  if (result is Uint8List) {
    return result;
  }
  throw Exception("Unsupported web file reader result: ${result.runtimeType}");
}

Future<Uint8List> readFileChunk(dynamic file, int start, int end) async {
  if (file is html.Blob) {
    return _readBlobBytes(file.slice(start, end));
  }

  try {
    final bytes = await file.bytes;
    if (bytes is Uint8List) {
      return Uint8List.sublistView(bytes, start, end);
    }
    if (bytes is List<int>) {
      return Uint8List.fromList(bytes.sublist(start, end));
    }
  } catch (_) {}

  throw Exception("Unsupported web file type: ${file.runtimeType}");
}

Future<Uint8List> readFileBytes(dynamic file) async {
  final size = await getUploadSize(file);
  return readFileChunk(file, 0, size);
}
