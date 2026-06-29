// Copyright (c) 2015, 2026, Oracle and/or its affiliates.

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
// 


part of '../../app_trust.dart';

class _AppTrustTokenResult {
  final String token;
  final int expireTimeMillis;

  const _AppTrustTokenResult({
    required this.token,
    required this.expireTimeMillis,
  });
}

class _AppTrustState {
  final FusabaseApp app;
  final WebProvider? webProvider;
  _AppTrustTokenResult? cachedToken;
  Future<_AppTrustTokenResult>? inFlight;

  _AppTrustState({required this.app, required this.webProvider});
}

FusabaseException _appTrustError(String code, String message) {
  return FusabaseException(
    code: 'app-trust/$code',
    message: message,
    name: 'FusabaseAppTrustError',
  );
}

String _storageKey(FusabaseApp app) {
  final projectId = app.options.projectID.trim();
  final appId = app.options.appID.trim();
  return '$projectId:$appId';
}

String _providerKeyForWeb(String platform, String appId) {
  final normalizedPlatform = 'web';
  final normalizedAppId = appId.trim().toLowerCase();
  if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(normalizedAppId)) {
    throw _appTrustError(
      'invalid-app-id',
      'Invalid appID: expected 32 hex characters.',
    );
  }
  return '$normalizedPlatform|$normalizedAppId';
}

String _buildAttestUrl(FusabaseApp app) {
  final ordsHost = app.options.ordsHost;
  final projectId = app.options.projectID;
  final apiKey = app.options.appID;
  if (ordsHost.isEmpty) {
    throw _appTrustError(
      'missing-ords-host',
      'Missing ordsHost in Fusabase app options.',
    );
  }
  if (projectId.isEmpty) {
    throw _appTrustError(
      'missing-project-id',
      'Missing projectID in Fusabase app options.',
    );
  }
  if (apiKey.isEmpty) {
    throw _appTrustError(
      'missing-app-id',
      'Missing appID in Fusabase app options.',
    );
  }
  final base =
      ordsHost.endsWith('/')
          ? ordsHost.substring(0, ordsHost.length - 1)
          : ordsHost;
  return '$base/_/baas-services/appcheck/${Uri.encodeComponent(projectId)}/attest?apiKey=${Uri.encodeComponent(apiKey)}';
}

String? _siteKeyForAttestationRequest(WebProvider provider) {
  if (provider is HCaptchaProvider) {
    return provider.siteKey;
  }
  if (provider is ReCaptchaEnterpriseProvider) {
    return provider.siteKey;
  }
  return null;
}

int _defaultExpiryMillis() {
  return DateTime.now().millisecondsSinceEpoch +
      const Duration(minutes: 5).inMilliseconds;
}

int? _readExpiryMillis(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

Future<_AppTrustTokenResult?> _loadPersistedToken(_AppTrustState state) async {
  final persisted = await apptrustdb.getPersistedToken(_storageKey(state.app));
  if (persisted == null) {
    return null;
  }

  final token = persisted['token'];
  final expireTimeMillis = _readExpiryMillis(persisted['expireTimeMillis']);
  if (token is! String || token.isEmpty || expireTimeMillis == null) {
    return null;
  }
  if (expireTimeMillis <=
      DateTime.now().millisecondsSinceEpoch +
          const Duration(seconds: 5).inMilliseconds) {
    state.cachedToken = null;
    state.app.setInternalAppTrustToken(null);
    state.app.setInternalPersistedAppTrustToken(null);
    return null;
  }

  final result = _AppTrustTokenResult(
    token: token,
    expireTimeMillis: expireTimeMillis,
  );
  state.cachedToken = result;
  state.app.setInternalAppTrustToken(result.token);
  state.app.setInternalPersistedAppTrustToken(result.token);
  final appTrust = state.app.internalAppTrustInstance;
  if (appTrust is FusabaseAppTrust) {
    appTrust._emitTokenChange(result.token);
  }
  return result;
}

/// Entry point for App Trust operations.
class FusabaseAppTrust {
  FusabaseApp app;
  _AppTrustState? _state;
  final StreamController<String> _tokenController =
      StreamController<String>.broadcast();

  static final Map<String, FusabaseAppTrust> _instances = {};

  FusabaseAppTrust._(this.app);

  void _emitTokenChange(String token) {
    if (!_tokenController.isClosed) {
      _tokenController.add(token);
    }
  }

  /// Rebinds this App Trust instance to a newly initialized app with the same
  /// name while preserving the active provider and cached token.
  void useApp(FusabaseApp app) {
    if (identical(this.app, app)) {
      app.setInternalAppTrustInstance(this);
      return;
    }

    final previousState = _state;
    final previousToken = previousState?.cachedToken;
    this.app = app;
    app.setInternalAppTrustInstance(this);

    if (previousToken != null) {
      app.setInternalAppTrustToken(previousToken.token);
      app.setInternalPersistedAppTrustToken(previousToken.token);
    }

    if (previousState != null) {
      _state = _AppTrustState(app: app, webProvider: previousState.webProvider)
        ..cachedToken = previousState.cachedToken;
    }
  }

  /// Returns the App Trust instance for the default Fusabase app.
  static FusabaseAppTrust get instance {
    return instanceFor(app: Fusabase.app());
  }

  /// Returns the App Trust instance for a specific app.
  static FusabaseAppTrust instanceFor({required FusabaseApp app}) {
    final existing = _instances[app.name];
    if (existing == null) {
      return _instances.putIfAbsent(app.name, () => FusabaseAppTrust._(app));
    }

    existing.useApp(app);

    return existing;
  }

  /// Emits token changes similarly to App Trust.
  Stream<String> get onTokenChange {
    if (!kIsWeb) {
      return const Stream<String>.empty();
    }
    return _onTokenChange();
  }

  Stream<String> _onTokenChange() async* {
    final currentToken =
        app.internalAppTrustToken ??
        app.internalPersistedAppTrustToken ??
        app.options.appTrustToken;
    if (currentToken != null && currentToken.isNotEmpty) {
      yield currentToken;
    }
    yield* _tokenController.stream;
  }

  /// Activates App Trust for the current app.
  Future<void> activate({
    AndroidProvider? androidProvider,
    AppleProvider? appleProvider,
    WebProvider? webProvider,
  }) async {
    if (!kIsWeb) {
      return;
    }
    if (webProvider == null) {
      throw _appTrustError(
        'missing-provider',
        'A webProvider is required when activating App Trust on web.',
      );
    }

    _state = _AppTrustState(app: app, webProvider: webProvider);
    app.setInternalAppTrustInstance(this);
    await _loadPersistedToken(_state!);
  }

  /// Retrieves the current App Trust token.
  Future<String?> getToken([bool forceRefresh = false]) async {
    if (!kIsWeb) {
      return null;
    }

    final configuredToken = app.options.appTrustToken;
    if (!forceRefresh &&
        configuredToken != null &&
        configuredToken.isNotEmpty) {
      return configuredToken;
    }

    final state = _state;
    if (state == null) {
      throw _appTrustError(
        'not-activated',
        'Call FusabaseAppTrust.instance.activate() before getToken().',
      );
    }

    if (state.cachedToken == null) {
      await _loadPersistedToken(state);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    if (state.cachedToken != null &&
        state.cachedToken!.expireTimeMillis <=
            now + const Duration(seconds: 5).inMilliseconds) {
      state.cachedToken = null;
      app.setInternalAppTrustToken(null);
      app.setInternalPersistedAppTrustToken(null);
    }

    if (!forceRefresh &&
        state.cachedToken != null &&
        state.cachedToken!.expireTimeMillis >
            now + const Duration(seconds: 5).inMilliseconds) {
      return state.cachedToken!.token;
    }
    if (!forceRefresh && state.inFlight != null) {
      return (await state.inFlight!).token;
    }
    if (forceRefresh && state.inFlight != null) {
      try {
        await state.inFlight;
      } catch (_) {
        // Ignore the previous attempt and continue with a forced refresh.
      }
    }

    final provider = state.webProvider;
    if (provider == null) {
      throw _appTrustError(
        'missing-provider',
        'A web App Trust provider is required for web token retrieval.',
      );
    }

    state.inFlight =
        (() async {
          const action = 'attest';
          final attestationToken = await provider.getAttestationToken(action);
          final attestRequest = <String, dynamic>{
            'provider': _providerKeyForWeb('web', app.options.appID),
            'attestationToken': attestationToken,
            'action': action,
            'deviceInfo': {
              'platform': app.options.appType.toLowerCase(),
              'userAgent': attestation.getUserAgent(),
            },
          };
          final siteKey = _siteKeyForAttestationRequest(provider);
          if (siteKey != null && siteKey.isNotEmpty) {
            attestRequest['siteKey'] = siteKey;
          }
          final client = createClient(app);
          try {
            final response = await client.post(
              Uri.parse(_buildAttestUrl(app)),
              headers: {'content-type': 'application/json'},
              body: jsonEncode(attestRequest),
            );

            if (response.statusCode < 200 || response.statusCode > 299) {
              throw _appTrustError(
                'attestation-exchange-failed',
                'Attestation exchange failed (${response.statusCode}).',
              );
            }

            final json = jsonDecode(response.body);
            final token = json['attestToken'];
            if (token is! String || token.isEmpty) {
              throw _appTrustError(
                'invalid-attestation-response',
                'Attestation response missing attestToken.',
              );
            }

            final result = _AppTrustTokenResult(
              token: token,
              expireTimeMillis: _defaultExpiryMillis(),
            );
            state.cachedToken = result;
            app.setInternalAppTrustToken(result.token);
            app.setInternalPersistedAppTrustToken(result.token);
            _tokenController.add(result.token);
            await apptrustdb.setPersistedToken(_storageKey(app), {
              'token': result.token,
              'expireTimeMillis': result.expireTimeMillis,
              'updatedAtMillis': DateTime.now().millisecondsSinceEpoch,
            });
            return result;
          } finally {
            client.close();
            state.inFlight = null;
          }
        })();

    return (await state.inFlight!).token;
  }
}
