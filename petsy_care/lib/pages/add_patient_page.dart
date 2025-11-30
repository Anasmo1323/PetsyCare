import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:petsy_care/models/patient_model.dart';
import 'package:petsy_care/services/firestore_service.dart';

class AddPatientPage extends StatefulWidget {
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
  // --- NEW CONTROLLER ---
  final _deviceIdController = TextEditingController();

  final _firestoreService = FirestoreService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      _ownerNameController.text = widget.patient!.ownerName;
      _phoneController.text = widget.patient!.phoneNumber;
      _animalTypeController.text = widget.patient!.animalType;
      _breedController.text = widget.patient!.animalBreed;
      _ageController.text = widget.patient!.age;
      _weightController.text = widget.patient!.weight;
      // --- FILL DEVICE ID ---
      _deviceIdController.text = widget.patient!.deviceId;
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
    _deviceIdController.dispose();
    super.dispose();
  }

  Future<void> _savePatient() async {
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
      // --- SAVE DEVICE ID ---
      'deviceId': _deviceIdController.text.trim(), // Remove extra spaces
    };

    try {
      if (widget.patient == null) {
        patientData['createdAt'] = FieldValue.serverTimestamp();
        await _firestoreService.addPatient(patientData);
      } else {
        await _firestoreService.updatePatient(widget.patient!.id, patientData);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save patient: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    // --- DEVICE ID FIELD (The most important one for IoT) ---
                    TextFormField(
                      controller: _deviceIdController,
                      decoration: const InputDecoration(
                        labelText: 'Smart Cage Device ID',
                        hintText: 'e.g., cage_001',
                        prefixIcon: Icon(Icons.qr_code),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ownerNameController,
                      decoration: const InputDecoration(labelText: 'Owner Name'),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _animalTypeController,
                            decoration: const InputDecoration(labelText: 'Type'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _breedController,
                            decoration: const InputDecoration(labelText: 'Breed'),
                          ),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(labelText: 'Weight'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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