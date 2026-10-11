import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../models/clothing_item.dart';
import '../services/ai_service.dart';
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
class _CustomColorDialog extends StatefulWidget {
  final String initialColor;
  final ColorScheme colors;

  const _CustomColorDialog({
    required this.initialColor,
    required this.colors,
  });

  @override
  State<_CustomColorDialog> createState() =>
      _CustomColorDialogState();
}

class _CustomColorDialogState
    extends State<_CustomColorDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController(
      text: widget.initialColor,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = widget.colors;

    return AlertDialog(
      title: const Text(
        'Custom Color',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: 'e.g. Burgundy',
          prefixIcon: Icon(
            Icons.palette_outlined,
            color: colors.primary,
          ),
          filled: true,
          fillColor:
              colors.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: colors.primary,
              width: 1.5,
            ),
          ),
        ),
        onSubmitted: (value) {
          final String trimmed = value.trim();

          if (trimmed.isEmpty) return;

          Navigator.of(context).pop(trimmed);
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final String value =
                controller.text.trim();

            if (value.isEmpty) return;

            Navigator.of(context).pop(value);
          },
          child: const Text('Use Color'),
        ),
      ],
    );
  }
}

class _AddClothingScreenState
    extends State<AddClothingScreen> {
  final TextEditingController nameController =
      TextEditingController();

  Uint8List? selectedImage;

  String? selectedCategory;
  String? selectedColor;

  final ImagePicker imagePicker = ImagePicker();

  final AIService aiService = AIService();

  bool isAnalyzingImage = false;


  
  final List<String> categories = [
    'Top',
    'Bottom',
    'Shoes',
    'Outerwear',
    'Accessories',
  ];

final List<String> clothingColors = [
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


  void saveClothing() {
    final String name = nameController.text.trim();

    if (name.isEmpty || selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the clothing details.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final ClothingItem item = ClothingItem(
      id: widget.item?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      category: selectedCategory!,
      color: selectedColor,
      imagePath: widget.item?.imagePath,
      imageBytes: selectedImage,
    );

    Navigator.pop(context, item);
  }

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

 Future<void> _showCustomColorDialog() async {
  final ColorScheme colors =
      Theme.of(context).colorScheme;

  final String? customColor =
      await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return _CustomColorDialog(
        initialColor:
            selectedColor != null &&
                    !clothingColors.contains(selectedColor)
                ? selectedColor!
                : '',
        colors: colors,
      );
    },
  );

  if (!mounted) return;

  if (customColor == null ||
      customColor.trim().isEmpty) {
    return;
  }

  setState(() {
    selectedColor = customColor.trim();
  });
}

  Future<void> pickImage() async {
  if (isAnalyzingImage) return;

  final ThemeData theme = Theme.of(context);
  final ColorScheme colors = theme.colorScheme;

  final ImageSource? source =
      await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24),
      ),
    ),
    builder: (sheetContext) {
      final ThemeData sheetTheme =
          Theme.of(sheetContext);

      final ColorScheme sheetColors =
          sheetTheme.colorScheme;

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
                  color: sheetColors.outlineVariant,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Add Clothing Photo',
                style: TextStyle(
                  color: sheetColors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Choose how you want to add your photo',
                style: TextStyle(
                  color:
                      sheetColors.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 20),

              ListTile(
                onTap: () {
                  Navigator.pop(
                    sheetContext,
                    ImageSource.camera,
                  );
                },
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                tileColor:
                    sheetColors.surfaceContainerHighest,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: sheetColors.primary
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: sheetColors.primary,
                  ),
                ),
                title: Text(
                  'Take a Photo',
                  style: TextStyle(
                    color:
                        sheetColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Use your camera',
                  style: TextStyle(
                    color:
                        sheetColors.onSurfaceVariant,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              ListTile(
                onTap: () {
                  Navigator.pop(
                    sheetContext,
                    ImageSource.gallery,
                  );
                },
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                tileColor:
                    sheetColors.surfaceContainerHighest,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: sheetColors.primary
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: sheetColors.primary,
                  ),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    color:
                        sheetColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Select an existing photo',
                  style: TextStyle(
                    color:
                        sheetColors.onSurfaceVariant,
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

  try {
    final Uint8List originalBytes =
        await image.readAsBytes();

    final Uint8List compressedBytes =
        await FlutterImageCompress.compressWithList(
      originalBytes,
      minWidth: 1280,
      minHeight: 1280,
      quality: 75,
      format: CompressFormat.jpeg,
    );

    if (compressedBytes.isEmpty) {
      return;
    }

    if (!mounted) return;

    setState(() {
      selectedImage = compressedBytes;
      isAnalyzingImage = true;
    });

    // Automatically analyze the clothing photo.
    await _analyzeClothingImage(
      compressedBytes,
    );
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isAnalyzingImage = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to process this image.',
        ),
      ),
    );
  }
}

Future<void> _analyzeClothingImage(
  Uint8List imageBytes,
) async {
  try {
    final String base64Data =
        base64Encode(imageBytes);

    // We compress to JPEG above, so the MIME type
    // is always image/jpeg here.
    final String imageDataUrl =
        'data:image/jpeg;base64,$base64Data';

    final Map<String, dynamic> result =
        await aiService.analyzeClothingImage(
      imageBase64: imageDataUrl,
    );

    if (!mounted) return;

    final bool isClothing =
        result['is_clothing'] == true;

    // --------------------------------------------------
    // INVALID IMAGE
    // --------------------------------------------------

    if (!isClothing) {
      setState(() {
        selectedImage = null;
        isAnalyzingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
              Theme.of(context).colorScheme.inverseSurface,
          content: Text(
            "This isn't a valid clothing image.\n"
            "Please take a clear photo of a clothing item.",
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onInverseSurface,
            ),
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );

      return;
    }

    // --------------------------------------------------
    // READ AI RESULT
    // --------------------------------------------------

    final String name =
        result['name']?.toString().trim() ?? '';

    final String category =
        result['category']
                ?.toString()
                .trim() ??
            '';

    final String color =
        result['color']?.toString().trim() ?? '';

    // --------------------------------------------------
    // INVALID / INCOMPLETE RESULT
    // --------------------------------------------------

    if (name.isEmpty ||
        category.isEmpty ||
        color.isEmpty) {
      setState(() {
        selectedImage = null;
        isAnalyzingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "I couldn't identify the clothing clearly. "
            "Please take a clearer photo and try again.",
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );

      return;
    }

    // --------------------------------------------------
    // AUTO-FILL FORM
    // --------------------------------------------------

    setState(() {
      nameController.text = name;

      selectedCategory = categories.contains(
        category,
      )
          ? category
          : null;

      // This intentionally accepts ANY color.
      // Therefore custom colors are preserved.
      selectedColor = color;

      isAnalyzingImage = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'AI filled in the clothing details. '
          'You can edit them before saving.',
        ),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isAnalyzingImage = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to analyze the clothing photo. '
          'You can enter the details manually.',
        ),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
        Theme.of(context);

    final ColorScheme colors =
        theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    final Color pageBackground = isDark
        ? const Color(0xFF08051F)
        : colors.surface;

    final Color appBarBackground = isDark
        ? const Color(0xFF100B31)
        : colors.surface;

    final Color cardBackground = isDark
        ? const Color(0xFF151033)
        : colors.surfaceContainerHighest;

    final Color secondaryBackground = isDark
        ? const Color(0xFF211642)
        : colors.surfaceContainer;

    final Color secondaryText = isDark
        ? const Color(0xFFAAA4C2)
        : colors.onSurfaceVariant;

    return Scaffold(
      backgroundColor: pageBackground,

      appBar: AppBar(
        backgroundColor: appBarBackground,
        foregroundColor: colors.onSurface,
        elevation: 0,

        title: Text(
          isEditing
              ? 'Edit Clothing'
              : 'Add Clothing',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colors.onSurface,
          ),
        ),
      ),

      body: SingleChildScrollView(
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
            Text(
              isEditing
                  ? 'Update your clothing item'
                  : 'Add a new item to your wardrobe',
              style: TextStyle(
                color: secondaryText,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 20),

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
                  color: cardBackground,
                  borderRadius:
                      BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.outlineVariant,
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

                      if (isAnalyzingImage)
                        Container(
                          color: Colors.black54,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: colors.primary,
                                ),

                                const SizedBox(height: 12),

                                Text(
                                  'AI is analyzing your clothing...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      if (!isAnalyzingImage)
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius:
                                  BorderRadius.circular(13),
                            ),
                            padding:
                                const EdgeInsets.all(11),
                            child: Icon(
                              Icons.edit_rounded,
                              color: colors.onPrimary,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
              ),
            ),

            const SizedBox(height: 24),

            _buildSectionTitle(
              'Basic Information',
            ),

            const SizedBox(height: 12),

            _buildLabel('Clothing Name'),

            const SizedBox(height: 7),

            TextField(
              controller: nameController,
              style: TextStyle(
                color: colors.onSurface,
              ),
              cursorColor: colors.primary,
              decoration: InputDecoration(
                hintText:
                    'e.g. Black T-Shirt',
                hintStyle: TextStyle(
                  color: secondaryText,
                ),
                prefixIcon: Icon(
                  Icons.checkroom_outlined,
                  color: colors.primary,
                ),
                filled: true,
                fillColor: cardBackground,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color:
                        colors.outlineVariant,
                  ),
                ),
                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color:
                        colors.outlineVariant,
                  ),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: colors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            _buildLabel('Category'),

            const SizedBox(height: 7),

            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              dropdownColor: cardBackground,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 14,
              ),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: secondaryText,
              ),
              hint: Text(
                'Select a category',
                style: TextStyle(
                  color: secondaryText,
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
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  );
                },
              ).toList(),
              onChanged: (String? value) {
                if (!mounted) return;

                setState(() {
                  selectedCategory = value;
                });
              },
            ),

            const SizedBox(height: 18),

            _buildLabel(
              'Color',
              optional: true,
            ),

            const SizedBox(height: 7),

            DropdownButtonFormField<String>(
              initialValue:
                  clothingColors.contains(selectedColor)
                      ? selectedColor
                      : null,
              dropdownColor: cardBackground,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 14,
              ),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: secondaryText,
              ),
              hint: Text(
                'Select a color',
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 14,
                ),
              ),
              decoration: _dropdownDecoration(
                Icons.palette_outlined,
              ),
              items: clothingColors.map(
                (String color) {
                  return DropdownMenuItem<String>(
                    value: color,
                    child: Text(
                      color,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  );
                },
              ).toList(),
              onChanged: (String? value) {
                if (!mounted) return;

                setState(() {
                  selectedColor = value;
                });
              },
            ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showCustomColorDialog,
              icon: const Icon(
                Icons.palette_outlined,
              ),
              label: const Text(
                'Use Custom Color',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primary,
                side: BorderSide(
                  color: colors.outlineVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
              ),
            ),
          ),

          if (selectedColor != null &&
              !clothingColors.contains(selectedColor)) ...[
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: secondaryBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      selectedColor!,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: _showCustomColorDialog,
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed:
                  isAnalyzingImage ? null : saveClothing,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  if (isAnalyzingImage)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onPrimary,
                      ),
                    )
                  else
                    Icon(
                      isEditing
                          ? Icons.save_rounded
                          : Icons.add_rounded,
                      size: 21,
                    ),

                  const SizedBox(width: 8),

                  Text(
                    isAnalyzingImage
                        ? 'Analyzing...'
                        : isEditing
                            ? 'Save Changes'
                            : 'Save Clothing',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }



  Widget _buildEmptyPhoto() {
    final ThemeData theme =
        Theme.of(context);

    final ColorScheme colors =
        theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    return Column(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: colors.primary
                .withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.add_a_photo_outlined,
            color: colors.primary,
            size: 31,
          ),
        ),

        const SizedBox(height: 14),

        Text(
          'Add a clothing photo',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          'Tap here to choose an image',
          style: TextStyle(
            color: isDark
                ? const Color(0xFFAAA4C2)
                : colors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Text(
      title,
      style: TextStyle(
        color: colors.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildLabel(
    String label, {
    bool optional = false,
  }) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),

        if (optional) ...[
          const SizedBox(width: 5),
          Text(
            '(Optional)',
            style: TextStyle(
              color:
                  colors.onSurfaceVariant,
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
    final ThemeData theme =
        Theme.of(context);

    final ColorScheme colors =
        theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    final Color fieldBackground = isDark
        ? const Color(0xFF151033)
        : colors.surfaceContainerHighest;

    return InputDecoration(
      prefixIcon: Icon(
        icon,
        color: colors.primary,
      ),
      filled: true,
      fillColor: fieldBackground,
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide: BorderSide(
          color: colors.outlineVariant,
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide: BorderSide(
          color: colors.outlineVariant,
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide: BorderSide(
          color: colors.primary,
          width: 1.5,
        ),
      ),
    );
  }
}