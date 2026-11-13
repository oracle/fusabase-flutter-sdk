# Core Module

Use `package:fusabase/core.dart` to initialize and retrieve `FusabaseApp` instances. The app holds the shared configuration used by Authentication, OracleDB, Storage, and App Trust.

## Primary Types

- `Fusabase`: initializes apps and retrieves registered apps.
- `FusabaseApp`: an initialized app and its `FusabaseOptions`.
- `FusabaseOptions`: configuration created from a `Map<String, dynamic>`.
- `FusabaseConfig`: internal service configuration associated with an app.
- `FusabaseException`: base exception type.

## Initialize an App

```dart
import 'package:fusabase/core.dart';

final options = FusabaseOptions({
  'ords_host': 'https://your-ords-host/ords/your-schema/',
  'schema': 'your-schema',
  'app_type': 'web',
  'app_id': 'your-app-id',
  'project_id': 'your-project-id',
  'objs_type': 'dbfs',
  'storage_bucket': 'your-bucket',
  'auth_type': 'base',
  'auth_id': 'your-auth-id',
});

final app = Fusabase.initializeApp(options: options);
```

See [`configuration.md`](configuration.md) for the option keys, defaults, and named-app behavior.

## Named Apps

```dart
import 'package:fusabase/core.dart';
import 'package:fusabase/auth.dart';
import 'package:fusabase/oracledb.dart';
import 'package:fusabase/storage.dart';

final reportingApp = Fusabase.initializeApp(
  name: 'reporting',
  options: options,
);

final auth = FusabaseAuth.instanceFor(app: reportingApp);
final database = FusabaseOracledb.instanceFor(app: reportingApp);
final storage = FusabaseStorage.instanceFor(app: reportingApp);
```

The `FusabaseAuth`, `FusabaseOracledb`, and `FusabaseStorage` libraries must also be imported to use those service classes. `Fusabase.app(name: 'reporting')` retrieves an initialized named app; it throws if the requested name has not been initialized. `Fusabase.apps` lists registered apps.

## Notes

- `Fusabase.initializeApp` returns the `FusabaseApp` it creates. The optional `name` argument identifies the app in the SDK registry; it is separate from the `app_name` option in `FusabaseOptions`.
- Service instances can be bound to a specific app with `instanceFor(app: app)`; the `instance` getter uses the default app.

## Related Docs

- [`configuration.md`](configuration.md)
- [`auth.md`](auth.md)
- [`oracledb.md`](oracledb.md)
- [`storage.md`](storage.md)
- [`app_trust.md`](app_trust.md)
