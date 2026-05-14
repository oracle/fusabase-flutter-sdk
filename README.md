# Oracle® Backend for Firebase (Fusabase) Flutter SDK

A Flutter SDK for Oracle Backend for Firebase (Fusabase) that provides authentication, document database, storage, App Trust, and vector search capabilities.

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
         'storage_bucket': 'your-bucket',
         'auth_type': 'base',
         'auth_id': 'your-auth-id',
       }),
     );
     runApp(MyApp());
   }
   ```

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
  'user@example.com',
  'password123!',
);

// Sign in
try {
  final credential = await auth.signInWithEmailAndPassword(
    'user@example.com',
    'password123!',
  );
  print('Signed in: ${credential.user.uid}');
} catch (e) {
  print('Sign in failed: $e');
}

// Auth state
auth.authStateChanges.listen((user) {
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

### Vector Search

Fusabase supports similarity search over dense and sparse embeddings via `Query.findNearest`. Use `FieldValue.denseVector` / `FieldValue.sparseVector` to build payloads.

```dart
import 'package:fusabase/oracledb.dart';

// Dense vector similarity search
final denseQuery = db.collection('documents').findNearest(
  'embedding',
  {'vector': [0.22, 0.93, -0.10]},
  metric: 'COSINE',
  topK: 10,
);
final denseSnap = await denseQuery.get();

// Sparse vector similarity search
final sparseQuery = db.collection('documents').findNearest(
  'embedding',
  {
    'sparse': FieldValue.sparseVector(
      /* dimension */ 1000,
      /* indices   */ [2, 7, 900],
      /* values    */ [0.9, 0.3, 0.5],
    ),
  },
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
final listResult = await storage.ref().child('uploads/').listAll();
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
