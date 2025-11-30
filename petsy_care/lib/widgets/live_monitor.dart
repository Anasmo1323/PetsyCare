import 'package:flutter/material.dart';
import 'package:petsy_care/services/realtime_db_service.dart';

class LiveMonitor extends StatelessWidget {
  final String deviceId;
  final RealtimeDBService _rtdb = RealtimeDBService();

  LiveMonitor({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    if (deviceId.isEmpty) {
      return const Center(child: Text('No Device ID linked to this patient.'));
    }

    return StreamBuilder<Map<String, String>>(
      stream: _rtdb.getSensorStream(deviceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final data = snapshot.data ?? {'temp': '--', 'humidity': '--'};
        final temp = data['temp']!;
        final hum = data['humidity']!;

        // Simple alert logic
        bool isCritical = false;
        try {
          double tVal = double.parse(temp);
          if (tVal < 36.0 || tVal > 39.5) isCritical = true;
        } catch (e) {} // Ignore parse errors

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // --- STATUS CARD ---
              Card(
                color: isCritical ? Colors.red.shade100 : Colors.green.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text('LIVE TEMPERATURE', 
                        style: TextStyle(color: isCritical ? Colors.red : Colors.green[800], fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$temp °C',
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                      ),
                      Text('Humidity: $hum %'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // --- CONTROLS ---
              const Text('Environment Controls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              SwitchListTile(
                title: const Text('Heating Pad'),
                subtitle: const Text('Turn on to warm the cage'),
                secondary: const Icon(Icons.wb_sunny, color: Colors.orange),
                value: false, // We need to read the *actual* state from DB later
                onChanged: (val) {
                  _rtdb.toggleHeater(deviceId, val);
                  // Note: In a real app, this switch should listen to the DB state
                  // to verify the hardware actually turned on.
                },
              ),
            ],
          ),
        );
      },
    );
  }
}