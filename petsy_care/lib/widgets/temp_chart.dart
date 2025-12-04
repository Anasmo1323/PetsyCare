import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:petsy_care/services/security_service.dart'; // Import Security

class TempChart extends StatefulWidget {
  final String deviceId;

  const TempChart({super.key, required this.deviceId});

  @override
  State<TempChart> createState() => _TempChartState();
} 

class _TempChartState extends State<TempChart> {
  List<FlSpot> _spots = [];
  
  // 1. Add the Security Service
  final SecurityService _security = SecurityService();

  final _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://petsycare-10533-default-rtdb.europe-west1.firebasedatabase.app',
  );

  @override
  void initState() {
    super.initState();
    _activateListeners();
  }

  void _activateListeners() {
    if (widget.deviceId.isEmpty) return;

    final ref = _database.ref('devices/${widget.deviceId}/history').limitToLast(20);

    ref.onValue.listen((event) {
      final rawData = event.snapshot.value;
      if (rawData == null) return;

      final List<FlSpot> newSpots = [];
      int index = 0;

      // Helper function to process a single entry
      void processEntry(dynamic entry) {
        if (entry == null) return;
        
        dynamic tempVal;
        if (entry is Map) {
          tempVal = entry['temp'];
        } else {
          tempVal = entry; 
        }
        
        // --- NEW: Decrypt the history point ---
        String decryptedString = _security.decrypt(tempVal.toString());
        
        // Parse the decrypted string to a double
        final double val = double.tryParse(decryptedString) ?? 0.0;
        
        newSpots.add(FlSpot(index.toDouble(), val));
        index++;
      }

      // Handle List vs Map structure
      if (rawData is List) {
        for (var entry in rawData) {
          processEntry(entry);
        }
      } else if (rawData is Map) {
        final sortedKeys = rawData.keys.toList()..sort();
        for (var key in sortedKeys) {
          processEntry(rawData[key]);
        }
      }

      if (mounted) {
        setState(() {
          _spots = newSpots;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_spots.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            "Waiting for history data...",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Temperature Trend (Last 20 Readings)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: const FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
              minY: 30, 
              maxY: 45, 
              lineBarsData: [
                LineChartBarData(
                  spots: _spots,
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}