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


import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'package:js/js.dart' as js;

const Duration _pollInterval = Duration(milliseconds: 50);

Future<void> _waitUntil(
  bool Function() predicate,
  String timeoutMessage, {
  int timeoutMs = 15000,
}) async {
  final start = DateTime.now().millisecondsSinceEpoch;
  while (!predicate()) {
    if (DateTime.now().millisecondsSinceEpoch - start > timeoutMs) {
      throw StateError(timeoutMessage);
    }
    await Future<void>.delayed(_pollInterval);
  }
}

html.Node _scriptParent() {
  return html.document.head ??
      html.document.body ??
      html.document.documentElement!;
}

bool _hasGrecaptcha() {
  return js_util.hasProperty(html.window, 'grecaptcha');
}

bool _hasGrecaptchaEnterprise() {
  if (!_hasGrecaptcha()) {
    return false;
  }
  final grecaptcha = js_util.getProperty(html.window, 'grecaptcha');
  return js_util.hasProperty(grecaptcha, 'enterprise');
}

bool _hasTurnstile() {
  return js_util.hasProperty(html.window, 'turnstile');
}

bool _hasHCaptcha() {
  return js_util.hasProperty(html.window, 'hcaptcha');
}

Future<void> _ensureScriptLoaded({
  required String id,
  required String src,
  required bool Function() isReady,
  required String timeoutMessage,
  required String loadFailureMessage,
  int timeoutMs = 15000,
}) async {
  if (isReady()) {
    return;
  }

  final existing = html.document.getElementById(id);
  if (existing != null) {
    await _waitUntil(isReady, timeoutMessage, timeoutMs: timeoutMs);
    return;
  }

  final script =
      html.ScriptElement()
        ..id = id
        ..async = true
        ..defer = true
        ..src = src;

  final completer = Completer<void>();
  script.onLoad.first.then((_) {
    if (!completer.isCompleted) {
      completer.complete();
    }
  });
  script.onError.first.then((_) {
    if (!completer.isCompleted) {
      completer.completeError(StateError(loadFailureMessage));
    }
  });

  _scriptParent().append(script);
  await completer.future;
  await _waitUntil(isReady, timeoutMessage, timeoutMs: timeoutMs);
}

Future<void> _waitForRecaptchaReady(dynamic recaptcha) async {
  final readyCompleter = Completer<void>();
  js_util.callMethod(recaptcha, 'ready', [
    js.allowInterop(([dynamic _]) {
      if (!readyCompleter.isCompleted) {
        readyCompleter.complete();
      }
    }),
  ]);
  await readyCompleter.future.timeout(
    const Duration(seconds: 10),
    onTimeout: () => throw StateError('grecaptcha.ready() timed out'),
  );
}

Future<String> getReCaptchaV3Token(String siteKey, String action) async {
  await _ensureScriptLoaded(
    id: 'fusabase-app-trust-v3-$siteKey',
    src:
        'https://www.google.com/recaptcha/api.js?render=${Uri.encodeComponent(siteKey)}',
    isReady: _hasGrecaptcha,
    timeoutMessage: 'Timed out loading reCAPTCHA v3 script.',
    loadFailureMessage: 'Failed to load reCAPTCHA v3 script.',
  );

  final grecaptcha = js_util.getProperty(html.window, 'grecaptcha');
  await _waitForRecaptchaReady(grecaptcha);

  final token = await js_util.promiseToFuture<String>(
    js_util.callMethod(grecaptcha, 'execute', [
      siteKey,
      js_util.jsify({'action': action}),
    ]),
  );

  return token;
}

Future<String> getReCaptchaEnterpriseToken(
  String siteKey,
  String action,
) async {
  await _ensureScriptLoaded(
    id: 'fusabase-app-trust-enterprise-$siteKey',
    src:
        'https://www.google.com/recaptcha/enterprise.js?render=${Uri.encodeComponent(siteKey)}',
    isReady: _hasGrecaptchaEnterprise,
    timeoutMessage: 'Timed out loading enterprise attestation script.',
    loadFailureMessage: 'Failed to load enterprise attestation script.',
  );

  final grecaptcha = js_util.getProperty(html.window, 'grecaptcha');
  final enterprise = js_util.getProperty(grecaptcha, 'enterprise');
  await _waitForRecaptchaReady(enterprise);

  final token = await js_util.promiseToFuture<String>(
    js_util.callMethod(enterprise, 'execute', [
      siteKey,
      js_util.jsify({'action': action}),
    ]),
  );

  return token;
}

Future<String> getTurnstileToken(
  String siteKey, {
  required String action,
  String? cData,
}) async {
  await _ensureScriptLoaded(
    id: 'fusabase-app-trust-turnstile-$siteKey',
    src:
        'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit',
    isReady: _hasTurnstile,
    timeoutMessage: 'Timed out loading Turnstile attestation script.',
    loadFailureMessage: 'Failed to load Turnstile attestation script.',
  );

  final turnstile = js_util.getProperty(html.window, 'turnstile');
  final container =
      html.DivElement()
        ..style.position = 'absolute'
        ..style.left = '-9999px'
        ..style.top = '-9999px';
  (html.document.body ?? html.document.documentElement!).append(container);

  dynamic widgetId;
  try {
    final completer = Completer<String>();
    Timer? timeout;

    void resolveToken(dynamic token) {
      if (!completer.isCompleted) {
        timeout?.cancel();
        completer.complete((token ?? '').toString());
      }
    }

    void rejectToken(Object error) {
      if (!completer.isCompleted) {
        timeout?.cancel();
        completer.completeError(
          error is Error ? error : StateError(error.toString()),
        );
      }
    }

    timeout = Timer(const Duration(seconds: 20), () {
      rejectToken(
        StateError('Timed out waiting for Turnstile token after 20000ms'),
      );
    });

    widgetId = js_util.callMethod(turnstile, 'render', [
      container,
      js_util.jsify({
        'sitekey': siteKey,
        'size': 'normal',
        'execution': 'render',
        'action': action,
        'cData': cData,
        'callback': js.allowInterop((dynamic token) {
          resolveToken(token);
        }),
        'error-callback': js.allowInterop(([dynamic code]) {
          final suffix =
              code == null || code.toString().isEmpty ? '' : ' (code=$code)';
          rejectToken(StateError('Turnstile failed to generate token$suffix'));
        }),
        'expired-callback': js.allowInterop(([dynamic _]) {
          rejectToken(StateError('Turnstile token expired'));
        }),
      }),
    ]);

    // 🔥 FIX: Replace setTimeout with Future.delayed
    Future.delayed(Duration.zero, () {
      void execute() {
        js_util.callMethod(turnstile, 'execute', [widgetId]);
      }

      try {
        execute();
      } catch (e) {
        final message = e.toString().toLowerCase();
        if (message.contains('already executing') &&
            js_util.hasProperty(turnstile, 'reset')) {
          try {
            js_util.callMethod(turnstile, 'reset', [widgetId]);
            execute();
            return;
          } catch (resetError) {
            rejectToken(resetError);
            return;
          }
        }
        rejectToken(e);
      }
    });

    final token = await completer.future;
    return token;
  } finally {
    try {
      if (widgetId != null && js_util.hasProperty(turnstile, 'remove')) {
        js_util.callMethod(turnstile, 'remove', [widgetId]);
      }
    } catch (_) {
      // Ignore cleanup failures.
    }
    try {
      container.remove();
    } catch (_) {
      // Ignore cleanup failures.
    }
  }
}

Future<String> getHCaptchaToken(String siteKey, String action) async {
  if (action.isNotEmpty) {
    // Kept for signature parity; hCaptcha does not use action directly.
  }

  await _ensureScriptLoaded(
    id: 'fusabase-app-trust-hcaptcha-$siteKey',
    src: 'https://js.hcaptcha.com/1/api.js?render=explicit',
    isReady: _hasHCaptcha,
    timeoutMessage: 'Timed out loading hCaptcha attestation script.',
    loadFailureMessage: 'Failed to load hCaptcha attestation script.',
  );

  final hcaptcha = js_util.getProperty(html.window, 'hcaptcha');
  final container =
      html.DivElement()
        ..style.position = 'absolute'
        ..style.left = '-9999px'
        ..style.top = '-9999px';
  (html.document.body ?? html.document.documentElement!).append(container);

  dynamic widgetId;
  try {
    final completer = Completer<String>();

    void resolveToken(dynamic token) {
      if (!completer.isCompleted) {
        completer.complete((token ?? '').toString());
      }
    }

    void rejectToken(Object error) {
      if (!completer.isCompleted) {
        completer.completeError(
          error is Error ? error : StateError(error.toString()),
        );
      }
    }

    widgetId = js_util.callMethod(hcaptcha, 'render', [
      container,
      js_util.jsify({
        'sitekey': siteKey,
        'size': 'invisible',
        'callback': js.allowInterop((dynamic token) {
          resolveToken(token);
        }),
        'error-callback': js.allowInterop(([dynamic _]) {
          rejectToken(StateError('hCaptcha failed to generate token'));
        }),
        'expired-callback': js.allowInterop(([dynamic _]) {
          rejectToken(StateError('hCaptcha token expired'));
        }),
      }),
    ]);

    try {
      final result = js_util.callMethod(hcaptcha, 'execute', [
        widgetId,
        js_util.jsify({'async': true}),
      ]);
      if (result != null && js_util.hasProperty(result, 'then')) {
        js_util
            .promiseToFuture<dynamic>(result)
            .then(resolveToken)
            .catchError(rejectToken);
      }
    } catch (_) {
      // Older versions rely on the callback-only path.
    }

    final token = await completer.future;
    return token;
  } finally {
    try {
      if (widgetId != null && js_util.hasProperty(hcaptcha, 'remove')) {
        js_util.callMethod(hcaptcha, 'remove', [widgetId]);
      }
    } catch (_) {
      // Ignore cleanup failures.
    }
    try {
      container.remove();
    } catch (_) {
      // Ignore cleanup failures.
    }
  }
}

String getUserAgent() {
  return html.window.navigator.userAgent;
}
