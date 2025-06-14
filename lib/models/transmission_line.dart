// lib/models/transmission_line.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TransmissionLine {
  final String id; // Document ID from Firestore or local ID
  final String name;
  final int totalTowers;

  TransmissionLine({
    required this.id, // ID is now crucial for both Firestore and local
    required this.name,
    required this.totalTowers,
  });

  // Factory constructor to create a TransmissionLine from a Firestore DocumentSnapshot
  factory TransmissionLine.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      [SnapshotOptions? options]) {
    final data = snapshot.data();
    return TransmissionLine(
      id: snapshot.id, // The document ID from Firestore
      name: data?['name'] as String? ?? 'Unknown Line',
      totalTowers: data?['totalTowers'] as int? ?? 0,
    );
  }

  // Method to convert a TransmissionLine object into a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'totalTowers': totalTowers,
      'createdAt': FieldValue.serverTimestamp(), // Optional: add a timestamp
    };
  }

  // NEW: Method to convert a TransmissionLine object into a Map for SQLite (local database)
  Map<String, dynamic> toMap() {
    return {
      'id': id, // Include ID for local storage if it's the primary key
      'name': name,
      'totalTowers': totalTowers,
    };
  }

  // NEW: Factory constructor to create a TransmissionLine from a Map (for SQLite retrieval)
  factory TransmissionLine.fromMap(Map<String, dynamic> map) {
    return TransmissionLine(
      id: map['id'] as String,
      name: map['name'] as String,
      totalTowers: map['totalTowers'] as int,
    );
  }
}
