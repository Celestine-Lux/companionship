import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/activity_record.dart';
import '../models/companion.dart';

class DatabaseService {
  Database? _database;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'companionship.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE activities (
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            userName TEXT NOT NULL,
            type TEXT NOT NULL,
            appName TEXT,
            appPackage TEXT,
            batteryLevel INTEGER,
            timestamp TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE companions (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            pairingCode TEXT NOT NULL,
            pairedAt TEXT NOT NULL,
            isActive INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> insertActivity(ActivityRecord record) async {
    await _database?.insert('activities', record.toJson());
  }

  Future<List<ActivityRecord>> getActivities({int limit = 100}) async {
    final List<Map<String, dynamic>>? maps = await _database?.query(
      'activities',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps?.map((m) => ActivityRecord.fromJson(m)).toList() ?? [];
  }

  Future<void> insertCompanion(Companion companion) async {
    await _database?.insert('companions', companion.toJson());
  }

  Future<Companion?> getActiveCompanion() async {
    final List<Map<String, dynamic>>? maps = await _database?.query(
      'companions',
      where: 'isActive = ?',
      whereArgs: [1],
      limit: 1,
    );
    return maps?.isNotEmpty == true ? Companion.fromJson(maps!.first) : null;
  }

  Future<void> clearActivities() async {
    await _database?.delete('activities');
  }

  Future<void> deactivateCompanion(String id) async {
    await _database?.update(
      'companions',
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
