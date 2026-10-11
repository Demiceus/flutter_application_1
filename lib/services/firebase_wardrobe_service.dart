import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/clothing_item.dart';

class FirebaseWardrobeService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>
      get _clothingCollection {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('clothing');
  }

  Future<List<ClothingItem>> getClothingItems() async {
    final snapshot = await _clothingCollection
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      Uint8List? imageBytes;

      final imageBase64 = data['imageBase64'] as String?;

      if (imageBase64 != null && imageBase64.isNotEmpty) {
        try {
          imageBytes = base64Decode(imageBase64);
        } catch (_) {
          imageBytes = null;
        }
      }

      return ClothingItem(
        id: doc.id,
        name: data['name'] as String? ?? '',
        category: data['category'] as String? ?? '',
        color: data['color'] as String?,
        imageBytes: imageBytes,
      );
    }).toList();
  }

  Future<void> addClothing(ClothingItem item) async {
    String? imageBase64;

    if (item.imageBytes != null &&
        item.imageBytes!.isNotEmpty) {
      imageBase64 = base64Encode(item.imageBytes!);
    }

    await _clothingCollection.doc(item.id).set({
      'name': item.name,
      'category': item.category,
      'color': item.color,
      'imageBase64': imageBase64,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateClothing(ClothingItem item) async {
    String? imageBase64;

    if (item.imageBytes != null &&
        item.imageBytes!.isNotEmpty) {
      imageBase64 = base64Encode(item.imageBytes!);
    }

    await _clothingCollection.doc(item.id).update({
      'name': item.name,
      'category': item.category,
      'color': item.color,
      'imageBase64': imageBase64,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteClothing(String id) async {
    await _clothingCollection.doc(id).delete();
  }
}