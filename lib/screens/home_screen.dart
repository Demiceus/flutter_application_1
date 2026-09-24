import 'package:flutter/material.dart';

import '../models/clothing_item.dart';
import '../services/local_wardrobe_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocalWardrobeService localWardrobeService =
      LocalWardrobeService();

  List<ClothingItem> recentItems = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadHomeData();
  }

  Future<void> loadHomeData() async {
    try {
      final List<ClothingItem> items =
          await localWardrobeService.getClothingItems();

      if (!mounted) return;

      setState(() {
        recentItems = items.take(4).toList();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> refreshHome() async {
    await loadHomeData();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    final Color background =
        theme.scaffoldBackgroundColor;

    final Color card =
        colors.surface;

    final Color secondaryCard =
        colors.surfaceContainerHighest;

    final Color border =
        colors.outlineVariant;

    final Color primaryText =
        colors.onSurface;

    final Color secondaryText =
        colors.onSurfaceVariant;

    final Color imageBackground =
        Color.alphaBlend(
      colors.primary.withValues(
        alpha: isDark ? 0.08 : 0.05,
      ),
      colors.surface,
    );

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refreshHome,
          color: colors.primary,
          backgroundColor: card,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isDark
                      ? Color.alphaBlend(
                          colors.primary.withValues(
                            alpha: 0.10,
                          ),
                          background,
                        )
                      : Color.alphaBlend(
                          colors.primary.withValues(
                            alpha: 0.035,
                          ),
                          background,
                        ),
                  background,
                  background,
                ],
              ),
            ),
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: colors.primary,
                    ),
                  )
                : SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      18,
                      18,
                      30,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _buildHeader(
                          primaryText: primaryText,
                          secondaryText: secondaryText,
                          card: secondaryCard,
                          border: border,
                          accent: colors.primary,
                        ),

                        const SizedBox(height: 24),

                        _buildWelcomeCard(
                          isDark: isDark,
                          primaryText: primaryText,
                          secondaryText: secondaryText,
                          card: card,
                          border: border,
                          accent: colors.primary,
                        ),

                        const SizedBox(height: 24),

                        _buildSectionTitle(
                          'Your Closet',
                          primaryText,
                        ),

                        const SizedBox(height: 12),

                        _buildClosetStats(
                          card: card,
                          border: border,
                          primaryText: primaryText,
                          secondaryText: secondaryText,
                          accent: colors.primary,
                        ),

                        const SizedBox(height: 24),

                        _buildSectionTitle(
                          'Closetly AI',
                          primaryText,
                        ),

                        const SizedBox(height: 12),

                        _buildAICard(
                          card: card,
                          border: border,
                          primaryText: primaryText,
                          secondaryText: secondaryText,
                          accent: colors.primary,
                          imageBackground:
                              imageBackground,
                        ),

                        const SizedBox(height: 24),

                        _buildSectionTitle(
                          'Recently Added',
                          primaryText,
                        ),

                        const SizedBox(height: 12),

                        _buildRecentItems(
                          card: card,
                          border: border,
                          primaryText: primaryText,
                          secondaryText: secondaryText,
                          accent: colors.primary,
                          imageBackground:
                              imageBackground,
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({
    required Color primaryText,
    required Color secondaryText,
    required Color card,
    required Color border,
    required Color accent,
  }) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.checkroom_rounded,
            color: ThemeData.estimateBrightnessForColor(
                      accent,
                    ) ==
                    Brightness.dark
                ? Colors.white
                : Colors.black,
            size: 25,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Closetly',
                style: TextStyle(
                  color: primaryText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Your personal wardrobe',
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard({
    required bool isDark,
    required Color primaryText,
    required Color secondaryText,
    required Color card,
    required Color border,
    required Color accent,
  }) {
    final Color welcomeStart =
        Color.alphaBlend(
      accent.withValues(
        alpha: isDark ? 0.22 : 0.08,
      ),
      card,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            welcomeStart,
            card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Color.alphaBlend(
                  accent.withValues(
                    alpha: 0.30,
                  ),
                  border,
                )
              : border,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(
              alpha: isDark ? 0.10 : 0.06,
            ),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back 👋',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Organize your wardrobe, discover new outfits, and let Closetly AI help you dress better.',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      accent.withValues(
                        alpha: isDark
                            ? 0.16
                            : 0.08,
                      ),
                      card,
                    ),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 8,
                        color: Color(0xFF56E39F),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'AI ready',
                        style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                accent.withValues(
                  alpha: isDark
                      ? 0.22
                      : 0.10,
                ),
                card,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: accent,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    Color primaryText,
  ) {
    return Text(
      title,
      style: TextStyle(
        color: primaryText,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildClosetStats({
    required Color card,
    required Color border,
    required Color primaryText,
    required Color secondaryText,
    required Color accent,
  }) {
    final int totalItems =
        recentItems.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStat(
              Icons.checkroom_rounded,
              '$totalItems',
              'Recent items',
              accent,
              primaryText,
              secondaryText,
            ),
          ),

          Container(
            width: 1,
            height: 45,
            color: border,
          ),

          Expanded(
            child: _buildStat(
              Icons.auto_awesome_rounded,
              'AI',
              'Stylist',
              accent,
              primaryText,
              secondaryText,
            ),
          ),

          Container(
            width: 1,
            height: 45,
            color: border,
          ),

          Expanded(
            child: _buildStat(
              Icons.cloud_off_rounded,
              'Local',
              'Storage',
              accent,
              primaryText,
              secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    IconData icon,
    String value,
    String label,
    Color accent,
    Color primaryText,
    Color secondaryText,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: accent,
          size: 23,
        ),

        const SizedBox(height: 7),

        Text(
          value,
          style: TextStyle(
            color: primaryText,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          label,
          style: TextStyle(
            color: secondaryText,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildAICard({
    required Color card,
    required Color border,
    required Color primaryText,
    required Color secondaryText,
    required Color accent,
    required Color imageBackground,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    accent.withValues(
                      alpha: 0.12,
                    ),
                    imageBackground,
                  ),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: accent,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your AI Stylist',
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Get outfit ideas from your closet',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: imageBackground,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tips_and_updates_outlined,
                  color: accent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ask Closetly what to wear for any occasion.',
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItems({
    required Color card,
    required Color border,
    required Color primaryText,
    required Color secondaryText,
    required Color accent,
    required Color imageBackground,
  }) {
    if (recentItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: card,
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: border,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.checkroom_outlined,
              color: accent,
              size: 42,
            ),

            const SizedBox(height: 10),

            Text(
              'Your wardrobe is empty',
              style: TextStyle(
                color: primaryText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Add your first clothing item to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryText,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount: recentItems.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final ClothingItem item =
            recentItems[index];

        return _buildRecentItemCard(
          item,
          card,
          border,
          primaryText,
          secondaryText,
          accent,
          imageBackground,
        );
      },
    );
  }

  Widget _buildRecentItemCard(
    ClothingItem item,
    Color card,
    Color border,
    Color primaryText,
    Color secondaryText,
    Color accent,
    Color imageBackground,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: imageBackground,
              child: item.imageBytes != null
                  ? Image.memory(
                      item.imageBytes!,
                      fit: BoxFit.cover,
                    )
                  : Center(
                      child: Icon(
                        Icons.checkroom_rounded,
                        color: accent,
                        size: 42,
                      ),
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
                    color: primaryText,
                    fontWeight:
                        FontWeight.w600,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  item.category,
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 12,
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