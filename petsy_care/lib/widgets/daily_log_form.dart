import 'package:flutter/material.dart';
import 'package:petsy_care/models/daily_log_model.dart';
import 'package:petsy_care/services/firestore_service.dart';

class DailyLogForm extends StatefulWidget {
  // We pass in all the IDs and the specific day's data
  final String patientId;
  final String planId;
  final String dayKey; // e.g., "day1", "day2"
  final DailyLog dailyLog;

  const DailyLogForm({
    super.key,
    required this.patientId,
    required this.planId,
    required this.dayKey,
    required this.dailyLog,
  });

  @override
  State<DailyLogForm> createState() => _DailyLogFormState();
}

class _DailyLogFormState extends State<DailyLogForm> {
  // Create controllers and pre-fill them with the data
  late final TextEditingController _notesController;
  late final TextEditingController _tempController;
  late final TextEditingController _feedingController;
  late final TextEditingController _stoolController;
  late final TextEditingController _urineController;
  late final TextEditingController _medicationController;

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with the existing data
    _notesController = TextEditingController(text: widget.dailyLog.notes);
    _tempController = TextEditingController(text: widget.dailyLog.temperature);
    _feedingController = TextEditingController(text: widget.dailyLog.feeding);
    _stoolController = TextEditingController(text: widget.dailyLog.stool);
    _urineController = TextEditingController(text: widget.dailyLog.urine);
    _medicationController =
        TextEditingController(text: widget.dailyLog.medication);
  }

  @override
  void dispose() {
    // Clean up all controllers
    _notesController.dispose();
    _tempController.dispose();
    _feedingController.dispose();
    _stoolController.dispose();
    _urineController.dispose();
    _medicationController.dispose();
    super.dispose();
  }

  // This function saves the *entire form* for this day
  void _saveDailyLog() {
    final logData = {
      'notes': _notesController.text,
      'temperature': _tempController.text,
      'feeding': _feedingController.text,
      'stool': _stoolController.text,
      'urine': _urineController.text,
      'medication': _medicationController.text,
    };

    _firestoreService.updateDailyLog(
      patientId: widget.patientId,
      planId: widget.planId,
      dayKey: widget.dayKey,
      logData: logData,
    );

    // Show a confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.dayKey} saved!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(labelText: 'Diagnosis / Notes'),
        ),
        TextFormField(
          controller: _tempController,
          decoration: const InputDecoration(labelText: 'Temperature'),
        ),
        TextFormField(
          controller: _feedingController,
          decoration: const InputDecoration(labelText: 'Feeding'),
        ),
        TextFormField(
          controller: _stoolController,
          decoration: const InputDecoration(labelText: 'Stool'),
        ),
        TextFormField(
          controller: _urineController,
          decoration: const InputDecoration(labelText: 'Urine'),
        ),
        TextFormField(
          controller: _medicationController,
          decoration: const InputDecoration(labelText: 'Medication & Instructions'),
          maxLines: 3,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _saveDailyLog,
          child: const Text('Save Day'),
        ),
      ],
    );
  }
}