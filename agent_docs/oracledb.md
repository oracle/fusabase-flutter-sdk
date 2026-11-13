# OracleDB Module

Use `package:fusabase/oracledb.dart` for document references, collection queries, snapshots, transactions, batches, aggregates, vector search, and duality-view APIs.

## Primary Types

- `FusabaseOracledb`
- `CollectionReference`, `DocumentReference`, and `Query`
- `DocumentSnapshot`, `QueryDocumentSnapshot`, and `QuerySnapshot`
- `FieldValue`, `FieldPath`, `Filter`, `GetOptions`, and `SetOptions`
- `WriteBatch`, `Transaction`, and `BulkUpdate`
- `AggregateQuery` and duality-view reference types

## Get the Database Instance

```dart
import 'package:fusabase/oracledb.dart';

final db = FusabaseOracledb.instance;
```

`FusabaseOracledb.instance` uses the default app. Use `FusabaseOracledb.instanceFor(app: app)` for a specific `FusabaseApp`.

## Documents and Collections

```dart
final posts = db.collection('posts');
final post = posts.doc('post-123');

final snapshot = await post.get();
if (snapshot.exists) {
  print(snapshot.data());
}

final created = await posts.add({
  'title': 'Hello World',
  'createdAt': DateTime.now(),
});

await post.set({'title': 'Updated', 'views': 0});
await post.update({'views': 1});
await post.delete();
```

## Queries

```dart
final query = db.collection('posts')
    .where('published', isEqualTo: true)
    .orderBy('createdAt', descending: true)
    .limit(10);

final results = await query.get();
for (final document in results.docs) {
  print('${document.id}: ${document.data()}');
}
```

Queries also support `snapshots()` for listening to document or query changes:

```dart
final subscription = post.snapshots().listen((snapshot) {
  print(snapshot.data());
});

await subscription.cancel();
```

## Vector Search

Use `findNearest` as a query constraint. The dense query vector is passed in a `vector` map; sparse query vectors use `FieldValue.sparseVector`.

```dart
final nearest = db.collection('documents').findNearest(
  'embedding',
  {'vector': [0.22, 0.93, -0.10]},
  metric: 'COSINE',
  topK: 10,
);
final matches = await nearest.get();

final sparse = db.collection('documents').findNearest(
  'embedding',
  {
    'sparse': FieldValue.sparseVector(
      1000,
      [2, 7, 900],
      [0.9, 0.3, 0.5],
    ),
  },
  metric: 'DOT',
  topK: 5,
);
final sparseMatches = await sparse.get();
```

Supported metrics are `COSINE`, `EUCLIDEAN`, and `DOT`. `FieldValue` also provides write sentinels such as `arrayUnion`, `arrayRemove`, `increment`, `delete`, and `serverTimestamp`.

## Transactions and Batches

```dart
await db.runTransaction((transaction) async {
  final snapshot = await transaction.get(post);
  final views = snapshot.data()?['views'] as int? ?? 0;
  transaction.update(post, {'views': views + 1});
});

final batch = db.batch();
batch.set(post, {'published': true});
await batch.commit();
```

`runTransaction` retries failed attempts up to five times by default; `maxAttempts` controls the retry limit. A `WriteBatch` collects writes until `commit()`.

## Other Public Areas

- `snapshots()` streams on documents and queries.
- Aggregation query support, including count, sum, and average fields.
- Collection-group queries, bulk updates, and duality-view references.

## Notes

- `DocumentReference.get()` returns a `DocumentSnapshot`; collection/query reads return a `QuerySnapshot` whose results are in `docs`.
- Document writes accept map-shaped data. Use `SetOptions(merge: true)` with `set` when a write should merge instead of replace.
- Database operations use the app associated with the `FusabaseOracledb` instance and its authentication state.

## Related Docs

- [`core.md`](core.md)
- [`configuration.md`](configuration.md)
- [`auth.md`](auth.md)
- [`storage.md`](storage.md)
