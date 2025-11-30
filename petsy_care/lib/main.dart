import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// THIS PATH IS NOW CORRECT
import 'package:petsy_care/pages/auth_wrapper.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PetsyCareApp());
}

class PetsyCareApp extends StatelessWidget {
  const PetsyCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetsyCare',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // This points to your AuthWrapper
      home: const AuthWrapper(),
    );
  }
}