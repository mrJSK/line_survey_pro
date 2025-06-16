// lib/models/transmission_line.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TransmissionLine {
  final String id; // Document ID from Firestore or local ID
  final String
      name; // This will now store the consolidated name (e.g., "400kV Shamli Aligarh Line")
  // Removed: final int totalTowers; // This is now a computed field
  // NEW: Added fields
  final String? voltageLevel; // e.g., "765kV", "400kV"
  final int? towerRangeStart; // e.g., 175
  final int? towerRangeEnd; // e.g., 384

  TransmissionLine({
    required this.id,
    required this.name,
    this.voltageLevel,
    this.towerRangeStart,
    this.towerRangeEnd,
  });

  // NEW: Computed property for total towers based on range
  int get computedTotalTowers {
    if (towerRangeStart != null && towerRangeEnd != null) {
      return towerRangeEnd! - towerRangeStart! + 1;
    }
    return 0; // Return 0 if range is not fully defined
  }

  // Factory constructor to create a TransmissionLine from a Firestore DocumentSnapshot
  factory TransmissionLine.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      [SnapshotOptions? options]) {
    final data = snapshot.data();
    return TransmissionLine(
      id: snapshot.id, // The document ID from Firestore
      name: data?['name'] as String? ?? 'Unknown Line',
      // Removed: totalTowers is no longer retrieved
      voltageLevel: data?['voltageLevel'] as String?,
      towerRangeStart: data?['towerRangeStart'] as int?,
      towerRangeEnd: data?['towerRangeEnd'] as int?,
    );
  }

  // Method to convert a TransmissionLine object into a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      // Removed: 'totalTowers': totalTowers,
      'voltageLevel': voltageLevel,
      'towerRangeStart': towerRangeStart,
      'towerRangeEnd': towerRangeEnd,
      'createdAt': FieldValue.serverTimestamp(), // Optional: add a timestamp
    };
  }

  // Method to convert a TransmissionLine object into a Map for SQLite (local database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      // Removed: 'totalTowers': totalTowers,
      'voltageLevel': voltageLevel,
      'towerRangeStart': towerRangeStart,
      'towerRangeEnd': towerRangeEnd,
    };
  }

  // Factory constructor to create a TransmissionLine from a Map (for SQLite retrieval)
  factory TransmissionLine.fromMap(Map<String, dynamic> map) {
    return TransmissionLine(
      id: map['id'] as String,
      name: map['name'] as String,
      // Removed: totalTowers is no longer retrieved
      voltageLevel: map['voltageLevel'] as String?,
      towerRangeStart: map['towerRangeStart'] as int?,
      towerRangeEnd: map['towerRangeEnd'] as int?,
    );
  }

  // copyWith method for immutability
  TransmissionLine copyWith({
    String? id,
    String? name,
    // Removed: int? totalTowers,
    String? voltageLevel,
    int? towerRangeStart,
    int? towerRangeEnd,
  }) {
    return TransmissionLine(
      id: id ?? this.id,
      name: name ?? this.name,
      // Removed: totalTowers: totalTowers ?? this.totalTowers,
      voltageLevel: voltageLevel ?? this.voltageLevel,
      towerRangeStart: towerRangeStart ?? this.towerRangeStart,
      towerRangeEnd: towerRangeEnd ?? this.towerRangeEnd,
    );
  }
}
