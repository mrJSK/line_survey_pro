// lib/services/local_database_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:line_survey_pro/models/survey_record.dart';
import 'package:line_survey_pro/models/task.dart';
import 'dart:async'; // For StreamController

class LocalDatabaseService {
  static Database? _database;
  static const String _databaseName = 'line_survey_pro.db';
  static const int _databaseVersion = 3;

  // NEW: StreamController to notify listeners about local DB changes
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
    // Initial load into stream after DB is ready
    _updateStreamWithAllRecords();
    print('Local database initialized successfully.');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db
            .execute('ALTER TABLE $_surveyRecordsTable ADD COLUMN taskId TEXT');
      } catch (e) {/* ignore */}
      try {
        await db
            .execute('ALTER TABLE $_surveyRecordsTable ADD COLUMN userId TEXT');
      } catch (e) {/* ignore */}
    }
    print('Database upgraded from version $oldVersion to $newVersion.');
  }

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
        userId TEXT
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
    _updateStreamWithAllRecords(); // NEW: Notify listeners of change
  }

  Future<List<SurveyRecord>> getAllSurveyRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_surveyRecordsTable);
    return List.generate(maps.length, (i) {
      return SurveyRecord.fromMap(maps[i]);
    });
  }

  // NEW: Stream of all local survey records for real-time local UI updates
  Stream<List<SurveyRecord>> getAllSurveyRecordsStream() {
    // Ensure the stream is populated on first subscription
    _updateStreamWithAllRecords();
    return _surveyRecordsStreamController.stream;
  }

  // Helper to fetch and add records to the stream
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
      where: "status = ?",
      whereArgs: ['saved'],
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
    _updateStreamWithAllRecords(); // NEW: Notify listeners of change
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
    _updateStreamWithAllRecords(); // NEW: Notify listeners of change
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
    _updateStreamWithAllRecords(); // NEW: Notify listeners of change
  }

  Future<void> deleteSurveyRecordsByTaskId(String taskId) async {
    final db = await database;
    await db.delete(
      _surveyRecordsTable,
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
    _updateStreamWithAllRecords(); // NEW: Notify listeners of change
    print('Deleted local survey records for task $taskId.');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    _surveyRecordsStreamController.close(); // NEW: Close the stream controller
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
