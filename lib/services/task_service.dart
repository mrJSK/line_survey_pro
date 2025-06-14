// lib/services/task_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:line_survey_pro/models/task.dart'; // Import the Task data model

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get tasks assigned to a specific user.
  // This query uses a 'where' clause on 'assignedToUserId' and an 'orderBy' clause on 'dueDate'.
  // It requires a composite index in Firestore.
  // Ensure you've created this index in your Firebase Console:
  // Collection: 'tasks', Fields: 'assignedToUserId' (Ascending), 'dueDate' (Ascending).
  Future<List<Task>> getTasksForUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('assignedToUserId', isEqualTo: userId)
          .orderBy('dueDate', descending: false)
          .get();
      return snapshot.docs.map((doc) => Task.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error fetching tasks for user $userId: $e');
      rethrow; // Re-throw the error to be handled by the UI (e.g., SnackBar)
    }
  }

  // Get all tasks (typically for manager roles).
  // Orders tasks by their creation date in descending order.
  Future<List<Task>> getAllTasks() async {
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => Task.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error fetching all tasks: $e');
      rethrow;
    }
  }

  // Create a new task in Firestore.
  // Takes a Task object and converts it to a map for storage.
  Future<void> createTask(Task task) async {
    try {
      await _firestore.collection('tasks').doc(task.id).set(task.toMap());
      print('Task ${task.id} created successfully.');
    } catch (e) {
      print('Error creating task ${task.id}: $e');
      rethrow;
    }
  }

  // Update the status of an existing task.
  // Also sets the completionDate if the status is changed to 'Completed'.
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'status': newStatus,
        'completionDate':
            newStatus == 'Completed' ? FieldValue.serverTimestamp() : null,
      });
      print('Task $taskId status updated to $newStatus.');
    } catch (e) {
      print('Error updating status for task $taskId: $e');
      rethrow;
    }
  }

  // Add an associated survey record ID to a task's list of survey records.
  // Uses FieldValue.arrayUnion to safely add new IDs without overwriting existing ones.
  Future<void> addSurveyRecordToTask(
      String taskId, String surveyRecordId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'associatedSurveyRecordIds': FieldValue.arrayUnion([surveyRecordId]),
      });
      print('SurveyRecord $surveyRecordId added to task $taskId.');
    } catch (e) {
      print('Error adding survey record $surveyRecordId to task $taskId: $e');
      rethrow;
    }
  }

  // NEW METHOD: Update multiple fields of an existing task.
  // Takes a Task object and updates its corresponding document in Firestore.
  Future<void> updateTask(Task task) async {
    try {
      await _firestore.collection('tasks').doc(task.id).update(task.toMap());
      print('Task ${task.id} updated successfully.');
    } catch (e) {
      print('Error updating task ${task.id}: $e');
      rethrow;
    }
  }

  // NEW METHOD: Delete a task from Firestore by its ID.
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();
      print('Task $taskId deleted successfully.');
    } catch (e) {
      print('Error deleting task $taskId: $e');
      rethrow;
    }
  }

  // NEW METHOD: Get real-time updates for a specific user's tasks.
  // Returns a Stream of lists of Task objects.
  // This stream will emit new lists whenever the underlying data changes in Firestore.
  // This also requires the same composite index as getTasksForUser.
  Stream<List<Task>> streamTasksForUser(String userId) {
    return _firestore
        .collection('tasks')
        .where('assignedToUserId', isEqualTo: userId)
        .orderBy('dueDate', descending: false)
        .snapshots() // Use snapshots() for real-time updates
        .map((snapshot) =>
            snapshot.docs.map((doc) => Task.fromMap(doc.data())).toList())
        .handleError((e) {
      print('Error streaming tasks for user $userId: $e');
      // Depending on your error handling, you might want to rethrow or just log.
      // For streams, logging is often sufficient as the stream can continue.
    });
  }

  // NEW METHOD: Get real-time updates for all tasks (for managers).
  // Returns a Stream of lists of Task objects.
  // This stream will emit new lists whenever the underlying data changes in Firestore.
  Stream<List<Task>> streamAllTasks() {
    return _firestore
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots() // Use snapshots() for real-time updates
        .map((snapshot) =>
            snapshot.docs.map((doc) => Task.fromMap(doc.data())).toList())
        .handleError((e) {
      print('Error streaming all tasks: $e');
    });
  }

  // --- Existing Optional Future Methods ---

  // Get a single task by its ID.
  Future<Task?> getTaskById(String taskId) async {
    try {
      final docSnapshot =
          await _firestore.collection('tasks').doc(taskId).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return Task.fromMap(docSnapshot.data()!);
      }
    } catch (e) {
      print('Error fetching task $taskId: $e');
    }
    return null;
  }
}
