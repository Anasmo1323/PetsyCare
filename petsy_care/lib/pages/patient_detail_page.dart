// --- This is the complete, new code for patient_detail_page.dart ---

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petsy_care/models/patient_model.dart';
import 'package:petsy_care/models/treatment_plan_model.dart';
import 'package:petsy_care/services/firestore_service.dart';
import 'package:petsy_care/pages/add_patient_page.dart';
import 'package:petsy_care/pages/treatment_plan_detail_page.dart';
import 'package:petsy_care/widgets/live_monitor.dart';
import 'package:petsy_care/pages/breed_classifier_page.dart';

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
    return StreamBuilder<Patient>(
      stream: _firestoreService.getPatientStream(widget.patientId),
      builder: (context, snapshot) {
        // --- Loading & Error Handling ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
        }
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: Text('Patient not found.')));
        }

        final Patient patient = snapshot.data!;

        // --- NEW: DefaultTabController wraps the Scaffold ---
        return DefaultTabController(
          length: 2, // We now have 2 tabs
          child: Scaffold(
            appBar: AppBar(
              title: Text(patient.ownerName),
              actions: [
// --- AI SCANNER BUTTON ---
              IconButton(
                icon: const Icon(Icons.center_focus_strong),
                tooltip: 'AI Breed Scan',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // Pass the patient ID so the scanner knows who to update
                      builder: (context) => BreedClassifierPage(patientId: patient.id),
                    ),
                  );
                },
              ),
              // -------------------------
              ],
              // --- NEW: The Tab Bar ---
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.assignment), text: "Plan"),
                  Tab(icon: Icon(Icons.monitor_heart), text: "Live Monitor"),
                ],
              ),
            ),
            
            // --- NEW: The Body is now a TabBarView ---
            body: TabBarView(
              children: [
                // --- TAB 1: The Original Treatment Plan View ---
                ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildPatientInfoCard(patient),
                    const SizedBox(height: 20),
                    Text(
                      'Treatment Plans',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<List<TreatmentPlan>>(
                      stream: _firestoreService.getTreatmentPlans(widget.patientId),
                      builder: (context, planSnapshot) {
                        if (!planSnapshot.hasData || planSnapshot.data!.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text('No treatment plans found.'),
                            ),
                          );
                        }
                        final plans = planSnapshot.data!;
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: plans.length,
                          itemBuilder: (context, index) {
                            final plan = plans[index];
                            final formattedDate = DateFormat.yMMMd().format(plan.startDate.toDate());
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

                // --- TAB 2: The New Live Monitor ---
                // We pass the deviceId from the patient to the monitor
                LiveMonitor(deviceId: patient.deviceId),
              ],
            ),
            
            // Floating Action Button (Only shows on the Plan tab technically, 
            // but for simplicity we keep it global or we can hide it conditionally. 
            // For now, let's keep it simple).
            floatingActionButton: FloatingActionButton(
              onPressed: _addNewTreatmentPlan,
              tooltip: 'Start New Treatment Plan',
              child: const Icon(Icons.add),
            ),
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