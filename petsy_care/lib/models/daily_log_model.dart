class DailyLog {
  final String notes;
  final String temperature;
  final String feeding;
  final String stool;
  final String urine;
  final String medication;

  DailyLog({
    this.notes = '',
    this.temperature = '',
    this.feeding = '',
    this.stool = '',
    this.urine = '',
    this.medication = '',
  });

  // A method to convert this object to a Map (for saving to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'notes': notes,
      'temperature': temperature,
      'feeding': feeding,
      'stool': stool,
      'urine': urine,
      'medication': medication,
    };
  }

  // A factory to create a DailyLog from a Map (when loading from Firestore)
  factory DailyLog.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return DailyLog(); // Return an empty log if data is null
    }
    return DailyLog(
      notes: data['notes'] ?? '',
      temperature: data['temperature'] ?? '',
      feeding: data['feeding'] ?? '',
      stool: data['stool'] ?? '',
      urine: data['urine'] ?? '',
      medication: data['medication'] ?? '',
    );
  }
}