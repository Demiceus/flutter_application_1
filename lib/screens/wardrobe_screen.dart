import 'package:flutter/material.dart';

import '../models/clothing_item.dart';
import '../services/local_wardrobe_service.dart';
import '../widget/clothing_card.dart';
import '../widget/wardrobe_filter.dart';
import 'add_clothing_screen.dart';
import 'clothing_details_screen.dart';

class WardrobeScreen extends StatefulWidget {
  final VoidCallback? onOpenAI;

  const WardrobeScreen({
    super.key,
    this.onOpenAI,
  });

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
 final LocalWardrobeService localWardrobeService =
    LocalWardrobeService();

  List<ClothingItem> clothingItems = [];

  final TextEditingController searchController =
      TextEditingController();

  String selectedCategory = 'All';
  String searchQuery = '';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadClothing();
  }

// LOAD FROM LOCAL DATABASE
  Future<void> loadClothing() async {
    try {
      final List<ClothingItem> items =
    await localWardrobeService.getClothingItems();

      if (!mounted) return;

      setState(() {
        clothingItems = items;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load wardrobe: $e',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // SEARCH + CATEGORY FILTER
  List<ClothingItem> get filteredItems {
  return clothingItems.where((item) {
    final bool matchesCategory =
        selectedCategory == 'All' ||
        item.category == selectedCategory;

    final String query = searchQuery.toLowerCase();

    final bool matchesSearch =
        query.isEmpty ||
        item.name.toLowerCase().contains(query) ||
        item.category.toLowerCase().contains(query) ||
        (item.color?.toLowerCase().contains(query) ?? false);

    return matchesCategory && matchesSearch;
  }).toList();
}

  // ADD CLOTHING
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
      try {
        await localWardrobeService.addClothing(newItem);

        if (!mounted) return;

        setState(() {
          clothingItems.add(newItem);
        });
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save clothing: $e',
            ),
          ),
        );
      }
    }
  }

  // OPEN DETAILS
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

    // DELETE
    if (result.deleted) {
      try {
        await localWardrobeService.deleteClothing(
          item.id,
        );

        if (!mounted) return;

        setState(() {
          clothingItems.removeAt(index);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${item.name} deleted',
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete clothing: $e',
            ),
          ),
        );
      }

      return;
    }

    // EDIT
    if (result.item != null) {
      try {
        await localWardrobeService.updateClothing(
          result.item!,
        );

        if (!mounted) return;

        setState(() {
          clothingItems[index] = result.item!;
        });
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update clothing: $e',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<ClothingItem> items = filteredItems;

    return Scaffold(
      appBar: AppBar(
      backgroundColor: const Color(0xFF100B31),
      foregroundColor: Colors.white,

      title: const Text(
        'Closetly',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: widget.onOpenAI,
              tooltip: 'Closetly AI',
              icon: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple.shade100,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.deepPurple,
                  size: 21,
                ),
              ),
            ),
          ),
        ],
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
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF8A5CFF),
                        ),
                      )
                    : Column(
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
                          borderRadius:
                              BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // CATEGORY FILTER
                  WardrobeFilter(
                    selectedCategory: selectedCategory,
                    clothingItems: clothingItems,
                    onCategoryChanged: (category) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  // GRID
                  Expanded(
                    child: items.isEmpty
                        ? Center(
                          child: Text(
                            searchQuery.isNotEmpty
                                ? 'No clothing found'
                                : 'No items in this category',
                            style: const TextStyle(
                              color: Color(0xFFAAA4C2),
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
                              final ClothingItem item =
                                  items[index];

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