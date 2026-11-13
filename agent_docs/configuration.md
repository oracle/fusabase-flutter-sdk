# Configuration

Use `FusabaseOptions` from `package:fusabase/core.dart` to configure an app. Its constructor accepts a `Map<String, dynamic>` using the option keys below.

## Initialize with Options

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

## Option Keys

The initialization example supplies these project settings:

| Key | Purpose |
| --- | --- |
| `ords_host` | ORDS base URL for the project. |
| `schema` | Oracle schema name. |
| `app_type` | Client type; defaults to `web` when omitted. |
| `app_id` | App identifier. |
| `project_id` | Project identifier. |
| `objs_type` | Object storage type. `dbfs` is retained; other values are normalized to `oci-objs`. |
| `storage_bucket` | Storage bucket name. |
| `auth_type` | Authentication mode; the value is normalized to lowercase. |
| `auth_id` | Authentication identifier. |

Other supported keys include `app_name`, `appTrustToken`, and `idcs_domain_url`. The SDK app registry name is passed separately to `Fusabase.initializeApp(name: ..., options: ...)`; it is not the same as the `app_name` option.

## Runtime Options

- `version` selects the OracleDB API version and defaults to `2`.
- `use_socket` defaults to `false`.
- `long_polling_interval` is in seconds. Values outside 5–300 seconds use the default of 29 seconds.
- `upload_chunk_size` defaults to 16 MiB.
- `max_upload_size` defaults to 100 MiB. The constructor also reads `upload_max_size` and `maxUploadSize` as fallback keys.

## Notes

- The input map uses snake case for most option keys; some supported keys and aliases use other casing. Dart properties use names such as `projectID`, `appID`, and `storageBucket`.
- `FusabaseOptions` does not load files or environment variables. The application supplies the map.

## Related Docs

- [`core.md`](core.md)
- [`auth.md`](auth.md)
- [`app_trust.md`](app_trust.md)
