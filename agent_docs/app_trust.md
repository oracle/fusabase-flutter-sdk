# App Trust

Use `package:fusabase/app_trust.dart` to configure web attestation providers and retrieve App Trust tokens. In the current Flutter implementation, App Trust is active on web; `activate()` is a no-op on non-web platforms.

## Primary Types

- `FusabaseAppTrust`
- `WebProvider`
- `TurnstileProvider`
- `HCaptchaProvider`
- `ReCaptchaV3Provider`
- `ReCaptchaEnterpriseProvider`
- `AndroidProvider` and `AppleProvider` enums are present in the API, but native activation is not currently implemented.

## Activate a Web Provider

```dart
import 'package:fusabase/app_trust.dart';

final appTrust = FusabaseAppTrust.instance;
await appTrust.activate(
  webProvider: TurnstileProvider('YOUR_TURNSTILE_SITE_KEY'),
);
```

Other supported web providers are `HCaptchaProvider`, `ReCaptchaV3Provider`, and `ReCaptchaEnterpriseProvider`. `CloudflareTurnstileProvider` is a deprecated alias for `TurnstileProvider`.

Use `FusabaseAppTrust.instanceFor(app: app)` when configuring a named app.

## Retrieve and Observe Tokens

```dart
final token = await appTrust.getToken();
final refreshedToken = await appTrust.getToken(true);

final subscription = appTrust.onTokenChange.listen((token) {
  print('App Trust token updated');
});
await subscription.cancel();
```

`getToken()` returns a `Future<String?>`. Passing `true` requests a refresh. If no configured token is available, web token retrieval requires `activate()` to have completed. On non-web platforms `getToken()` returns `null`, and `onTokenChange` is an empty stream.

## Notes

- The web activation API requires a `webProvider`; omitting it on web throws an App Trust exception.
- Matching web backend requests receive the active App Trust token automatically; applications normally do not need to add the header themselves.
- The `androidProvider` and `appleProvider` parameters on `activate()` currently have no effect because activation returns immediately on non-web platforms.
- `appTrustToken` can also be supplied in the `FusabaseOptions` map. See [`configuration.md`](configuration.md).

## Related Docs

- [`core.md`](core.md)
- [`configuration.md`](configuration.md)
- [`auth.md`](auth.md)
