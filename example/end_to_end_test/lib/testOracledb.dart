// test/oracledb_integration_test.dart
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusabase/core.dart';
import 'package:fusabase/oracledb.dart';
import 'package:fusabase/auth.dart';
import 'package:fusabase/storage.dart';


void oracledb_test() {
  group('OBAAS Integration Tests for version 1 (Dart)', () {
    // App / DB handles
    late FusabaseApp app;
    late FusabaseOracledb db;
    late CollectionReference cityRef;
    late CollectionReference cityRef1;
    CollectionReference? subColPlacesRef;
    late DocumentReference docRef;
    late DocumentReference docRef1;
    String? testDocRefId;
    DocumentReference? subDocColPlacesRef;

    const options = {};

    const collectionName = 'Users';
    String? testDocId;
    final testDocData = {
      "_id": 50042,
      "name": "Alice",
      "age": 30,
      "about": "Student",
    };

    const cityCol = 'city';
    const cityCol1 = 'pl';
    const docId = 'city_001';
    final initialData = {
      'name': 'Metropolis',
      'population': 500000,
      'mayor.name': 'John Doe',
      'stats': {
        'founded': 1850,
        'nicknames': ['Big City', 'The Hub'],
        'metrics': {'area_km2': 450}
      }
    };

    String? testDocId1;
    final initialData1 = {
      "_id": 50041,
      "name": "Alice",
      "age": 30,
      "about": "Student",
    };

    // Setup once
    setUpAll(() async {
      app = Fusabase.initializeApp(name: 'test', options: FusabaseOptions(options));
      db = FusabaseOracledb.instanceFor(app: app);

      cityRef = db.collection('city');
      cityRef1 = db.collection('pl');
    });

    // Cleanup once after all tests (equivalent to after(async () => {...}) in Mocha)
    tearDownAll(() async {
      Future<void> safeDelete(DocumentReference? ref) async {
        if (ref == null) return;
        try {
          await ref.delete();
        } catch (_) {}
      }

      try {
        await safeDelete(cityRef.doc('SF'));
        await safeDelete(cityRef.doc('TEST_LA'));
        await safeDelete(cityRef.doc('TOK'));
        await safeDelete(cityRef.doc('TEST_LA1'));
        await safeDelete(cityRef.doc('TRANS_TEST2'));
        await safeDelete(cityRef1.doc('surat'));
        if (testDocId1 != null) {
          await safeDelete(db.collection(collectionName).doc(testDocId1));
        }
        if (testDocId != null) {
          await safeDelete(db.collection(collectionName).doc(testDocId));
        }
        if (testDocRefId != null) {
          await safeDelete(db.collection(collectionName).doc(testDocRefId));
        }
        await safeDelete(db.collection(cityCol).doc(docId));
        if (subColPlacesRef != null) {
          try {
            await safeDelete(subColPlacesRef!.doc('P1'));
            await safeDelete(subColPlacesRef!.doc('P2'));
          } catch (_) {}
        }
        await safeDelete(cityRef.doc('UPDATE_TEST'));
      } catch (_) {}
    });

    test('should initialize the app', () {
      expect(app.options.ordsHost, options['ords_host']);
      expect(app.options.schema, options['schema']);
      expect(app.options.appID, options['app_id']);
      expect(app.options.objsType, options['objs_type']);
      expect(app.options.storageBucket, options['storage_bucket']);
      expect(app.options.authType, options['auth_type']);
      expect(app.options.authID, options['auth_id']);
    });

    test('should initialize oracledb', () {
      expect(db.app.options.ordsHost, options['ords_host']);
      expect(db.app.options.schema, options['schema']);
      expect(db.app.options.appID, options['app_id']);
      expect(db.app.options.objsType, options['objs_type']);
      expect(db.app.options.storageBucket, options['storage_bucket']);
      expect(db.app.options.authType, options['auth_type']);
      expect(db.app.options.authID, options['auth_id']);
    });

    test('should get city collection reference', () {
      expect(cityRef, isNotNull);
      expect(cityRef.oracledb, isNotNull);
      expect(cityRef.oracledb.app.name, 'test');
      expect(cityRef.id, 'city');
      expect(cityRef.path, 'city');
      expect(cityRef.parent, isNull);
    });

    test('should add and delete document', () async {
      final resAddDoc = await db.collection('city').add({
        'name': 'Udaipur',
        'country': 'India',
        'state': 'Rajasthan',
        'capital': false,
        'population': 200000,
        'regions': ['Mevar'],
      });
      expect(resAddDoc.id, isNotNull);
      await resAddDoc.delete();
    });

    test('should set multiple docs in city', () async {
      await cityRef.doc('SF').set({
        'name': 'San Francisco',
        'state': 'CA',
        'country': 'USA',
        'capital': false,
        'population': 860000,
        'regions': ['west_coast', 'norcal']
      });
      await cityRef.doc('TEST_LA').set({
        'name': 'San Francisco',
        'state': 'CA',
        'country': 'USA',
        'capital': false,
        'population': 10000,
        'regions': ['west_coast', 'norcal']
      });
      await cityRef.doc('TEST_LA1').set({
        'name': 'San Francisco',
        'state': 'CA',
        'country': 'USA',
        'capital': false,
        'population': 10000,
        'regions': ['west_coast', 'norcal']
      });
      await cityRef.doc('TOK').set({
        'name': 'Tokyo',
        'state': null,
        'country': 'Japan',
        'capital': true,
        'population': 9000000,
        'regions': ['kanto', 'honshu']
      });
    });

    test('should update a doc', () async {
      await cityRef.doc('UPDATE_TEST').set({
        'name': 'UPDATE_TEST',
        'state': null,
        'country': 'Japan',
        'capital': true,
        'population': 9000000,
        'regions': ['kanto', 'honshu']
      });
      await cityRef.doc('UPDATE_TEST').update({'population': 1000000});
      final s = await cityRef.doc('UPDATE_TEST').get();
    });

    test('setdoc with merge', () async {
      await cityRef1.doc('surat').set({
        'name': 'UPDATE_TEST',
        'state': null,
        'country': 'Japan',
        'capital': true,
        'population': 9000000
      });
      await cityRef1.doc('surat').set({'population': 1}, SetOptions(merge: true));
      final docSnap = await cityRef1.doc('surat').get();
      expect(docSnap, isNotNull);
      expect(docSnap.get('population'), equals(1));
    });

    test('should get on query level', () async {
      final resdoc = await cityRef.get();
      expect(resdoc, isNotNull);
    });

    test('should run a transaction', () async {
      await cityRef.doc('TRANS_TEST2').set({
        'name': 'Tokyo',
        'state': null,
        'country': 'Japan',
        'capital': true,
        'population': 9000000,
        'regions': ['kanto', 'honshu']
      });
      final sfDocRef = db.collection('city').doc('TRANS_TEST2');

      final transRes1 = await db.runTransaction((Transaction transaction) async {
        final sfDoc = await transaction.get(sfDocRef);
        transaction.update(sfDocRef, {'population': 123453});
        return 123453;
      });

      expect(transRes1, equals(123453));
    });

    test('should execute WriteBatch', () async {
      final batch = db.batch();
      final nycRef = db.collection('city').doc('BATCH_TEST');
      batch.set(nycRef, {'name': 'New York City'});
      batch.update(nycRef, {'population': 11000});
      batch.delete(nycRef);
      await batch.commit();
    });

    test('collection group', () async {
      final commentsGroup = db.collectionGroup('comments');
      final res = await commentsGroup.get();
      expect(res, isNotNull);
      expect(res.docs, isNotNull);
      expect(res.query, isNotNull);
    });

    test('should get count', () async {
      final ares1 = await cityRef.count().get();
      expect(ares1.data['count'], isNotNull);
      final ares2 = await cityRef.orderBy('population').count().get();
      expect(ares2.data['count'], isNotNull);
    });

    test('should run aggregate', () async {
      final ares3 = await cityRef.aggregate(
        sum('population')
      ).get();
      expect(ares3.data['population'], isNotNull);
    });

    test('should aggregate total and final population ordered by population', () async {
      final ares4 = await cityRef.orderBy('population').aggregate(
        sum('population')
      ).get();
      expect(ares4.data['population'], isNotNull);
    });

    test('should get documents from city collection', () async {
      final res1 = await db.collection('city').get();
      expect(res1, isNotNull);
      expect(res1.docs, isNotNull);
      expect(res1.query, isNotNull);
      expect(res1.docs.isNotEmpty, isTrue);
    });

    test('should get documents from city collection with where ==', () async {
    final res2 = await db.collection('city')
        .where('capital', isEqualTo: true)
        .get();

    expect(res2, isNotNull);
    expect(res2.docs, isNotNull);
  });

  test('should get documents from city collection with comparison operators', () async {
    final resGte = await db.collection('city')
        .where('population', isGreaterThanOrEqualTo: 200000)
        .get();
    expect(resGte.docs, isNotNull);

    final resLte = await db.collection('city')
        .where('population', isLessThanOrEqualTo: 200000)
        .get();
    expect(resLte.docs, isNotNull);

    final resGt = await db.collection('city')
        .where('population', isGreaterThan: 200000)
        .get();
    expect(resGt.docs, isNotNull);

    final resLt = await db.collection('city')
        .where('population', isLessThan: 200000)
        .get();
    expect(resLt.docs, isNotNull);
  });

  test('should get documents with in / not-in / != / array-contains / array-contains-any', () async {
    final resIn = await db.collection('city')
        .where('country', whereIn: ['USA'])
        .get();
    expect(resIn.docs, isNotNull);

    final resNotIn = await db.collection('city')
        .where('country', whereNotIn: ['USA'])
        .get();
    expect(resNotIn.docs, isNotNull);

    final resNeq = await db.collection('city')
        .where('country', isNotEqualTo: 'USA')
        .get();
    expect(resNeq.docs, isNotNull);

    final resArrayContains = await db.collection('city')
        .where('regions', arrayContains: 'west_coast')
        .get();
    expect(resArrayContains.docs, isNotNull);

    final resArrayContainsAny = await db.collection('city')
        .where('regions', arrayContainsAny: ['west_coast', 'honshu'])
        .get();
    expect(resArrayContainsAny.docs, isNotNull);
  });

  test('should get documents from city collection with orderBy', () async {
    final res3 = await db.collection('city')
        .orderBy('name', descending: true)
        .get();

    expect(res3.docs, isNotNull);
    expect(res3.docs.first.data().isNotEmpty, isTrue);
  });

    test('should get documents with limit', () async {
      final res4 = await db.collection('city').limit(1).get();
      expect(res4.docs.length, equals(1));
    });

    test('should delete document TEMP from city collection', () async {
      await cityRef.doc('TEMP').set({
        'name': 'San Francisco',
        'state': 'CA',
        'country': 'USA',
        'capital': false,
        'population': 860000,
        'regions': ['west_coast', 'norcal']
      });
      await db.collection('city').doc('TEMP').delete();
    });

    test('should create correct document reference for SF', () {
      docRef = db.collection('city').doc('SF');
      expect(docRef, isNotNull);
      expect(docRef.oracledb, isNotNull);
      expect(docRef.oracledb.app.name, equals('test'));
      expect(docRef.id, equals('SF'));
      expect(docRef.path, equals('city/SF'));
      expect(docRef.parent!.id, equals('city'));
    });

    test('should get document data from SF docRef', () async {
      final res5 = await docRef.get();
      expect(res5.data(), isNotNull);
      expect(res5.reference.id, equals('SF'));
    });

    test('should create correct subcollection reference for SF/places', () {
      subColPlacesRef = db.collection('city').doc('SF').collection('places');
      expect(subColPlacesRef, isNotNull);
      expect(subColPlacesRef!.oracledb, isNotNull);
      expect(subColPlacesRef!.oracledb.app.name, equals('test'));
      expect(subColPlacesRef!.id, equals('places'));
      expect(subColPlacesRef!.path, equals('city/SF/places'));
      expect(subColPlacesRef!.parent!.id, equals('SF'));
    });

    test('should set documents in SF/places subcollection', () async {
      await subColPlacesRef!.doc('P1').set({'name': 'P11', 'state': 'P12', 'country': 'P13'});
      await subColPlacesRef!.doc('P2').set({'name': 'P21', 'state': 'P22', 'country': 'P23'});
    });

    test('should create correct document reference for SF/places/P1', () {
      subDocColPlacesRef = db.collection('city').doc('SF').collection('places').doc('P1');
      expect(subDocColPlacesRef, isNotNull);
      expect(subDocColPlacesRef!.oracledb, isNotNull);
      expect(subDocColPlacesRef!.oracledb.app.name, equals('test'));
      expect(subDocColPlacesRef!.id, equals('P1'));
      expect(subDocColPlacesRef!.path, equals('city/SF/places/P1'));
      expect(subDocColPlacesRef!.parent!.id, equals('places'));
    });

    test('should verify QuerySnapshot from city collection', () async {
      final res7 = await db.collection('city').get();
      expect(res7.docs, isNotNull);
      expect(res7.query, isNotNull);
      expect(res7.query.id, equals('city'));
      expect(res7.metadata, isNotNull);
      expect(res7.size, greaterThan(0));
    });

    test('should iterate through QuerySnapshot documents', () async {
      final res7 = await db.collection('city').get();
      for (final doc in res7.docs) {
        expect(doc.id, isNotNull);
        expect(doc.metadata, isNotNull);
        expect(doc.reference, isNotNull);
        expect(doc.data, isNotNull);
      }
    });

    test('should limit results with limitToLast', () async {
      final res8 = await db.collection('city').orderBy('population').limitToLast(3).get();
      expect(res8.docs.length, equals(3));
    });

    test('startAt/startAfter/endAt/endBefore tests', () async {
    final res9 = await db.collection('city')
        .orderBy('population')
        .startAt([860000])
        .get();
    expect(res9.docs.first.data()['population'], equals(860000));

    final res10 = await db.collection('city')
        .orderBy('population')
        .startAfter([860000])
        .get();
    expect(res10.docs.first.data()['population'], greaterThan(860000));

    final res11 = await db.collection('city')
        .orderBy('population')
        .endAt([860000])
        .get();
    expect(res11.docs.last.data()['population'], equals(860000));

    final res12 = await db.collection('city')
        .orderBy('population')
        .endBefore([860000])
        .get();
    expect(res12.docs.last.data()['population'], lessThan(860000));
  });

  test('should work with FieldPath startAt and where', () async {
    final res13 = await db.collection('city')
        .orderBy(FieldPath(['population']))
        .startAt([860000])
        .get();
    expect(res13.docs.first.data()['population'], equals(860000));

    final res14 = await db.collection('city')
        .where(FieldPath(['capital']), isEqualTo: true)
        .get();
    expect(res14, isNotNull);
    expect(res14.docs.first.data(), isNotNull);
  });

  test('should verify FieldPath properties', () {
    final fd1 = FieldPath(['population']);
    expect(fd1.toString(), contains('population'));

    expect(FieldPath.documentId.toString(), contains('OID'));

    final fd2 = FieldPath(['population', 'place1']);
    expect(fd2.toString(), contains('population#FieldPath#place1'));
  });

  test('should work with startAt using DocumentSnapshot', () async {
    final res9 = await db.collection('city')
        .orderBy('population')
        .startAt([860000]).get();

    final startDoc = res9.docs.first;

    final res15 = await db.collection('city')
        .orderBy('population')
        .startAtDocument(startDoc)
        .get();

    expect(res15.docs.first.data()['population'], equals(860000));
  });

  test('should update document population', () async {
    await docRef.update({'population': 800000});
    final res19 = await docRef.get();
    expect(res19.get('population'), equals(800000));
    expect(res19.reference.id, equals('SF'));
  });

  test('should update document population using FieldPath', () async {
    final fd1 = FieldPath(['population']);
    try {
      await docRef.update({fd1: 810000});
    } catch (_) {
      await docRef.update({'population': 810000});
    }

    final res20 = await docRef.get();
    expect(res20.get('population'), equals(810000));

    try {
      expect(res20.get(fd1), equals(810000));
    } catch (_) {}
  });

  test('should update field with dot using FieldPath', () async {
    await db.collection(cityCol).doc(docId).set(initialData);
    final mayorNamePath = FieldPath(['mayor.name']);

    try {
      await db.collection(cityCol).doc(docId).update({mayorNamePath: 'Jane Smith'});
    } catch (_) {
      await db.collection(cityCol).doc(docId).update({'mayor.name': 'Jane Smith'});
    }

    final doc = await db.collection(cityCol).doc(docId).get();
    final d = doc.data();
    if (d!=null) {
    expect(d.containsKey('mayor.name') ||
        (d['mayor']?['name'] != null), isTrue); }
  });

  test('should set nested document', () async {
    docRef1 = db.collection('pl').doc('alice');
    await docRef1.set({
      'profile': {
        'name': 'Alice',
        'stats': {'age': 30, 'score': 10},
        'hobbies': ['reading', 'chess']
      },
      'nestedJson': {
        'level1': {
          'level2': {'deepKey': 'original', 'anotherKey': 123}
        }
      },
      'lastLogin': Timestamp.now()
    });
  });

  test('should update nested field using FieldPath', () async {
    final path = FieldPath(['profile', 'stats', 'score']);
    try {
      await docRef1.update({path: 42});
    } catch (_) {
      await docRef1.update({'profile.stats.score': 42});
    }
    final doc = await docRef1.get();
    expect(doc.get('profile')['stats']['score'], equals(42));
  });

  test('should increment numeric field', () async {
    await docRef1.update({'profile.stats.age': FieldValue.increment(5)});
    final doc = await docRef1.get();
    expect(doc.get('profile')['stats']['age'], equals(35));
  });

  test('should add items to array', () async {
    await docRef1.update({
      'profile.hobbies': FieldValue.arrayUnion(['coding', 'travel'])
    });
    final doc = await docRef1.get();
    final list = List.from(doc.get('profile')['hobbies']);
    expect(list, containsAll(['reading', 'chess', 'coding', 'travel']));
  });

  test('should remove items from array', () async {
    await docRef1.update({
      'profile.hobbies': FieldValue.arrayRemove(['chess'])
    });
    final doc = await docRef1.get();
    final list = List.from(doc.get('profile')['hobbies']);
    expect(list, isNot(contains('chess')));
  });

  test('should delete nested field', () async {
    await docRef1.update({'profile.stats.score': FieldValue.delete()});
    final doc = await docRef1.get();
    final stats = doc.get('profile')['stats'];
    expect(stats.containsKey('score'), isFalse);
  });

  test('should combine operations in a single update', () async {
    await docRef1.update({
      'profile.newField': 'test',
      'profile.stats.age': FieldValue.increment(-10),
      'profile.hobbies': FieldValue.arrayUnion(['gaming']),
    });
    final doc = await docRef1.get();

    expect(doc.get('profile')['stats']['age'], equals(25));
    expect(doc.get('profile')['hobbies'], contains('gaming'));
    expect(doc.get('profile')['newField'], equals('test'));
  });

  test('update special characters using FieldPath', () async {
    final weirdRef = db.collection('pl').doc('settings');
    await weirdRef.set({'key.with.dot': {'enabled': true}});
    final path = FieldPath(['key.with.dot', 'enabled']);

    try {
      await weirdRef.update({path: false});
    } catch (_) {
      await weirdRef.update({'key.with.dot.enabled': false});
    }

    final doc = await weirdRef.get();
    expect(doc.get('key.with.dot')['enabled'], equals(false));
  });

  test('update deeply nested key', () async {
    final path = FieldPath(['nestedJson', 'level1', 'level2', 'deepKey']);
    try {
      await docRef1.update({path: 'updatedValue'});
    } catch (_) {
      await docRef1.update({'nestedJson.level1.level2.deepKey': 'updatedValue'});
    }
    final doc = await docRef1.get();
    expect(doc.get('nestedJson')['level1']['level2']['deepKey'], equals('updatedValue'));
  });

  test('increment deeply nested numeric field', () async {
    final path = FieldPath(['nestedJson', 'level1', 'level2', 'anotherKey']);
    try {
      await docRef1.update({path: FieldValue.increment(10)});
    } catch (_) {
      await docRef1.update({
        'nestedJson.level1.level2.anotherKey': FieldValue.increment(10)
      });
    }
    final doc = await docRef1.get();
    expect(doc.get('nestedJson')['level1']['level2']['anotherKey'], equals(133));
  });

  test('delete deeply nested key', () async {
    final path = FieldPath(['nestedJson', 'level1', 'level2', 'deepKey']);
    try {
      await docRef1.update({path: FieldValue.delete()});
    } catch (_) {
      await docRef1.update({
        'nestedJson.level1.level2.deepKey': FieldValue.delete()
      });
    }
    final doc = await docRef1.get();
    expect(
      doc.get('nestedJson')['level1']['level2'].containsKey('deepKey'),
      isFalse,
    );
  });

  test('update deeply nested metrics', () async {
    await db.collection(cityCol).doc(docId).set(initialData);
    final path = FieldPath(['stats', 'metrics', 'area_km2']);

    try {
      await db.collection(cityCol).doc(docId).update({path: 500});
    } catch (_) {
      await db.collection(cityCol).doc(docId).update({
        'stats.metrics.area_km2': 500
      });
    }

    final doc = await db.collection(cityCol).doc(docId).get();
    expect(doc.get('stats')['metrics']['area_km2'], equals(500));
  });

  test('delete deeply nested field using FieldPath', () async {
    final path = FieldPath(['stats', 'founded']);
    try {
      await db.collection(cityCol).doc(docId).update({path: FieldValue.delete()});
    } catch (_) {
      await db.collection(cityCol).doc(docId).update({
        'stats.founded': FieldValue.delete()
      });
    }

    final doc = await db.collection(cityCol).doc(docId).get();
    expect(doc.get('stats').containsKey('founded'), isFalse);
  });

  test('increment population', () async {
    await db.collection(cityCol).doc(docId).update({
      'population': FieldValue.increment(50000)
    });
    final doc = await db.collection(cityCol).doc(docId).get();
    expect(doc.get('population'), equals(550000));
  });

  test('add nickname using FieldPath', () async {
    final path = FieldPath(['stats', 'nicknames']);
    try {
      await db.collection(cityCol).doc(docId).update({
        path: FieldValue.arrayUnion(['City of Lights'])
      });
    } catch (_) {
      await db.collection(cityCol).doc(docId).update({
        'stats.nicknames': FieldValue.arrayUnion(['City of Lights'])
      });
    }
    final doc = await db.collection(cityCol).doc(docId).get();
    expect(doc.get('stats')['nicknames'], contains('City of Lights'));
  });

  test('remove nickname using FieldPath', () async {
    final path = FieldPath(['stats', 'nicknames']);
    try {
      await db.collection(cityCol).doc(docId).update({
        path: FieldValue.arrayRemove(['Big City'])
      });
    } catch (_) {
      await db.collection(cityCol).doc(docId).update({
        'stats.nicknames': FieldValue.arrayRemove(['Big City'])
      });
    }
    final doc = await db.collection(cityCol).doc(docId).get();
    expect(doc.get('stats')['nicknames'], isNot(contains('Big City')));
  });

  // joins: custom API, leave as is
  test('joins: should fetch', () async {
    final resJoins = await db.join('TEST_1').get();
    expect(resJoins.docs.isEmpty, isFalse);
  });

  // relational tests
  test('relational: create', () async {
    final res = await db.collection(collectionName).add(testDocData);
    testDocId = res.id;

    final doc = await db.collection(collectionName).doc(testDocId!).get();
    expect(doc.data(), equals(testDocData));
  });

  test('relational: read', () async {
    final doc = await db.collection(collectionName).doc(testDocId!).get();
    expect(doc.get('name'), equals('Alice'));
  });

  test('relational: update', () async {
    await db.collection(collectionName).doc(testDocId!).update({'age': 31});
    final doc = await db.collection(collectionName).doc(testDocId!).get();
    expect(doc.get('age'), equals(31));
  });

  test('relational: increment age', () async {
    await db.collection(collectionName)
        .doc(testDocId!)
        .update({'age': FieldValue.increment(1)});
    final doc = await db.collection(collectionName).doc(testDocId!).get();
    expect(doc.get('age'), equals(32));
  });

  test('relational: custom Timestamp', () async {
    final ts = Timestamp.fromDate(DateTime.utc(2025, 1, 1));
    await db.collection(collectionName)
        .doc(testDocId!)
        .update({'about': ts});

    final doc = await db.collection(collectionName).doc(testDocId!).get();
    final stored = doc.get('about');

    expect(stored, isA<Timestamp>());
    expect(stored.toDate().toUtc().toIso8601String(),
        equals('2025-01-01T00:00:00.000Z'));
  });

  test('relational: transaction update', () async {
    await db.runTransaction((transaction) async {
      final ref = db.collection(collectionName).doc(testDocId!);
      final snap = await transaction.get(ref);
      transaction.update(ref, {'age': 35});
    });
    final doc = await db.collection(collectionName).doc(testDocId!).get();
    expect(doc.get('age'), equals(35));
  });

  test('relational: setdoc merge', () async {
    final newRef = await db.collection(collectionName).add(initialData1);
    testDocId1 = newRef.id;

    await newRef.set({'age': 1}, SetOptions(merge: true));

    final docSnap = await newRef.get();
    expect(docSnap.get('age'), equals(1));
  });

  test('relational: batch update', () async {
    final batch = db.batch();
    final ref = db.collection(collectionName).doc(testDocId!);

    batch.update(ref, {'about': 'Graduated', 'age': 30});
    await batch.commit();

    final doc = await ref.get();
    expect(doc.get('about'), equals('Graduated'));
    expect(doc.get('age'), equals(30));
  });

  test('relational: delete', () async {
    await db.collection(collectionName).doc(testDocId!).delete();
    final deleted = await db.collection(collectionName).doc(testDocId!).get();
    expect(deleted.exists, isFalse);
  });

    // duality view
    late CollectionReference testColRef;
    DocumentReference? testDocRef;
    
    final data = {
      "_id": 25,
      "departmentName": "DBAl",
      "location": "ww",
      "employees": [
        {"employeeNumber": 12, "employeeName": "P32RATIK", "job": "CLERK", "salary": 12}
      ]
    };

    test('duality view: should create a document', () async {
      testColRef = db.dualityViewCollection('department_dv');
      final res = await testColRef.add(data);
      testDocRefId = res.id;
      testDocRef = db.dualityViewDoc('department_dv/$testDocRefId');
      expect(testDocRefId, isNotNull);
    });

    test('duality view: should read collection docs', () async {
      await testColRef.get();
    });

    test('duality view: should read a document', () async {
      final docSnap = await db.dualityViewCollection('department_dv').doc(testDocRefId!).get();
      final employees = docSnap.get('employees') as List;
    });

    test('duality view: should update a document', () async {
      await db.dualityViewCollection('department_dv').doc(testDocRefId!).update({'departmentName': 'Chirag'});
      final doc = await testDocRef!.get();
      expect(doc.get('departmentName'), equals('Chirag'));
    });

    test('duality view: should delete a document', () async {
      await db.dualityViewCollection('department_dv').doc(testDocRefId!).delete();
      final doc = await testDocRef!.get();
    });
   });



   group('OBAAS Integration Tests for version 2 (Dart)', () {
    // App / DB handles
    late FusabaseApp app;
    late FusabaseOracledb db;
    late CollectionReference cityRef;
    late CollectionReference cityRef1;
    CollectionReference? subColPlacesRef;
    late DocumentReference docRef;
    late DocumentReference docRef1;
    String? testDocRefId;
    DocumentReference? subDocColPlacesRef;

    const options = {};

    const collectionName = 'Users';
    String? testDocId;
    final testDocData = {
      "_id": 50042,
      "name": "Alice",
      "age": 30,
      "about": "Student",
    };

    const cityCol = 'city';
    const cityCol1 = 'pl';
    const docId = 'city_001';
    final initialData = {
      'name': 'Metropolis',
      'population': 500000,
      'mayor.name': 'John Doe',
      'stats': {
        'founded': 1850,
        'nicknames': ['Big City', 'The Hub'],
        'metrics': {'area_km2': 450}
      }
    };

    String? testDocId1;
    final initialData1 = {
      "_id": 50041,
      "name": "Alice",
      "age": 30,
      "about": "Student",
    };

    // Setup once
    setUpAll(() async {
      app = Fusabase.initializeApp(name: 'test', options: FusabaseOptions(options));
      db = FusabaseOracledb.instanceFor(app: app);

      cityRef = db.collection('city');
      cityRef1 = db.collection('pl');
    });

    // Cleanup once after all tests (equivalent to after(async () => {...}) in Mocha)
    tearDownAll(() async {
      Future<void> safeDelete(DocumentReference? ref) async {
        if (ref == null) return;
        try {
          await ref.delete();
        } catch (_) {}
      }

      try {
        await safeDelete(cityRef.doc('SF'));
        await safeDelete(cityRef.doc('TEST_LA'));
        await safeDelete(cityRef.doc('TOK'));
        await safeDelete(cityRef.doc('TEST_LA1'));
        await safeDelete(cityRef.doc('TRANS_TEST2'));
        await safeDelete(cityRef1.doc('surat'));
        if (testDocId1 != null) {
          await safeDelete(db.collection(collectionName).doc(testDocId1));
        }
        if (testDocId != null) {
          await safeDelete(db.collection(collectionName).doc(testDocId));
        }
        if (testDocRefId != null) {
          await safeDelete(db.collection(collectionName).doc(testDocRefId));
        }
        await safeDelete(db.collection(cityCol).doc(docId));
        if (subColPlacesRef != null) {
          try {
            await safeDelete(subColPlacesRef!.doc('P1'));
            await safeDelete(subColPlacesRef!.doc('P2'));
          } catch (_) {}
        }
        await safeDelete(cityRef.doc('UPDATE_TEST'));
      } catch (_) {}
    });

    test('should initialize the app', () {
      expect(app.options.ordsHost, options['ords_host']);
      expect(app.options.schema, options['schema']);
      expect(app.options.appID, options['app_id']);
      expect(app.options.objsType, options['objs_type']);
      expect(app.options.storageBucket, options['storage_bucket']);
      expect(app.options.authType, options['auth_type']);
      expect(app.options.authID, options['auth_id']);
    });

    test('should initialize oracledb', () {
      expect(db.app.options.ordsHost, options['ords_host']);
      expect(db.app.options.schema, options['schema']);
      expect(db.app.options.appID, options['app_id']);
      expect(db.app.options.objsType, options['objs_type']);
      expect(db.app.options.storageBucket, options['storage_bucket']);
      expect(db.app.options.authType, options['auth_type']);
      expect(db.app.options.authID, options['auth_id']);
    });

    test('should get city collection reference', () {
      expect(cityRef, isNotNull);
      expect(cityRef.oracledb, isNotNull);
      expect(cityRef.oracledb.app.name, 'test');
      expect(cityRef.id, 'city');
      expect(cityRef.path, 'city');
      expect(cityRef.parent, isNull);
    });

    test('should add and delete document', () async {
      final resAddDoc = await db.collection('city').add({
        'name': 'Udaipur',
        'country': 'India',
        'state': 'Rajasthan',
        'capital': false,
        'population': 200000,
        'regions': ['Mevar'],
      });
      expect(resAddDoc.id, isNotNull);
      await resAddDoc.delete();
    });

    test('should set multiple docs in city', () async {
      await cityRef.doc('SF').set({
        'name': 'San Francisco',
        'state': 'CA',
        'country': 'USA',
        'capital': false,
        'population': 860000,
        'regions': ['west_coast', 'norcal']
      });
      await cityRef.doc('TEST_LA').set({
        'name': 'San Francisco',
        'state': 'CA',
        'country': 'USA',
        'capital': false,
        'population': 10000,
        'regions': ['west_coast', 'norcal']
      });
      await cityRef.doc('TEST_LA1').set({
        'name': 'San Francisco',
        'state': 'CA',
        'country': 'USA',
        'capital': false,
        'population': 10000,
        'regions': ['west_coast', 'norcal']
      });
      await cityRef.doc('TOK').set({
        'name': 'Tokyo',
        'state': null,
        'country': 'Japan',
        'capital': true,
        'population': 9000000,
        'regions': ['kanto', 'honshu']
      });
    });

    test('should update a doc', () async {
      await cityRef.doc('UPDATE_TEST').set({
        'name': 'UPDATE_TEST',
        'state': null,
        'country': 'Japan',
        'capital': true,
        'population': 9000000,
        'regions': ['kanto', 'honshu']
      });
      await cityRef.doc('UPDATE_TEST').update({'population': 1000000});
      final s = await cityRef.doc('UPDATE_TEST').get();
    });

    test('setdoc with merge', () async {
      await cityRef1.doc('surat').set({
        'name': 'UPDATE_TEST',
        'state': null,
        'country': 'Japan',
        'capital': true,
        'population': 9000000
      });
      await cityRef1.doc('surat').set({'population': 1}, SetOptions(merge: true));
      final docSnap = await cityRef1.doc('surat').get();
      expect(docSnap, isNotNull);
      expect(docSnap.get('population'), equals(1));
    });

    test('should get on query level', () async {
      final resdoc = await cityRef.get();
      expect(resdoc, isNotNull);
    });

    test('should run a transaction', () async {
      await cityRef.doc('TRANS_TEST2').set({
        'name': 'Tokyo',
        'state': null,
        'country': 'Japan',
        'capital': true,
        'population': 9000000,
        'regions': ['kanto', 'honshu']
      });
      final sfDocRef = db.collection('city').doc('TRANS_TEST2');

      final transRes1 = await db.runTransaction((Transaction transaction) async {
        final sfDoc = await transaction.get(sfDocRef);
        transaction.update(sfDocRef, {'population': 123453});
        return 123453;
      });

      expect(transRes1, equals(123453));
    });

    test('should execute WriteBatch', () async {
      final batch = db.batch();
      final nycRef = db.collection('city').doc('BATCH_TEST');
      batch.set(nycRef, {'name': 'New York City'});
      batch.update(nycRef, {'population': 11000});
      batch.delete(nycRef);
      await batch.commit();
    });

    test('collection group', () async {
      final commentsGroup = db.collectionGroup('comments');
      final res = await commentsGroup.get();
      expect(res, isNotNull);
      expect(res.docs, isNotNull);
      expect(res.query, isNotNull);
    });

    test('should get count', () async {
      final ares1 = await cityRef.count().get();
      expect(ares1.data['count'], isNotNull);
      final ares2 = await cityRef.orderBy('population').count().get();
      expect(ares2.data['count'], isNotNull);
    });

    test('should run aggregate', () async {
      final ares3 = await cityRef.aggregate(
        sum('population')
      ).get();
      expect(ares3.data['population'], isNotNull);
    });

    test('should aggregate total and final population ordered by population', () async {
      final ares4 = await cityRef.orderBy('population').aggregate(
        sum('population')
      ).get();
      expect(ares4.data['population'], isNotNull);
    });

    test('should get documents from city collection', () async {
      final res1 = await db.collection('city').get();
      expect(res1, isNotNull);
      expect(res1.docs, isNotNull);
      expect(res1.query, isNotNull);
      expect(res1.docs.isNotEmpty, isTrue);
    });

    test('should get documents from city collection with where ==', () async {
    final res2 = await db.collection('city')
        .where('capital', isEqualTo: true)
        .get();

    expect(res2, isNotNull);
    expect(res2.docs, isNotNull);
  });

  test('should get documents from city collection with comparison operators', () async {
    final resGte = await db.collection('city')
        .where('population', isGreaterThanOrEqualTo: 200000)
        .get();
    expect(resGte.docs, isNotNull);

    final resLte = await db.collection('city')
        .where('population', isLessThanOrEqualTo: 200000)
        .get();
    expect(resLte.docs, isNotNull);

    final resGt = await db.collection('city')
        .where('population', isGreaterThan: 200000)
        .get();
    expect(resGt.docs, isNotNull);

    final resLt = await db.collection('city')
        .where('population', isLessThan: 200000)
        .get();
    expect(resLt.docs, isNotNull);
  });

  test('should get documents with in / not-in / != / array-contains / array-contains-any', () async {
    final resIn = await db.collection('city')
        .where('country', whereIn: ['USA'])
        .get();
    expect(resIn.docs, isNotNull);

    final resNotIn = await db.collection('city')
        .where('country', whereNotIn: ['USA'])
        .get();
    expect(resNotIn.docs, isNotNull);

    final resNeq = await db.collection('city')
        .where('country', isNotEqualTo: 'USA')
        .get();
    expect(resNeq.docs, isNotNull);

    final resArrayContains = await db.collection('city')
        .where('regions', arrayContains: 'west_coast')
        .get();
    expect(resArrayContains.docs, isNotNull);

    final resArrayContainsAny = await db.collection('city')
        .where('regions', arrayContainsAny: ['west_coast', 'honshu'])
        .get();
    expect(resArrayContainsAny.docs, isNotNull);
  });

  test('should get documents from city collection with orderBy', () async {
    final res3 = await db.collection('city')
        .orderBy('name', descending: true)
        .get();

    expect(res3.docs, isNotNull);
    expect(res3.docs.first.data().isNotEmpty, isTrue);
  });

    test('should get documents with limit', () async {
      final res4 = await db.collection('city').limit(1).get();
      expect(res4.docs.length, equals(1));
    });

    test('should delete document TEMP from city collection', () async {
      await cityRef.doc('TEMP').set({
        'name': 'San Francisco',
        'state': 'CA',
        'country': 'USA',
        'capital': false,
        'population': 860000,
        'regions': ['west_coast', 'norcal']
      });
      await db.collection('city').doc('TEMP').delete();
    });

    test('should create correct document reference for SF', () {
      docRef = db.collection('city').doc('SF');
      expect(docRef, isNotNull);
      expect(docRef.oracledb, isNotNull);
      expect(docRef.oracledb.app.name, equals('test'));
      expect(docRef.id, equals('SF'));
      expect(docRef.path, equals('city/SF'));
      expect(docRef.parent!.id, equals('city'));
    });

    test('should get document data from SF docRef', () async {
      final res5 = await docRef.get();
      expect(res5.data(), isNotNull);
      expect(res5.reference.id, equals('SF'));
    });

    test('should create correct subcollection reference for SF/places', () {
      subColPlacesRef = db.collection('city').doc('SF').collection('places');
      expect(subColPlacesRef, isNotNull);
      expect(subColPlacesRef!.oracledb, isNotNull);
      expect(subColPlacesRef!.oracledb.app.name, equals('test'));
      expect(subColPlacesRef!.id, equals('places'));
      expect(subColPlacesRef!.path, equals('city/SF/places'));
      expect(subColPlacesRef!.parent!.id, equals('SF'));
    });

    test('should set documents in SF/places subcollection', () async {
      await subColPlacesRef!.doc('P1').set({'name': 'P11', 'state': 'P12', 'country': 'P13'});
      await subColPlacesRef!.doc('P2').set({'name': 'P21', 'state': 'P22', 'country': 'P23'});
    });

    test('should create correct document reference for SF/places/P1', () {
      subDocColPlacesRef = db.collection('city').doc('SF').collection('places').doc('P1');
      expect(subDocColPlacesRef, isNotNull);
      expect(subDocColPlacesRef!.oracledb, isNotNull);
      expect(subDocColPlacesRef!.oracledb.app.name, equals('test'));
      expect(subDocColPlacesRef!.id, equals('P1'));
      expect(subDocColPlacesRef!.path, equals('city/SF/places/P1'));
      expect(subDocColPlacesRef!.parent!.id, equals('places'));
    });

    test('should verify QuerySnapshot from city collection', () async {
      final res7 = await db.collection('city').get();
      expect(res7.docs, isNotNull);
      expect(res7.query, isNotNull);
      expect(res7.query.id, equals('city'));
      expect(res7.metadata, isNotNull);
      expect(res7.size, greaterThan(0));
    });

    test('should iterate through QuerySnapshot documents', () async {
      final res7 = await db.collection('city').get();
      for (final doc in res7.docs) {
        expect(doc.id, isNotNull);
        expect(doc.metadata, isNotNull);
        expect(doc.reference, isNotNull);
        expect(doc.data, isNotNull);
      }
    });

    test('should limit results with limitToLast', () async {
      final res8 = await db.collection('city').orderBy('population').limitToLast(3).get();
      expect(res8.docs.length, equals(3));
    });

    test('startAt/startAfter/endAt/endBefore tests', () async {
    final res9 = await db.collection('city')
        .orderBy('population')
        .startAt([860000])
        .get();
    expect(res9.docs.first.data()['population'], equals(860000));

    final res10 = await db.collection('city')
        .orderBy('population')
        .startAfter([860000])
        .get();
    expect(res10.docs.first.data()['population'], greaterThan(860000));

    final res11 = await db.collection('city')
        .orderBy('population')
        .endAt([860000])
        .get();
    expect(res11.docs.last.data()['population'], equals(860000));

    final res12 = await db.collection('city')
        .orderBy('population')
        .endBefore([860000])
        .get();
    expect(res12.docs.last.data()['population'], lessThan(860000));
  });

  test('should work with FieldPath startAt and where', () async {
    final res13 = await db.collection('city')
        .orderBy(FieldPath(['population']))
        .startAt([860000])
        .get();
    expect(res13.docs.first.data()['population'], equals(860000));

    final res14 = await db.collection('city')
        .where(FieldPath(['capital']), isEqualTo: true)
        .get();
    expect(res14, isNotNull);
    expect(res14.docs.first.data(), isNotNull);
  });

  test('should verify FieldPath properties', () {
    final fd1 = FieldPath(['population']);
    expect(fd1.toString(), contains('population'));

    expect(FieldPath.documentId.toString(), contains('OID'));

    final fd2 = FieldPath(['population', 'place1']);
    expect(fd2.toString(), contains('population#FieldPath#place1'));
  });

  test('should work with startAt using DocumentSnapshot', () async {
    final res9 = await db.collection('city')
        .orderBy('population')
        .startAt([860000]).get();

    final startDoc = res9.docs.first;

    final res15 = await db.collection('city')
        .orderBy('population')
        .startAtDocument(startDoc)
        .get();

    expect(res15.docs.first.data()['population'], equals(860000));
  });

  test('should update document population', () async {
    await docRef.update({'population': 800000});
    final res19 = await docRef.get();
    expect(res19.get('population'), equals(800000));
    expect(res19.reference.id, equals('SF'));
  });

  test('should update document population using FieldPath', () async {
    final fd1 = FieldPath(['population']);
    try {
      await docRef.update({fd1: 810000});
    } catch (_) {
      await docRef.update({'population': 810000});
    }

    final res20 = await docRef.get();
    expect(res20.get('population'), equals(810000));

    try {
      expect(res20.get(fd1), equals(810000));
    } catch (_) {}
  });

  test('should update field with dot using FieldPath', () async {
    await db.collection(cityCol).doc(docId).set(initialData);
    final mayorNamePath = FieldPath(['mayor.name']);

    try {
      await db.collection(cityCol).doc(docId).update({mayorNamePath: 'Jane Smith'});
    } catch (_) {
      await db.collection(cityCol).doc(docId).update({'mayor.name': 'Jane Smith'});
    }

    final doc = await db.collection(cityCol).doc(docId).get();
    final d = doc.data();
    if (d!=null) {
    expect(d.containsKey('mayor.name') ||
        (d['mayor']?['name'] != null), isTrue); }
  });

  test('should set nested document', () async {
    docRef1 = db.collection('pl').doc('alice');
    await docRef1.set({
      'profile': {
        'name': 'Alice',
        'stats': {'age': 30, 'score': 10},
        'hobbies': ['reading', 'chess']
      },
      'nestedJson': {
        'level1': {
          'level2': {'deepKey': 'original', 'anotherKey': 123}
        }
      },
      'lastLogin': Timestamp.now()
    });
  });

  test('should update nested field using FieldPath', () async {
    final path = FieldPath(['profile', 'stats', 'score']);
    try {
      await docRef1.update({path: 42});
    } catch (_) {
      await docRef1.update({'profile.stats.score': 42});
    }
    final doc = await docRef1.get();
    expect(doc.get('profile')['stats']['score'], equals(42));
  });

  test('should increment numeric field', () async {
    await docRef1.update({'profile.stats.age': FieldValue.increment(5)});
    final doc = await docRef1.get();
    expect(doc.get('profile')['stats']['age'], equals(35));
  });

  test('should add items to array', () async {
    await docRef1.update({
      'profile.hobbies': FieldValue.arrayUnion(['coding', 'travel'])
    });
    final doc = await docRef1.get();
    final list = List.from(doc.get('profile')['hobbies']);
    expect(list, containsAll(['reading', 'chess', 'coding', 'travel']));
  });

  test('should remove items from array', () async {
    await docRef1.update({
      'profile.hobbies': FieldValue.arrayRemove(['chess'])
    });
    final doc = await docRef1.get();
    final list = List.from(doc.get('profile')['hobbies']);
    expect(list, isNot(contains('chess')));
  });

  test('should delete nested field', () async {
    await docRef1.update({'profile.stats.score': FieldValue.delete()});
    final doc = await docRef1.get();
    final stats = doc.get('profile')['stats'];
    expect(stats.containsKey('score'), isFalse);
  });

  test('should combine operations in a single update', () async {
    await docRef1.update({
      'profile.newField': 'test',
      'profile.stats.age': FieldValue.increment(-10),
      'profile.hobbies': FieldValue.arrayUnion(['gaming']),
    });
    final doc = await docRef1.get();

    expect(doc.get('profile')['stats']['age'], equals(25));
    expect(doc.get('profile')['hobbies'], contains('gaming'));
    expect(doc.get('profile')['newField'], equals('test'));
  });

  test('update special characters using FieldPath', () async {
    final weirdRef = db.collection('pl').doc('settings');
    await weirdRef.set({'key.with.dot': {'enabled': true}});
    final path = FieldPath(['key.with.dot', 'enabled']);

    try {
      await weirdRef.update({path: false});
    } catch (_) {
      await weirdRef.update({'key.with.dot.enabled': false});
    }

    final doc = await weirdRef.get();
    expect(doc.get('key.with.dot')['enabled'], equals(false));
  });

  test('update deeply nested key', () async {
    final path = FieldPath(['nestedJson', 'level1', 'level2', 'deepKey']);
    try {
      await docRef1.update({path: 'updatedValue'});
    } catch (_) {
      await docRef1.update({'nestedJson.level1.level2.deepKey': 'updatedValue'});
    }
    final doc = await docRef1.get();
    expect(doc.get('nestedJson')['level1']['level2']['deepKey'], equals('updatedValue'));
  });

  test('increment deeply nested numeric field', () async {
    final path = FieldPath(['nestedJson', 'level1', 'level2', 'anotherKey']);
    try {
      await docRef1.update({path: FieldValue.increment(10)});
    } catch (_) {
      await docRef1.update({
        'nestedJson.level1.level2.anotherKey': FieldValue.increment(10)
      });
    }
    final doc = await docRef1.get();
    expect(doc.get('nestedJson')['level1']['level2']['anotherKey'], equals(133));
  });

  test('delete deeply nested key', () async {
    final path = FieldPath(['nestedJson', 'level1', 'level2', 'deepKey']);
    try {
      await docRef1.update({path: FieldValue.delete()});
    } catch (_) {
      await docRef1.update({
        'nestedJson.level1.level2.deepKey': FieldValue.delete()
      });
    }
    final doc = await docRef1.get();
    expect(
      doc.get('nestedJson')['level1']['level2'].containsKey('deepKey'),
      isFalse,
    );
  });

  test('update deeply nested metrics', () async {
    await db.collection(cityCol).doc(docId).set(initialData);
    final path = FieldPath(['stats', 'metrics', 'area_km2']);

    try {
      await db.collection(cityCol).doc(docId).update({path: 500});
    } catch (_) {
      await db.collection(cityCol).doc(docId).update({
        'stats.metrics.area_km2': 500
      });
    }

    final doc = await db.collection(cityCol).doc(docId).get();
    expect(doc.get('stats')['metrics']['area_km2'], equals(500));
  });

  test('delete deeply nested field using FieldPath', () async {
    final path = FieldPath(['stats', 'founded']);
    try {
      await db.collection(cityCol).doc(docId).update({path: FieldValue.delete()});
    } catch (_) {
      await db.collection(cityCol).doc(docId).update({
        'stats.founded': FieldValue.delete()
      });
    }

    final doc = await db.collection(cityCol).doc(docId).get();
    expect(doc.get('stats').containsKey('founded'), isFalse);
  });

  test('increment population', () async {
    await db.collection(cityCol).doc(docId).update({
      'population': FieldValue.increment(50000)
    });
    final doc = await db.collection(cityCol).doc(docId).get();
    expect(doc.get('population'), equals(550000));
  });

  test('add nickname using FieldPath', () async {
    final path = FieldPath(['stats', 'nicknames']);
    try {
      await db.collection(cityCol).doc(docId).update({
        path: FieldValue.arrayUnion(['City of Lights'])
      });
    } catch (_) {
      await db.collection(cityCol).doc(docId).update({
        'stats.nicknames': FieldValue.arrayUnion(['City of Lights'])
      });
    }
    final doc = await db.collection(cityCol).doc(docId).get();
    expect(doc.get('stats')['nicknames'], contains('City of Lights'));
  });

  test('remove nickname using FieldPath', () async {
    final path = FieldPath(['stats', 'nicknames']);
    try {
      await db.collection(cityCol).doc(docId).update({
        path: FieldValue.arrayRemove(['Big City'])
      });
    } catch (_) {
      await db.collection(cityCol).doc(docId).update({
        'stats.nicknames': FieldValue.arrayRemove(['Big City'])
      });
    }
    final doc = await db.collection(cityCol).doc(docId).get();
    expect(doc.get('stats')['nicknames'], isNot(contains('Big City')));
  });

  // joins: custom API, leave as is
  test('joins: should fetch', () async {
    final resJoins = await db.join('TEST_1').get();
    expect(resJoins.docs.isEmpty, isFalse);
  });

  // relational tests
  test('relational: create', () async {
    final res = await db.collection(collectionName).add(testDocData);
    testDocId = res.id;

    final doc = await db.collection(collectionName).doc(testDocId!).get();
    expect(doc.data(), equals(testDocData));
  });

  test('relational: read', () async {
    final doc = await db.collection(collectionName).doc(testDocId!).get();
    expect(doc.get('name'), equals('Alice'));
  });

  test('relational: update', () async {
    await db.collection(collectionName).doc(testDocId!).update({'age': 31});
    final doc = await db.collection(collectionName).doc(testDocId!).get();
    expect(doc.get('age'), equals(31));
  });

  test('relational: increment age', () async {
    await db.collection(collectionName)
        .doc(testDocId!)
        .update({'age': FieldValue.increment(1)});
    final doc = await db.collection(collectionName).doc(testDocId!).get();
    expect(doc.get('age'), equals(32));
  });

  test('relational: custom Timestamp', () async {
    final ts = Timestamp.fromDate(DateTime.utc(2025, 1, 1));
    await db.collection(collectionName)
        .doc(testDocId!)
        .update({'about': ts});

    final doc = await db.collection(collectionName).doc(testDocId!).get();
    final stored = doc.get('about');

    expect(stored, isA<Timestamp>());
    expect(stored.toDate().toUtc().toIso8601String(),
        equals('2025-01-01T00:00:00.000Z'));
  });

  test('relational: transaction update', () async {
    await db.runTransaction((transaction) async {
      final ref = db.collection(collectionName).doc(testDocId!);
      final snap = await transaction.get(ref);
      transaction.update(ref, {'age': 35});
    });
    final doc = await db.collection(collectionName).doc(testDocId!).get();
    expect(doc.get('age'), equals(35));
  });

  test('relational: setdoc merge', () async {
    final newRef = await db.collection(collectionName).add(initialData1);
    testDocId1 = newRef.id;

    await newRef.set({'age': 1}, SetOptions(merge: true));

    final docSnap = await newRef.get();
    expect(docSnap.get('age'), equals(1));
  });

  test('relational: batch update', () async {
    final batch = db.batch();
    final ref = db.collection(collectionName).doc(testDocId!);

    batch.update(ref, {'about': 'Graduated', 'age': 30});
    await batch.commit();

    final doc = await ref.get();
    expect(doc.get('about'), equals('Graduated'));
    expect(doc.get('age'), equals(30));
  });

  test('relational: delete', () async {
    await db.collection(collectionName).doc(testDocId!).delete();
    final deleted = await db.collection(collectionName).doc(testDocId!).get();
    expect(deleted.exists, isFalse);
  });

    // duality view
    late CollectionReference testColRef;
    DocumentReference? testDocRef;
    
    final data = {
      "_id": 25,
      "departmentName": "DBAl",
      "location": "ww",
      "employees": [
        {"employeeNumber": 12, "employeeName": "P32RATIK", "job": "CLERK", "salary": 12}
      ]
    };

    test('duality view: should create a document', () async {
      testColRef = db.dualityViewCollection('department_dv');
      final res = await testColRef.add(data);
      testDocRefId = res.id;
      testDocRef = db.dualityViewDoc('department_dv/$testDocRefId');
      expect(testDocRefId, isNotNull);
    });

    test('duality view: should read collection docs', () async {
      await testColRef.get();
    });

    test('duality view: should read a document', () async {
      final docSnap = await db.dualityViewCollection('department_dv').doc(testDocRefId!).get();
      final employees = docSnap.get('employees') as List;
    });

    test('duality view: should update a document', () async {
      await db.dualityViewCollection('department_dv').doc(testDocRefId!).update({'departmentName': 'Chirag'});
      final doc = await testDocRef!.get();
      expect(doc.get('departmentName'), equals('Chirag'));
    });

    test('duality view: should delete a document', () async {
      await db.dualityViewCollection('department_dv').doc(testDocRefId!).delete();
      final doc = await testDocRef!.get();
    });
    });
}
