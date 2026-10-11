import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
// USER PROFILE - FIRESTORE
// ==========================================================

DocumentReference<Map<String, dynamic>>
    get _userProfileDocument {
  final User? user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception('User is not logged in.');
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('profile')
      .doc('info');
}

Future<Map<String, dynamic>> getUserProfile() async {
  final DocumentSnapshot<Map<String, dynamic>> snapshot =
      await _userProfileDocument.get();

  if (!snapshot.exists) {
    return {
      'nickname': 'Closetly User',
      'gender': null,
    };
  }

  final Map<String, dynamic> data =
      snapshot.data() ?? {};

  return {
    'nickname':
        data['nickname'] as String? ?? 'Closetly User',
    'gender':
        data['gender'] as String?,
  };
}

Future<void> saveUserProfile({
  required String nickname,
  String? gender,
}) async {
  await _userProfileDocument.set(
    {
      'nickname': nickname,
      'gender': gender,
      'updatedAt': Timestamp.now(),
    },
    SetOptions(merge: true),
  );
}
// ==========================================================
// APPEARANCE SETTINGS - FIRESTORE
// ==========================================================

CollectionReference<Map<String, dynamic>>
    get _appearanceSettingsCollection {
  final User? user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception('User is not logged in.');
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('settings');
}

Future<Map<String, String>> getAppearanceSettings() async {
  final QuerySnapshot<Map<String, dynamic>> snapshot =
      await _appearanceSettingsCollection.get();

  final Map<String, String> settings = {};

  for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
      in snapshot.docs) {
    final Map<String, dynamic> data = doc.data();

    final String? value = data['value'] as String?;

    if (value != null) {
      settings[doc.id] = value;
    }
  }

  // Default settings for new accounts.
  settings.putIfAbsent('themeMode', () => 'dark');
  settings.putIfAbsent('accentColor', () => 'purple');
  settings.putIfAbsent('animations', () => 'true');

  return settings;
}

Future<void> saveAppearanceSetting({
  required String key,
  required String value,
}) async {
  await _appearanceSettingsCollection
      .doc(key)
      .set({
        'value': value,
        'updatedAt': Timestamp.now(),
      });
}
// ==========================================================
// AI MESSAGES - FIRESTORE
// ==========================================================

CollectionReference<Map<String, dynamic>>
    get _aiMessagesCollection {
  final User? user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception('User is not logged in.');
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('ai_messages');
}

Future<void> saveAIMessage({
  required bool isUser,
  required String messageType,
  required String content,
}) async {
  await _aiMessagesCollection.add({
    'isUser': isUser,
    'messageType': messageType,
    'content': content,
    'createdAt': Timestamp.now(),
  });
}

Future<List<Map<String, dynamic>>> getAIMessages() async {
  final QuerySnapshot<Map<String, dynamic>> snapshot =
      await _aiMessagesCollection
          .orderBy('createdAt', descending: false)
          .get();

  return snapshot.docs.map((doc) {
    final Map<String, dynamic> data = doc.data();

    return {
      'id': doc.id,
      'isUser': data['isUser'] == true,
      'messageType':
          data['messageType'] as String? ?? 'text',
      'content':
          data['content'] as String? ?? '',
      'createdAt': data['createdAt'],
    };
  }).toList();
}

Future<void> clearAIMessages() async {
  final QuerySnapshot<Map<String, dynamic>> snapshot =
      await _aiMessagesCollection.get();

  final WriteBatch batch =
      FirebaseFirestore.instance.batch();

  for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
      in snapshot.docs) {
    batch.delete(doc.reference);
  }

  await batch.commit();
}
  // ==========================================================
// CLOTHING
// ==========================================================

Future<void> updateClothing({
  required String id,
  required String name,
  required String category,
  String? color,
  String? imagePath,
  Uint8List? imageData,
}) async {
  final Database db = await database;

  await db.update(
    'clothing',
    {
      'name': name,
      'category': category,
      'color': color,
      'imagePath': imagePath,
      'imageData': imageData,
    },
    where: 'id = ?',
    whereArgs: [id],
  );
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