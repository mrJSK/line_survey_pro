// lib/services/local_database_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:line_survey_pro/models/survey_record.dart';
import 'package:line_survey_pro/models/task.dart';
import 'dart:async'; // For StreamController

class LocalDatabaseService {
  static Database? _database;
  static const String _databaseName = 'line_survey_pro.db';
  // Increment to a new version (e.g., 4) because we're adding many new columns
  static const int _databaseVersion = 4;

  static final StreamController<List<SurveyRecord>>
      _surveyRecordsStreamController =
      StreamController<List<SurveyRecord>>.broadcast();

  static const String _surveyRecordsTable = 'survey_records';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> initializeDatabase() async {
    await database;
    _updateStreamWithAllRecords();
    print('Local database initialized successfully.');
  }

  // --- IMPORTANT: Database Schema Migration ---
  // This is crucial for adding new columns to existing databases.
  // Each 'if (oldVersion < X)' block should contain DDL for changes introduced in version X.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration from version 1 to 2 (taskId, userId)
    if (oldVersion < 2) {
      try {
        await db
            .execute('ALTER TABLE $_surveyRecordsTable ADD COLUMN taskId TEXT');
      } catch (e) {/* column might already exist from previous partial runs */}
      try {
        await db
            .execute('ALTER TABLE $_surveyRecordsTable ADD COLUMN userId TEXT');
      } catch (e) {/* ignore */}
      print('Migrated to DB Version 2: Added taskId and userId.');
    }
    // Migration from version 2 to 3 (if photoUrl was added then removed, or just to sync version)
    if (oldVersion < 3) {
      // If photoUrl was explicitly added in a version 2 migration, and you want it removed
      // this is where complex ALTER TABLE (rename, create new, copy, drop) would go.
      // For now, if you just removed it from SurveyRecord.toMap() and onCreate,
      // old DBs will just have the unused column.
      print(
          'Migrated to DB Version 3 (no new columns or complex schema change in this version logic).');
    }
    // Migration from version 3 to 4 (Adding all new patrolling detail columns)
    if (oldVersion < 4) {
      try {
        await db.execute(
            'ALTER TABLE $_surveyRecordsTable ADD COLUMN missingTowerParts TEXT');
      } catch (e) {}
      try {
        await db.execute(
            'ALTER TABLE $_surveyRecordsTable ADD COLUMN soilCondition TEXT');
      } catch (e) {}
      try {
        await db.execute(
            'ALTER TABLE $_surveyRecordsTable ADD COLUMN stubCopingLeg TEXT');
      } catch (e) {}
      try {
        await db.execute(
            'ALTER TABLE $_surveyRecordsTable ADD COLUMN earthing TEXT');
      } catch (e) {}
      try {
        await db.execute(
            'ALTER TABLE $_surveyRecordsTable ADD COLUMN conditionOfTowerParts TEXT');
      } catch (e) {}
      try {
        await db.execute(
            'ALTER TABLE $_surveyRecordsTable ADD COLUMN statusOfInsulator TEXT');
      } catch (e) {}
      try {
        await db.execute(
            'ALTER TABLE $_surveyRecordsTable ADD COLUMN jumperStatus TEXT');
      } catch (e) {}
      try {
        await db.execute(
            'ALTER TABLE $_surveyRecordsTable ADD COLUMN hotSpots TEXT');
      } catch (e) {}
      try {
        await db.execute(
            'ALTER TABLE $_surveyRecordsTable ADD COLUMN numberPlate TEXT');
      } catch (e) {}
      try {
        await db.execute(
            'ALTER TABLE $_surveyRecordsTable ADD COLUMN dangerBoard TEXT');
      } catch (e) {}
      try {
        await db.execute(
            'ALTER TABLE $_surveyRecordsTable ADD COLUMN phasePlate TEXT');
      } catch (e) {}
      try {
        await db.execute(
            'ALTER TABLE $_surveyRecordsTable ADD COLUMN nutAndBoltCondition TEXT');
      } catch (e) {}
      try {
        await db.execute(
            'ALTER TABLE $_surveyRecordsTable ADD COLUMN antiClimbingDevice TEXT');
      } catch (e) {}
      try {
        await db.execute(
            'ALTER TABLE $_surveyRecordsTable ADD COLUMN wildGrowth TEXT');
      } catch (e) {}
      try {
        await db.execute(
            'ALTER TABLE $_surveyRecordsTable ADD COLUMN birdGuard TEXT');
      } catch (e) {}
      try {
        await db.execute(
            'ALTER TABLE $_surveyRecordsTable ADD COLUMN birdNest TEXT');
      } catch (e) {}
      try {
        await db.execute(
            'ALTER TABLE $_surveyRecordsTable ADD COLUMN archingHorn TEXT');
      } catch (e) {}
      try {
        await db.execute(
            'ALTER TABLE $_surveyRecordsTable ADD COLUMN coronaRing TEXT');
      } catch (e) {}
      try {
        await db.execute(
            'ALTER TABLE $_surveyRecordsTable ADD COLUMN insulatorType TEXT');
      } catch (e) {}
      try {
        await db.execute(
            'ALTER TABLE $_surveyRecordsTable ADD COLUMN opgwJointBox TEXT');
      } catch (e) {}
      print('Migrated to DB Version 4: Added all patrolling detail columns.');
    }
    print('Database upgraded from version $oldVersion to $newVersion.');
  }

  // Define the table schema for NEW database creations (version 4)
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_surveyRecordsTable(
        id TEXT PRIMARY KEY,
        lineName TEXT,
        towerNumber INTEGER,
        latitude REAL,
        longitude REAL,
        timestamp TEXT,
        photoPath TEXT,
        status TEXT,
        taskId TEXT,
        userId TEXT,
        -- New Patrolling Details
        missingTowerParts TEXT,
        soilCondition TEXT,
        stubCopingLeg TEXT,
        earthing TEXT,
        conditionOfTowerParts TEXT,
        statusOfInsulator TEXT,
        jumperStatus TEXT,
        hotSpots TEXT,
        numberPlate TEXT,
        dangerBoard TEXT,
        phasePlate TEXT,
        nutAndBoltCondition TEXT,
        antiClimbingDevice TEXT,
        wildGrowth TEXT,
        birdGuard TEXT,
        birdNest TEXT,
        archingHorn TEXT,
        coronaRing TEXT,
        insulatorType TEXT,
        opgwJointBox TEXT
      )
    ''');
    print('Database created with version $version.');
  }

  // --- Survey Record Operations ---
  Future<void> saveSurveyRecord(SurveyRecord record) async {
    final db = await database;
    await db.insert(
      _surveyRecordsTable,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _updateStreamWithAllRecords(); // Notify listeners of change
  }

  Future<List<SurveyRecord>> getAllSurveyRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_surveyRecordsTable);
    return List.generate(maps.length, (i) {
      return SurveyRecord.fromMap(maps[i]);
    });
  }

  Stream<List<SurveyRecord>> getAllSurveyRecordsStream() {
    _updateStreamWithAllRecords(); // Ensure stream is populated on first subscription
    return _surveyRecordsStreamController.stream;
  }

  Future<void> _updateStreamWithAllRecords() async {
    final records = await getAllSurveyRecords();
    if (!_surveyRecordsStreamController.isClosed) {
      _surveyRecordsStreamController.add(records);
    }
  }

  Future<List<SurveyRecord>> getUnsyncedSurveyRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _surveyRecordsTable,
      where:
          "status = ? OR status = ?", // Look for 'saved_photo_only' or 'saved_complete'
      whereArgs: ['saved_photo_only', 'saved_complete'],
    );
    return List.generate(maps.length, (i) {
      return SurveyRecord.fromMap(maps[i]);
    });
  }

  Future<void> updateSurveyRecordStatus(
      String recordId, String newStatus) async {
    final db = await database;
    await db.update(
      _surveyRecordsTable,
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [recordId],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _updateStreamWithAllRecords(); // Notify listeners of change
  }

  Future<List<SurveyRecord>> getSurveyRecordsByLineAndTower(
      String lineName, int towerNumber) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _surveyRecordsTable,
      where: 'lineName = ? AND towerNumber = ?',
      whereArgs: [lineName, towerNumber],
    );
    return List.generate(maps.length, (i) {
      return SurveyRecord.fromMap(maps[i]);
    });
  }

  Future<List<SurveyRecord>> getSurveyRecordsByLine(String lineName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _surveyRecordsTable,
      where: 'lineName = ?',
      whereArgs: [lineName],
    );
    return List.generate(maps.length, (i) {
      return SurveyRecord.fromMap(maps[i]);
    });
  }

  Future<Map<String, int>> getSurveyProgressForUserTasks(
      List<Task> userTasks) async {
    if (userTasks.isEmpty) return {};

    final db = await database;
    final List<String> taskIds = userTasks.map((task) => task.id).toList();
    final String inClause = List.filled(taskIds.length, '?').join(',');

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT lineName, taskId, COUNT(DISTINCT towerNumber) as completedTowers
      FROM $_surveyRecordsTable
      WHERE taskId IN ($inClause) AND status = 'uploaded'
      GROUP BY lineName, taskId
    ''', taskIds);

    final Map<String, int> progress = {};
    for (var row in result) {
      final String lineName = row['lineName'] as String;
      final String taskId = row['taskId'] as String;
      final int completedTowers = row['completedTowers'] as int;

      final Task? matchingTask =
          userTasks.firstWhereOrNull((task) => task.id == taskId);

      if (matchingTask != null) {
        progress[lineName] = (progress[lineName] ?? 0) + completedTowers;
      }
    }
    return progress;
  }

  Future<Map<String, int>> getSurveyProgress() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT lineName, COUNT(DISTINCT towerNumber) as completedTowers
      FROM $_surveyRecordsTable
      WHERE status = 'uploaded'
      GROUP BY lineName
    ''');

    final Map<String, int> progress = {};
    for (var row in result) {
      progress[row['lineName'] as String] = row['completedTowers'] as int;
    }
    return progress;
  }

  Future<void> deleteSurveyRecord(String id) async {
    final db = await database;
    await db.delete(
      _surveyRecordsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    _updateStreamWithAllRecords(); // Notify listeners of change
  }

  Future<void> deleteSurveyRecords(Set<String> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final String inClause = ids.map((_) => '?').join(',');
    await db.delete(
      _surveyRecordsTable,
      where: 'id IN ($inClause)',
      whereArgs: ids.toList(),
    );
    _updateStreamWithAllRecords(); // Notify listeners of change
  }

  Future<void> deleteSurveyRecordsByTaskId(String taskId) async {
    final db = await database;
    await db.delete(
      _surveyRecordsTable,
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
    _updateStreamWithAllRecords(); // Notify listeners of change
    print('Deleted local survey records for task $taskId.');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    _surveyRecordsStreamController.close(); // Close the stream controller
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
