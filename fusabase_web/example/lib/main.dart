import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:obaas_web/obaas_web.dart';

void main() {
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
    try {
      final socialPlugin = ObaasWeb(
        scheme:"https",
        host:"https://phoenix313956.dev3sub2phx.databasede3phx.oraclevcn.com",
        port:8443,
        path:'/ords/user1/_/baas-services/idm/idcs/1786a2c493faf572e0630c6846649ea7/socialidp',
        queryParameters: {
          "method": "google",
          "appID": "1786a2c493faf572e0630c6846649ea7"
        },
        appID: "1786a2c493faf572e0630c6846649ea7",
        callbackUrlScheme: 'baasmobile1786a2c493faf572e0630c6846649ea7'
          );
        socialPlugin.socialLogin();
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

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
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
  }
}
