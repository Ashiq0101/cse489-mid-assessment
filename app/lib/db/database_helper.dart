import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart'; // Add for kIsWeb
import '../models/landmark.dart';
import '../models/visit_history.dart';
import '../models/visit_queue.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // In-memory fallback for Chrome Web testing
  final List<Landmark> _webLandmarks = [];
  final List<VisitHistory> _webHistory = [];
  final List<VisitQueue> _webQueue = [];

  DatabaseHelper._init();

  Future<Database?> get database async {
    if (kIsWeb) return null; // Bypass SQLite on Web completely
    
    if (_database != null) return _database!;
    _database = await _initDB('landmarks.db');
    return _database!;
  }
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. Landmarks Cache Table
    await db.execute('''
      CREATE TABLE landmarks (
        id INTEGER PRIMARY KEY,
        title TEXT,
        lat REAL,
        lon REAL,
        image TEXT,
        is_active INTEGER,
        visit_count INTEGER,
        avg_distance REAL,
        score REAL
      )
    ''');

    // 2. Visit History Table
    await db.execute('''
      CREATE TABLE visit_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        landmark_id INTEGER,
        landmark_title TEXT,
        visit_time TEXT,
        visitor_lat REAL,
        visitor_lon REAL,
        distance REAL
      )
    ''');

    // 3. Offline Action Queue Table
    await db.execute('''
      CREATE TABLE visit_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT,
        payload TEXT,
        status TEXT,
        timestamp TEXT,
        image_path TEXT
      )
    ''');
  }

  // --- Landmark Cache ---
  Future<void> cacheLandmarks(List<Landmark> landmarks) async {
    if (kIsWeb) {
      _webLandmarks.clear();
      _webLandmarks.addAll(landmarks);
      return;
    }
    final db = await instance.database;
    Batch batch = db!.batch();
    batch.delete('landmarks'); // Clear old cache
    for (var l in landmarks) {
      batch.insert('landmarks', l.toJson());
    }
    await batch.commit();
  }

  Future<List<Landmark>> getCachedLandmarks() async {
    if (kIsWeb) return _webLandmarks;
    final db = await instance.database;
    final result = await db!.query('landmarks');
    return result.map((json) => Landmark.fromJson(json)).toList();
  }

  // --- Visit History ---
  Future<int> insertVisit(VisitHistory visit) async {
    if (kIsWeb) {
      _webHistory.add(visit);
      return _webHistory.length;
    }
    final db = await instance.database;
    return await db!.insert('visit_history', visit.toMap());
  }

  Future<List<VisitHistory>> getVisitHistory() async {
    if (kIsWeb) return _webHistory.reversed.toList();
    final db = await instance.database;
    final result = await db!.query('visit_history', orderBy: 'id DESC');
    return result.map((json) => VisitHistory.fromMap(json)).toList();
  }

  // --- Visit Queue (Offline Actions) ---
  Future<int> queueAction(VisitQueue queueItem) async {
    if (kIsWeb) {
      _webQueue.add(queueItem);
      return _webQueue.length;
    }
    final db = await instance.database;
    return await db!.insert('visit_queue', queueItem.toMap());
  }

  Future<List<VisitQueue>> getPendingQueue() async {
    if (kIsWeb) return _webQueue.where((q) => q.status == 'pending').toList();
    final db = await instance.database;
    final result = await db!.query('visit_queue', where: 'status = ?', whereArgs: ['pending']);
    return result.map((json) => VisitQueue.fromMap(json)).toList();
  }

  Future<int> deleteQueueItem(int id) async {
    if (kIsWeb) return 0; // Not perfectly simulated with IDs on web, but this is acceptable mock behavior
    final db = await instance.database;
    return await db!.delete('visit_queue', where: 'id = ?', whereArgs: [id]);
  }
}
