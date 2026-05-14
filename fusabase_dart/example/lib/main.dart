import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io' show HttpServer;
import 'dart:convert';
import 'package:obaas_dart/obaas_dart.dart';
import 'package:http/http.dart' as http;



void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
   
  String _status = '';

  @override
  void initState() {
    super.initState();
    // startServer();
  }

  // Future<void> startServer() async {
  //   final server = await HttpServer.bind('127.0.0.1', 43823);

  //   server.listen((req) async {
  //     setState(() { _status = 'Received request!'; });

  //     req.response.headers.add('Content-Type', 'text/html');
  
  //     req.response.close();
  //   });
  // }

  void authenticate() async {
   

    // Present the dialog to the user
    final result = await ObaasDartPlugin.socialLogin();
    print(result);

    


// final url1 = Uri.https('idcs-a395d02748a14ef0ab06f01f08209676.identity.oraclecloud.com:443', 'oauth2/v1/token');
// print(url1);
// // Use this code to get an access token
// final response = await http.post(url1, body: {
//   'client_id': googleClientId,
//   'redirect_uri': '$callbackUrlScheme://nodata',
//   'grant_type': 'authorization_code',
//   'code': code,
// });
// print(response);
// // Get the access token from the response
// final accessToken = jsonDecode(response.body)['access_token'] as String;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Web Auth example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Status: $_status\n'),
              const SizedBox(height: 80),
              ElevatedButton(
                child: Text('Authenticate'),
                onPressed: () { this.authenticate(); },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

