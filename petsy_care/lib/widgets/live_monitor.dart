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

            // Stream 3: Heater Status (Actual State)
            return StreamBuilder<bool>(
              stream: _rtdb.getHeaterStream(deviceId),
              builder: (context, heaterSnapshot) {
                
                // Stream 4: Configuration (Auto Mode & Target Temp)
                return StreamBuilder<Map<String, dynamic>>(
                  stream: _rtdb.getConfigStream(deviceId),
                  builder: (context, configSnapshot) {

                    if (sensorSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final data = sensorSnapshot.data ?? {'temp': '--', 'humidity': '--'};
                    final temp = data['temp']!;
                    final hum = data['humidity']!;
                    
                    final isDistress = distressSnapshot.data ?? false;
                    final isHeaterOn = heaterSnapshot.data ?? false; 
                    
                    final config = configSnapshot.data ?? {'auto_mode': false, 'target_temp': 37.0};
                    final bool isAuto = config['auto_mode'];
                    final double targetTemp = config['target_temp'];

                    // --- NEW LOGIC: Check if Manual Mode is Active ---
                    // If Heater is ON but Auto is OFF, then Manual Mode is driving it.
                    bool isManualActive = isHeaterOn && !isAuto;

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
                                    const SizedBox(height: 10),
                                    Chip(
                                      label: Text(isHeaterOn ? "Heater Active" : "Heater Off"),
                                      backgroundColor: isHeaterOn ? Colors.orange.shade100 : Colors.grey.shade200,
                                      avatar: Icon(Icons.wb_sunny, size: 18, color: isHeaterOn ? Colors.orange : Colors.grey),
                                    )
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

                            // 1. AUTO MODE SWITCH
                            // Locked if Manual Heater is currently ON
                            SwitchListTile(
                              title: const Text('Automated Thermostat'),
                              subtitle: isManualActive
                                  ? const Text('Disabled (Turn off Manual Heater first)', style: TextStyle(color: Colors.grey))
                                  : const Text('Maintain minimum temperature automatically'),
                              value: isAuto,
                              activeColor: Colors.blue,
                              // LOCK LOGIC:
                              onChanged: isManualActive
                                  ? null // Disable click
                                  : (val) => _rtdb.toggleAutoMode(deviceId, val),
                            ),

                            // 2. TARGET TEMP SLIDER (Only visible if Auto is ON)
                            if (isAuto) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 10),
                                    Text("Target Minimum: ${targetTemp.toStringAsFixed(1)} °C", 
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                    Slider(
                                      value: targetTemp,
                                      min: 30.0,
                                      max: 42.0,
                                      divisions: 24, 
                                      label: targetTemp.toString(),
                                      onChanged: (val) => _rtdb.setTargetTemp(deviceId, val),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const Divider(),

                            // 3. MANUAL HEATER SWITCH
                            // Locked if Auto is ON
                            SwitchListTile(
                              title: const Text('Manual Heating Pad'),
                              subtitle: isAuto 
                                ? const Text('Disabled (Thermostat is Active)', style: TextStyle(color: Colors.grey)) 
                                : const Text('Turn on manually to warm the cage'),
                              
                              secondary: Icon(Icons.wb_sunny, color: isHeaterOn ? Colors.orange : Colors.grey),
                              
                              value: isHeaterOn, 
                              
                              // LOCK LOGIC:
                              onChanged: isAuto 
                                ? null // Disable click
                                : (val) {
                                    _rtdb.toggleHeater(deviceId, val);
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
          }
        );
      },
    );
  }
}