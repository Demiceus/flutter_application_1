import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/clothing_item.dart';

class AddClothingScreen extends StatefulWidget {
  final ClothingItem? item;

  const AddClothingScreen({
    super.key,
    this.item,
  });

  @override
  State<AddClothingScreen> createState() => _AddClothingScreenState();
}

class _AddClothingScreenState extends State<AddClothingScreen> {
  final nameController = TextEditingController();

  Uint8List? selectedImage;

  String? selectedCategory;
  String? selectedColor;

  final ImagePicker imagePicker = ImagePicker();

  final List<String> categories = [
    'Top',
    'Bottom',
    'Shoes',
    'Outerwear',
    'Accessories',
  ];

  final List<String> colors = [
    'Black',
    'White',
    'Gray',
    'Red',
    'Blue',
    'Green',
    'Yellow',
    'Orange',
    'Purple',
    'Pink',
    'Brown',
    'Beige',
    'Navy',
  ];

  bool get isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();

    if (widget.item != null) {
      nameController.text = widget.item!.name;
      selectedCategory = widget.item!.category;
      selectedColor = widget.item!.color;
      selectedImage = widget.item!.imageBytes;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final XFile? image = await imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) return;

    final Uint8List bytes = await image.readAsBytes();

    if (!mounted) return;

    setState(() {
      selectedImage = bytes;
    });
  }

  void saveClothing() {
    final String name = nameController.text.trim();

    if (name.isEmpty || selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a clothing name and select a category',
          ),
        ),
      );
      return;
    }

    final ClothingItem item = ClothingItem(
      id: widget.item?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      category: selectedCategory!,
      color: selectedColor,
      imageBytes: selectedImage,
    );

    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Clothing' : 'Add Clothing',
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            // PHOTO
            GestureDetector(
              onTap: pickImage,
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: selectedImage == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 50,
                          ),
                          SizedBox(height: 10),
                          Text('Tap to add photo'),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          selectedImage!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // NAME
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Clothing Name',
                hintText: 'e.g. Black T-Shirt',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // CATEGORY
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // COLOR
            DropdownButtonFormField<String>(
              initialValue: selectedColor,
              decoration: const InputDecoration(
                labelText: 'Color (Optional)',
                hintText: 'Select a color',
                border: OutlineInputBorder(),
              ),
              items: colors.map((String color) {
                return DropdownMenuItem<String>(
                  value: color,
                  child: Text(color),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  selectedColor = value;
                });
              },
            ),

            const SizedBox(height: 24),

            // SAVE
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: saveClothing,
                child: Text(
                  isEditing ? 'Save Changes' : 'Save Clothing',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}