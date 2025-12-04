import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:petsy_care/services/auth_service.dart';
import 'package:petsy_care/services/firestore_service.dart';
import 'package:petsy_care/main.dart'; // Access Global Key

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController(); // New field for Register
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoginMode = true; // Toggle between Login and Register

  // --- CONFIGURATION ---
  static const String _requiredDomain = 'petsy.com';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Helper to Show Errors ---
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // --- MAIN SUBMIT LOGIC ---
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();
      String name = _nameController.text.trim();

      // 1. Domain Check (Applies to both)
      if (!email.endsWith(_requiredDomain)) {
        _showError("Access Denied: Email must end with @$_requiredDomain");
        return;
      }

      if (_isLoginMode) {
        // --- LOGIN FLOW ---
        await _authService.signInWithEmail(email, password);
        // AuthWrapper handles navigation
      } else {
        // --- REGISTER FLOW ---
        UserCredential? cred = await _authService.signUpWithEmail(email, password);

        if (cred != null && cred.user != null) {
          // Create Database Entry with the Name
          await _firestoreService.createUser(
            cred.user!.uid, 
            email, 
            name.isEmpty ? 'Vet' : name // Use the typed name
          );
        }
      }

    } catch (e) {
      _showError(_isLoginMode ? "Login Failed: $e" : "Registration Failed: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- TOGGLE MODE ---
  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _formKey.currentState?.reset(); // Clear errors
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.pets, size: 80, color: Colors.blue),
                  const SizedBox(height: 20),
                  
                  // --- DYNAMIC TITLE ---
                  Text(
                    _isLoginMode ? 'Welcome Back' : 'Create Account',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  Text(
                    _isLoginMode ? 'Login to access your clinic' : 'Register a new staff account',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // --- NAME FIELD (Only for Register) ---
                  if (!_isLoginMode) ...[
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (val) {
                        if (!_isLoginMode && (val == null || val.isEmpty)) return 'Required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // --- EMAIL FIELD ---
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                      helperText: 'Must be @$_requiredDomain',
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if (!val.contains('@')) return 'Invalid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // --- PASSWORD FIELD ---
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if (val.length < 6) return 'Min 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    // --- MAIN ACTION BUTTON ---
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _handleSubmit,
                      child: Text(
                        _isLoginMode ? 'LOGIN' : 'REGISTER',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // --- TOGGLE BUTTON ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_isLoginMode ? "Don't have an account? " : "Already have an account? "),
                        TextButton(
                          onPressed: _toggleMode,
                          child: Text(
                            _isLoginMode ? 'Register Here' : 'Login Here',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}