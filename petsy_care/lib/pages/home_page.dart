import 'package:flutter/material.dart';
import 'package:petsy_care/models/patient_model.dart'; // Corrected import
import 'package:petsy_care/services/auth_service.dart'; // Corrected import
import 'package:petsy_care/services/firestore_service.dart'; // Corrected import
import 'package:petsy_care/pages/add_patient_page.dart';
// ... other imports
import 'package:petsy_care/pages/patient_detail_page.dart';
import 'package:petsy_care/pages/visits_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PetsyCare Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authService.signOut();
            },
          )
        ],
      ),
body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // "Visits" Button
            ElevatedButton.icon(
              icon: const Icon(Icons.pets),
              label: const Text('Visits & Patients'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 30),
                textStyle: const TextStyle(fontSize: 22),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VisitsPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // "Medications" Button
            ElevatedButton.icon(
              icon: const Icon(Icons.medical_services),
              label: const Text('Medications'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 30),
                textStyle: const TextStyle(fontSize: 22),
                backgroundColor: Colors.grey[700], // Different color for now
              ),
              onPressed: () {
                // We will build this page next!
                // Navigator.push(context, ...);
              },
            ),
          ],
        ),
      ),

    );
  }
}