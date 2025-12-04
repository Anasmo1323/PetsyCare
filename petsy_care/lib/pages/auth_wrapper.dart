import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petsy_care/pages/home_page.dart';
import 'package:petsy_care/pages/login_page.dart';
import 'package:petsy_care/services/auth_service.dart';
import 'package:petsy_care/services/firestore_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();
    
    // --- CONFIGURATION ---
    const String requiredDomain = 'petsy.com';

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // 1. Loading Firebase Auth state...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. Not Logged In -> Show Login Page
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        // 3. User IS Logged In... Let's Verify them.
        final User user = snapshot.data!;

        // --- GATEKEEPER CHECK 1: DOMAIN ---
        // Even if they hacked the login page, this blocks them here.
        if (user.email == null || !user.email!.endsWith(requiredDomain)) {
          return _buildAccessDeniedScreen(
            context, 
            "Access Denied",
            "The email '${user.email}' does not belong to the organization ($requiredDomain).",
            authService
          );
        }

        // --- GATEKEEPER CHECK 2: DATABASE REGISTRATION ---
        // Check if their ID exists in the 'users' collection
        return FutureBuilder<bool>(
          future: firestoreService.checkUserExists(user.uid),
          builder: (context, dbSnapshot) {
            if (dbSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text("Verifying Account..."),
                    ],
                  ),
                ),
              );
            }

            final bool isRegistered = dbSnapshot.data ?? false;

            if (isRegistered) {
              // --- SUCCESS: GO TO HOME ---
              return const HomePage();
            } else {
              // --- FAIL: NOT REGISTERED ---
              return _buildAccessDeniedScreen(
                context,
                "Account Not Found",
                "You are logged in, but your account record was not found in the database.\n\nPlease logout and register again.",
                authService
              );
            }
          },
        );
      },
    );
  }

  // --- REUSABLE ERROR SCREEN ---
  // This shows a red screen if they fail security checks
  Widget _buildAccessDeniedScreen(BuildContext context, String title, String message, AuthService auth) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, color: Colors.red, size: 80),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () async {
                await auth.signOut(); 
              },
            ),
          ],
        ),
      ),
    );
  }
}