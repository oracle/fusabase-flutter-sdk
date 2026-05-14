import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fusabase/core.dart';
import 'package:fusabase/globals.dart' as globals;
import 'package:fusabase/oracledb.dart';

void main() {
  FusabaseOracledb buildDb([String suffix = '']) {
    final app = Fusabase.initializeApp(
      name: 'vector-test-$suffix-${DateTime.now().microsecondsSinceEpoch}',
      options: FusabaseOptions({
        'ords_host': 'https://example.com/ords/',
        'schema': 'schema',
        'app_id': 'app',
        'project_id': 'project',
        'objs_type': 'oci-objs',
        'storage_bucket': 'bucket',
        'auth_type': 'base',
        'auth_id': 'auth',
        'version': 2,
        'use_socket': false,
      }),
    );
    return FusabaseOracledb.instanceFor(app: app);
  }

  group('vector helpers', () {
    test('FieldValue builds dense and sparse vectors', () {
      expect(
        FieldValue.denseVector([0.1, -0.2, 3]),
        {
          'type': 'dense',
          'values': [0.1, -0.2, 3],
        },
      );

      expect(
        FieldValue.sparseVector(5, [1, 3], [0.2, 0.9]),
        {
          'type': 'sparse',
          'dimension': 5,
          'indices': [1, 3],
          'values': [0.2, 0.9],
        },
      );
    });

    test('FieldValue rejects invalid vectors', () {
      expect(
        () => FieldValue.denseVector([1, 'bad']),
        throwsA(isA<FusabaseException>()),
      );
      expect(
        () => FieldValue.sparseVector(3, [1], [0.1, 0.2]),
        throwsA(isA<FusabaseException>()),
      );
    });
  });

  group('vector payload shaping', () {
    test('update payload routes vector fields to \$embeddings', () {
      final db = buildDb('update');
      final doc = db.collection('cities').doc('sf');

      final payload = createPayloadForUpdateVersion2New(doc, {
        'embedding': FieldValue.denseVector([0.1, 0.2]),
        'legacy': FieldValue.deleteVector(),
        'name': 'San Francisco',
      }, false);

      expect(payload[0], {
        'field': r'$embeddings',
        'value': {
          'embedding': {
            'type': 'dense',
            'values': [0.1, 0.2],
          },
        },
        'op': 'set',
        'valueType': 'mapValue',
      });
      expect(payload[1], {
        'field': r'$embeddings',
        'value': ['legacy'],
        'op': 'delete',
        'valueType': 'arrayValue',
      });
      expect(payload[2], {
        'field': 'name',
        'value': 'San Francisco',
        'op': 'set',
        'valueType': 'stringValue',
      });
    });

    test('serializeVersion2 includes embeddings block', () {
      final db = buildDb('set');
      final doc = db.collection('cities').doc('sf');

      final payload = serializeVersion2(doc, {
        'embedding': FieldValue.sparseVector(4, [1, 3], [0.5, 0.9]),
        'name': 'SF',
      }, false);

      expect(payload.first, {
        'field': r'$embeddings',
        'value': {
          'embedding': {
            'type': 'sparse',
            'dimension': 4,
            'indices': [1, 3],
            'values': [0.5, 0.9],
          },
        },
        'op': 'set',
        'valueType': 'mapValue',
      });
    });

    test('create embedding extraction rejects deleteVector', () {
      expect(
        () => extractEmbeddingsMapForCreate({
          'legacy': FieldValue.deleteVector(),
        }),
        throwsA(isA<FusabaseException>()),
      );
    });
  });

  group('vector query', () {
    test('findNearest adds vectorSearch to v2 query payload', () async {
      final db = buildDb('query');
      final query = db.collection('cities').findNearest(
        'embedding',
        {
          'vector': [0.2, 0.4, -0.1],
        },
        metric: 'COSINE',
        topK: 10,
        threshold: 0.75,
      );

      late Map<String, dynamic> requestBody;
      final client = MockClient((request) async {
        requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('{"ret":[]}', 200);
      });

      await QueryHelper().get(
        client,
        null,
        query,
        globals.LogLevel.silent,
        null,
        null,
      );

      expect(requestBody['vectorSearch'], {
        'field': 'embedding',
        'query': {
          'vector': [0.2, 0.4, -0.1],
        },
        'metric': 'COSINE',
        'topK': 10,
        'threshold': 0.75,
      });
    });

    test('findNearest validates query shape', () {
      final db = buildDb('query-invalid');
      final query = db.collection('cities');

      expect(
        () => query.findNearest('embedding', {
          'vector': [1, 2],
          'sparse': FieldValue.sparseVector(2, [0], [1.0]),
        }),
        throwsA(isA<FusabaseException>()),
      );
      expect(
        () => query.findNearest('embedding', {
          'vector': [1, 2],
        }, topK: 0),
        throwsA(isA<FusabaseException>()),
      );
    });
  });
}
