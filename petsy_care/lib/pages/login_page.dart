import 'package:flutter/material.dart';
import 'package:petsy_care/services/auth_service.dart';
import 'package:petsy_care/services/firestore_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  // Unified Login/Register function
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    
    try {
      // 1. Trigger Google Sign In
      final userCred = await _authService.signInWithGoogle();
      
      if (userCred != null && userCred.user != null) {
        final user = userCred.user!;
        
        // 2. Check if user exists in DB
        final exists = await _firestoreService.checkUserExists(user.uid);
        
        if (!exists) {
          // 3. If not, AUTO-REGISTER them (Don't block them)
          await _firestoreService.createUser(
            user.uid, 
            user.email!, 
            user.displayName ?? 'Vet'
          );
        }
        
        // Success! AuthWrapper will take us Home.
      }
    } catch (e) {
      print("Login Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.pets, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'PetsyCare',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const Text(
                'Debug Mode: Open Access',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
              
              const SizedBox(height: 60),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In with Google'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _handleGoogleSignIn,
                ),
            ],
          ),
        ),
      ),
    );
  }
}