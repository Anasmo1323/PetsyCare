import 'package:flutter/material.dart';
import 'package:petsy_care/pages/add_patient_page.dart';
import 'package:petsy_care/pages/patient_list_page.dart';

class VisitsPage extends StatelessWidget {
  const VisitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visits & Patients'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // "Add New Patient" Button
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Add New Patient'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddPatientPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // "View Patient List" Button
            ElevatedButton.icon(
              icon: const Icon(Icons.list_alt),
              label: const Text('View Patient List'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PatientListPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}