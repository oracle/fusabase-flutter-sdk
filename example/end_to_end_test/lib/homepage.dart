import 'package:flutter/material.dart';
import 'package:fusabase/core.dart';
import 'package:fusabase/oracledb.dart';
import 'package:fusabase/auth.dart';
import 'package:fusabase/storage.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final FusabaseAuth _auth = FusabaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _handleRedirectResult();
  }

  Future<void> _handleRedirectResult() async {
    try {
      final result = await _auth.getRedirectResult();
      if (result.user != null) {
        debugPrint("Signed in as: ${result.user!.email}");
      }
    } catch (e) {
      debugPrint("Redirect error: $e");
    }
  }

  Future<void> _signInWithGoogleRedirect() async {
    final provider = GoogleAuthProvider();
    await _auth.signInWithRedirect(provider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Web Redirect Login')),
      body: Center(
        child: StreamBuilder<User?>(
          stream: _auth.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (snapshot.hasData) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Logged in as ${snapshot.data!.email}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await _auth.signOut();
                    },
                    child: const Text('Logout'),
                  )
                ],
              );
            }

            return ElevatedButton(
              onPressed: _signInWithGoogleRedirect,
              child: const Text('Sign in with Google'),
            );
          },
        ),
      ),
    );
  }
}