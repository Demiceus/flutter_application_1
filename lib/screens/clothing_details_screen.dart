import 'package:flutter/material.dart';

import '../models/clothing_item.dart';
import 'add_clothing_screen.dart';

class ClothingDetailsResult {
  final ClothingItem? item;
  final bool deleted;

  const ClothingDetailsResult({
    this.item,
    this.deleted = false,
  });
}

class ClothingDetailsScreen extends StatefulWidget {
  final ClothingItem item;

  const ClothingDetailsScreen({
    super.key,
    required this.item,
  });

  @override
  State<ClothingDetailsScreen> createState() =>
      _ClothingDetailsScreenState();
}

class _ClothingDetailsScreenState
    extends State<ClothingDetailsScreen> {

  Future<void> editClothing() async {
    final ClothingItem? updatedItem =
        await Navigator.push<ClothingItem>(
      context,
      MaterialPageRoute(
        builder: (context) => AddClothingScreen(
          item: widget.item,
        ),
      ),
    );

    if (!mounted) return;

    if (updatedItem != null) {
      Navigator.pop(
        context,
        ClothingDetailsResult(
          item: updatedItem,
        ),
      );
    }
  }

  Future<void> deleteClothing() async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Clothing?'),

          content: Text(
            'Are you sure you want to delete '
            '"${widget.item.name}"?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (confirmDelete == true) {
      Navigator.pop(
        context,
        const ClothingDetailsResult(
          deleted: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ClothingItem item = widget.item;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clothing Details'),

        actions: [
          // EDIT
          IconButton(
            onPressed: editClothing,
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
          ),

          // DELETE
          IconButton(
            onPressed: deleteClothing,
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PHOTO
            SizedBox(
              width: double.infinity,
              height: 420,
              child: item.imageBytes != null
                  ? Image.memory(
                      item.imageBytes!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.checkroom,
                        size: 100,
                        color: Colors.grey,
                      ),
                    ),
            ),

            // DETAILS
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  _DetailRow(
                    label: 'Category',
                    value: item.category,
                  ),

                  const SizedBox(height: 12),

                  _DetailRow(
                    label: 'Color',
                    value: item.color ?? 'Not specified',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 15,
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}