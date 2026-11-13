<br />
<p align="center">
  <img src="assets/fusabase-color.svg" alt="Fusabase logo" width="180" />
</p>

<h1 align="center">Oracle Backend with Firebase APIs (Fusabase) Flutter SDK</h1>

<p align="center">
  <a href="https://docs.oracle.com/en/database/oracle/backend-for-firebase/26.1/index.html">Guides</a>
</p>

A Flutter SDK for Oracle Backend with Firebase APIs (Fusabase) that provides authentication, document database, storage, App Trust, and vector search capabilities, backed entirely by Oracle AI Database via ORDS.

This Oracle Backend with Firebase APIs Flutter SDK follows the Firebase design, API patterns, and rules-based authorization model. Its SDK interfaces are designed to mirror the Firebase SDK interfaces so developers can move across backends with minimal changes. This Oracle Backend with Firebase APIs Flutter SDK is a distinct Oracle offering.

## Prerequisites

- Flutter SDK 3.29.2 or later
- Dart SDK 3.7.0 or later

## Installation

The package is published from `oracle/fusabase-flutter-sdk` as a git dependency (not on pub.dev).

1. Add the package to your `pubspec.yaml`:
   ```yaml
   dependencies:
     fusabase:
       git:
         url: https://github.com/oracle/fusabase-flutter-sdk.git
         ref: 26.1.0
   ```

2. Install:
   ```bash
   flutter pub get
   ```

3. Initialize the SDK in your app:
   ```dart
   import 'package:fusabase/core.dart';

   void main() {
     Fusabase.initializeApp(
       name: 'your-app-name',
       options: FusabaseOptions({
         'ords_host': 'https://your-ords-host/ords/your-schema/',
         'schema': 'your-schema',
         'app_id': 'your-app-id',
         'project_id': 'your-project-id',
         'objs_type': 'dbfs',
         'backend_type': 'COLLECTION',
         'storage_bucket': 'your-bucket',
         'auth_type': 'base',
         'auth_id': 'your-auth-id',
       }),
     );
     runApp(MyApp());
   }
   ```

### Initialization options

Pass a `FusabaseOptions` map to `Fusabase.initializeApp`. These are the
supported keys:

`initializeApp` also accepts an optional `name` (`String`) for the application
instance. When omitted, it uses `OracleDefaultApp`.

| Key | Type | Required | Description |
| --- | --- | --- | --- |
| `ords_host` | `String` | Yes | Base ORDS URL, including any required path prefix. |
| `schema` | `String` | Yes | Database schema name. |
| `app_id` | `String` | Yes | Application identifier. |
| `project_id` | `String` | Yes | Project identifier used by service endpoints. |
| `objs_type` | `String` | Yes | Object storage type. Use `dbfs` for DBFS; any other value selects `oci-objs`. |
| `backend_type` | `String` | Yes | Backend data model. Use `COLLECTION`. `RELATIONAL` is rejected during initialization. |
| `storage_bucket` | `String` | Yes | Default object storage bucket. |
| `auth_type` | `String` | Yes | Authentication mode, such as `base`, `ldap`, or `idcs`. `e-idcs` is normalized to `idcs`. |
| `auth_id` | `String?` | No | Optional authentication-service identifier. |
| `app_type` | `String` | No | Application type. Defaults to `web`. |
| `app_name` | `String?` | No | Optional application-display name. |
| `use_socket` | `bool` | No | Enables WebSocket transport for realtime listeners. Defaults to `true`. |
| `long_polling_interval` | `int` | No | Long-polling interval in whole seconds. Values outside 5–300 use the default of 29 seconds. |
| `upload_chunk_size` | `int` | No | Upload chunk size in bytes. Defaults to 16 MiB. |
| `max_upload_size` | `int` | No | Maximum upload size in bytes. Defaults to 100 MiB. `upload_max_size` and `maxUploadSize` are also accepted. |

## Dependencies

The SDK relies on these Flutter packages:

- `http` — HTTP requests to the Fusabase backend
- `shared_preferences` — local persistence for session tokens and app preferences
- `sqflite` — local SQLite database used for offline caching
- `web` — web-platform integration
- `plugin_platform_interface` — Flutter plugin platform abstraction

They are pulled in automatically by `flutter pub get`.

## Usage

### Authentication

```dart
import 'package:fusabase/auth.dart';

final auth = FusabaseAuth.instance;

// Sign up
final created = await auth.createUserWithEmailAndPassword(
  email: 'user@example.com',
  password: 'password123!',
);

// Sign in
try {
  final credential = await auth.signInWithEmailAndPassword(
    email: 'user@example.com',
    password: 'password123!',
  );
  print('Signed in: ${credential.user?.uid}');
} catch (e) {
  print('Sign in failed: $e');
}

// Auth state
auth.authStateChanges().listen((user) {
  if (user != null) {
    print('User signed in: ${user.uid}');
  } else {
    print('User signed out');
  }
});

// Sign out
await auth.signOut();
```

### Database (OracleDB)

```dart
import 'package:fusabase/oracledb.dart';

final db = FusabaseOracledb.instance;

// Read a document
final docRef = db.collection('posts').doc('post-123');
final docSnap = await docRef.get();
if (docSnap.exists) {
  print('Post: ${docSnap.data()}');
}

// Create a document
final newDocRef = await db.collection('posts').add({
  'title': 'Hello World',
  'createdAt': DateTime.now(),
});

// Query
final query = db.collection('posts')
    .where('published', isEqualTo: true)
    .orderBy('createdAt', descending: true)
    .limit(10);
final querySnapshot = await query.get();
for (final doc in querySnapshot.docs) {
  print('${doc.id}: ${doc.data()}');
}
```

### Realtime database updates

Use `snapshots()` to receive the initial result and later changes. Cancel the
subscription when the listener is no longer needed.

```dart
final subscription = db.collection('posts')
    .where('published', isEqualTo: true)
    .orderBy('createdAt', descending: true)
    .snapshots()
    .listen((snapshot) {
  for (final change in snapshot.docChanges) {
    print('${change.type}: ${change.doc.id}');
  }
});

await subscription.cancel();
```

### Vector Search

Fusabase supports similarity search over dense and sparse embeddings via `Query.findNearest`. Use `FieldValue.denseVector` / `FieldValue.sparseVector` to build payloads.

```dart
import 'package:fusabase/oracledb.dart';

// Dense vector similarity search
final denseQuery = db.collection('documents').findNearest(
  'embedding',
  FieldValue.denseVector([0.22, 0.93, -0.10]),
  metric: 'COSINE',
  topK: 10,
);
final denseSnap = await denseQuery.get();

// Sparse vector similarity search
final sparseQuery = db.collection('documents').findNearest(
  'embedding',
  FieldValue.sparseVector(
    /* dimension */ 1000,
    /* indices   */ [2, 7, 900],
    /* values    */ [0.9, 0.3, 0.5],
  ),
  metric: 'DOT',
  topK: 5,
);
final sparseSnap = await sparseQuery.get();
```

Supported metrics: `'COSINE'`, `'EUCLIDEAN'`, `'DOT'`.

### Storage

```dart
import 'package:fusabase/storage.dart';

final storage = FusabaseStorage.instance;

// Upload
final storageRef = storage.ref().child('uploads/photo.jpg');
await storageRef.putFile(file);

// Download URL
final downloadURL = await storageRef.getDownloadURL();

// Metadata
final meta = await storageRef.getMetadata();

// List
final listResult = await storage.ref('uploads').listAll();
for (final ref in listResult.items) {
  print('File: ${ref.name}');
}

// Delete
await storageRef.delete();
```

### App Trust (Web)

Fusabase App Trust protects your backend endpoints by adding an attestation token to all `/_/baas-services/*` requests. App Trust is active on the **web** platform; on mobile platforms `activate` is a no-op.

```dart
import 'package:fusabase/core.dart';
import 'package:fusabase/app_trust.dart';

final appTrust = FusabaseAppTrust.instance;
```

Pick one provider:

#### Cloudflare Turnstile

```dart
await appTrust.activate(
  webProvider: TurnstileProvider('YOUR_TURNSTILE_SITE_KEY'),
);
```

#### hCaptcha

```dart
await appTrust.activate(
  webProvider: HCaptchaProvider('YOUR_HCAPTCHA_SITE_KEY'),
);
```

#### reCAPTCHA v3

```dart
await appTrust.activate(
  webProvider: ReCaptchaV3Provider('YOUR_RECAPTCHA_V3_SITE_KEY'),
);
```

#### reCAPTCHA Enterprise

```dart
await appTrust.activate(
  webProvider: ReCaptchaEnterpriseProvider('YOUR_RECAPTCHA_ENTERPRISE_SITE_KEY'),
);
```

Pre-mint or refresh a token (optional — normally automatic):

```dart
final token = await appTrust.getToken(true);
```

## Documentation

Generate API documentation with `dartdoc`:

```bash
dart run dartdoc
```

Output is written to the `doc/api/` directory.

## Building the Project

This package is a Dart/Flutter library, so there is no platform-specific build step. To resolve and analyze:

```bash
flutter pub get
dart analyze
```

To build a sample app that uses this SDK, run `flutter build apk` / `flutter build ios` / `flutter build web` inside the app — not this library.

## Running Tests

```bash
flutter test
```

## Trademarks

Firebase is a trademark of Google LLC. Use of the Firebase name here is solely to describe the design patterns and SDK interfaces that Oracle Backend with Firebase APIs follows for developer familiarity and ease of migration; it does not imply any affiliation with or endorsement by Google.

## Contributing

This project welcomes contributions from the community. Before submitting a pull request, please [review our contribution guide](./CONTRIBUTING.md).

## Security

Please consult the [security guide](./SECURITY.md) for our responsible security vulnerability disclosure process.

## License

Copyright (c) 2015, 2026, Oracle and/or its affiliates.

This software is dual-licensed to you under the Universal Permissive License
(UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl and Apache License
2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
either license.

If you elect to accept the software under the Apache License, Version 2.0,
the following applies:

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
