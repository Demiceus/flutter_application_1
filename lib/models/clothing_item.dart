import 'dart:typed_data';

class ClothingItem {
  final String id;
  final String name;
  final String category;
  final String? color;
  final Uint8List? imageBytes;
  final String? imagePath;

  ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    this.color,
    this.imageBytes,
    this.imagePath,
  });

  ClothingItem copyWith({
    String? id,
    String? name,
    String? category,
    String? color,
    Uint8List? imageBytes,
    String? imagePath,
  }) {
    return ClothingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      color: color ?? this.color,
      imageBytes: imageBytes ?? this.imageBytes,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}