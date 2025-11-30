// --- This is the complete, new code for patient_list_page.dart ---

import 'package:flutter/material.dart';
import 'package:petsy_care/models/patient_model.dart';
import 'package:petsy_care/pages/patient_detail_page.dart';
import 'package:petsy_care/services/auth_service.dart';
import 'package:petsy_care/services/firestore_service.dart';
import 'package:table_calendar/table_calendar.dart';

class PatientListPage extends StatefulWidget {
  const PatientListPage({super.key});

  @override
  State<PatientListPage> createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage> {
  final authService = AuthService();
  final firestoreService = FirestoreService();

  // State variables
  late Stream<List<Patient>> _patientStream;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month; // Start in month view

  @override
  void initState() {
    super.initState();
    // On start, load all patients for the CURRENT MONTH
    _patientStream = firestoreService.getPatients(selectedMonth: _focusedDay);
  }

  // This function re-builds the stream based on user selection
  void _updateStream() {
    setState(() {
      if (_selectedDay != null) {
        // 1. User tapped a specific day
        _patientStream = firestoreService.getPatients(selectedDay: _selectedDay);
      } else {
        // 2. User is just viewing a month (swiped)
        _patientStream = firestoreService.getPatients(selectedMonth: _focusedDay);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Patients'),
        actions: [
          // Clear filter button
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Show All Patients',
            onPressed: () {
              setState(() {
                _selectedDay = null;
                _focusedDay = DateTime.now();
                // 3. Show ALL patients, no filter
                _patientStream = firestoreService.getPatients();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authService.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          )
        ],
      ),
      body: Column(
        children: [
          // --- The Calendar Widget ---
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            
            // --- This fixes the crash from before ---
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            
            // --- This handles swiping between months ---
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
                _selectedDay = null; // Clear day selection when swiping month
                _updateStream();
              });
            },
            
            // --- This handles tapping a specific day ---
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _updateStream();
              });
            },
          ),
          
          // --- The Patient List ---
          Expanded(
            child: StreamBuilder<List<Patient>>(
              stream: _patientStream, // Stream is now managed by our state
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  // This is where the index error will appear
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'An error occurred. Have you created the Firestore index? Check the Debug Console for a link.\n\nError: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No patients found for this period.'),
                  );
                }

                final patients = snapshot.data!;

                return ListView.builder(
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    return ListTile(
                      title: Text(patient.ownerName),
                      subtitle: Text(
                          '${patient.animalType} - ${patient.animalBreed}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PatientDetailPage(patientId: patient.id),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}