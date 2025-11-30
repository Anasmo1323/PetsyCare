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
    const String requiredDomain = 'eng-st.cu.edu.eg';

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // 1. Waiting for Firebase to initialize
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. User is NOT logged in
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        // 3. User IS logged in
        final User user = snapshot.data!;

        // --- GATEKEEPER CHECK 1: Domain ---
        // If the domain is wrong, DO NOT show HomePage. 
        // Just show loading while LoginPage logic kicks them out.
        if (!user.email!.endsWith(requiredDomain)) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // --- GATEKEEPER CHECK 2: Database Existence ---
        // We use a FutureBuilder to check if they are in the 'users' collection
        return FutureBuilder<bool>(
          future: firestoreService.checkUserExists(user.uid),
          builder: (context, dbSnapshot) {
            // While checking DB... show loading (Prevents Home Page flash)
            if (dbSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            // If user exists in DB -> Show Home
            if (dbSnapshot.data == true) {
              return const HomePage();
            } 
            
            // If user does NOT exist (but has valid domain):
            // This happens during 2 scenarios:
            // A. They are trying to "Login" but haven't registered -> LoginPage will kick them out.
            // B. They are "Registering" -> LoginPage is currently creating their account.
            // In both cases, showing a loader is safer than showing Home.
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
          },
        );
      },
    );
  }
}