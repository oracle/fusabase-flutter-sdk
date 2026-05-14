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

// types/timestamp.dart

part of '../../oracledb.dart';

/// Represents a point in time with nanosecond precision.
///
///
/// Parameters:
/// - [secondsSinceEpoch]: Seconds since Unix epoch.
/// - [nanosecondsSinceEpoch]: Nanoseconds (0-999,999,999).
///
/// Returns:
/// A [Timestamp] instance.
///
/// Example:
/// ```dart
/// var ts = Timestamp(1609459200, 0); // 2021-01-01 00:00:00
/// ```
class Timestamp implements Comparable<Timestamp> {
  final int secondsSinceEpoch;
  final int nanosecondsSinceEpoch;

Timestamp(this.secondsSinceEpoch, this.nanosecondsSinceEpoch) {
    if (nanosecondsSinceEpoch < 0 ||
        nanosecondsSinceEpoch >= 1000000000) {
      throw Exception(OracledbErrorMessages.invalidNanosecondsRange);
    }
    if (secondsSinceEpoch < -62135596800 ||
        secondsSinceEpoch >= 253402300800) {
      throw Exception(OracledbErrorMessages.invalidSecondsRange);
    }
  }

  /// Creates a Timestamp from milliseconds since epoch.
  ///
  /// Parameters:
  /// - [milliseconds]: Milliseconds since Unix epoch.
  ///
  /// Returns:
  /// A [Timestamp] instance.
  ///
  /// Example:
  /// ```dart
  /// var ts = Timestamp.fromMillisecondsSinceEpoch(1609459200000);
  /// ```
  factory Timestamp.fromMillisecondsSinceEpoch(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final nanoseconds = (milliseconds % 1000) * 1000000;
    return Timestamp(seconds, nanoseconds);
  }

  /// Creates a Timestamp from microseconds since epoch.
  ///
  /// Parameters:
  /// - [microseconds]: Microseconds since Unix epoch.
  ///
  /// Returns:
  /// A [Timestamp] instance.
  ///
  /// Example:
  /// ```dart
  /// var ts = Timestamp.fromMicrosecondsSinceEpoch(1609459200000000);
  /// ```
  factory Timestamp.fromMicrosecondsSinceEpoch(int microseconds) {
    final seconds = microseconds ~/ 1000000;
    final nanoseconds = (microseconds % 1000000) * 1000;
    return Timestamp(seconds, nanoseconds);
  }

  /// Creates a Timestamp from a DateTime.
  ///
  /// Parameters:
  /// - [date]: The DateTime object.
  ///
  /// Returns:
  /// A [Timestamp] instance.
  ///
  /// Example:
  /// ```dart
  /// var ts = Timestamp.fromDate(DateTime(2021, 1, 1));
  /// ```
  factory Timestamp.fromDate(DateTime date) {
    return Timestamp.fromMicrosecondsSinceEpoch(date.microsecondsSinceEpoch);
  }

  /// Creates a Timestamp for the current time.
  ///
  /// Returns:
  /// A [Timestamp] for now.
  ///
  /// Example:
  /// ```dart
  /// var now = Timestamp.now();
  /// ```
  factory Timestamp.now() {
    return Timestamp.fromMicrosecondsSinceEpoch(
      DateTime.now().microsecondsSinceEpoch,
    );
  }

  /// Creates a Timestamp from an ISO 8601 string.
  ///
  /// Parameters:
  /// - [str]: The timestamp string.
  ///
  /// Returns:
  /// A [Timestamp] instance.
  ///
  /// Example:
  /// ```dart
  /// var ts = Timestamp.fromTimestampString('2021-01-01T00:00:00.000');
  /// ```
  factory Timestamp.fromTimestampString(String str) {
    final regex = RegExp(r'^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})(?:\.(\d{1,6}))?$');
    final match = regex.firstMatch(str);

if (match == null) {
      throw Exception(OracledbErrorMessages.format(OracledbErrorMessages.invalidTimestampString, [str]));
    }

    final base = match.group(1)!;
    String fraction = match.group(2) ?? "0";

    // Pad to 6 digits (microseconds precision)
    fraction = fraction.padRight(6, "0");

    final millis = int.parse(fraction.substring(0, 3));
    final micros = int.parse(fraction.substring(3, 6));

    // Build Date in UTC using only milliseconds
    final date = DateTime.parse("${base}.${millis.toString().padLeft(3, '0')}Z");

    final seconds = date.millisecondsSinceEpoch ~/ 1000;
    final nanoseconds = millis * 1000000 + micros * 1000;

    return Timestamp(seconds, nanoseconds);
  }

  /// Gets the seconds since epoch.
  int get seconds => secondsSinceEpoch;
  /// Gets the nanoseconds since epoch.
  int get nanoseconds => nanosecondsSinceEpoch;

  /// Gets milliseconds since epoch.
  int get millisecondsSinceEpoch => seconds * 1000 + nanoseconds ~/ 1000000;
  /// Gets microseconds since epoch.
  int get microsecondsSinceEpoch => seconds * 1000000 + nanoseconds ~/ 1000;

  /// Compares this Timestamp to another.
  ///
  /// Parameters:
  /// - [other]: The other Timestamp.
  ///
  /// Returns:
  /// Negative if less, positive if greater, zero if equal.
  ///
  /// Example:
  /// ```dart
  /// if (ts1.compareTo(ts2) < 0) print('ts1 is earlier');
  /// ```
  @override
  int compareTo(Timestamp other) {
    if (seconds == other.seconds) {
      return nanoseconds.compareTo(other.nanoseconds);
    }
    return seconds.compareTo(other.seconds);
  }

  /// Converts to a DateTime in UTC.
  ///
  /// Returns:
  /// The corresponding DateTime.
  ///
  /// Example:
  /// ```dart
  /// var dt = ts.toDate();
  /// ```
  DateTime toDate() =>
      DateTime.fromMicrosecondsSinceEpoch(microsecondsSinceEpoch, isUtc: true);

  /// Converts to an ISO 8601 string with microseconds.
  ///
  /// Returns:
  /// The timestamp string.
  ///
  /// Example:
  /// ```dart
  /// print(ts.toTimestampString()); // e.g., '2021-01-01T00:00:00.000000'
  /// ```
  String toTimestampString() {
    // 1. Convert seconds → milliseconds (DateTime in Dart supports microseconds)
    final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);

    // 2. Format ISO string w/o trailing 'Z'
    final base = date.toIso8601String().replaceFirst('Z', '');

    // 3. Extract JS-style microseconds (3 digits)
    final microseconds = ((nanoseconds % 1000000) / 1000).floor();
    final microStr = microseconds.toString().padLeft(3, '0');

    return "$base$microStr";
  }

  @override
  /// Returns the timestamp string.
  String toString() => toTimestampString();

  @override
  /// Gets a hash code.
  int get hashCode => Object.hash(seconds, nanoseconds);

  @override
  /// Checks equality with another Timestamp.
  bool operator ==(Object other) =>
      other is Timestamp &&
      other.seconds == seconds &&
      other.nanoseconds == nanoseconds;
}
