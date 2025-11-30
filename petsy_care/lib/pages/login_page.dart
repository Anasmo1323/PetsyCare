import 'package:flutter/material.dart';
import 'package:petsy_care/services/auth_service.dart';
import 'package:petsy_care/services/firestore_service.dart';
import 'package:petsy_care/main.dart'; // Import to access rootScaffoldMessengerKey

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  static const String _requiredDomain = 'eng-st.cu.edu.eg';

  // --- 1. LOGIN Logic ---
  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    
    try {
      final userCred = await _authService.signInWithGoogle();
      
      if (userCred != null && userCred.user != null) {
        final user = userCred.user!;
        
        // CHECK 1: Domain
        if (!user.email!.endsWith(_requiredDomain)) {
          await _showErrorAndDisconnect(
            "Access Denied: Your email (${user.email}) does not belong to $_requiredDomain."
          );
          return;
        }

        // CHECK 2: Registration
        final exists = await _firestoreService.checkUserExists(user.uid);
        if (!exists) {
          await _showErrorAndDisconnect(
            "Account not found. Please Register first."
          );
          return;
        }
        
        // If passed, we do nothing. AuthWrapper sees the user and takes us Home.
      }
    } catch (e) {
      // Handle crashes
      print("Login Error: $e");
    } finally {
      // Ensure loading stops even if user cancels
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. REGISTER Logic ---
  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);

    try {
      final userCred = await _authService.signInWithGoogle();

      if (userCred != null && userCred.user != null) {
        final user = userCred.user!;

        // CHECK 1: Domain
        if (!user.email!.endsWith(_requiredDomain)) {
          await _showErrorAndDisconnect(
            "Registration Denied: Email must end with $_requiredDomain."
          );
          return;
        }

        // CHECK 2: Create if new
        final exists = await _firestoreService.checkUserExists(user.uid);
        if (!exists) {
          await _firestoreService.createUser(user.uid, user.email!, user.displayName ?? 'Vet');
        }
      }
    } catch (e) {
      print("Register Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Helper to Show Error & Force Logout ---
  Future<void> _showErrorAndDisconnect(String message) async {
    // 1. Force Disconnect (Fixes the "Stuck" issue)
    await _authService.disconnect();
    
    // 2. Show the Red Error Bar using the GLOBAL KEY
    // This ensures it shows up even if the screen is flashing/changing
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating, // Floats above content
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
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
                'Private Clinic Portal',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              
              const SizedBox(height: 60),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Login with Official Email'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _handleLogin,
                ),
                
                const SizedBox(height: 20),
                const Row(children: [Expanded(child: Divider()), Text(" OR "), Expanded(child: Divider())]),
                const SizedBox(height: 20),

                OutlinedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Register New Account'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _handleRegister,
                ),
                
                const SizedBox(height: 20),
                const Text(
                  '* Access restricted to @eng-st.cu.edu.eg',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}