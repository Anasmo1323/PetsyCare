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

      // 1. Get the Raw Strings
      String rawTemp = data['temperature']?.toString() ?? '';
      String rawHum = data['humidity']?.toString() ?? '';

      // --- DEBUG: Print what we actually got ---
      print("🔥 RAW FROM FIREBASE: Temp='$rawTemp' | Hum='$rawHum'");

      // 2. Clean the data (Remove newlines or whitespace that breaks encryption)
      rawTemp = rawTemp.trim().replaceAll('\n', '').replaceAll('\r', '');
      rawHum = rawHum.trim().replaceAll('\n', '').replaceAll('\r', '');

      // 3. Decrypt
      String realTemp = '--';
      String realHum = '--';

      // Only attempt decryption if it looks like encrypted data (long string)
      // If it's short (like "38.5"), just show it directly to prevent crashing.
      if (rawTemp.length > 10) {
         realTemp = _security.decrypt(rawTemp);
      } else {
         realTemp = rawTemp; // Assume it's already plain text
      }

      if (rawHum.length > 10) {
         realHum = _security.decrypt(rawHum);
      } else {
         realHum = rawHum;
      }

      print("✅ DECRYPTED: $realTemp / $realHum");

      return {
        'temp': realTemp, 
        'humidity': realHum,
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

  // Set Target Temp
  Future<void> setTargetTemp(String deviceId, double temp) async {
    if (deviceId.isEmpty) return;
    await _db.ref('devices/$deviceId/config').update({'target_temp': temp});
  }

  // Toggle Auto Mode
  Future<void> toggleAutoMode(String deviceId, bool isAuto) async {
    if (deviceId.isEmpty) return;
    await _db.ref('devices/$deviceId/config').update({'auto_mode': isAuto});
  }

  // Listen to Config (to update UI sliders)
  Stream<Map<String, dynamic>> getConfigStream(String deviceId) {
    if (deviceId.isEmpty) return Stream.value({});
    return _db.ref('devices/$deviceId/config').onValue.map((event) {
      final data = event.snapshot.value as Map?;
      return {
        'auto_mode': data?['auto_mode'] ?? false,
        'target_temp': (data?['target_temp'] ?? 37.0).toDouble(),
      };
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