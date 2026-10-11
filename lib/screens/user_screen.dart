  import 'package:flutter/material.dart';

  import '../services/database_service.dart';
  import 'appearance_screen.dart';
  import 'profile_screen.dart';

  class UserScreen extends StatefulWidget {
    const UserScreen({super.key});

    @override
    State<UserScreen> createState() => _UserScreenState();
  }

  class _UserScreenState extends State<UserScreen> {
    String nickname = 'Closetly User';

    @override
    void initState() {
      super.initState();
      loadProfile();
    }

    Future<void> loadProfile() async {
      final Map<String, dynamic> profile =
          await DatabaseService.instance.getUserProfile();

      if (!mounted) return;

      setState(() {
        nickname =
            profile['nickname'] as String? ??
            'Closetly User';
      });
    }

    Future<void> openProfile() async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfileScreen(),
        ),
      );

      if (result == true) {
        await loadProfile();
      }
    }

    @override
    Widget build(BuildContext context) {
      final ThemeData theme = Theme.of(context);
      final ColorScheme colors = theme.colorScheme;

      final bool isDark =
          theme.brightness == Brightness.dark;

      final Color pageBackground = isDark
          ? const Color(0xFF08051F)
          : colors.surface;

      final Color cardBackground = isDark
          ? const Color(0xFF151033)
          : colors.surfaceContainerHighest;

      final Color borderColor = isDark
          ? const Color(0xFF29204F)
          : colors.outlineVariant;

      final Color secondaryText = isDark
          ? const Color(0xFFAAA4C2)
          : colors.onSurfaceVariant;

      final Color iconBackground = isDark
          ? const Color(0xFF211642)
          : colors.primaryContainer;

      return Scaffold(
        backgroundColor: pageBackground,
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF12082F),
                        Color(0xFF0B0623),
                        Color(0xFF08051F),
                      ],
                    )
                  : null,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                18,
                20,
                18,
                30,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: colors.onPrimary,
                          size: 27,
                        ),
                      ),

                      const SizedBox(width: 13),

                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile',
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 24,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            'Manage your Closetly',
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // PROFILE CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius:
                          BorderRadius.circular(22),
                      border: Border.all(
                        color: borderColor,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colors.primary.withValues(
                                  alpha: 0.85,
                                ),
                                colors.primary.withValues(
                                  alpha: 0.55,
                                ),
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            color: colors.onPrimary,
                            size: 43,
                          ),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          nickname,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 19,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          'Your wardrobe profile',
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 18),

                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: iconBackground,
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.circle,
                                color: Color(0xFF56E39F),
                                size: 8,
                              ),

                              const SizedBox(width: 7),

                              Text(
                                'Local profile',
                                style: TextStyle(
                                  color:
                                      colors.primary,
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

                  const SizedBox(height: 24),

                  // SETTINGS TITLE
                  Text(
                    'Settings',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // PROFILE
                  _buildSettingCard(
                    icon: Icons.person_outline_rounded,
                    title: 'Profile',
                    subtitle:
                        'Manage your profile information',
                    onTap: openProfile,
                  ),

                  const SizedBox(height: 10),

                  // APPEARANCE
                  _buildSettingCard(
                    icon: Icons.palette_outlined,
                    title: 'Appearance',
                    subtitle:
                        'Customize your Closetly experience',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AppearanceScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ABOUT TITLE
                  Text(
                    'About',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ABOUT CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius:
                          BorderRadius.circular(18),
                      border: Border.all(
                        color: borderColor,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: colors.primary,
                            ),

                            const SizedBox(width: 10),

                            Text(
                              'Closetly',
                              style: TextStyle(
                                color:
                                    colors.onSurface,
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Text(
                          'Your personal wardrobe assistant.',
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            color: secondaryText.withValues(
                              alpha: 0.65,
                            ),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget _buildSettingCard({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      final ThemeData theme = Theme.of(context);
      final ColorScheme colors = theme.colorScheme;

      final bool isDark =
          theme.brightness == Brightness.dark;

      final Color cardBackground = isDark
          ? const Color(0xFF151033)
          : colors.surfaceContainerHighest;

      final Color borderColor = isDark
          ? const Color(0xFF29204F)
          : colors.outlineVariant;

      final Color iconBackground = isDark
          ? const Color(0xFF211642)
          : colors.primaryContainer;

      final Color secondaryText = isDark
          ? const Color(0xFFAAA4C2)
          : colors.onSurfaceVariant;

      return Material(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: colors.primary,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        subtitle,
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.chevron_right_rounded,
                  color: secondaryText,
                ),
              ],
            ),
          ),
        ),
      );
    }
  }