import 'package:flutter/material.dart';

import '../models/clothing_item.dart';

class ClothingCard extends StatelessWidget {
  final ClothingItem item;
  final VoidCallback onTap;

  const ClothingCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    final Color cardColor = isDark
        ? const Color(0xFF151033)
        : colors.surface;

    final Color secondaryText = isDark
        ? const Color(0xFFAAA4C2)
        : colors.onSurfaceVariant;

    final Color emptyImageBackground = isDark
        ? const Color(0xFF211642)
        : colors.surfaceContainerHighest;

    final Color emptyImageIcon = isDark
        ? const Color(0xFFAAA4C2)
        : colors.onSurfaceVariant;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isDark ? 3 : 2,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark
            ? const BorderSide(
                color: Color(0xFF29204F),
              )
            : BorderSide(
                color: colors.outlineVariant,
              ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              child: item.imageBytes != null
                  ? Image.memory(
                      item.imageBytes!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: double.infinity,
                      color: emptyImageBackground,
                      child: Icon(
                        Icons.checkroom,
                        size: 60,
                        color: emptyImageIcon,
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    item.category,
                    style: TextStyle(
                      fontSize: 13,
                      color: secondaryText,
                    ),
                  ),

                  if (item.color != null) ...[
                    const SizedBox(height: 3),

                    Text(
                      item.color!,
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}