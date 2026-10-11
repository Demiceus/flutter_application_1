import 'package:flutter/material.dart';

import '../models/clothing_item.dart';
import '../services/firebase_wardrobe_service.dart';
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
  State<WardrobeScreen> createState() => WardrobeScreenState();
}

class WardrobeScreenState extends State<WardrobeScreen> {
 final FirebaseWardrobeService wardrobeService =
    FirebaseWardrobeService();

  List<ClothingItem> clothingItems = [];

  final TextEditingController searchController =
      TextEditingController();

  String selectedCategory = 'All';
  String searchQuery = '';

  bool isLoading = true;

  @override
  void initState() {
  super.initState();
  refreshWardrobe();
}

// LOAD FROM LOCAL DATABASE
  Future<void> refreshWardrobe() async {
  try {
    final List<ClothingItem> items =
        await wardrobeService.getClothingItems();

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
        await wardrobeService.addClothing(newItem);

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
        wardrobeService.deleteClothing(item.id);

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
        wardrobeService.updateClothing(result.item!);

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

  final ThemeData theme = Theme.of(context);
  final ColorScheme colors = theme.colorScheme;
  final bool isDark = theme.brightness == Brightness.dark;

  final Color pageBackground = isDark
      ? const Color(0xFF08051F)
      : colors.surface;

  final Color appBarBackground = isDark
      ? const Color(0xFF100B31)
      : colors.surface;

  final Color searchBackground = isDark
      ? const Color(0xFF151033)
      : colors.surfaceContainerHighest;

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
        'Closetly',
        style: TextStyle(
          color: colors.onSurface,
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
                color: colors.primary.withValues(
                  alpha: isDark ? 0.22 : 0.12,
                ),
              ),
              child: Icon(
                Icons.auto_awesome,
                color: colors.primary,
                size: 21,
              ),
            ),
          ),
        ),
      ],
    ),

    body: Container(
      color: pageBackground,

      child: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colors.primary,
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
                    style: TextStyle(
                      color: colors.onSurface,
                    ),
                    cursorColor: colors.primary,
                    decoration: InputDecoration(
                      hintText: 'Search clothing...',
                      hintStyle: TextStyle(
                        color: secondaryText,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: secondaryText,
                      ),
                      suffixIcon:
                          searchQuery.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    searchController.clear();

                                    setState(() {
                                      searchQuery = '';
                                    });
                                  },
                                  icon: Icon(
                                    Icons.clear,
                                    color: secondaryText,
                                  ),
                                )
                              : null,
                      filled: true,
                      fillColor: searchBackground,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: colors.primary,
                          width: 1.5,
                        ),
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
                            style: TextStyle(
                              color: secondaryText,
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
                          itemBuilder:
                              (context, index) {
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
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      child: const Icon(Icons.add),
    ),
  );
}
}