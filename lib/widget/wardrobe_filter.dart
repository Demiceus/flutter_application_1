import 'package:flutter/material.dart';

class WardrobeFilter extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  const WardrobeFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  static const List<String> categories = [
    'All',
    'Top',
    'Bottom',
    'Shoes',
    'Outerwear',
    'Accessories',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final bool isSelected = category == selectedCategory;

          return FilterChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) {
              onCategoryChanged(category);
            },
          );
        },
      ),
    );
  }
}