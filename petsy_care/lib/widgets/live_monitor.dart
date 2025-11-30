import 'package:flutter/material.dart';
import 'package:petsy_care/services/realtime_db_service.dart';
import 'package:petsy_care/widgets/temp_chart.dart'; // Make sure this is imported!

class LiveMonitor extends StatelessWidget {
  final String deviceId;
  final RealtimeDBService _rtdb = RealtimeDBService();

  LiveMonitor({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    if (deviceId.isEmpty) {
      return const Center(child: Text('No Device ID linked to this patient.'));
    }

    // --- Stream 1: Sensor Data (Temp/Hum) ---
    return StreamBuilder<Map<String, String>>(
      stream: _rtdb.getSensorStream(deviceId),
      builder: (context, sensorSnapshot) {
        
        // --- Stream 2: Distress Signal (The ML Alert) ---
        return StreamBuilder<bool>(
          stream: _rtdb.getDistressStream(deviceId),
          builder: (context, distressSnapshot) {
            
            if (sensorSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = sensorSnapshot.data ?? {'temp': '--', 'humidity': '--'};
            final temp = data['temp']!;
            final hum = data['humidity']!;
            
            // Check if distress is active (default to false)
            final isDistress = distressSnapshot.data ?? false;

            // --- THE FIX: Wrap everything in SingleChildScrollView ---
            return SingleChildScrollView( 
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // --- THE NEW DISTRESS BANNER ---
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

                    // --- STATUS CARD (Changes color if Distress is active) ---
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

                    // --- THE GRAPH ---
                    // This widget shows the history line chart
                    TempChart(deviceId: deviceId),

                    const SizedBox(height: 30),
                    
                    // --- CONTROLS ---
                    const Text('Environment Controls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Heating Pad'),
                      subtitle: const Text('Turn on to warm the cage'),
                      secondary: const Icon(Icons.wb_sunny, color: Colors.orange),
                      value: false, // In a real app, you would listen to the actual state
                      onChanged: (val) {
                        _rtdb.toggleHeater(deviceId, val);
                      },
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }
}