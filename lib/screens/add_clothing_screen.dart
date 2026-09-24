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
  State<AddClothingScreen> createState() =>
      _AddClothingScreenState();
}

class _AddClothingScreenState
    extends State<AddClothingScreen> {
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
  final ImageSource? source =
      await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: const Color(0xFF151033),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24),
      ),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            16,
            20,
            24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A3C70),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Add Clothing Photo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Choose how you want to add your photo',
                style: TextStyle(
                  color: Color(0xFFAAA4C2),
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 20),

              // CAMERA
              ListTile(
                onTap: () {
                  Navigator.pop(
                    context,
                    ImageSource.camera,
                  );
                },
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                tileColor:
                    const Color(0xFF211642),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration:
                      const BoxDecoration(
                    color: Color(0xFF30205C),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFFB99AFF),
                  ),
                ),
                title: const Text(
                  'Take a Photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Use your camera',
                  style: TextStyle(
                    color: Color(0xFFAAA4C2),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // GALLERY
              ListTile(
                onTap: () {
                  Navigator.pop(
                    context,
                    ImageSource.gallery,
                  );
                },
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                tileColor:
                    const Color(0xFF211642),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration:
                      const BoxDecoration(
                    color: Color(0xFF30205C),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Color(0xFFB99AFF),
                  ),
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Select an existing photo',
                  style: TextStyle(
                    color: Color(0xFFAAA4C2),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (source == null) return;

  final XFile? image =
      await imagePicker.pickImage(
    source: source,
  );

  if (image == null) return;

  final Uint8List bytes =
      await image.readAsBytes();

  if (!mounted) return;

  setState(() {
    selectedImage = bytes;
  });
}
  Future<void> saveClothing() async {
    final String name =
        nameController.text.trim();

    if (name.isEmpty ||
        selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF211642),
          content: Text(
            'Please enter a clothing name and select a category',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      );
      return;
    }

    final String clothingId =
        widget.item?.id ??
            DateTime.now()
                .microsecondsSinceEpoch
                .toString();

    final ClothingItem item = ClothingItem(
      id: clothingId,
      name: name,
      category: selectedCategory!,
      color: selectedColor,
      imageBytes: selectedImage,
      imagePath: null,
    );

    if (!mounted) return;

    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08051F),

      appBar: AppBar(
        backgroundColor: const Color(0xFF100B31),
        foregroundColor: Colors.white,
        elevation: 0,

        title: Text(
          isEditing
              ? 'Edit Clothing'
              : 'Add Clothing',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
          ),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF12082F),
              Color(0xFF0B0623),
              Color(0xFF08051F),
            ],
          ),
        ),

        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            18,
            20,
            18,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // PAGE INTRO
              Text(
                isEditing
                    ? 'Update your clothing item'
                    : 'Add a new item to your wardrobe',
                style: const TextStyle(
                  color: Color(0xFFAAA4C2),
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 20),

              // PHOTO SECTION
              _buildSectionTitle(
                'Clothing Photo',
              ),

              const SizedBox(height: 10),

              GestureDetector(
                onTap: pickImage,
                child: Container(
                  width: double.infinity,
                  height: 270,
                  decoration: BoxDecoration(
                    color: const Color(0xFF151033),
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF30245A),
                      width: 1.2,
                    ),
                  ),
                  clipBehavior:
                      Clip.antiAlias,
                  child: selectedImage == null
                      ? _buildEmptyPhoto()
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(
                              selectedImage!,
                              fit: BoxFit.cover,
                            ),

                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: Container(
                                decoration:
                                    BoxDecoration(
                                  color: const Color(
                                    0xFF7C4DFF,
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(13),
                                ),
                                child: const Padding(
                                  padding:
                                      EdgeInsets.all(11),
                                  child: Icon(
                                    Icons
                                        .edit_rounded,
                                    color:
                                        Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // BASIC INFORMATION
              _buildSectionTitle(
                'Basic Information',
              ),

              const SizedBox(height: 12),

              // NAME
              _buildLabel('Clothing Name'),

              const SizedBox(height: 7),

              TextField(
                controller: nameController,
                style: const TextStyle(
                  color: Colors.white,
                ),
                cursorColor:
                    const Color(0xFFB99AFF),
                decoration: InputDecoration(
                  hintText:
                      'e.g. Black T-Shirt',
                  hintStyle: const TextStyle(
                    color: Color(0xFF6F6887),
                  ),
                  prefixIcon: const Icon(
                    Icons.checkroom_outlined,
                    color: Color(0xFF8A5CFF),
                  ),
                  filled: true,
                  fillColor:
                      const Color(0xFF151033),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color(0xFF29204F),
                    ),
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color(0xFF29204F),
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                    borderSide:
                        const BorderSide(
                      color: Color(0xFF7C4DFF),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // CATEGORY
              _buildLabel('Category'),

              const SizedBox(height: 7),

              DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              dropdownColor: const Color(0xFF151033),

              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),

              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFFAAA4C2),
              ),

              hint: const Text(
                'Select a category',
                style: TextStyle(
                  color: Color(0xFFAAA4C2),
                  fontSize: 14,
                ),
              ),

              decoration: _dropdownDecoration(
                Icons.category_outlined,
              ),

              items: categories.map(
                (String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  );
                },
              ).toList(),

              onChanged: (String? value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),
              const SizedBox(height: 18),

              // COLOR
              _buildLabel(
                'Color',
                optional: true,
              ),

              const SizedBox(height: 7),

              DropdownButtonFormField<String>(
              initialValue: selectedColor,
              dropdownColor: const Color(0xFF151033),

              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),

              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFFAAA4C2),
              ),

              hint: const Text(
                'Select a color',
                style: TextStyle(
                  color: Color(0xFFAAA4C2),
                  fontSize: 14,
                ),
              ),

              decoration: _dropdownDecoration(
                Icons.palette_outlined,
              ),

              items: colors.map(
                (String color) {
                  return DropdownMenuItem<String>(
                    value: color,
                    child: Text(
                      color,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  );
                },
              ).toList(),

              onChanged: (String? value) {
                setState(() {
                  selectedColor = value;
                });
              },
            ),

              const SizedBox(height: 30),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: saveClothing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF7C4DFF),
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        isEditing
                            ? Icons
                                .save_rounded
                            : Icons
                                .add_rounded,
                        size: 21,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isEditing
                            ? 'Save Changes'
                            : 'Save Clothing',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPhoto() {
    return Column(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: const BoxDecoration(
            color: Color(0xFF211642),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add_a_photo_outlined,
            color: Color(0xFFB99AFF),
            size: 31,
          ),
        ),

        const SizedBox(height: 14),

        const Text(
          'Add a clothing photo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Tap here to choose an image',
          style: TextStyle(
            color: Color(0xFFAAA4C2),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildLabel(
    String label, {
    bool optional = false,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFDDD8EB),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),

        if (optional) ...[
          const SizedBox(width: 5),
          const Text(
            '(Optional)',
            style: TextStyle(
              color: Color(0xFF6F6887),
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _dropdownDecoration(
  IconData icon,
) {
  return InputDecoration(
    prefixIcon: Icon(
      icon,
      color: const Color(0xFF8A5CFF),
    ),

    filled: true,

    fillColor: const Color(0xFF151033),

    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(
        color: Color(0xFF29204F),
      ),
    ),

    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(
        color: Color(0xFF29204F),
      ),
    ),

    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(
        color: Color(0xFF7C4DFF),
        width: 1.5,
      ),
    ),
  );
}
}