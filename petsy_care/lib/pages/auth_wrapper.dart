import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petsy_care/pages/home_page.dart';
import 'package:petsy_care/pages/login_page.dart';
import 'package:petsy_care/services/auth_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show a loading circle while checking
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if data (the user) exists
        if (snapshot.hasData) {
          // User IS logged in, show HomePage
          return const HomePage();
        } else {
          // User is NOT logged in, show LoginPage
          return const LoginPage();
        }
      },
    );
  }
}