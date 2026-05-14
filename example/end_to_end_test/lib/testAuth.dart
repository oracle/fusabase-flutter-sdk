import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusabase/core.dart';
import 'package:fusabase/oracledb.dart';
import 'package:fusabase/auth.dart';
import 'package:fusabase/storage.dart';

String generateRandomEmail() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final random = Random();
  final username = List.generate(10, (_) => chars[random.nextInt(chars.length)]).join();
  const domains = ['gmail.com', 'yahoo.com', 'outlook.com', 'randommail.com'];
  final domain = domains[random.nextInt(domains.length)];
  return '$username@$domain';
}

void auth_test() {
  group('OBAAS Auth Tests', () {
    late FusabaseApp app;
    late FusabaseAuth auth;
    const options = {};

    const provideridValue = "password";
    const provideridValue1 = "UserNamePassword";

    final email = generateRandomEmail();
    const password = "Chirag@123";
    const newPassword = "Chirag@1234";
    const newName1 = "Test name 1";
    const phoneNumber1 = "1234567891";
    const newName2 = "Test name 2";
    const phoneNumber2 = "1234567892";

    setUpAll(() async {
      app = Fusabase.initializeApp( name:"test", options:FusabaseOptions(options));
      auth = FusabaseAuth.instanceFor(app:app);
    });

    group('App Initialization', () {
      test('should set app options correctly', () {
        expect(app.options.ordsHost, equals(options['ords_host']));
        expect(app.options.schema, equals(options['schema']));
        expect(app.options.appID, equals(options['app_id']));
        expect(app.options.objsType, equals(options['objs_type']));
        expect(app.options.storageBucket, equals(options['storage_bucket']));
        expect(app.options.authType, equals(options['auth_type']));
        expect(app.options.authID, equals(options['auth_id']));
      });
    });

    group('User Lifecycle', () {
      late User createdUser;

      test('should create a user with email and password', () async {
        final res1 = await auth.createUserWithEmailAndPassword(email:email, password:password);
        expect(res1.user, isNotNull);
        expect(res1.credential, isNotNull);
        expect(res1.user!.displayName, equals('- -'));
        expect(res1.user!.email, equals(email));
        expect(res1.user!.phoneNumber, isNull);
        expect(res1.user!.photoURL, isNull);
        expect(res1.user!.refreshToken, isNotEmpty);
        expect(res1.credential!.providerId, equals(provideridValue));
        expect(res1.credential!.signInMethod, equals('password'));
        createdUser = res1.user!;
      });

      test('should sign in with email and password', () async {
        final res2 = await auth.signInWithEmailAndPassword(email:email, password:password);
        expect(res2.user, isNotNull);
        expect(res2.credential, isNotNull);
        expect(res2.user!.email, equals(email));
        expect(auth.currentUser!.email, equals(email));
      });

      test('should update password', () async {
        await createdUser.updatePassword(password, newPassword);
        final res3 = await auth.signInWithEmailAndPassword(email:email, password:newPassword);
        expect(res3.user, isNotNull);
        expect(res3.user!.email, equals(email));
      });

      test('should update displayName', () async {
        await createdUser.updateProfile(displayName: newName1);
        final res4 = await auth.signInWithEmailAndPassword(email:email, password:newPassword);
        expect(res4.user!.displayName, equals(newName1));
      });

      test('should sign out', () async {
        await auth.signOut();
        expect(auth.currentUser, isNull);
      });
    });

    group('Token and Reload Tests', () {
      late User signedInUser;

      setUpAll(() async {
        final res = await auth.signInWithEmailAndPassword(email:email, password:newPassword);
        signedInUser = res.user!;
      });

      test('should get IdToken', () async {
        final token = await signedInUser.getIdToken();
        expect(token, isA<String>());
      });

      test('should get IdTokenResult', () async {
        final tokenRes = await signedInUser.getIdTokenResult();
        expect(tokenRes, isA<IdTokenResult>());
      });

      test('should reload user', () async {
        await signedInUser.reload();
        expect(auth.currentUser!.email, equals(signedInUser.email));
      });
    });
  });
}
