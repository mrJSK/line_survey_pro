// lib/services/task_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:line_survey_pro/models/task.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get tasks assigned to a specific user
  Future<List<Task>> getTasksForUser(String userId) async {
    final snapshot = await _firestore
        .collection('tasks')
        .where('assignedToUserId', isEqualTo: userId)
        .orderBy('dueDate', descending: false)
        .get();
    return snapshot.docs.map((doc) => Task.fromMap(doc.data())).toList();
  }

  // Get all tasks (for managers)
  Future<List<Task>> getAllTasks() async {
    final snapshot = await _firestore
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Task.fromMap(doc.data())).toList();
  }

  // Create a new task
  Future<void> createTask(Task task) async {
    await _firestore.collection('tasks').doc(task.id).set(task.toMap());
  }

  // Update task status
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': newStatus,
      'completionDate':
          newStatus == 'Completed' ? FieldValue.serverTimestamp() : null,
    });
  }

  // Add associated survey record ID to a task
  Future<void> addSurveyRecordToTask(
      String taskId, String surveyRecordId) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'associatedSurveyRecordIds': FieldValue.arrayUnion([surveyRecordId]),
    });
  }

  // You can add more methods here for:
  // - Getting a single task by ID
  // - Updating other task fields
  // - Deleting tasks
  // - Stream of tasks for real-time updates (using snapshots())
}
