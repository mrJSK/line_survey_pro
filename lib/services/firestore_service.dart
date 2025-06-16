// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:line_survey_pro/models/transmission_line.dart';

class FirestoreService {
  // Get the Firestore instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // IMPORTANT: This path is set for public data sharing in Canvas Firebase setups.
  // Replace 'your_app_id' with __app_id variable if available in Canvas runtime
  // or a default value for local testing.
  // For production, you might structure this differently based on your app's needs.
  static String get _basePath {
    // Original path: 'artifacts/$appId/public/data'
    // Based on your screenshot, the 'transmissionLines' collection is at the root.
    // So, we'll return an empty string or adjust as per where 'transmissionLines' actually exists.
    // If you intend to use the 'artifacts' structure, you must manually move
    // your 'transmissionLines' collection into 'artifacts/__app_id/public/data'
    // within the Firebase console. In that case, this original path would be correct:
    // const String appId = String.fromEnvironment('APP_ID', defaultValue: 'default-line-survey-app');
    // return 'artifacts/$appId/public/data';

    // For now, let's assume 'transmissionLines' is directly at the root.
    return ''; // Empty string means the collection is at the database root
  }

  // Collection reference for transmission lines
  CollectionReference<TransmissionLine> get _transmissionLinesRef {
    // If _basePath is empty, it means collection('transmissionLines') directly
    // If _basePath is not empty, it means collection('$_basePath/transmissionLines')
    return _db
        .collection(_basePath.isEmpty
            ? 'transmissionLines'
            : '$_basePath/transmissionLines')
        .withConverter<TransmissionLine>(
          fromFirestore: TransmissionLine.fromFirestore,
          toFirestore: (line, _) => line.toFirestore(),
        );
  }

  // Fetches all transmission lines from Firestore.
  // Returns a Stream for real-time updates.
  Stream<List<TransmissionLine>> getTransmissionLinesStream() {
    return _transmissionLinesRef
        .snapshots() // Get real-time updates as snapshots
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data())
            .toList()); // Convert snapshots to list of TransmissionLine
  }

  // Fetches all transmission lines once (not real-time).
  Future<List<TransmissionLine>> getTransmissionLinesOnce() async {
    try {
      final querySnapshot = await _transmissionLinesRef.get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching transmission lines from Firestore: $e');
      throw Exception('Failed to fetch transmission lines: $e');
    }
  }

  // Adds a new transmission line to Firestore.
  // Throws an exception if the operation fails.
  // Updated to include new fields from TransmissionLine model.
  Future<void> addTransmissionLine(TransmissionLine line) async {
    try {
      // When adding, Firestore will use the toFirestore() method defined in the TransmissionLine model.
      // So, no explicit modification needed here beyond calling .add(line).
      await _transmissionLinesRef.add(line);
    } catch (e) {
      print('Error adding transmission line: $e');
      throw Exception('Failed to add transmission line: $e');
    }
  }

  // NEW: Update a transmission line in Firestore.
  Future<void> updateTransmissionLine(TransmissionLine line) async {
    try {
      await _transmissionLinesRef
          .doc(line.id)
          .set(line, SetOptions(merge: true));
    } catch (e) {
      print('Error updating transmission line: $e');
      throw Exception('Failed to update transmission line: $e');
    }
  }

  // NEW: Delete a transmission line from Firestore.
  Future<void> deleteTransmissionLine(String lineId) async {
    try {
      await _transmissionLinesRef.doc(lineId).delete();
    } catch (e) {
      print('Error deleting transmission line: $e');
      throw Exception('Failed to delete transmission line: $e');
    }
  }
}
