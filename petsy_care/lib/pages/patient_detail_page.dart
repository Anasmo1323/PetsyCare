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
  final String patientId;

  const PatientDetailPage({super.key, required this.patientId});

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

// 1. Add the Mixin to handle tab animations
class _PatientDetailPageState extends State<PatientDetailPage> with SingleTickerProviderStateMixin {
  final _firestoreService = FirestoreService();
  
  // 2. Define the controller
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 3. Initialize the controller with 2 tabs
    _tabController = TabController(length: 2, vsync: this);
    
    // Listen for tab changes to update the FAB visibility
    _tabController.addListener(() {
      setState(() {}); 
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

        // We removed DefaultTabController because we are managing it manually now
        return Scaffold(
          appBar: AppBar(
            title: Text(patient.ownerName),
            actions: [
              // Scanner Button
              IconButton(
                icon: const Icon(Icons.center_focus_strong),
                tooltip: 'AI Breed Scan',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BreedClassifierPage(patientId: patient.id),
                    ),
                  );
                },
              ),
              // Edit Button
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Patient',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddPatientPage(patient: patient),
                    ),
                  );
                },
              ),
            ],
            // 4. Attach our manual controller to the TabBar
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.assignment), text: "Plan"),
                Tab(icon: Icon(Icons.monitor_heart), text: "Live Monitor"),
              ],
            ),
          ),
          
          // 5. Attach our manual controller to the ب
          body: TabBarView(
            controller: _tabController,
            children: [
              // --- TAB 1: Plan ---
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

              // --- TAB 2: Live Monitor ---
              LiveMonitor(deviceId: patient.deviceId),
            ],
          ),
          
          // 6. THE LOGIC: Only show FAB if index is 0 (The Plan Tab)
          floatingActionButton: _tabController.index == 0 
              ? FloatingActionButton(
                  onPressed: _addNewTreatmentPlan,
                  child: const Icon(Icons.add),
                  tooltip: 'Start New Treatment Plan',
                )
              : null, // Returning null hides the button completely
        );
      },
    );
  }

Widget _buildPatientInfoCard(Patient patient) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Owner: ${patient.ownerName}', style: const TextStyle(fontSize: 16)),
            Text('Phone: ${patient.phoneNumber}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text('Animal: ${patient.animalType}', style: const TextStyle(fontSize: 16)),
            // Highlight the Breed so you can see the AI update worked
            Text('Breed: ${patient.animalBreed}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 18, 88, 168))),
            Text('Age: ${patient.age}', style: const TextStyle(fontSize: 16)),
            Text('Weight: ${patient.weight} kg', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}