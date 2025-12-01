import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:petsy_care/services/security_service.dart';

class RealtimeDBService {
  // 1. The Database Instance (with your specific Europe URL)
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://petsycare-10533-default-rtdb.europe-west1.firebasedatabase.app',
  );
  
  final SecurityService _security = SecurityService();

  // 2. Stream for Temperature & Humidity
  Stream<Map<String, String>> getSensorStream(String deviceId) {
    if (deviceId.isEmpty) return Stream.value({});

    final ref = _db.ref('devices/$deviceId/live_data');

    return ref.onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return {'temp': '--', 'humidity': '--'};

      String rawTemp = data['temperature']?.toString() ?? '--';
      String rawHum = data['humidity']?.toString() ?? '--';

      // Uncomment these lines when encryption is ready on hardware
      // String realTemp = _security.decrypt(rawTemp);
      // String realHum = _security.decrypt(rawHum);

      return {
        'temp': rawTemp, 
        'humidity': rawHum,
      };
    });
  }
// Listen for Heater Status
  // Path: devices/cage_001/controls/heater
  Stream<bool> getHeaterStream(String deviceId) {
    if (deviceId.isEmpty) return Stream.value(false);

    final ref = _db.ref('devices/$deviceId/controls/heater');

    return ref.onValue.map((event) {
      // If null (not set yet), assume false
      if (event.snapshot.value == true) return true;
      return false;
    });
  }
  // 3. THIS WAS MISSING: Stream for Distress Signal (Boolean)
  Stream<bool> getDistressStream(String deviceId) {
    if (deviceId.isEmpty) return Stream.value(false);

    // Path: devices/cage_001/distress_active
    final ref = _db.ref('devices/$deviceId/distress_active');

    return ref.onValue.map((event) {
      // If the value exists and is true, return true. Otherwise false.
      if (event.snapshot.value == true) return true;
      return false;
    });
  }

  // 4. Command to toggle Heater
  Future<void> toggleHeater(String deviceId, bool isOn) async {
    if (deviceId.isEmpty) return;
    
    final ref = _db.ref('devices/$deviceId/controls');
    
    await ref.update({
      'heater': isOn, 
    });
  }
}