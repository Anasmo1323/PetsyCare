import 'package:cloud_firestore/cloud_firestore.dart';

class Patient {
  final String id;
  final String ownerName;
  final String phoneNumber;
  final String animalType;
  final String animalBreed;
  final String age;
  final String weight;
  final String deviceId; // --- NEW: Links patient to IoT Device ---
  final Timestamp createdAt;

  Patient({
    required this.id,
    required this.ownerName,
    required this.phoneNumber,
    required this.animalType,
    required this.animalBreed,
    required this.age,
    required this.weight,
    this.deviceId = '', // --- NEW: Default to empty ---
    required this.createdAt,
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
      deviceId: data['deviceId'] ?? '', // --- NEW ---
      createdAt: data['createdAt'] ?? Timestamp.now(),
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
      'deviceId': deviceId, // --- NEW ---
      // createdAt is handled by the service
    };
  }
}