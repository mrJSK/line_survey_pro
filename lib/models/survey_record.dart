// lib/models/survey_record.dart
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SurveyRecord {
  final String id;
  final String lineName;
  final int towerNumber;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String photoPath; // Local path to the image file
  final String status; // e.g., 'saved', 'uploaded'
  final String? taskId;
  final String? userId;

  SurveyRecord({
    String? id,
    required this.lineName,
    required this.towerNumber,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.photoPath,
    this.status = 'saved',
    this.taskId,
    this.userId,
  }) : id = id ?? const Uuid().v4();

  factory SurveyRecord.fromFirestore(Map<String, dynamic> map) {
    return SurveyRecord(
      id: map['id'] as String,
      lineName: map['lineName'] as String,
      towerNumber: map['towerNumber'] as int,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      photoPath: map['photoPath'] as String? ??
          '', // Read photoPath, can be empty if not synced
      status: map['status'] as String,
      taskId: map['taskId'] as String?,
      userId: map['userId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'lineName': lineName,
      'towerNumber': towerNumber,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'taskId': taskId,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory SurveyRecord.fromMap(Map<String, dynamic> map) {
    return SurveyRecord(
      id: map['id'] as String,
      lineName: map['lineName'] as String,
      towerNumber: map['towerNumber'] as int,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      timestamp: DateTime.parse(map['timestamp'] as String),
      photoPath: map['photoPath'] as String,
      status: map['status'] as String,
      taskId: map['taskId'] as String?,
      userId: map['userId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lineName': lineName,
      'towerNumber': towerNumber,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'photoPath': photoPath,
      'status': status,
      'taskId': taskId,
      'userId': userId,
    };
  }

  SurveyRecord copyWith({
    String? id,
    String? lineName,
    int? towerNumber,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    String? photoPath,
    String? status,
    String? taskId,
    String? userId,
  }) {
    return SurveyRecord(
      id: id ?? this.id,
      lineName: lineName ?? this.lineName,
      towerNumber: towerNumber ?? this.towerNumber,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      photoPath: photoPath ?? this.photoPath,
      status: status ?? this.status,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() {
    return 'SurveyRecord(id: $id, line: $lineName, tower: $towerNumber, status: $status, taskId: $taskId, userId: $userId)';
  }
}
