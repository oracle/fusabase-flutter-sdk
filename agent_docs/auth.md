# Authentication

Use `package:fusabase/auth.dart` for account creation, email/password sign-in, browser provider sign-in, session state, and user access. Authentication instances are associated with a `FusabaseApp`.

## Primary Types

- `FusabaseAuth`
- `User` and `UserCredential`
- `AuthCredential` and `IdTokenResult`
- `ActionCodeSettings` and `Persistence`
- Providers: `EmailAuthProvider`, `GoogleAuthProvider`, `FacebookAuthProvider`, `GithubAuthProvider`, `OAuthProvider`, `SAMLAuthProvider`, and `IDCSAuthProvider`
- `FusabaseAuthException` for authentication failures

## Get the Auth Instance

```dart
import 'package:fusabase/auth.dart';

final auth = FusabaseAuth.instance;
```

`FusabaseAuth.instance` uses the default app. Bind to a named app with:

```dart
final auth = FusabaseAuth.instanceFor(app: app);
```

## Email and Password

```dart
final created = await auth.createUserWithEmailAndPassword(
  email: 'user@example.com',
  password: 'password123!',
);

final signedIn = await auth.signInWithEmailAndPassword(
  email: 'user@example.com',
  password: 'password123!',
);

print(created.user?.uid);
print(signedIn.user?.email);
```

`UserCredential.user` is nullable. `auth.currentUser` provides the current `User?` on the auth instance.

## Observe Auth State

```dart
final subscription = auth.authStateChanges().listen((user) {
  if (user != null) {
    print('Signed in: ${user.uid}');
  } else {
    print('Signed out');
  }
});

// Cancel the listener when it is no longer needed.
await subscription.cancel();
```

The stream APIs are methods: `authStateChanges()`, `idTokenChanges()`, and `userChanges()`.

## Sign Out and Password Reset

```dart
await auth.signOut();
await auth.sendPasswordResetEmail(email: 'user@example.com');
```

The library also exposes `verifyPasswordResetCode` and `confirmPasswordReset` for completing a password reset flow.

## Provider Sign-In on Web

Browser popup sign-in uses a provider instance:

```dart
final result = await auth.signInWithPopup(GoogleAuthProvider());
print(result.user?.uid);
```

Other browser providers include Facebook, GitHub, OAuth, SAML, and IDCS. The module also exposes `signInWithCredential` for provider credentials.

## Persistence

```dart
await auth.setPersistence(Persistence.LOCAL);
```

`setPersistence` is web-only and throws `FusabaseAuthException` on non-web platforms. Available modes are `LOCAL`, `INDEXED_DB`, `SESSION`, and `NONE`.

## Notes

- Creating an auth instance starts asynchronous session initialization and restoration. Async authentication methods wait for that initialization before running.
- Email/password methods take named `email` and `password` arguments.
- Provider popup sign-in uses the browser auth helper; do not treat it as the native sign-in flow.

## Related Docs

- [`core.md`](core.md)
- [`configuration.md`](configuration.md)
- [`oracledb.md`](oracledb.md)
