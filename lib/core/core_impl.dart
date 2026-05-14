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

part of '../core.dart';

/// The default name used for instances of [FusabaseApp].
const String defaultFusabaseAppName = globals.defaultAppName;

const String _appTrustHeader = 'X-BAAS-AppCheck';
const String instanceIdHeader = 'X-BAAS-InstanceId';
const String _browserInstanceIdStorageKey = 'fusabase_instance_id';

class _BufferedResponse {
  final http.StreamedResponse response;
  final List<int> bytes;

  const _BufferedResponse(this.response, this.bytes);
}

bool _isAppTrustAttestEndpoint(String url) {
  return RegExp(r'/_/baas-services/appcheck/[^/]+/attest(\?|$)').hasMatch(url);
}

bool _shouldAttachAppTrustHeader(Uri uri) {
  if (!kIsWeb) {
    return false;
  }
  final url = uri.toString();
  if (!url.contains('/_/baas-services/')) {
    return false;
  }
  if (_isAppTrustAttestEndpoint(url)) {
    return false;
  }
  return true;
}

String? _getAppTrustToken(FusabaseApp? app) {
  if (app == null) {
    return null;
  }
  if (app._appTrustToken != null && app._appTrustToken!.isNotEmpty) {
    return app._appTrustToken;
  }
  if (app._appTrustTokenPersisted != null &&
      app._appTrustTokenPersisted!.isNotEmpty) {
    return app._appTrustTokenPersisted;
  }
  if (app.options.appTrustToken != null &&
      app.options.appTrustToken!.isNotEmpty) {
    return app.options.appTrustToken;
  }
  return null;
}

bool _includesAppTrustHint(String text) {
  return text.toLowerCase().contains('appcheck');
}

String _randomHex(int length) {
  const chars = '0123456789abcdef';
  final random = Random.secure();
  return List.generate(
    length,
    (_) => chars[random.nextInt(chars.length)],
  ).join();
}

String _generateBrowserInstanceId() {
  final random = Random.secure();
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final suffix =
      List.generate(10, (_) => chars[random.nextInt(chars.length)]).join();
  return 'fusabase_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}_$suffix';
}

String _getOrCreateInstanceId(FusabaseApp app) {
  if (!kIsWeb) {
    app.instanceId ??= _randomHex(32);
    return app.instanceId!;
  }

  if (app.instanceId != null && app.instanceId!.isNotEmpty) {
    return app.instanceId!;
  }

  try {
    final existing = browser_instance.getStoredBrowserInstanceId(
      _browserInstanceIdStorageKey,
    );
    if (existing != null && existing.isNotEmpty) {
      app.instanceId = existing;
      return existing;
    }

    final created = _generateBrowserInstanceId();
    browser_instance.setStoredBrowserInstanceId(
      _browserInstanceIdStorageKey,
      created,
    );
    app.instanceId = created;
    return created;
  } catch (_) {
    app.instanceId ??= _generateBrowserInstanceId();
  }

  return app.instanceId!;
}

String _buildInstanceIdHeaderValue(FusabaseApp app) {
  final instanceId = _getOrCreateInstanceId(app);
  final platform = kIsWeb ? 'web' : app.options.appType.toLowerCase();
  final normalizedAppId =
      kIsWeb ? app.options.appID.trim().toUpperCase() : app.options.appID;
  final sanitizedInstanceId = instanceId.replaceAll('-', '');
  return '$platform|$normalizedAppId|$sanitizedInstanceId';
}

void _attachAppTrustHeadersToRequest(
  http.BaseRequest request,
  FusabaseApp app, {
  bool overwrite = false,
}) {
  final appTrustToken = _getAppTrustToken(app);
  if (appTrustToken != null && appTrustToken.isNotEmpty) {
    if (overwrite || !request.headers.containsKey(_appTrustHeader)) {
      request.headers[_appTrustHeader] = appTrustToken;
    }
  }

  final headerValue = _buildInstanceIdHeaderValue(app);
  if (headerValue.isNotEmpty) {
    if (overwrite || !request.headers.containsKey(instanceIdHeader)) {
      request.headers[instanceIdHeader] = headerValue;
    }
  }
}

Future<void> _primeAppTrustToken(FusabaseApp app) async {
  final appTrustInstance = app.internalAppTrustInstance;
  if (appTrustInstance == null) {
    return;
  }
  try {
    final token = await (appTrustInstance as dynamic).getToken();
    if (token is String && token.isNotEmpty) {
      app.setInternalAppTrustToken(token);
      app.setInternalPersistedAppTrustToken(token);
    }
  } catch (_) {
    // Ignore eager token warmup errors and allow the request to proceed.
  }
}

http.BaseRequest? _cloneRequest(http.BaseRequest request) {
  if (request is http.Request) {
    final clone =
        http.Request(request.method, request.url)
          ..followRedirects = request.followRedirects
          ..maxRedirects = request.maxRedirects
          ..persistentConnection = request.persistentConnection
          ..headers.addAll(request.headers)
          ..bodyBytes = request.bodyBytes;
    return clone;
  }

  return null;
}

Future<_BufferedResponse> _bufferResponse(
  http.StreamedResponse response,
) async {
  final bytes = await response.stream.toBytes();
  return _BufferedResponse(
    http.StreamedResponse(
      http.ByteStream(Stream<List<int>>.value(bytes)),
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    ),
    bytes,
  );
}

FusabaseApp? _fallbackApp() {
  final defaultApp = Fusabase._apps[globals.defaultAppName];
  for (final value in Fusabase._apps.values) {
    if (value is FusabaseApp &&
        (_getAppTrustToken(value) != null ||
            value.internalAppTrustInstance != null)) {
      return value;
    }
  }
  if (defaultApp is FusabaseApp) {
    return defaultApp;
  }
  for (final value in Fusabase._apps.values) {
    if (value is FusabaseApp) {
      return value;
    }
  }
  return null;
}

class _FusabaseHttpClient extends http.BaseClient {
  final http.Client _inner;
  final FusabaseApp? _app;

  _FusabaseHttpClient(this._inner, this._app);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final app = _app ?? _fallbackApp();
    if (app == null || !_shouldAttachAppTrustHeader(request.url)) {
      return _inner.send(request);
    }

    final retryRequest = _cloneRequest(request);

    await _primeAppTrustToken(app);
    _attachAppTrustHeadersToRequest(request, app);

    final response = await _inner.send(request);
    if (response.statusCode < 400) {
      return response;
    }

    final bufferedResponse = await _bufferResponse(response);
    final bodyText = utf8.decode(bufferedResponse.bytes, allowMalformed: true);
    final shouldRefresh =
        response.statusCode == 401 || _includesAppTrustHint(bodyText);
    if (!shouldRefresh) {
      return bufferedResponse.response;
    }

    final appTrustInstance = app.internalAppTrustInstance;
    if (appTrustInstance == null || retryRequest == null) {
      return bufferedResponse.response;
    }

    try {
      await (appTrustInstance as dynamic).getToken(true);
    } catch (_) {
      return bufferedResponse.response;
    }

    _attachAppTrustHeadersToRequest(retryRequest, app, overwrite: true);
    return _inner.send(retryRequest);
  }

  @override
  void close() {
    _inner.close();
  }
}

/// Creates a new HTTP client for making requests.
///
/// Returns:
/// - A new [http.Client] instance.
/// @nodoc
http.Client createClient([FusabaseApp? app]) {
  return _FusabaseHttpClient(http.Client(), app);
}

/// Manages [FusabaseApp] instances.
///
/// Provides factory methods for initializing and retrieving [FusabaseApp] instances.
/// This is the entry point for accessing Fusabase functionality.
class Fusabase {
  /// Internal storage for [FusabaseApp] instances.
  static final Map<String, dynamic> _apps = {};

  /// The hash code for this instance.
  @override
  int get hashCode => toString().hashCode;

  /// Returns the [FusabaseApp] with the given name (or the default [FusabaseApp] if
  /// no name specified).
  ///
  /// Parameters:
  ///
  /// Returns:
  /// - The [FusabaseApp] instance.
  ///
  /// Throws:
  /// - [Exception] if no app with the given name exists.
  ///
  /// Example:
  /// ```dart
  /// final app = Fusabase.app(name: 'my-app');
  /// ```
  static FusabaseApp app({String name = globals.defaultAppName}) {
    FusabaseApp? app = _apps[name];
    if (app == null) {
      throw Exception("$name app doesn't exist!");
    }
    return app;
  }

  /// A list of all initialized [FusabaseApp] instances.
  ///
  /// Returns:
  /// - A [List] of all [FusabaseApp] instances.
  static List<FusabaseApp> get apps {
    List<FusabaseApp> appsList = [];
    _apps.values.forEach((value) => appsList.add(value));
    return appsList;
  }

  /// Test whether [other] is equal to this instance.
  ///
  /// Returns:
  /// - `true` if [other] is equivalent to this instance, `false` otherwise.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Fusabase) return false;
    return other.hashCode == hashCode;
  }

  /// A string representation of this instance.
  @override
  String toString() => '$Fusabase';

  /// Initializes an [FusabaseApp] with the given [options] and [name].
  ///
  /// If [name] is not provided, the default name is used. If the default app
  /// does not yet exist, it will also be created with the same options.
  ///
  /// Parameters:
  /// - [name]: Optional name for the app.
  /// - [options]: The [FusabaseOptions] to configure the app.
  ///
  /// Returns:
  /// - The newly initialized [FusabaseApp].
  ///
  /// Example:
  /// ```dart
  /// final options = FusabaseOptions(
  ///   ordsHost: 'https://example.com',
  ///   // other options
  /// );
  /// final app = Fusabase.initializeApp(options: options, name: 'my-app');
  /// ```
  static FusabaseApp initializeApp({
    String name = globals.defaultAppName,
    required FusabaseOptions options,
  }) {
    void inheritAppTrustState(FusabaseApp target, FusabaseApp source) {
      if (source.options.projectID != target.options.projectID ||
          source.options.appID != target.options.appID) {
        return;
      }

      target.setInternalAppTrustToken(source.internalAppTrustToken);
      target.setInternalPersistedAppTrustToken(
        source.internalPersistedAppTrustToken,
      );
      target.instanceId = source.instanceId;

      final appTrustInstance = source.internalAppTrustInstance;
      if (appTrustInstance != null) {
        target.setInternalAppTrustInstance(appTrustInstance);
        try {
          (appTrustInstance as dynamic).useApp(target);
        } catch (_) {
          // Older App Trust implementations do not expose useApp.
        }
      }
    }

    final previousApp = _apps[name];
    FusabaseApp app = FusabaseApp(name: name, options: options);
    if (previousApp is FusabaseApp) {
      inheritAppTrustState(app, previousApp);
    }
    if (name != globals.defaultAppName) {
      final previousDefaultApp = _apps[globals.defaultAppName];
      final defaultApp = FusabaseApp(
        name: globals.defaultAppName,
        options: options,
      );
      if (previousDefaultApp is FusabaseApp) {
        inheritAppTrustState(defaultApp, previousDefaultApp);
      } else {
        defaultApp.setInternalAppTrustToken(app.internalAppTrustToken);
        defaultApp.setInternalPersistedAppTrustToken(
          app.internalPersistedAppTrustToken,
        );
        defaultApp.instanceId = app.instanceId;
      }
      _apps[globals.defaultAppName] = defaultApp;
    }
    _apps[name] = app;

    return app;
  }
}

/// An app provides configuration for a particular Fusabase project.
///
class FusabaseApp {
  /// The name of this app.
  String _name;

  /// The log level for this app.
  globals.LogLevel _logLevel;

  /// The configuration options for this app.
  FusabaseOptions _options;
  dynamic auth;
  dynamic store;

  /// Storage service.
  dynamic storage;

  /// Internal configuration.
  FusabaseConfig? _config;
  String? instanceId;
  String? _appTrustToken;
  String? _appTrustTokenPersisted;
  dynamic _appTrustInstance;

  /// Constructs a new [FusabaseApp] with the provided [name] and [options].
  ///
  /// Parameters:
  /// - [name]: The name for the app.
  /// - [options]: The configuration options.
  FusabaseApp({required String name, required FusabaseOptions options})
    : _name = name,
      _options = options,
      _logLevel = globals.LogLevel.silent,
      _appTrustToken = options.appTrustToken,
      _appTrustTokenPersisted = options.appTrustToken {
    _config = FusabaseConfig(
      objsType: options.objsType,
      storageBucket: options.storageBucket,
      projectID: options.projectID,
      authType: options.authType,
    );

    if (options.authType == 'idcs') {
      _config?.idcsConfig = options.idcsConfig;
    }
    if (options.authType == 'ldap' ||
        options.authType == 'base' ||
        options.authType == 'ldap_s' ||
        options.authType == 'base_s') {
      _config?.authID = options.authID;
    }
  }

  /// The internal configuration for this app.
  ///
  /// Returns:
  /// - The [FusabaseConfig] instance or null.
  FusabaseConfig? get config {
    return _config;
  }

  /// The in-memory app trust token used for outgoing requests.
  String? get internalAppTrustToken => _appTrustToken;

  /// The persisted app trust token loaded from storage.
  String? get internalPersistedAppTrustToken => _appTrustTokenPersisted;

  /// The app trust instance associated with this app.
  dynamic get internalAppTrustInstance => _appTrustInstance;

  /// Updates the current in-memory app trust token.
  void setInternalAppTrustToken(String? token) {
    _appTrustToken = token;
  }

  /// Updates the persisted app trust token cached on the app.
  void setInternalPersistedAppTrustToken(String? token) {
    _appTrustTokenPersisted = token;
  }

  /// Registers the current app trust instance for this app.
  void setInternalAppTrustInstance(dynamic instance) {
    _appTrustInstance = instance;
  }

  /// The current log level for this app.
  ///
  /// Returns:
  /// - The [globals.LogLevel].
  globals.LogLevel get logLevel {
    return _logLevel;
  }

  /// The name of this app.
  ///
  /// Returns:
  /// - The app name as a [String].
  String get name => _name;

  /// The hash code for this instance.
  @override
  int get hashCode => Object.hash(name, options);

  /// The [FusabaseOptions] for this app.
  ///
  /// Returns:
  /// - The [FusabaseOptions] instance.
  FusabaseOptions get options {
    return _options;
  }

  /// A string representation of this app.
  @override
  String toString() => '$FusabaseApp($name)';

  /// Deletes the app and releases associated resources.
  ///
  /// Returns:
  /// - A [Future] that completes when deletion is done.
  Future<void> delete() async {
    auth = null;
    store = null;
    storage = null;
    Fusabase._apps.remove(name);
  }

  /// Test whether [other] is equal to this instance.
  ///
  /// Returns:
  /// - `true` if [other] is equivalent, `false` otherwise.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FusabaseApp) return false;
    return other.name == name && other.options == options;
  }
}

/// The set of integrated products and configuration for an app.
///
class FusabaseOptions {
  /// The ORDS host URL.
  final String ordsHost;

  /// The application type.
  final String appType;

  /// Optional app name.
  final String? appName;

  /// The schema name.
  final String schema;

  /// The app ID.
  final String appID;

  /// The objects type.
  final String objsType;

  /// The project ID.
  final String projectID;

  /// The storage bucket.
  final String storageBucket;

  /// The authentication type.
  final String authType;

  /// Optional authentication ID.
  String? authID;

  /// Optional app trust token.
  String? appTrustToken;

  /// Optional IDCS configuration.
  Map<String, String>? idcsConfig;

  /// The Oracle DB version to use.
  int useOracledbVersion;

  /// Web socket config
  bool useSocket;

  /// Logn polling interval
  int longPollingInterval;

  /// Upload chunk size
  int chunkSize;

  /// Maximum upload size in bytes
  int maxUploadSize;

  /// Constructs [FusabaseOptions] from a [Map].
  ///
  /// Parameters:
  /// - [options]: A map with configuration keys and values.
  FusabaseOptions(Map<String, dynamic> options)
    : ordsHost = options["ords_host"],
      appType = (options["app_type"] ?? "web").toString(),
      appName = options["app_name"],
      schema = options["schema"],
      appID = options["app_id"],
      projectID = options["project_id"],
      objsType =
          options["objs_type"].toLowerCase() == 'dbfs' ? 'dbfs' : 'oci-objs',
      storageBucket = options["storage_bucket"],
      authType = options["auth_type"].toLowerCase(),
      authID = options["auth_id"],
      appTrustToken = options["appTrustToken"] ?? options["appCheckToken"],
      useOracledbVersion = options["version"] ?? 2,
      idcsConfig = options["idcs_config"],
      useSocket = options["use_socket"] ?? false,
      longPollingInterval = options["long_polling_interval"] ?? 29,
      chunkSize = options["upload_chunk_size"] ?? 16 * 1024 * 1024,
      maxUploadSize =
          options["max_upload_size"] ??
          options["upload_max_size"] ??
          options["maxUploadSize"] ??
          100 * 1024 * 1024;

  /// A string representation of this options instance.
  @override
  String toString() {
    return '$FusabaseOptions(ordsHost: $ordsHost, appType: $appType, appName: $appName, project:$schema, projectID:$projectID, appId:$appID, objsType:$objsType, storageBucket:$storageBucket, authType:$authType, authID:$authID, hasAppTrustToken:${appTrustToken != null && appTrustToken!.isNotEmpty}, idcsConfig:${idcsConfig.toString()}, chunkSize:$chunkSize, maxUploadSize:$maxUploadSize )';
  }

  /// Test whether [other] is equal to this instance.
  ///
  /// Returns:
  /// - `true` if equal, `false` otherwise.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FusabaseOptions) return false;
    return toString() == other.toString();
  }
}

/// Internal configuration derived from [FusabaseOptions].
class FusabaseConfig {
  /// Type of objects.
  String objsType;

  /// Storage bucket name.
  String storageBucket;

  /// Project ID.
  String projectID;

  /// Authentication type.
  String authType;

  /// Authentication ID.
  String? authID;

  /// IDCS configuration.
  Map<String, String>? idcsConfig;

  /// Constructs an [FusabaseConfig].
  ///
  /// Parameters:
  /// - [objsType]
  /// - [storageBucket]
  /// - [projectID]
  /// - [authType]
  /// - [authID]
  /// - [idcsConfig]
  FusabaseConfig({
    required this.objsType,
    required this.storageBucket,
    required this.projectID,
    required this.authType,
    this.authID,
    this.idcsConfig,
  });
}

/// An exception thrown by Fusabase operations.
///
class FusabaseException implements Exception {
  /// The error message.
  final String? message;

  /// The error code.
  final String? code;

  /// The error name.
  String? name;

  /// The stack trace.
  final StackTrace? stackTrace;

  /// Constructs an [FusabaseException].
  ///
  /// Parameters:
  /// - [message]
  /// - [code]
  /// - [name]
  /// - [stackTrace]
  FusabaseException({this.message, this.code, this.name, this.stackTrace});

  /// The hash code for this exception.
  @override
  int get hashCode => Object.hash(code, message);

  /// Test if [other] is equal to this exception.
  ///
  /// Returns:
  /// - `true` if equal, `false` otherwise.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FusabaseException) return false;
    return other.hashCode == hashCode;
  }

  /// A string representation of this exception.
  @override
  String toString() {
    if (code == "AbortError") {
      return "AbortError";
    }
    if (code == "oracledb/internal") {
      return "oracledb/internal";
    }
    String output = '[$code] $message';
    return output;
  }
}

/// Utility methods for Fusabase.
/// @nodoc
class Utils {
  static const String _redacted = '[REDACTED]';
  static final RegExp _sensitiveKeyPattern = RegExp(
    r'(authorization|authz|token|password|passwd|pwd|secret|credential|assertion|code_verifier|refresh_token|access_token|id_token|api[_-]?key|client[_-]?secret|apptrusttoken|appchecktoken)',
    caseSensitive: false,
  );
  static final RegExp _authorizationValuePattern = RegExp(
    r'\b(Basic|Bearer)\s+[-._~+/=A-Za-z0-9]+',
    caseSensitive: false,
  );
  static final RegExp _jwtPattern = RegExp(
    r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]*',
  );

  static bool _isSensitiveKey(dynamic key) {
    return key != null && _sensitiveKeyPattern.hasMatch(key.toString());
  }

  static dynamic _redactForLog(dynamic value, [dynamic key]) {
    if (_isSensitiveKey(key)) {
      return _redacted;
    }
    if (value == null || value is num || value is bool) {
      return value;
    }
    if (value is http.Response) {
      return <String, dynamic>{
        'statusCode': value.statusCode,
        'reasonPhrase': value.reasonPhrase,
        'headers': _redactForLog(value.headers),
        'body': _redacted,
      };
    }
    if (value is Map) {
      return value.map((dynamic mapKey, dynamic mapValue) {
        return MapEntry(mapKey, _redactForLog(mapValue, mapKey));
      });
    }
    if (value is List<int>) {
      return '[REDACTED ${value.length} bytes]';
    }
    if (value is Iterable) {
      return value.map((dynamic item) => _redactForLog(item)).toList();
    }
    if (value is Uri) {
      return _redactString(value.toString());
    }
    if (value is String) {
      return _redactString(value);
    }
    return _redactString(value.toString());
  }

  static String _redactString(String value) {
    dynamic decoded;
    try {
      decoded = jsonDecode(value);
    } catch (_) {
      decoded = null;
    }
    if (decoded is Map || decoded is List) {
      return jsonEncode(_redactForLog(decoded));
    }

    var redacted = value.replaceAllMapped(_authorizationValuePattern, (match) {
      return '${match.group(1)} $_redacted';
    });
    redacted = redacted.replaceAllMapped(_jwtPattern, (_) => _redacted);
    redacted = redacted.replaceAllMapped(
      RegExp(
        r'(?i)\b(authorization|authz|token|password|passwd|pwd|secret|credential|assertion|code_verifier|refresh_token|access_token|id_token|apiKey|api_key|client_secret)=([^&\s,}]+)',
      ),
      (match) => '${match.group(1)}=$_redacted',
    );
    return redacted;
  }

  static dynamic _redactPayloadForLog(dynamic data) {
    if (data == null) {
      return null;
    }
    if (data is List<int>) {
      return '[REDACTED payload: ${data.length} bytes]';
    }
    return '[REDACTED payload]';
  }

  /// Logs the given [data] if [logLevel] is error.
  ///
  /// Parameters:
  /// - [logLevel]
  /// - [data]
  static void baasLogger(globals.LogLevel logLevel, dynamic data) {
    if (logLevel == globals.LogLevel.error) {
      inspect(_redactForLog(data));
    }
  }

  /// Traces request information for debugging if [logLevel] is error.
  ///
  /// Parameters:
  /// - [logLevel]
  /// - [reqUrl]
  /// - [headers]
  /// - [data]
  /// - [e]
  /// - [stackTrace]
  static void baasTrace(
    globals.LogLevel logLevel,
    dynamic reqUrl,
    dynamic headers,
    dynamic data,
    dynamic e,
    dynamic stackTrace,
  ) {
    if (logLevel == globals.LogLevel.error) {
      inspect(_redactForLog(reqUrl));
      inspect(_redactForLog(headers));
      inspect(_redactPayloadForLog(data));
      inspect(_redactForLog(e));
      inspect(_redactForLog(stackTrace.toString()));
    }
  }

  /// Validates the [response] status code.
  ///
  /// Parameters:
  /// - [logLevel]
  /// - [response]
  ///
  /// Throws:
  /// - [Exception] if status code is not successful.
  static void checkResponse(globals.LogLevel logLevel, http.Response response) {
    if (response.statusCode < 200 || response.statusCode > 299) {
      Utils.baasLogger(logLevel, response);
      throw Exception('Invalid Response! -> ${response.statusCode}');
    }
  }
}
