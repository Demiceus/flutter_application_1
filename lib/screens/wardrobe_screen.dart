import 'package:flutter/material.dart';

import '../models/clothing_item.dart';
import '../widget/clothing_card.dart';
import '../widget/graph_paper_background.dart';
import '../widget/wardrobe_filter.dart';
import 'add_clothing_screen.dart';
import 'clothing_details_screen.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final List<ClothingItem> clothingItems = [
    ClothingItem(
      id: 'clothing_001',
      name: 'Baggy Pants Gray',
      category: 'Bottom',
      color: 'Gray',
    ),
    ClothingItem(
      id: 'clothing_002',
      name: 'Compression Shirt Black',
      category: 'Top',
      color: 'Black',
    ),
    ClothingItem(
      id: 'clothing_003',
      name: 'White Sneakers',
      category: 'Shoes',
      color: 'White',
    ),
  ];

  final TextEditingController searchController =
      TextEditingController();

  String selectedCategory = 'All';
  String searchQuery = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<ClothingItem> get filteredItems {
    return clothingItems.where((item) {
      final bool matchesCategory =
          selectedCategory == 'All' ||
          item.category == selectedCategory;

      final bool matchesSearch =
          searchQuery.isEmpty ||
          item.name.toLowerCase().contains(
                searchQuery.toLowerCase(),
              );

      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> addClothing() async {
    final ClothingItem? newItem =
        await Navigator.push<ClothingItem>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddClothingScreen(),
      ),
    );

    if (!mounted) return;

    if (newItem != null) {
      setState(() {
        clothingItems.add(newItem);
      });
    }
  }

  Future<void> openClothingDetails(
    ClothingItem item,
    int index,
  ) async {
    final ClothingDetailsResult? result =
        await Navigator.push<ClothingDetailsResult>(
      context,
      MaterialPageRoute(
        builder: (context) => ClothingDetailsScreen(
          item: item,
        ),
      ),
    );

    if (!mounted) return;

    if (result == null) return;

    if (result.deleted) {
      setState(() {
        clothingItems.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} deleted'),
        ),
      );

      return;
    }

    if (result.item != null) {
      setState(() {
        clothingItems[index] = result.item!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<ClothingItem> items = filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Closetly',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: GraphPaperBackground(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // SEARCH
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search clothing...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            searchController.clear();

                            setState(() {
                              searchQuery = '';
                            });
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // CATEGORY FILTER
            WardrobeFilter(
              selectedCategory: selectedCategory,
              onCategoryChanged: (category) {
                setState(() {
                  selectedCategory = category;
                });
              },
            ),

            const SizedBox(height: 12),

            // CLOTHING GRID
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        searchQuery.isNotEmpty
                            ? 'No clothing found'
                            : 'No items in this category',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.70,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final ClothingItem item = items[index];

                        // Find the actual index in the original list.
                        final int originalIndex =
                            clothingItems.indexOf(item);

                        return ClothingCard(
                          item: item,
                          onTap: () {
                            openClothingDetails(
                              item,
                              originalIndex,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: addClothing,
        child: const Icon(Icons.add),
      ),
    );
  }
}