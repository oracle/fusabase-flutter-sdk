import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';


//tests
 import './testAuth.dart';
 import './testOracledb.dart';
 import './testObjectStore.dart';
  import './homepage.dart';

 import 'package:fusabase/core.dart';
import 'package:fusabase/oracledb.dart';
import 'package:fusabase/auth.dart';
import 'package:fusabase/storage.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
         auth_test();
         oracledb_test();
         storage_test(); 

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = "1";
    });
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Flutter Web Redirect Auth',
      home: const AuthGate(),
    );
  }
}
