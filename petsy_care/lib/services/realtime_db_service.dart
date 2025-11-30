import 'package:firebase_database/firebase_database.dart';
import 'package:petsy_care/services/security_service.dart';

class RealtimeDBService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final SecurityService _security = SecurityService();

  // Listen to the live sensors for a specific device
  Stream<Map<String, String>> getSensorStream(String deviceId) {
    if (deviceId.isEmpty) return Stream.value({});

    // Point to: devices/cage_001/live_data
    final ref = _db.ref('devices/$deviceId/live_data');

    return ref.onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return {'temp': '--', 'humidity': '--'};

      // 1. Get the encrypted strings
      String encTemp = data['temperature']?.toString() ?? '';
      String encHum = data['humidity']?.toString() ?? '';

      // 2. Decrypt them using your SecurityService
      String realTemp = _security.decrypt(encTemp);
      String realHum = _security.decrypt(encHum);

      return {
        'temp': realTemp,
        'humidity': realHum,
      };
    });
  }

  // Send a command to the hardware (e.g. Heater ON)
  Future<void> toggleHeater(String deviceId, bool isOn) async {
    if (deviceId.isEmpty) return;
    
    // Point to: devices/cage_001/controls
    final ref = _db.ref('devices/$deviceId/controls');
    
    await ref.update({
      'heater': isOn, // Hardware listens to this
    });
  }
}