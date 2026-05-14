import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fusabase/core.dart';
import 'package:fusabase/oracledb.dart';
import 'package:fusabase/auth.dart';
import 'package:fusabase/storage.dart';

void storage_test() {

  const options = {};

  late FusabaseApp app;
  late FusabaseStorage storage;
  late Reference ref1;
  late Reference ref2;
  late Reference ref3;

  group("OBAAS Storage Tests", () {
    test("should initialize app with correct options", () {
      app = Fusabase.initializeApp( name:"test", options:FusabaseOptions(options));

      expect(app.options.ordsHost, options["ords_host"]);
      expect(app.options.schema, options["schema"]);
      expect(app.options.appID, options["app_id"]);
      expect(app.options.objsType, options["objs_type"]);
      expect(app.options.storageBucket, options["storage_bucket"]);
      expect(app.options.authType, options["auth_type"]);
      expect(app.options.authID, options["auth_id"]);
    });

    test("should get storage object with correct config", () {
      storage = FusabaseStorage.instanceFor(app:app);
      expect(storage.app.options.ordsHost, options["ords_host"]);
      expect(storage.app.options.schema, options["schema"]);
      expect(storage.app.options.appID, options["app_id"]);
      expect(storage.app.options.objsType, options["objs_type"]);
      expect(storage.app.options.storageBucket, options["storage_bucket"]);
      expect(storage.app.options.authType, options["auth_type"]);
      expect(storage.app.options.authID, options["auth_id"]);
    });

    test("should create references correctly", () {
      ref1 = storage.ref("products/11");

      expect(ref1.name, "11");
      expect(ref1.root.name, "");
      expect(ref1.parent!.name, "products");
      expect(ref1.parent!.parent!.name, "");
      expect(ref1.storage, isNotNull);
      expect(ref1.bucket, options["storage_bucket"]);
      expect(ref1.fullPath, "products/11");

      ref2 = ref1.child("16.jpg");

      expect(ref2.name, "16.jpg");
      expect(ref2.root.name, "");
      expect(ref2.parent!.name, "11");
      expect(ref2.parent!.parent!.name, "products");
      expect(ref2.parent!.parent!.parent!.name, "");
      expect(ref2.storage, isNotNull);
      expect(ref2.bucket, options["storage_bucket"]);
      expect(ref2.fullPath, "products/11/16.jpg");
    });

    test("should update retry times", () {
      storage.setMaxOperationRetryTime(const Duration(seconds: 60));
      storage.setMaxUploadRetryTime(const Duration(seconds: 60));
    });

    test("should upload, fetch URL, metadata, list, and delete", () async {
      ref3 = ref1.child("array2.jpg");

      Uint8List bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      try {
        await ref3.delete();
      } catch (e) {
        print(e);
      }

      final snapshot = await ref3.putData(bytes);

      final url = await ref3.getDownloadURL();
      expect(url, isA<String>());

      final meta = await ref3.getMetadata();
      expect(meta.bucket, options["storage_bucket"]);
      expect(meta.fullPath, ref3.fullPath);
      expect(meta.name, ref3.name);
      expect(meta.updated, isNotNull);
      expect(meta.size, isNotNull);
      expect(meta.customMetadata, isNotNull);

      final listRes = await ref1.list();

      final listAllRes = await ref1.listAll();
    });
  });
}
