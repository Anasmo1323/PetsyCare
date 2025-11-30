import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petsy_care/models/patient_model.dart'; // Corrected import
import 'package:petsy_care/services/auth_service.dart'; // Corrected import
import 'package:petsy_care/models/treatment_plan_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();

  // Helper to get the current clinic ID
  // We'll build this logic out later. For now, it's a placeholder.
  String? get _clinicId {
    // In a real app, you'd get the user's clinic ID
    // For now, we can use the user's UID as a stand-in
    return _auth.currentUser?.uid;
  }

  // --- Patient Methods ---

  // Add a new patient
// Add a new patient
  Future<void> addPatient(Map<String, dynamic> patientData) async {

    
    // --- THIS IS THE NEW LOGIC ---
    if (_clinicId == null) {
      throw Exception('User is not logged in. Cannot add patient.');
    }
    // --- END OF NEW LOGIC ---

    try {
      await _db
          .collection('clinics')
          .doc(_clinicId)
          .collection('patients')
          .add(patientData);
    } catch (e) {
      print(e);
      // Re-throw the error so the UI can catch it
      rethrow; 
    }
  }
Future<void> updatePatient(String patientId, Map<String, dynamic> patientData) async {
  if (_clinicId == null) return; // Not logged in

  try {
    await _db
        .collection('clinics')
        .doc(_clinicId)
        .collection('patients')
        .doc(patientId) // Get the specific patient
        .update(patientData); // Use 'update' instead of 'add'
  } catch (e) {
    print(e);
    // Handle the error
  }
}
// --- User Management Methods ---

  // 1. Check if a user document exists
  Future<bool> checkUserExists(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // 2. Create a new user document
  Future<void> createUser(String uid, String email, String name) async {
    try {
      await _db.collection('users').doc(uid).set({
        'email': email,
        'name': name,
        'role': 'vet', // Default role
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print(e);
      throw e;
    }
  }
  // Get a stream of all patients for the clinic
Stream<List<Patient>> getPatients({
    DateTime? selectedDay,
    DateTime? selectedMonth,
  }) {
    if (_clinicId == null) {
      return Stream.value([]);
    }

    // Start building the query
    Query query = _db
        .collection('clinics')
        .doc(_clinicId)
        .collection('patients');

    // --- NEW LOGIC ---
    if (selectedDay != null) {
      // 1. FILTER BY DAY
      final startOfDay = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
      );
      final endOfDay = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day + 1,
      );
      query = query
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
          .where('createdAt', isLessThan: endOfDay);
          
    } else if (selectedMonth != null) {
      // 2. FILTER BY MONTH
      final startOfMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month,
        1,
      );
      final endOfMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + 1,
        1,
      );
      query = query
          .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
          .where('createdAt', isLessThan: endOfMonth)
          .orderBy('createdAt', descending: true); // Order by date within the month
          
    } else {
      // 3. NO FILTER (Show all, newest first)
      query = query.orderBy('createdAt', descending: true);
    }
    // --- END OF NEW LOGIC ---

    // Return the stream from our final query
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              Patient.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  Stream<Patient> getPatientStream(String patientId) {
  if (_clinicId == null) {
    throw Exception('User not logged in');
  }

  return _db
      .collection('clinics')
      .doc(_clinicId)
      .collection('patients')
      .doc(patientId)
      .snapshots() // This is the magic!
      .map((snapshot) {
    // When the data changes, this map function runs
    return Patient.fromFirestore(
        snapshot.data() as Map<String, dynamic>, snapshot.id);
  });
}
  // --- Medicine Methods ---
  // (We will add these later)
// --- Visit Methods ---

// Add a new visit for a specific patient
// --- Treatment Plan Methods ---

// Creates a new, blank 7-day plan for a patient
Future<void> createNewTreatmentPlan(String patientId) async {
  if (_clinicId == null) return;

  // Get the data for a new, empty plan from our model
  final newPlanData = TreatmentPlan.createNewPlanData();

  try {
    await _db
        .collection('clinics')
        .doc(_clinicId)
        .collection('patients')
        .doc(patientId)
        .collection('plans') // We store plans in a 'plans' sub-collection
        .add(newPlanData);
  } catch (e) {
    print(e);
    // Handle error
  }
}

// Gets a real-time stream of all plans for a patient
Stream<List<TreatmentPlan>> getTreatmentPlans(String patientId) {
  if (_clinicId == null) {
    return Stream.value([]);
  }

  return _db
      .collection('clinics')
      .doc(_clinicId)
      .collection('patients')
      .doc(patientId)
      .collection('plans')
      .orderBy('startDate', descending: true) // Show newest plans first
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => TreatmentPlan.fromFirestore(doc))
        .toList();
  });
}

// This is the new "edit" function.
// It updates a *single day* inside a *specific plan*.
Future<void> updateDailyLog({
  required String patientId,
  required String planId,
  required String dayKey, // This will be "day1", "day2", etc.
  required Map<String, dynamic> logData, // This is the DailyLog.toMap()
}) async {
  if (_clinicId == null) return;

  try {
    await _db
        .collection('clinics')
        .doc(_clinicId)
        .collection('patients')
        .doc(patientId)
        .collection('plans')
        .doc(planId)
        .update({
          dayKey: logData // This updates just one field, e.g., "day1"
        });
  } catch (e) {
    print(e);
    // Handle error
  }
}

}