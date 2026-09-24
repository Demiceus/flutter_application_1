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
        version: 5,
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
      version: 5,
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

    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY,
        nickname TEXT NOT NULL,
        gender TEXT
      )
    ''');

    await db.insert(
      'user_profile',
      {
        'id': 1,
        'nickname': 'Closetly User',
        'gender': null,
      },
    );
    await db.execute('''
    CREATE TABLE app_settings (
      settingKey TEXT PRIMARY KEY,
      settingValue TEXT NOT NULL
    )
  ''');

  await db.insert(
    'app_settings',
    {
      'settingKey': 'themeMode',
      'settingValue': 'dark',
    },
  );

  await db.insert(
    'app_settings',
    {
      'settingKey': 'accentColor',
      'settingValue': 'purple',
    },
  );

  await db.insert(
    'app_settings',
    {
      'settingKey': 'animations',
      'settingValue': 'true',
    },
  );
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

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE user_profile (
          id INTEGER PRIMARY KEY,
          nickname TEXT NOT NULL,
          gender TEXT
        )
      ''');

      await db.insert(
        'user_profile',
        {
          'id': 1,
          'nickname': 'Closetly User',
          'gender': null,
        },
      );
    }

    if (oldVersion < 5) {
  await db.execute('''
    CREATE TABLE app_settings (
      settingKey TEXT PRIMARY KEY,
      settingValue TEXT NOT NULL
    )
  ''');

  await db.insert(
    'app_settings',
    {
      'settingKey': 'themeMode',
      'settingValue': 'dark',
    },
  );

  await db.insert(
    'app_settings',
    {
      'settingKey': 'accentColor',
      'settingValue': 'purple',
    },
  );

  await db.insert(
    'app_settings',
    {
      'settingKey': 'animations',
      'settingValue': 'true',
    },
  );
}
  }

  // ==========================================================
  // USER PROFILE
  // ==========================================================

  Future<Map<String, dynamic>> getUserProfile() async {
    final Database db = await database;

    final List<Map<String, dynamic>> results =
        await db.query(
      'user_profile',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (results.isEmpty) {
      await db.insert(
        'user_profile',
        {
          'id': 1,
          'nickname': 'Closetly User',
          'gender': null,
        },
      );

      return {
        'id': 1,
        'nickname': 'Closetly User',
        'gender': null,
      };
    }

    return results.first;
  }

  Future<void> saveUserProfile({
    required String nickname,
    String? gender,
  }) async {
    final Database db = await database;

    await db.insert(
      'user_profile',
      {
        'id': 1,
        'nickname': nickname,
        'gender': gender,
      },
      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );
  }
// ==========================================================
  // APPEARANCE
  // ==========================================================
Future<Map<String, String>> getAppearanceSettings() async {
  final Database db = await database;

  final List<Map<String, dynamic>> rows =
      await db.query('app_settings');

  final Map<String, String> settings = {};

  for (final Map<String, dynamic> row in rows) {
    settings[row['settingKey'] as String] =
        row['settingValue'] as String;
  }

  return settings;
}

Future<void> saveAppearanceSetting({
  required String key,
  required String value,
}) async {
  final Database db = await database;

  await db.insert(
    'app_settings',
    {
      'settingKey': key,
      'settingValue': value,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
  // ==========================================================
  // AI MESSAGES
  // ==========================================================

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

  // ==========================================================
  // CLOSE DATABASE
  // ==========================================================

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}