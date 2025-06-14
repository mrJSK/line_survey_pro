// lib/models/survey_record.dart

// No need to import anything specific here for basic model.
// Ensure your other imports are correct in files that use this.

class SurveyRecord {
  final String id;
  final String lineName;
  final int towerNumber; // Ensure this is an int
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String photoPath;
  final String status; // e.g., 'saved', 'pending_upload'

  SurveyRecord({
    required this.id,
    required this.lineName,
    required this.towerNumber,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.photoPath,
    required this.status,
  });

  // Factory constructor to create a SurveyRecord from a Map (for SQLite retrieval)
  factory SurveyRecord.fromMap(Map<String, dynamic> map) {
    return SurveyRecord(
      id: map['id'] as String,
      lineName: map['lineName'] as String,
      // Fix: Ensure towerNumber is parsed as int, in case it comes as String from DB
      towerNumber: map['towerNumber'] is int
          ? map['towerNumber'] as int
          : int.parse(map['towerNumber'].toString()), // Robust parsing
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      // FIX: Robustly parse timestamp. Try DateTime.parse, if fails, try int parsing (epoch).
      timestamp: map['timestamp'] is String
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      photoPath: map['photoPath'] as String,
      status: map['status'] as String,
    );
  }

  // Method to convert a SurveyRecord object into a Map for SQLite (local database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lineName': lineName,
      'towerNumber': towerNumber,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp':
          timestamp.toIso8601String(), // Store DateTime as ISO 8601 string
      'photoPath': photoPath,
      'status': status,
    };
  }
}
