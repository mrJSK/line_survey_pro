// lib/services/survey_firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:line_survey_pro/models/survey_record.dart'; // Import the SurveyRecord model

class SurveyFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference for survey records in Firestore.
  // Uses .withConverter to automatically convert between SurveyRecord objects and Firestore documents.
  CollectionReference<SurveyRecord> get _surveyRecordsRef {
    return _firestore.collection('survey_records').withConverter<SurveyRecord>(
          fromFirestore: (snapshot, _) => SurveyRecord.fromFirestore(snapshot
              .data()!), // Converts Firestore data to SurveyRecord object
          toFirestore: (record, _) => record
              .toFirestore(), // Converts SurveyRecord object to Firestore data
        );
  }

  // Uploads a single SurveyRecord's details (metadata) to Firestore.
  // This method guarantees the status of the record in Firestore is 'uploaded' after a successful write.
  // It no longer handles image uploads to Firebase Storage.
  // Returns the ID of the saved record (which is the SurveyRecord's ID), or null on failure.
  Future<String?> uploadSurveyRecordDetails(SurveyRecord record) async {
    try {
      // CRITICAL FIX: Create a new SurveyRecord object with the status explicitly set to 'uploaded'.
      // This ensures that even if the local record had 'saved' status, the Firestore record will be 'uploaded'.
      final recordToUploadToFirestore = record.copyWith(status: 'uploaded');

      // Set (create or overwrite) this record in Firestore. The document ID will be the record's ID.
      await _surveyRecordsRef
          .doc(recordToUploadToFirestore.id)
          .set(recordToUploadToFirestore);
      print(
          'Survey Record ${recordToUploadToFirestore.id} details uploaded to Firestore with status: uploaded.');
      return recordToUploadToFirestore
          .id; // Return the ID upon successful upload
    } catch (e) {
      print('Error uploading survey record details ${record.id}: $e');
      return null; // Return null on failure
    }
  }

  // Fetches survey records for a specific user in real-time.
  // Orders records by timestamp in descending order (most recent first).
  Stream<List<SurveyRecord>> streamSurveyRecordsForUser(String userId) {
    // This query might require a composite index in Firestore:
    // Collection: 'survey_records', Fields: 'userId' (Ascending), 'timestamp' (Descending).
    return _firestore
        .collection('survey_records')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots() // Provides real-time updates
        .map((snapshot) => snapshot.docs
            .map((doc) => SurveyRecord.fromFirestore(doc.data()))
            .toList())
        .handleError((e) {
      print('Error streaming survey records for user $userId: $e');
      // Error handling for the stream. The stream itself might not terminate on error.
    });
  }

  // Fetches all survey records in real-time (typically for manager roles).
  // Orders records by timestamp in descending order (most recent first).
  Stream<List<SurveyRecord>> streamAllSurveyRecords() {
    // This query might require a single-field index in Firestore:
    // Collection: 'survey_records', Field: 'timestamp' (Descending).
    return _firestore
        .collection('survey_records')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SurveyRecord.fromFirestore(doc.data()))
            .toList())
        .handleError((e) {
      print('Error streaming all survey records: $e');
    });
  }

  // Gets survey records associated with a list of specific task IDs.
  // Used for calculating worker dashboard progress based on assigned tasks.
  // Handles Firestore's 'whereIn' query limit (max 10 items).
  Future<List<SurveyRecord>> getSurveyRecordsForTaskIds(
      List<String> taskIds) async {
    if (taskIds.isEmpty) return []; // Return empty list if no task IDs provided
    try {
      List<SurveyRecord> allRecords = [];
      const int maxInQuerySize =
          10; // Firestore 'whereIn' clause has a limit of 10 items

      // Iterate through task IDs in chunks to respect the query limit
      for (int i = 0; i < taskIds.length; i += maxInQuerySize) {
        final currentChunk =
            taskIds.sublist(i, (i + maxInQuerySize).clamp(0, taskIds.length));
        final snapshot = await _firestore
            .collection('survey_records')
            .where('taskId', whereIn: currentChunk)
            .get(); // Perform a one-time get operation for the chunk
        allRecords.addAll(snapshot.docs
            .map((doc) => SurveyRecord.fromFirestore(doc.data()))
            .toList());
      }
      return allRecords;
    } catch (e) {
      print('Error getting survey records for task IDs: $e');
      return []; // Return empty list on error
    }
  }

  // Deletes a single survey record's details from Firestore by its ID.
  Future<void> deleteSurveyRecordDetails(String recordId) async {
    try {
      await _surveyRecordsRef.doc(recordId).delete();
      print('Deleted survey record details $recordId from Firestore.');
    } catch (e) {
      print('Error deleting survey record details $recordId: $e');
      rethrow; // Re-throw to be handled by the calling UI
    }
  }

  // Deletes multiple survey records' details from Firestore that are associated with a specific task ID.
  Future<void> deleteSurveyRecordsByTaskId(String taskId) async {
    try {
      final querySnapshot = await _firestore
          .collection('survey_records')
          .where('taskId', isEqualTo: taskId)
          .get();
      final batch = _firestore.batch(); // Use a batch write for efficiency
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference); // Add each document deletion to the batch
      }
      await batch.commit(); // Commit the batch operation
      print('Deleted survey record details for task $taskId from Firestore.');
    } catch (e) {
      print('Error deleting survey record details for task $taskId: $e');
      rethrow;
    }
  }

  // Updates the status of a survey record in Firestore.
  // This method is used when the status changes (e.g., from 'saved' to 'uploaded' or other custom statuses).
  Future<void> updateSurveyRecordStatus(
      String recordId, String newStatus) async {
    try {
      await _surveyRecordsRef.doc(recordId).update({'status': newStatus});
      print(
          'Survey record $recordId status updated to $newStatus in Firestore.');
    } catch (e) {
      print('Error updating survey record $recordId status: $e');
      rethrow;
    }
  }
}
