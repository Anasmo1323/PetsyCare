import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TempChart extends StatefulWidget {
  final String deviceId;

  const TempChart({super.key, required this.deviceId});

  @override
  State<TempChart> createState() => _TempChartState();
}

class _TempChartState extends State<TempChart> {
  List<FlSpot> _spots = [];

  // --- IMPORTANT: Use your specific Europe URL here ---
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

    // Listen to history
    final ref = _database.ref('devices/${widget.deviceId}/history').limitToLast(20);

    ref.onValue.listen((event) {
      final rawData = event.snapshot.value;
      if (rawData == null) return;

      final List<FlSpot> newSpots = [];
      int index = 0;

      // CASE 1: Data is a List (like your current JSON export: [null, {temp:37.5}, ...])
      if (rawData is List) {
        for (var entry in rawData) {
          if (entry == null) continue; // Skip null entries
          // Handle case where entry is just a number or a map
          dynamic tempVal;
          if (entry is Map) {
            tempVal = entry['temp'];
          } else {
            tempVal = entry; 
          }
          
          final double val = double.tryParse(tempVal.toString()) ?? 0.0;
          newSpots.add(FlSpot(index.toDouble(), val));
          index++;
        }
      } 
      // CASE 2: Data is a Map (Keys are random IDs: "-Nxy89...")
      else if (rawData is Map) {
        // Sort by keys to keep time order
        final sortedKeys = rawData.keys.toList()..sort();
        for (var key in sortedKeys) {
          final entry = rawData[key];
          final double val = double.tryParse(entry['temp'].toString()) ?? 0.0;
          newSpots.add(FlSpot(index.toDouble(), val));
          index++;
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
    // If no history exists yet
    if (_spots.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            "No history data available.\nAdd data to '/history' in Firebase.",
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
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide Time axis for simplicity
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
              minY: 30, // Optimized for Vet/Body Temp range
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