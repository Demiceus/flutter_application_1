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
        .where((item) => item.category == category)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (context, index) {
          final String category = categories[index];
          final int count = getItemCount(category);

          return FilterChip(
            label: Text('$category ($count)'),
            selected: category == selectedCategory,
            onSelected: (_) {
              onCategoryChanged(category);
            },
          );
        },
      ),
    );
  }
}