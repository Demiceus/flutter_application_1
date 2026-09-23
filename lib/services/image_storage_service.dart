import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ImageStorageService {
  Future<Directory> _getImageDirectory() async {
    final Directory appDirectory =
        await getApplicationDocumentsDirectory();

    final Directory imageDirectory = Directory(
      path.join(appDirectory.path, 'Closetly', 'images'),
    );

    if (!await imageDirectory.exists()) {
      await imageDirectory.create(
        recursive: true,
      );
    }

    return imageDirectory;
  }

  Future<String> saveImage({
    required String clothingId,
    required Uint8List imageBytes,
  }) async {
    final Directory imageDirectory =
        await _getImageDirectory();

    final String imagePath = path.join(
      imageDirectory.path,
      '$clothingId.jpg',
    );

    final File imageFile = File(imagePath);

    await imageFile.writeAsBytes(
      imageBytes,
      flush: true,
    );

    return imagePath;
  }

  Future<void> deleteImage(
    String? imagePath,
  ) async {
    if (imagePath == null || imagePath.isEmpty) {
      return;
    }

    final File imageFile = File(imagePath);

    if (await imageFile.exists()) {
      await imageFile.delete();
    }
  }
}