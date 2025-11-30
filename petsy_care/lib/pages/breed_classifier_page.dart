import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petsy_care/services/firestore_service.dart';
import 'package:petsy_care/services/ml_service.dart';

class BreedClassifierPage extends StatefulWidget {
  final String? patientId; // We now accept a patient ID

  const BreedClassifierPage({super.key, this.patientId});

  @override
  State<BreedClassifierPage> createState() => _BreedClassifierPageState();
}

class _BreedClassifierPageState extends State<BreedClassifierPage> {
  final MLService _mlService = MLService();
  final FirestoreService _firestoreService = FirestoreService(); // For the update
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedImage;
  String _result = "";
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _mlService.initialize();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 224,
        maxHeight: 224,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _result = "";
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final prediction = await _mlService.classifyImage(_selectedImage!);
      
      setState(() {
        _result = prediction;
      });

      // --- NEW LOGIC: Ask to update if we have a patientId ---
      if (widget.patientId != null) {
        _showUpdateDialog(prediction);
      }

    } catch (e) {
      setState(() {
        _result = "Analysis failed.";
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  // --- NEW DIALOG FUNCTION ---
  Future<void> _showUpdateDialog(String prediction) async {
    // Clean the string (Remove confidence %)
    // "German Shepherd (96.5%)" -> "German Shepherd"
    String breedOnly = prediction.split('(')[0].trim();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must choose
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Patient Record?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('The AI detected this breed:'),
                Text(
                  breedOnly, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 10),
                const Text('Do you want to overwrite the current breed with this result?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes, Update'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog first
                await _updatePatientBreed(breedOnly);
              },
            ),
          ],
        );
      },
    );
  }

  // --- NEW UPDATE FUNCTION ---
  Future<void> _updatePatientBreed(String newBreed) async {
    try {
      await _firestoreService.updatePatient(
        widget.patientId!, 
        {'animalBreed': newBreed} // Only update this one field
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Breed updated successfully!')),
        );
        // Optional: Go back to patient page automatically
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Breed Scanner')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: _selectedImage == null
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_search, size: 50, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("No image selected"),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_selectedImage != null)
              ElevatedButton(
                onPressed: _isAnalyzing ? null : _analyzeImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: _isAnalyzing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('IDENTIFY BREED', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 30),
            if (_result.isNotEmpty)
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text("ANALYSIS RESULT", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 10),
                      Text(
                        _result,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}