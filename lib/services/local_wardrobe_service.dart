import 'package:sqflite/sqflite.dart';
import 'dart:typed_data';
import '../models/clothing_item.dart';
import 'database_service.dart';

class LocalWardrobeService {
  final DatabaseService _databaseService =
      DatabaseService.instance;

  Future<List<ClothingItem>> getClothingItems() async {
    final Database db = await _databaseService.database;

    final List<Map<String, dynamic>> maps =
        await db.query(
      'clothing',
      orderBy: 'rowid DESC',
    );

    return maps.map((map) {
      return ClothingItem(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      color: map['color'] as String?,
      imagePath: map['imagePath'] as String?,
      imageBytes: map['imageData'] != null
          ? Uint8List.fromList(
              (map['imageData'] as List).cast<int>(),
            )
          : null,
    );
    }).toList();
  }

  Future<void> addClothing(
    ClothingItem item,
  ) async {
    final Database db = await _databaseService.database;

    await db.insert(
    'clothing',
    {
      'id': item.id,
      'name': item.name,
      'category': item.category,
      'color': item.color,
      'imagePath': item.imagePath,
      'imageData': item.imageBytes,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
  }

  Future<void> updateClothing(
    ClothingItem item,
  ) async {
    final Database db = await _databaseService.database;

    await db.update(
    'clothing',
    {
      'name': item.name,
      'category': item.category,
      'color': item.color,
      'imagePath': item.imagePath,
      'imageData': item.imageBytes,
    },
    where: 'id = ?',
    whereArgs: [item.id],
  );
  }

  Future<void> deleteClothing(
    String id,
  ) async {
    final Database db = await _databaseService.database;

    await db.delete(
      'clothing',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}