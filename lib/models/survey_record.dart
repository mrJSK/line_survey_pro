// lib/models/survey_record.dart
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp

class SurveyRecord {
  final String id;
  final String lineName;
  final int towerNumber;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String photoPath; // Local path to the image file
  String status; // e.g., 'saved_photo_only', 'saved_complete', 'uploaded'
  final String? taskId;
  final String? userId;

  // NEW: Detailed Patrolling Points
  String? missingTowerParts; // E.g., "Yes", "No", "Description"
  String? soilCondition; // E.g., "Good", "Eroded", "Soft"
  String? stubCopingLeg; // E.g., "Good", "Damaged", "Missing"
  String? earthing; // E.g., "Good", "Needs repair", "Missing"
  String? conditionOfTowerParts; // E.g., "Good", "Corroded", "Bent"
  String? statusOfInsulator; // E.g., "Good", "Broken", "Flashover"
  String? jumperStatus; // E.g., "Good", "Loose", "Damaged"
  String? hotSpots; // E.g., "Yes", "No", "Location/Temp"
  String? numberPlate; // E.g., "Present", "Missing", "Damaged"
  String? dangerBoard; // E.g., "Present", "Missing", "Damaged"
  String? phasePlate; // E.g., "Present", "Missing", "Damaged"
  String? nutAndBoltCondition; // E.g., "Tight", "Loose", "Missing"
  String? antiClimbingDevice; // E.g., "Intact", "Damaged", "Missing"
  String? wildGrowth; // E.g., "None", "Minor", "Heavy"
  String? birdGuard; // E.g., "Present", "Missing", "Damaged"
  String? birdNest; // E.g., "Present", "Absent", "Obstructing"
  String? archingHorn; // E.g., "Good", "Damaged", "Missing"
  String? coronaRing; // E.g., "Good", "Damaged", "Missing"
  String? insulatorType; // E.g., "Disc", "Long Rod", "Polymer"
  String? opgwJointBox; // E.g., "Good", "Damaged", "Open"

  SurveyRecord({
    String? id,
    required this.lineName,
    required this.towerNumber,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.photoPath,
    this.status =
        'saved_photo_only', // Default status: photo captured, details pending
    this.taskId,
    this.userId,
    // Initialize new fields
    this.missingTowerParts,
    this.soilCondition,
    this.stubCopingLeg,
    this.earthing,
    this.conditionOfTowerParts,
    this.statusOfInsulator,
    this.jumperStatus,
    this.hotSpots,
    this.numberPlate,
    this.dangerBoard,
    this.phasePlate,
    this.nutAndBoltCondition,
    this.antiClimbingDevice,
    this.wildGrowth,
    this.birdGuard,
    this.birdNest,
    this.archingHorn,
    this.coronaRing,
    this.insulatorType,
    this.opgwJointBox,
  }) : id = id ?? const Uuid().v4();

  // Factory constructor to create a SurveyRecord from a Firestore document's data Map
  factory SurveyRecord.fromFirestore(Map<String, dynamic> map) {
    return SurveyRecord(
      id: map['id'] as String,
      lineName: map['lineName'] as String,
      towerNumber: map['towerNumber'] as int,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      photoPath: map['photoPath'] as String? ??
          '', // PhotoPath might not exist in Firestore-only records if not syncing
      status: map['status'] as String,
      taskId: map['taskId'] as String?,
      userId: map['userId'] as String?,
      // Read new fields
      missingTowerParts: map['missingTowerParts'] as String?,
      soilCondition: map['soilCondition'] as String?,
      stubCopingLeg: map['stubCopingLeg'] as String?,
      earthing: map['earthing'] as String?,
      conditionOfTowerParts: map['conditionOfTowerParts'] as String?,
      statusOfInsulator: map['statusOfInsulator'] as String?,
      jumperStatus: map['jumperStatus'] as String?,
      hotSpots: map['hotSpots'] as String?,
      numberPlate: map['numberPlate'] as String?,
      dangerBoard: map['dangerBoard'] as String?,
      phasePlate: map['phasePlate'] as String?,
      nutAndBoltCondition: map['nutAndBoltCondition'] as String?,
      antiClimbingDevice: map['antiClimbingDevice'] as String?,
      wildGrowth: map['wildGrowth'] as String?,
      birdGuard: map['birdGuard'] as String?,
      birdNest: map['birdNest'] as String?,
      archingHorn: map['archingHorn'] as String?,
      coronaRing: map['coronaRing'] as String?,
      insulatorType: map['insulatorType'] as String?,
      opgwJointBox: map['opgwJointBox'] as String?,
    );
  }

  // Method to convert a SurveyRecord object to a Map for Firestore
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
      // Add new fields for Firestore
      'missingTowerParts': missingTowerParts,
      'soilCondition': soilCondition,
      'stubCopingLeg': stubCopingLeg,
      'earthing': earthing,
      'conditionOfTowerParts': conditionOfTowerParts,
      'statusOfInsulator': statusOfInsulator,
      'jumperStatus': jumperStatus,
      'hotSpots': hotSpots,
      'numberPlate': numberPlate,
      'dangerBoard': dangerBoard,
      'phasePlate': phasePlate,
      'nutAndBoltCondition': nutAndBoltCondition,
      'antiClimbingDevice': antiClimbingDevice,
      'wildGrowth': wildGrowth,
      'birdGuard': birdGuard,
      'birdNest': birdNest,
      'archingHorn': archingHorn,
      'coronaRing': coronaRing,
      'insulatorType': insulatorType,
      'opgwJointBox': opgwJointBox,
    };
  }

  // Factory constructor to create a SurveyRecord from a Map (for SQLite retrieval)
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
      // Read new fields
      missingTowerParts: map['missingTowerParts'] as String?,
      soilCondition: map['soilCondition'] as String?,
      stubCopingLeg: map['stubCopingLeg'] as String?,
      earthing: map['earthing'] as String?,
      conditionOfTowerParts: map['conditionOfTowerParts'] as String?,
      statusOfInsulator: map['statusOfInsulator'] as String?,
      jumperStatus: map['jumperStatus'] as String?,
      hotSpots: map['hotSpots'] as String?,
      numberPlate: map['numberPlate'] as String?,
      dangerBoard: map['dangerBoard'] as String?,
      phasePlate: map['phasePlate'] as String?,
      nutAndBoltCondition: map['nutAndBoltCondition'] as String?,
      antiClimbingDevice: map['antiClimbingDevice'] as String?,
      wildGrowth: map['wildGrowth'] as String?,
      birdGuard: map['birdGuard'] as String?,
      birdNest: map['birdNest'] as String?,
      archingHorn: map['archingHorn'] as String?,
      coronaRing: map['coronaRing'] as String?,
      insulatorType: map['insulatorType'] as String?,
      opgwJointBox: map['opgwJointBox'] as String?,
    );
  }

  // Method to convert a SurveyRecord object to a Map for SQLite storage
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
      // Add new fields for SQLite
      'missingTowerParts': missingTowerParts,
      'soilCondition': soilCondition,
      'stubCopingLeg': stubCopingLeg,
      'earthing': earthing,
      'conditionOfTowerParts': conditionOfTowerParts,
      'statusOfInsulator': statusOfInsulator,
      'jumperStatus': jumperStatus,
      'hotSpots': hotSpots,
      'numberPlate': numberPlate,
      'dangerBoard': dangerBoard,
      'phasePlate': phasePlate,
      'nutAndBoltCondition': nutAndBoltCondition,
      'antiClimbingDevice': antiClimbingDevice,
      'wildGrowth': wildGrowth,
      'birdGuard': birdGuard,
      'birdNest': birdNest,
      'archingHorn': archingHorn,
      'coronaRing': coronaRing,
      'insulatorType': insulatorType,
      'opgwJointBox': opgwJointBox,
    };
  }

  // copyWith method for immutability
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
    String? missingTowerParts,
    String? soilCondition,
    String? stubCopingLeg,
    String? earthing,
    String? conditionOfTowerParts,
    String? statusOfInsulator,
    String? jumperStatus,
    String? hotSpots,
    String? numberPlate,
    String? dangerBoard,
    String? phasePlate,
    String? nutAndBoltCondition,
    String? antiClimbingDevice,
    String? wildGrowth,
    String? birdGuard,
    String? birdNest,
    String? archingHorn,
    String? coronaRing,
    String? insulatorType,
    String? opgwJointBox,
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
      // Copy new fields
      missingTowerParts: missingTowerParts ?? this.missingTowerParts,
      soilCondition: soilCondition ?? this.soilCondition,
      stubCopingLeg: stubCopingLeg ?? this.stubCopingLeg,
      earthing: earthing ?? this.earthing,
      conditionOfTowerParts:
          conditionOfTowerParts ?? this.conditionOfTowerParts,
      statusOfInsulator: statusOfInsulator ?? this.statusOfInsulator,
      jumperStatus: jumperStatus ?? this.jumperStatus,
      hotSpots: hotSpots ?? this.hotSpots,
      numberPlate: numberPlate ?? this.numberPlate,
      dangerBoard: dangerBoard ?? this.dangerBoard,
      phasePlate: phasePlate ?? this.phasePlate,
      nutAndBoltCondition: nutAndBoltCondition ?? this.nutAndBoltCondition,
      antiClimbingDevice: antiClimbingDevice ?? this.antiClimbingDevice,
      wildGrowth: wildGrowth ?? this.wildGrowth,
      birdGuard: birdGuard ?? this.birdGuard,
      birdNest: birdNest ?? this.birdNest,
      archingHorn: archingHorn ?? this.archingHorn,
      coronaRing: coronaRing ?? this.coronaRing,
      insulatorType: insulatorType ?? this.insulatorType,
      opgwJointBox: opgwJointBox ?? this.opgwJointBox,
    );
  }

  @override
  String toString() {
    return 'SurveyRecord(id: $id, line: $lineName, tower: $towerNumber, status: $status, taskId: $taskId, userId: $userId)';
  }
}
