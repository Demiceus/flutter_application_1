import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/appearance_service.dart';
import '../screens/login_screen.dart';
import '../main.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  User? _lastUser;
  bool _appearanceLoading = false;

  Future<void> _handleUser(User? user) async {
    // Avoid repeating the same operation
    // every time StreamBuilder rebuilds.
    if (_lastUser?.uid == user?.uid) {
      return;
    }

    _lastUser = user;

    if (user == null) {
      AppearanceService.instance.resetToDefaults();
      return;
    }

    if (_appearanceLoading) {
      return;
    }

    _appearanceLoading = true;

    try {
      await AppearanceService.instance.load();
    } finally {
      _appearanceLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final User? user = snapshot.data;

        // Run appearance changes AFTER this build finishes.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          _handleUser(user);
        });

        if (user == null) {
          return const LoginScreen();
        }

        return const ClosetlyApp();
      },
    );
  }
}