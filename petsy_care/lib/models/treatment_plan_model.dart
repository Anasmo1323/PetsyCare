import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petsy_care/models/daily_log_model.dart';

class TreatmentPlan {
  final String id; // The Firestore document ID
  final Timestamp startDate;
  final DailyLog day1;
  final DailyLog day2;
  final DailyLog day3;
  final DailyLog day4;
  final DailyLog day5;
  final DailyLog day6;
  final DailyLog day7;

  TreatmentPlan({
    required this.id,
    required this.startDate,
    required this.day1,
    required this.day2,
    required this.day3,
    required this.day4,
    required this.day5,
    required this.day6,
    required this.day7,
  });

  // A factory to create a TreatmentPlan from a Firestore document
  factory TreatmentPlan.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return TreatmentPlan(
      id: doc.id,
      startDate: data['startDate'] ?? Timestamp.now(),
      // Use the DailyLog.fromMap factory to create each day's log
      day1: DailyLog.fromMap(data['day1']),
      day2: DailyLog.fromMap(data['day2']),
      day3: DailyLog.fromMap(data['day3']),
      day4: DailyLog.fromMap(data['day4']),
      day5: DailyLog.fromMap(data['day5']),
      day6: DailyLog.fromMap(data['day6']),
      day7: DailyLog.fromMap(data['day7']),
    );
  }
  
  // A helper method to create a brand new, empty plan
  // This is what we'll save to Firestore when you start a new plan
  static Map<String, dynamic> createNewPlanData() {
    final emptyLog = DailyLog().toMap(); // Get an empty log map
    return {
      'startDate': Timestamp.now(),
      'day1': emptyLog,
      'day2': emptyLog,
      'day3': emptyLog,
      'day4': emptyLog,
      'day5': emptyLog,
      'day6': emptyLog,
      'day7': emptyLog,
    };
  }
}