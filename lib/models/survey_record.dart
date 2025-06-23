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

  // Detailed Patrolling Points (existing)
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

  // Line Survey Screen fields (existing)
  bool? building;
  bool? tree;
  int? numberOfTrees; // Shown if tree is true
  String? conditionOfOpgw; // Dropdown: OK, Damaged
  String? conditionOfEarthWire; // Dropdown: OK, Damaged
  String? conditionOfConductor; // Dropdown: OK, Damaged
  String? midSpanJoint; // Dropdown: OK, Damaged
  bool? newConstruction;
  bool? objectOnConductor;
  bool? objectOnEarthwire;
  String? spacers; // Dropdown: OK, Damaged
  String? vibrationDamper; // Dropdown: OK, Damaged
  // String? roadCrossing; // Old dropdown: NH, SH, Chakk road, Over Bridge, Underpass - REMOVED
  bool? riverCrossing;
  // String? electricalLine; // Old dropdown: 400kV, 220kV, 132kV, 33kV, 11kV, PTW - REMOVED
  bool? railwayCrossing;

  // NEW: General Notes text area field
  String? generalNotes;

  // NEW: Fields for Road Crossing
  bool? hasRoadCrossing;
  List<String>? roadCrossingTypes; // E.g., ["NH", "SH"]
  String? roadCrossingName; // E.g., "GT road NH21"

  // NEW: Fields for Electrical Line Crossing
  bool? hasElectricalLineCrossing;
  List<String>? electricalLineTypes; // E.g., ["400kV", "220kV"]
  List<String>? electricalLineNames; // E.g., ["Line A", "Line B"]

  // NEW: Fields for Span details
  String? spanLength; // e.g., "250m"
  String? bottomConductor; // e.g., "Good", "Damaged"
  String? topConductor; // e.g., "Good", "Damaged"

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
    // Initialize existing detailed fields
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
    // Initialize Line Survey fields
    this.building,
    this.tree,
    this.numberOfTrees,
    this.conditionOfOpgw,
    this.conditionOfEarthWire,
    this.conditionOfConductor,
    this.midSpanJoint,
    this.newConstruction,
    this.objectOnConductor,
    this.objectOnEarthwire,
    this.spacers,
    this.vibrationDamper,
    // this.roadCrossing, // Removed from constructor
    this.riverCrossing,
    // this.electricalLine, // Removed from constructor
    this.railwayCrossing,
    // Initialize NEW General Notes field
    this.generalNotes,
    // Initialize NEW Road Crossing fields
    this.hasRoadCrossing,
    this.roadCrossingTypes,
    this.roadCrossingName,
    // Initialize NEW Electrical Line Crossing fields
    this.hasElectricalLineCrossing,
    this.electricalLineTypes,
    this.electricalLineNames,
    // Initialize NEW Span fields
    this.spanLength,
    this.bottomConductor,
    this.topConductor,
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
      // Read existing detailed fields
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
      // Read Line Survey fields
      building: map['building'] as bool?,
      tree: map['tree'] as bool?,
      numberOfTrees: map['numberOfTrees'] as int?,
      conditionOfOpgw: map['conditionOfOpgw'] as String?,
      conditionOfEarthWire: map['conditionOfEarthWire'] as String?,
      conditionOfConductor: map['conditionOfConductor'] as String?,
      midSpanJoint: map['midSpanJoint'] as String?,
      newConstruction: map['newConstruction'] as bool?,
      objectOnConductor: map['objectOnConductor'] as bool?,
      objectOnEarthwire: map['objectOnEarthwire'] as bool?,
      spacers: map['spacers'] as String?,
      vibrationDamper: map['vibrationDamper'] as String?,
      // roadCrossing: map['roadCrossing'] as String?, // Removed
      riverCrossing: map['riverCrossing'] as bool?,
      // electricalLine: map['electricalLine'] as String?, // Removed
      railwayCrossing: map['railwayCrossing'] as bool?,
      // Read NEW General Notes field
      generalNotes: map['generalNotes'] as String?,
      // Read NEW Road Crossing fields
      hasRoadCrossing: map['hasRoadCrossing'] as bool?,
      roadCrossingTypes: (map['roadCrossingTypes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      roadCrossingName: map['roadCrossingName'] as String?,
      // Read NEW Electrical Line Crossing fields
      hasElectricalLineCrossing: map['hasElectricalLineCrossing'] as bool?,
      electricalLineTypes: (map['electricalLineTypes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      electricalLineNames: (map['electricalLineNames'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      // Read NEW Span fields
      spanLength: map['spanLength'] as String?,
      bottomConductor: map['bottomConductor'] as String?,
      topConductor: map['topConductor'] as String?,
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
      // Add existing detailed fields for Firestore
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
      // Add Line Survey fields for Firestore
      'building': building,
      'tree': tree,
      'numberOfTrees': numberOfTrees,
      'conditionOfOpgw': conditionOfOpgw,
      'conditionOfEarthWire': conditionOfEarthWire,
      'conditionOfConductor': conditionOfConductor,
      'midSpanJoint': midSpanJoint,
      'newConstruction': newConstruction,
      'objectOnConductor': objectOnConductor,
      'objectOnEarthwire': objectOnEarthwire,
      'spacers': spacers,
      'vibrationDamper': vibrationDamper,
      // 'roadCrossing': roadCrossing, // Removed
      'riverCrossing': riverCrossing,
      // 'electricalLine': electricalLine, // Removed
      'railwayCrossing': railwayCrossing,
      // Add NEW General Notes field for Firestore
      'generalNotes': generalNotes,
      // Add NEW Road Crossing fields for Firestore
      'hasRoadCrossing': hasRoadCrossing,
      'roadCrossingTypes': roadCrossingTypes,
      'roadCrossingName': roadCrossingName,
      // Add NEW Electrical Line Crossing fields for Firestore
      'hasElectricalLineCrossing': hasElectricalLineCrossing,
      'electricalLineTypes': electricalLineTypes,
      'electricalLineNames': electricalLineNames,
      // Add NEW Span fields for Firestore
      'spanLength': spanLength,
      'bottomConductor': bottomConductor,
      'topConductor': topConductor,
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
      // Read existing detailed fields
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
      // Read Line Survey fields
      building: map['building'] == 1, // SQLite stores bool as int
      tree: map['tree'] == 1,
      numberOfTrees: map['numberOfTrees'] as int?,
      conditionOfOpgw: map['conditionOfOpgw'] as String?,
      conditionOfEarthWire: map['conditionOfEarthWire'] as String?,
      conditionOfConductor: map['conditionOfConductor'] as String?,
      midSpanJoint: map['midSpanJoint'] as String?,
      newConstruction: map['newConstruction'] == 1,
      objectOnConductor: map['objectOnConductor'] == 1,
      objectOnEarthwire: map['objectOnEarthwire'] == 1,
      spacers: map['spacers'] as String?,
      vibrationDamper: map['vibrationDamper'] as String?,
      // roadCrossing: map['roadCrossing'] as String?, // Removed
      riverCrossing: map['riverCrossing'] == 1,
      // electricalLine: map['electricalLine'] as String?, // Removed
      railwayCrossing: map['railwayCrossing'] == 1,
      // Read NEW General Notes field
      generalNotes: map['generalNotes'] as String?,
      // Read NEW Road Crossing fields
      hasRoadCrossing: map['hasRoadCrossing'] == 1,
      roadCrossingTypes: (map['roadCrossingTypes'] as String?)
          ?.split(','), // Assuming comma-separated string for SQLite
      roadCrossingName: map['roadCrossingName'] as String?,
      // Read NEW Electrical Line Crossing fields
      hasElectricalLineCrossing: map['hasElectricalLineCrossing'] == 1,
      electricalLineTypes: (map['electricalLineTypes'] as String?)
          ?.split(','), // Assuming comma-separated string for SQLite
      electricalLineNames: (map['electricalLineNames'] as String?)
          ?.split(','), // Assuming comma-separated string for SQLite
      // Read NEW Span fields
      spanLength: map['spanLength'] as String?,
      bottomConductor: map['bottomConductor'] as String?,
      topConductor: map['topConductor'] as String?,
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
      // Add existing detailed fields for SQLite
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
      // Add Line Survey fields for SQLite
      'building': building == true ? 1 : 0, // SQLite stores bool as int
      'tree': tree == true ? 1 : 0,
      'numberOfTrees': numberOfTrees,
      'conditionOfOpgw': conditionOfOpgw,
      'conditionOfEarthWire': conditionOfEarthWire,
      'conditionOfConductor': conditionOfConductor,
      'midSpanJoint': midSpanJoint,
      'newConstruction': newConstruction == true ? 1 : 0,
      'objectOnConductor': objectOnConductor == true ? 1 : 0,
      'objectOnEarthwire': objectOnEarthwire == true ? 1 : 0,
      'spacers': spacers,
      'vibrationDamper': vibrationDamper,
      // 'roadCrossing': roadCrossing, // Removed
      'riverCrossing': riverCrossing == true ? 1 : 0,
      // 'electricalLine': electricalLine, // Removed
      'railwayCrossing': railwayCrossing == true ? 1 : 0,
      // Add NEW General Notes field for SQLite
      'generalNotes': generalNotes,
      // Add NEW Road Crossing fields for SQLite
      'hasRoadCrossing': hasRoadCrossing == true ? 1 : 0,
      'roadCrossingTypes':
          roadCrossingTypes?.join(','), // Store as comma-separated string
      'roadCrossingName': roadCrossingName,
      // Add NEW Electrical Line Crossing fields for SQLite
      'hasElectricalLineCrossing': hasElectricalLineCrossing == true ? 1 : 0,
      'electricalLineTypes':
          electricalLineTypes?.join(','), // Store as comma-separated string
      'electricalLineNames':
          electricalLineNames?.join(','), // Store as comma-separated string
      // Add NEW Span fields for SQLite
      'spanLength': spanLength,
      'bottomConductor': bottomConductor,
      'topConductor': topConductor,
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
    // Copy new fields from Line Survey Screen
    bool? building,
    bool? tree,
    int? numberOfTrees,
    String? conditionOfOpgw,
    String? conditionOfEarthWire,
    String? conditionOfConductor,
    String? midSpanJoint,
    bool? newConstruction,
    bool? objectOnConductor,
    bool? objectOnEarthwire,
    String? spacers,
    String? vibrationDamper,
    // String? roadCrossing, // Removed from copyWith
    bool? riverCrossing,
    // String? electricalLine, // Removed from copyWith
    bool? railwayCrossing,
    // Copy NEW General Notes field
    String? generalNotes,
    // Copy NEW Road Crossing fields
    bool? hasRoadCrossing,
    List<String>? roadCrossingTypes,
    String? roadCrossingName,
    // Copy NEW Electrical Line Crossing fields
    bool? hasElectricalLineCrossing,
    List<String>? electricalLineTypes,
    List<String>? electricalLineNames,
    // Copy NEW Span fields
    String? spanLength,
    String? bottomConductor,
    String? topConductor,
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
      // Copy existing detailed fields
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
      // Copy new fields from Line Survey Screen
      building: building ?? this.building,
      tree: tree ?? this.tree,
      numberOfTrees: numberOfTrees ?? this.numberOfTrees,
      conditionOfOpgw: conditionOfOpgw ?? this.conditionOfOpgw,
      conditionOfEarthWire: conditionOfEarthWire ?? this.conditionOfEarthWire,
      conditionOfConductor: conditionOfConductor ?? this.conditionOfConductor,
      midSpanJoint: midSpanJoint ?? this.midSpanJoint,
      newConstruction: newConstruction ?? this.newConstruction,
      objectOnConductor: objectOnConductor ?? this.objectOnConductor,
      objectOnEarthwire: objectOnEarthwire ?? this.objectOnEarthwire,
      spacers: spacers ?? this.spacers,
      vibrationDamper: vibrationDamper ?? this.vibrationDamper,
      // roadCrossing: roadCrossing ?? this.roadCrossing, // Removed
      riverCrossing: riverCrossing ?? this.riverCrossing,
      // electricalLine: electricalLine ?? this.electricalLine, // Removed
      railwayCrossing: railwayCrossing ?? this.railwayCrossing,
      // Copy NEW General Notes field
      generalNotes: generalNotes ?? this.generalNotes,
      // Copy NEW Road Crossing fields
      hasRoadCrossing: hasRoadCrossing ?? this.hasRoadCrossing,
      roadCrossingTypes: roadCrossingTypes ?? this.roadCrossingTypes,
      roadCrossingName: roadCrossingName ?? this.roadCrossingName,
      // Copy NEW Electrical Line Crossing fields
      hasElectricalLineCrossing:
          hasElectricalLineCrossing ?? this.hasElectricalLineCrossing,
      electricalLineTypes: electricalLineTypes ?? this.electricalLineTypes,
      electricalLineNames: electricalLineNames ?? this.electricalLineNames,
      // Copy NEW Span fields
      spanLength: spanLength ?? this.spanLength,
      bottomConductor: bottomConductor ?? this.bottomConductor,
      topConductor: topConductor ?? this.topConductor,
    );
  }

  @override
  String toString() {
    return 'SurveyRecord(id: $id, line: $lineName, tower: $towerNumber, status: $status, taskId: $taskId, userId: $userId)';
  }
}
