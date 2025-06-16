// lib/models/task.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String assignedToUserId;
  final String? assignedToUserName;
  final String assignedByUserId;
  final String? assignedByUserName;
  final String lineName;
  final String targetTowerRange;
  final int numberOfTowersToPatrol;
  final DateTime dueDate;
  String
      status; // e.g., 'Pending', 'InProgress', 'SubmittedForReview', 'Completed', 'Rejected' (This is the *assigned* status)
  final DateTime createdAt;
  DateTime? completionDate;
  String? reviewNotes;
  List<String> associatedSurveyRecordIds;

  // NEW: Fields to hold counts of locally saved and uploaded surveys for this task
  // These are not stored in Firestore, but calculated and set by the app logic.
  int _localCompletedCount;
  int _uploadedCompletedCount;

  Task({
    required this.id,
    required this.assignedToUserId,
    this.assignedToUserName,
    required this.assignedByUserId,
    this.assignedByUserName,
    required this.lineName,
    required this.targetTowerRange,
    required this.numberOfTowersToPatrol,
    required this.dueDate,
    this.status = 'Pending',
    required this.createdAt,
    this.completionDate,
    this.reviewNotes,
    this.associatedSurveyRecordIds = const [],
    int localCompletedCount = 0, // Initialize with default
    int uploadedCompletedCount = 0, // Initialize with default
  })  : _localCompletedCount = localCompletedCount,
        _uploadedCompletedCount = uploadedCompletedCount;

  // Factory constructor from Firestore Map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      assignedToUserId: map['assignedToUserId'] as String,
      assignedToUserName: map['assignedToUserName'] as String?,
      assignedByUserId: map['assignedByUserId'] as String,
      assignedByUserName: map['assignedByUserName'] as String?,
      lineName: map['lineName'] as String,
      targetTowerRange: map['targetTowerRange'] as String,
      numberOfTowersToPatrol: (map['numberOfTowersToPatrol'] as int?) ?? 0,
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      status: map['status'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      completionDate: (map['completionDate'] as Timestamp?)?.toDate(),
      reviewNotes: map['reviewNotes'] as String?,
      associatedSurveyRecordIds:
          List<String>.from(map['associatedSurveyRecordIds'] ?? []),
    );
  }

  // Method to convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assignedToUserId': assignedToUserId,
      'assignedToUserName': assignedToUserName,
      'assignedByUserId': assignedByUserId,
      'assignedByUserName': assignedByUserName,
      'lineName': lineName,
      'targetTowerRange': targetTowerRange,
      'numberOfTowersToPatrol': numberOfTowersToPatrol,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'completionDate':
          completionDate != null ? Timestamp.fromDate(completionDate!) : null,
      'reviewNotes': reviewNotes,
      'associatedSurveyRecordIds': associatedSurveyRecordIds,
    };
  }

  // NEW: Getter for local completed count
  int get localCompletedCount => _localCompletedCount;
  // NEW: Setter for local completed count
  set localCompletedCount(int count) => _localCompletedCount = count;

  // NEW: Getter for uploaded completed count
  int get uploadedCompletedCount => _uploadedCompletedCount;
  // NEW: Setter for uploaded completed count
  set uploadedCompletedCount(int count) => _uploadedCompletedCount = count;

  // NEW: Derived status based on progress
  String get derivedStatus {
    if (uploadedCompletedCount >= numberOfTowersToPatrol &&
        numberOfTowersToPatrol > 0) {
      return 'Patrolled'; // Changed from 'Completed'
    } else if (uploadedCompletedCount > 0) {
      return 'In Progress (Uploaded)';
    } else if (localCompletedCount > 0) {
      return 'In Progress (Local)';
    } else {
      return 'Pending';
    }
  }

  // NEW: copyWith method for immutability and setting calculated fields
  Task copyWith({
    String? id,
    String? assignedToUserId,
    String? assignedToUserName,
    String? assignedByUserId,
    String? assignedByUserName,
    String? lineName,
    String? targetTowerRange,
    int? numberOfTowersToPatrol,
    DateTime? dueDate,
    String? status,
    DateTime? createdAt,
    DateTime? completionDate,
    String? reviewNotes,
    List<String>? associatedSurveyRecordIds,
    int? localCompletedCount,
    int? uploadedCompletedCount,
  }) {
    return Task(
      id: id ?? this.id,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      assignedToUserName: assignedToUserName ?? this.assignedToUserName,
      assignedByUserId: assignedByUserId ?? this.assignedByUserId,
      assignedByUserName: assignedByUserName ?? this.assignedByUserName,
      lineName: lineName ?? this.lineName,
      targetTowerRange: targetTowerRange ?? this.targetTowerRange,
      numberOfTowersToPatrol:
          numberOfTowersToPatrol ?? this.numberOfTowersToPatrol,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status, // Keep original status from Firestore
      createdAt: createdAt ?? this.createdAt,
      completionDate: completionDate ?? this.completionDate,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      associatedSurveyRecordIds:
          associatedSurveyRecordIds ?? this.associatedSurveyRecordIds,
      localCompletedCount: localCompletedCount ?? this.localCompletedCount,
      uploadedCompletedCount:
          uploadedCompletedCount ?? this.uploadedCompletedCount,
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, lineName: $lineName, targetTowerRange: $targetTowerRange, count: $numberOfTowersToPatrol, derivedStatus: $derivedStatus)';
  }
}
