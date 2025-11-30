// --- This is the complete, new code for patient_detail_page.dart ---

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petsy_care/models/patient_model.dart';
import 'package:petsy_care/models/treatment_plan_model.dart';
import 'package:petsy_care/services/firestore_service.dart';
import 'package:petsy_care/pages/add_patient_page.dart';
import 'package:petsy_care/pages/treatment_plan_detail_page.dart';

class PatientDetailPage extends StatefulWidget {
  // --- THIS IS THE CHANGE ---
  final String patientId;

  const PatientDetailPage({super.key, required this.patientId});

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  final _firestoreService = FirestoreService();

  void _addNewTreatmentPlan() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await _firestoreService.createNewTreatmentPlan(widget.patientId);
      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create plan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- THIS IS THE NEW STRUCTURE ---
    // We wrap the whole page in a StreamBuilder to get live updates
    return StreamBuilder<Patient>(
      stream: _firestoreService.getPatientStream(widget.patientId),
      builder: (context, snapshot) {
        // Handle loading and errors
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('Patient not found.')),
          );
        }

        // --- We have the data! ---
        final Patient patient = snapshot.data!;

        // We build the real Scaffold inside the builder
        return Scaffold(
          appBar: AppBar(
            title: Text(patient.ownerName), // Title is now from the stream
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Patient',
                onPressed: () {
                  // We pass the live patient object to the edit page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddPatientPage(patient: patient),
                    ),
                  );
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- Patient Info Section ---
              _buildPatientInfoCard(patient), // Pass the patient data

              const SizedBox(height: 20),

              // --- Treatment Plan History Section ---
              Text(
                'Treatment Plans',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),

              // This stream is for the sub-collection of plans
              StreamBuilder<List<TreatmentPlan>>(
                stream: _firestoreService.getTreatmentPlans(widget.patientId),
                builder: (context, planSnapshot) {
                  if (planSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!planSnapshot.hasData || planSnapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No treatment plans found. Add one!'),
                    );
                  }

                  final plans = planSnapshot.data!;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      final plan = plans[index];
                      final formattedDate =
                          DateFormat.yMMMd().format(plan.startDate.toDate());

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          title: Text('Plan from $formattedDate'),
                          subtitle: Text('ID: ${plan.id}'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TreatmentPlanDetailPage(
                                  patientId: widget.patientId,
                                  plan: plan,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _addNewTreatmentPlan,
            tooltip: 'Start New Treatment Plan',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  // Helper widget now takes a Patient object as an argument
  Widget _buildPatientInfoCard(Patient patient) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Owner: ${patient.ownerName}',
                style: const TextStyle(fontSize: 16)),
            Text('Phone: ${patient.phoneNumber}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text('Animal: ${patient.animalType} (${patient.animalBreed})',
                style: const TextStyle(fontSize: 16)),
            Text('Age: ${patient.age}', style: const TextStyle(fontSize: 16)),
            Text('Weight: ${patient.weight} kg',
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}