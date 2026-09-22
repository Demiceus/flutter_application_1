import 'dart:typed_data';

class ClothingItem {
  final String id;
  final String name;
  final String category;
  final String? color;
  final Uint8List? imageBytes;

  ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    this.color,
    this.imageBytes,
  });
}