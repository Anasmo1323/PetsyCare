import 'package:cloud_firestore/cloud_firestore.dart';

class Patient {
  final String id;
  final String ownerName;
  final String phoneNumber;
  final String animalType;
  final String animalBreed;
  final String age;
  final String weight;
  final String deviceId;
  final Timestamp createdAt;
  final String? imageUrl; // --- NEW: Holds the URL of the photo ---

  Patient({
    required this.id,
    required this.ownerName,
    required this.phoneNumber,
    required this.animalType,
    required this.animalBreed,
    required this.age,
    required this.weight,
    this.deviceId = '',
    required this.createdAt,
    this.imageUrl, // --- NEW: Optional parameter ---
  });

  factory Patient.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Patient(
      id: documentId,
      ownerName: data['ownerName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      animalType: data['animalType'] ?? '',
      animalBreed: data['animalBreed'] ?? '',
      age: data['age'] ?? '',
      weight: data['weight'] ?? '',
      deviceId: data['deviceId'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      imageUrl: data['imageUrl'], // --- NEW: Read from DB ---
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerName': ownerName,
      'phoneNumber': phoneNumber,
      'animalType': animalType,
      'animalBreed': animalBreed,
      'age': age,
      'weight': weight,
      'deviceId': deviceId,
      'imageUrl': imageUrl, // --- NEW: Write to DB ---
      // createdAt is handled by the service during creation
    };
  }
}