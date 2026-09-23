import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseService {
  static final DatabaseService instance =
      DatabaseService._init();

  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB('closetly.db');

    return _database!;
  }

  Future<Database> _initDB(
    String fileName,
  ) async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;

      return openDatabase(
        fileName,
        version: 3,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    }

    final String dbPath =
        await getDatabasesPath();

    final String dbFilePath =
        path.join(dbPath, fileName);

    return openDatabase(
      dbFilePath,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(
    Database db,
    int version,
  ) async {
    await db.execute('''
      CREATE TABLE clothing (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        color TEXT,
        imagePath TEXT,
        imageData BLOB
      )
    ''');

    await db.execute('''
      CREATE TABLE ai_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        isUser INTEGER NOT NULL,
        messageType TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE clothing ADD COLUMN imageData BLOB',
      );
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE ai_messages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          isUser INTEGER NOT NULL,
          messageType TEXT NOT NULL,
          content TEXT NOT NULL,
          createdAt INTEGER NOT NULL
        )
      ''');
    }
  }

  // ============================================================
  // AI CHAT HISTORY
  // ============================================================

  Future<void> saveAIMessage({
    required bool isUser,
    required String messageType,
    required String content,
  }) async {
    final Database db = await database;

    await db.insert(
      'ai_messages',
      {
        'isUser': isUser ? 1 : 0,
        'messageType': messageType,
        'content': content,
        'createdAt':
            DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<List<Map<String, dynamic>>>
      getAIMessages() async {
    final Database db = await database;

    return db.query(
      'ai_messages',
      orderBy: 'createdAt ASC, id ASC',
    );
  }

  Future<void> clearAIMessages() async {
    final Database db = await database;

    await db.delete('ai_messages');
  }

  // ============================================================
  // DATABASE CLOSE
  // ============================================================

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}