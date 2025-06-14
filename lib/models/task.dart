// lib/models/task.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String assignedToUserId; // ID of the worker assigned
  final String? assignedToUserName; // Optional: for display purposes
  final String assignedByUserId; // ID of the manager who assigned it
  final String? assignedByUserName; // Optional: for display purposes
  final String lineName; // The transmission line to patrol
  final String targetTowerRange; // e.g., "1-5", "10", "All"
  final DateTime dueDate; // The due date for the task
  String
      status; // e.g., 'Pending', 'InProgress', 'SubmittedForReview', 'Completed', 'Rejected'
  final DateTime createdAt;
  DateTime? completionDate; // When the task was marked complete by the worker
  String? reviewNotes; // Notes from manager if rejected/approved
  List<String>
      associatedSurveyRecordIds; // IDs of SurveyRecords created for this task

  Task({
    required this.id,
    required this.assignedToUserId,
    this.assignedToUserName,
    required this.assignedByUserId,
    this.assignedByUserName,
    required this.lineName,
    required this.targetTowerRange,
    required this.dueDate,
    this.status = 'Pending', // Default status
    required this.createdAt,
    this.completionDate,
    this.reviewNotes,
    this.associatedSurveyRecordIds = const [],
  });

  // Factory constructor to create a Task from a Firestore document snapshot or a Map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      assignedToUserId: map['assignedToUserId'] as String,
      assignedToUserName: map['assignedToUserName'] as String?,
      assignedByUserId: map['assignedByUserId'] as String,
      assignedByUserName: map['assignedByUserName'] as String?,
      lineName: map['lineName'] as String,
      targetTowerRange: map['targetTowerRange'] as String,
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      status: map['status'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      completionDate: (map['completionDate'] as Timestamp?)?.toDate(),
      reviewNotes: map['reviewNotes'] as String?,
      associatedSurveyRecordIds:
          List<String>.from(map['associatedSurveyRecordIds'] ?? []),
    );
  }

  // Method to convert a Task object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assignedToUserId': assignedToUserId,
      'assignedToUserName': assignedToUserName,
      'assignedByUserId': assignedByUserId,
      'assignedByUserName': assignedByUserName,
      'lineName': lineName,
      'targetTowerRange': targetTowerRange,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'completionDate':
          completionDate != null ? Timestamp.fromDate(completionDate!) : null,
      'reviewNotes': reviewNotes,
      'associatedSurveyRecordIds': associatedSurveyRecordIds,
    };
  }

  // Optional: For debugging or logging
  @override
  String toString() {
    return 'Task(id: $id, lineName: $lineName, targetTowerRange: $targetTowerRange, status: $status)';
  }
}
