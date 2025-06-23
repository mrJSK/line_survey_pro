// lib/models/tower_detail.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TowerDetail {
  final String id; // Composite ID: "${lineId}_${towerNumber}"
  final String lineId; // The ID of the associated TransmissionLine
  final String lineName; // The name of the associated TransmissionLine
  final int towerNumber;
  final String? towerType; // "Suspension" or "Tension"

  // Fields for Road Crossing
  final bool? hasRoadCrossing;
  final List<String>? roadCrossingTypes; // E.g., ["NH", "SH"]
  final String? roadCrossingName; // E.g., "GT road NH21"

  // Fields for Electrical Line Crossing
  final bool? hasElectricalLineCrossing;
  final List<String>? electricalLineTypes; // E.g., ["400kV", "220kV"]
  final List<String>? electricalLineNames; // E.g., ["Line A", "Line B"]

  // Fields for Span details
  final String? spanLength; // e.g., "250m"
  final String? bottomConductor; // e.g., "Good", "Damaged"
  final String? topConductor; // e.g., "Good", "Damaged"

  // Field for construction status
  final bool? newConstruction;
  final bool? building; // Moved from SurveyRecord

  TowerDetail({
    required this.id,
    required this.lineId,
    required this.lineName,
    required this.towerNumber,
    this.towerType,
    this.hasRoadCrossing,
    this.roadCrossingTypes,
    this.roadCrossingName,
    this.hasElectricalLineCrossing,
    this.electricalLineTypes,
    this.electricalLineNames,
    this.spanLength,
    this.bottomConductor,
    this.topConductor,
    this.newConstruction,
    this.building,
  });

  factory TowerDetail.fromFirestore(Map<String, dynamic> map) {
    return TowerDetail(
      id: map['id'] as String,
      lineId: map['lineId'] as String,
      lineName: map['lineName'] as String? ??
          'Unknown Line', // Fallback for existing data
      towerNumber: map['towerNumber'] as int,
      towerType: map['towerType'] as String?,
      hasRoadCrossing: map['hasRoadCrossing'] as bool?,
      roadCrossingTypes: (map['roadCrossingTypes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      roadCrossingName: map['roadCrossingName'] as String?,
      hasElectricalLineCrossing: map['hasElectricalLineCrossing'] as bool?,
      electricalLineTypes: (map['electricalLineTypes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      electricalLineNames: (map['electricalLineNames'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      spanLength: map['spanLength'] as String?,
      bottomConductor: map['bottomConductor'] as String?,
      topConductor: map['topConductor'] as String?,
      newConstruction: map['newConstruction'] as bool?,
      building: map['building'] as bool?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'lineId': lineId,
      'lineName': lineName,
      'towerNumber': towerNumber,
      'towerType': towerType,
      'hasRoadCrossing': hasRoadCrossing,
      'roadCrossingTypes': roadCrossingTypes,
      'roadCrossingName': roadCrossingName,
      'hasElectricalLineCrossing': hasElectricalLineCrossing,
      'electricalLineTypes': electricalLineTypes,
      'electricalLineNames': electricalLineNames,
      'spanLength': spanLength,
      'bottomConductor': bottomConductor,
      'topConductor': topConductor,
      'newConstruction': newConstruction,
      'building': building,
      'createdAt': FieldValue.serverTimestamp(), // Optional timestamp
    };
  }

  // copyWith method for immutability
  TowerDetail copyWith({
    String? id,
    String? lineId,
    String? lineName,
    int? towerNumber,
    String? towerType,
    bool? hasRoadCrossing,
    List<String>? roadCrossingTypes,
    String? roadCrossingName,
    bool? hasElectricalLineCrossing,
    List<String>? electricalLineTypes,
    List<String>? electricalLineNames,
    String? spanLength,
    String? bottomConductor,
    String? topConductor,
    bool? newConstruction,
    bool? building,
  }) {
    return TowerDetail(
      id: id ?? this.id,
      lineId: lineId ?? this.lineId,
      lineName: lineName ?? this.lineName,
      towerNumber: towerNumber ?? this.towerNumber,
      towerType: towerType ?? this.towerType,
      hasRoadCrossing: hasRoadCrossing ?? this.hasRoadCrossing,
      roadCrossingTypes: roadCrossingTypes ?? this.roadCrossingTypes,
      roadCrossingName: roadCrossingName ?? this.roadCrossingName,
      hasElectricalLineCrossing:
          hasElectricalLineCrossing ?? this.hasElectricalLineCrossing,
      electricalLineTypes: electricalLineTypes ?? this.electricalLineTypes,
      electricalLineNames: electricalLineNames ?? this.electricalLineNames,
      spanLength: spanLength ?? this.spanLength,
      bottomConductor: bottomConductor ?? this.bottomConductor,
      topConductor: topConductor ?? this.topConductor,
      newConstruction: newConstruction ?? this.newConstruction,
      building: building ?? this.building,
    );
  }
}
