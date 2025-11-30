import 'package:cloud_firestore/cloud_firestore.dart'; // Import this

class Patient {
  final String id;
  final String ownerName;
  final String phoneNumber;
  final String animalType;
  final String animalBreed;
  final String age;
  final String weight;
  final Timestamp createdAt; // --- ADD THIS ---

  Patient({
    required this.id,
    required this.ownerName,
    required this.phoneNumber,
    required this.animalType,
    required this.animalBreed,
    required this.age,
    required this.weight,
    required this.createdAt, // --- ADD THIS ---
  });

  // A factory to create a Patient from a Firestore document
  factory Patient.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Patient(
      id: documentId,
      ownerName: data['ownerName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      animalType: data['animalType'] ?? '',
      animalBreed: data['animalBreed'] ?? '',
      age: data['age'] ?? '',
      weight: data['weight'] ?? '',
      // --- ADD THIS LINE (and a fallback) ---
      createdAt: data['createdAt'] ?? Timestamp.now(), 
    );
  }

  // A method to convert a Patient object to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'ownerName': ownerName,
      'phoneNumber': phoneNumber,
      'animalType': animalType,
      'animalBreed': animalBreed,
      'age': age,
      'weight': weight,
      // We don't need 'createdAt' here because we'll set it
      // on the server when we add/update.
    };
  }
}