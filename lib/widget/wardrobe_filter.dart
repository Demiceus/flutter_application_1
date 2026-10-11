import 'package:flutter/material.dart';

import '../models/clothing_item.dart';

class WardrobeFilter extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final List<ClothingItem> clothingItems;

  const WardrobeFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.clothingItems,
  });

  static const List<String> categories = [
    'All',
    'Top',
    'Bottom',
    'Shoes',
    'Outerwear',
    'Accessories',
  ];

  int getItemCount(String category) {
    if (category == 'All') {
      return clothingItems.length;
    }

    return clothingItems
        .where(
          (item) => item.category == category,
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    final Color unselectedBackground = isDark
        ? const Color(0xFF151033)
        : colors.surfaceContainerHighest;

    final Color unselectedText = isDark
        ? const Color(0xFFAAA4C2)
        : colors.onSurfaceVariant;

    final Color borderColor = isDark
        ? const Color(0xFF29204F)
        : colors.outlineVariant;

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        itemCount: categories.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (context, index) {
          final String category =
              categories[index];

          final int count =
              getItemCount(category);

          final bool isSelected =
              category == selectedCategory;

          return FilterChip(
            label: Text(
              '$category ($count)',
            ),

            selected: isSelected,

            onSelected: (_) {
              onCategoryChanged(category);
            },

            backgroundColor:
                unselectedBackground,

            selectedColor:
                colors.primary.withValues(
              alpha: isDark ? 0.25 : 0.15,
            ),

            side: BorderSide(
              color: isSelected
                  ? colors.primary
                  : borderColor,
              width: isSelected ? 1.2 : 1,
            ),

            checkmarkColor:
                colors.primary,

            labelStyle: TextStyle(
              color: isSelected
                  ? colors.primary
                  : unselectedText,
              fontSize: 13,
              fontWeight: isSelected
                  ? FontWeight.w600
                  : FontWeight.w500,
            ),

            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(14),
            ),
          );
        },
      ),
    );
  }
}