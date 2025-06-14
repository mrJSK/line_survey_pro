// lib/services/local_database_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
// Ensure this model is compatible if used
import 'package:line_survey_pro/models/survey_record.dart'; // Your SurveyRecord model

class LocalDatabaseService {
  static Database? _database;
  static const String _databaseName = 'line_survey_pro.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _transmissionLinesTable =
      'transmission_lines'; // No longer storing lines here from Firestore integration
  static const String _surveyRecordsTable = 'survey_records';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Get a location using getDatabasesPath
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      // OnUpgrade: _onUpgrade, // Add if you plan schema migrations
    );
  }

  Future<void> initializeDatabase() async {
    await database; // Accessing the getter will ensure _initDatabase is called.
    print('Local database initialized successfully.');
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create survey_records table
    await db.execute('''
      CREATE TABLE $_surveyRecordsTable(
        id TEXT PRIMARY KEY,
        lineName TEXT,
        towerNumber INTEGER,
        latitude REAL,
        longitude REAL,
        timestamp TEXT,
        photoPath TEXT,
        status TEXT
      )
    ''');
  }

  // --- Survey Record Operations ---

  // Saves a new survey record to the local database.
  Future<void> saveSurveyRecord(SurveyRecord record) async {
    final db = await database;
    await db.insert(
      _surveyRecordsTable,
      record.toMap(), // Uses the toMap method from SurveyRecord
      conflictAlgorithm:
          ConflictAlgorithm.replace, // Replace if ID already exists
    );
  }

  // Fetches all survey records from the local database.
  Future<List<SurveyRecord>> getAllSurveyRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_surveyRecordsTable);
    return List.generate(maps.length, (i) {
      return SurveyRecord.fromMap(maps[i]); // Uses fromMap from SurveyRecord
    });
  }

  // Fetches survey records for a specific line and tower number.
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

  // NEW: Fetches all survey records for a specific line name.
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

  // Calculates and returns survey progress (towers completed per line).
  // This aggregates locally stored data.
  Future<Map<String, int>> getSurveyProgress() async {
    final db = await database;
    // Query to count records per line name
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT lineName, COUNT(DISTINCT towerNumber) as completedTowers
      FROM $_surveyRecordsTable
      GROUP BY lineName
    ''');

    final Map<String, int> progress = {};
    for (var row in result) {
      progress[row['lineName'] as String] = row['completedTowers'] as int;
    }
    return progress;
  }

  // Deletes a single survey record by its ID.
  Future<void> deleteSurveyRecord(String id) async {
    final db = await database;
    await db.delete(
      _surveyRecordsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete multiple survey records by their IDs.
  Future<void> deleteSurveyRecords(Set<String> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final String inClause = ids.map((_) => '?').join(',');
    await db.delete(
      _surveyRecordsTable,
      where: 'id IN ($inClause)',
      whereArgs: ids.toList(),
    );
  }

  // Close the database connection (optional, useful for testing or specific scenarios)
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null; // Clear the instance
  }
}
