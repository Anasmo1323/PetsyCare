import 'package:flutter/material.dart';
import 'package:petsy_care/services/realtime_db_service.dart';
import 'package:petsy_care/widgets/temp_chart.dart';

class LiveMonitor extends StatelessWidget {
  final String deviceId;
  final RealtimeDBService _rtdb = RealtimeDBService();

  LiveMonitor({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    if (deviceId.isEmpty) {
      return const Center(child: Text('No Device ID linked to this patient.'));
    }

    // Stream 1: Sensor Data
    return StreamBuilder<Map<String, String>>(
      stream: _rtdb.getSensorStream(deviceId),
      builder: (context, sensorSnapshot) {
        
        // Stream 2: Distress Signal
        return StreamBuilder<bool>(
          stream: _rtdb.getDistressStream(deviceId),
          builder: (context, distressSnapshot) {

            // Stream 3: Heater Status (NEW)
            return StreamBuilder<bool>(
              stream: _rtdb.getHeaterStream(deviceId),
              builder: (context, heaterSnapshot) {
                
                if (sensorSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = sensorSnapshot.data ?? {'temp': '--', 'humidity': '--'};
                final temp = data['temp']!;
                final hum = data['humidity']!;
                
                final isDistress = distressSnapshot.data ?? false;
                final isHeaterOn = heaterSnapshot.data ?? false; // Actual DB state

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // --- DISTRESS BANNER ---
                        if (isDistress)
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 40),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "DISTRESS DETECTED!\nCheck Patient Immediately.",
                                    style: TextStyle(
                                      color: Colors.white, 
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // --- STATUS CARD ---
                        Card(
                          color: isDistress ? Colors.red.shade50 : Colors.green.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Text('LIVE TEMPERATURE', 
                                  style: TextStyle(
                                    color: isDistress ? Colors.red : Colors.green[800], 
                                    fontWeight: FontWeight.bold
                                  )
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
                        
                        const SizedBox(height: 20),

                        // --- CHART ---
                        TempChart(deviceId: deviceId),

                        const SizedBox(height: 30),
                        
                        // --- CONTROLS ---
                        const Text('Environment Controls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Divider(),
                        SwitchListTile(
                          title: const Text('Heating Pad'),
                          subtitle: const Text('Turn on to warm the cage'),
                          secondary: Icon(Icons.wb_sunny, color: isHeaterOn ? Colors.orange : Colors.grey),
                          value: isHeaterOn, // Now uses the REAL value from Firebase
                          onChanged: (val) {
                            // 1. Send command to DB
                            _rtdb.toggleHeater(deviceId, val);
                            // 2. The StreamBuilder will see the change in DB and update the UI automatically
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }
            );
          }
        );
      },
    );
  }
}