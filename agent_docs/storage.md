# Storage Module

Use `package:fusabase/storage.dart` for object references, uploads, downloads, metadata, listing, and storage task lifecycle operations.

## Primary Types

- `FusabaseStorage`
- `Reference`
- `UploadTask`, `DownloadTask`, `TaskSnapshot`, and `TaskState`
- `ListResult` and `ListOptions`
- `FullMetadata` and `SettableMetadata`

## Get the Storage Instance

```dart
import 'package:fusabase/storage.dart';

final storage = FusabaseStorage.instance;
```

`FusabaseStorage.instance` uses the default app. Bind storage to a specific app with `FusabaseStorage.instanceFor(app: app)`.

## References and Uploads

```dart
final photo = storage.ref('uploads/photo.jpg');
final task = photo.putFile(
  file,
  SettableMetadata(contentType: 'image/jpeg'),
);

task.snapshotEvents.listen((snapshot) {
  print('${snapshot.bytesTransferred} / ${snapshot.totalBytes}');
});

final completed = await task;
print(completed.ref.fullPath);
```

`file` is the file value provided by the calling application. Use `putData(Uint8List, metadata?)` to upload bytes instead of a file. Both methods return an `UploadTask`, which can be awaited because it implements `Future<TaskSnapshot>`.

## Download, Metadata, and Listing

```dart
final url = await photo.getDownloadURL();
final metadata = await photo.getMetadata();

final page = await storage.ref('uploads/').list(
  ListOptions(maxResults: 100),
);
for (final item in page.items) {
  print(item.fullPath);
}

await photo.delete();
```

`list()` returns one page and exposes `nextPageToken`; `listAll()` recursively lists the items and prefixes under a reference. `getData()` can download an object into memory, with a default maximum size of 10 MiB.

## Upload Task Lifecycle

`UploadTask` exposes `pause()`, `resume()`, and `cancel()`. Its `snapshotEvents` stream reports `TaskSnapshot` updates; snapshots include the current state, transferred bytes, total bytes, reference, and metadata.

`TaskState` values are `paused`, `running`, `success`, `canceled`, and `error`. The task completes with a `TaskSnapshot` or completes with an error.

## Notes

- The root reference is `storage.ref()`; pass a path to create a reference directly.
- `putFile` and `putData` accept optional `SettableMetadata`. If `contentType` is omitted, the implementation defaults it to `application/octet-stream`.
- `Reference` also supports `refFromURL`, `getMetadata`, `getDownloadURL`, `getData`, `list`, and `listAll`.

## Related Docs

- [`core.md`](core.md)
- [`configuration.md`](configuration.md)
- [`auth.md`](auth.md)
