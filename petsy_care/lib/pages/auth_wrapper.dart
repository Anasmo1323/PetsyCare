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
        // 1. Loading...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. Not Logged In -> Show Login Page
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        // 3. User IS Logged In -> GO STRAIGHT HOME (No Security Checks)
        return const HomePage();
      },
    );
  }
}