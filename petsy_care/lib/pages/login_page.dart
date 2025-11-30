import 'package:flutter/material.dart';
import 'package:petsy_care/services/auth_service.dart'; // Import our service

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PetsyCare Login'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // We can add Email/Password fields here later
            ElevatedButton.icon(
              icon: const Icon(Icons.login), // You can find a Google 'G' icon
              label: const Text('Sign in with Google'),
              onPressed: () async {
                await authService.signInWithGoogle();
                // The AuthWrapper will handle the screen change
              },
            ),
          ],
        ),
      ),
    );
  }
}