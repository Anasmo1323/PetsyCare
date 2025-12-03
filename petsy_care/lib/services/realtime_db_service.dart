import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:petsy_care/services/security_service.dart'; // Make sure this file exists

class RealtimeDBService {
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://petsycare-10533-default-rtdb.europe-west1.firebasedatabase.app',
  );
  
  final SecurityService _security = SecurityService();

  Stream<Map<String, String>> getSensorStream(String deviceId) {
    if (deviceId.isEmpty) return Stream.value({});

    final ref = _db.ref('devices/$deviceId/live_data');

    return ref.onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return {'temp': '--', 'humidity': '--'};

      // 1. Get the Raw (Encrypted) Strings
      String rawTemp = data['temperature']?.toString() ?? '';
      String rawHum = data['humidity']?.toString() ?? '';

      // --- SECURITY UPGRADE: DECRYPTION ---
      // 2. Decrypt them using the shared key
      // If decryption fails (e.g. data is empty), it returns a safe default.
      String realTemp = _security.decrypt(rawTemp);
      String realHum = _security.decrypt(rawHum);

      return {
        'temp': realTemp, 
        'humidity': realHum,
      };
    });
  }

  // ... (Rest of your methods: getHeaterStream, toggleHeater etc. remain the same)
  // Note: For commands (App -> ESP), we usually keep them as plain Booleans (true/false) 
  // because encryption adds latency to controls, but you can encrypt them similarly if required.
  Stream<bool> getHeaterStream(String deviceId) { ... }
  Stream<bool> getDistressStream(String deviceId) { ... }
  Future<void> toggleHeater(String deviceId, bool isOn) async { ... }
}