// --- This is the complete, new code for add_patient_page.dart ---

import 'package:flutter/material.dart';
import 'package:petsy_care/models/patient_model.dart'; // We added this
import 'package:petsy_care/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddPatientPage extends StatefulWidget {
  // This is new! It's optional, so we can use this page
  // for both adding (null) and editing (not null).
  final Patient? patient;

  const AddPatientPage({super.key, this.patient});

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final _formKey = GlobalKey<FormState>();

  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _animalTypeController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();

  final _firestoreService = FirestoreService();
  bool _isLoading = false;

  // --- This is a new method ---
  @override
  void initState() {
    super.initState();
    // If we are editing, fill the fields with the patient's data
    if (widget.patient != null) {
      _ownerNameController.text = widget.patient!.ownerName;
      _phoneController.text = widget.patient!.phoneNumber;
      _animalTypeController.text = widget.patient!.animalType;
      _breedController.text = widget.patient!.animalBreed;
      _ageController.text = widget.patient!.age;
      _weightController.text = widget.patient!.weight;
    }
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _phoneController.dispose();
    _animalTypeController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // --- This method is UPDATED ---
  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    final Map<String, dynamic> patientData = {
      'ownerName': _ownerNameController.text,
      'phoneNumber': _phoneController.text,
      'animalType': _animalTypeController.text,
      'animalBreed': _breedController.text,
      'age': _ageController.text,
      'weight': _weightController.text,
    };

    try {
      if (widget.patient == null) {
        // ADD MODE
        patientData['createdAt'] = FieldValue.serverTimestamp();
        await _firestoreService.addPatient(patientData);
      } else {
        // EDIT MODE
        await _firestoreService.updatePatient(widget.patient!.id, patientData);
      }

      // If successful, pop the page
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // If error, show the snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save patient: $e')),
        );
      }
    } finally {
      // --- THIS IS THE NEW PART ---
      // This 'finally' block runs *no matter what*.
      // If the app is still on this page, turn off the spinner.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- This title is now dynamic ---
    final isEditing = widget.patient != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Patient' : 'Add New Patient'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _ownerNameController,
                      decoration: const InputDecoration(labelText: 'Owner Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an owner name';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                      keyboardType: TextInputType.phone,
                    ),
                    TextFormField(
                      controller: _animalTypeController,
                      decoration: const InputDecoration(labelText: 'Animal Type (e.g., Dog)'),
                    ),
                    TextFormField(
                      controller: _breedController,
                      decoration: const InputDecoration(labelText: 'Breed'),
                    ),
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(labelText: 'Weight (kg)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _savePatient,
                      child: const Text('Save Patient'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}