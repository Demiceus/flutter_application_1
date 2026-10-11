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
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Clothing Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: editClothing,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: deleteClothing,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            Container(
              width: double.infinity,
              height: 420,
              margin: const EdgeInsets.all(16),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF151033)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: item.imageBytes != null
                  ? Image.memory(
                      item.imageBytes!,
                      fit: BoxFit.cover,
                    )
                  : Center(
                      child: Icon(
                        Icons.checkroom_outlined,
                        size: 100,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
            ),

            // DETAILS
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                4,
                20,
                30,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),

                  const SizedBox(height: 24),

                  _DetailCard(
                    icon: Icons.category_outlined,
                    label: 'Category',
                    value: item.category,
                  ),

                  const SizedBox(height: 12),

                  _DetailCard(
                    icon: Icons.palette_outlined,
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

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF151033)
            : colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: colors.onSurfaceVariant,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}