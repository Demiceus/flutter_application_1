import 'package:flutter/material.dart';

import '../services/appearance_service.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() =>
      _AppearanceScreenState();
}

class _AppearanceScreenState
    extends State<AppearanceScreen> {
  final AppearanceService appearanceService =
      AppearanceService.instance;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appearanceService,
      builder: (context, _) {
        final ThemeData theme = Theme.of(context);
        final Color accent = appearanceService.accent;
        final bool isDark =
            theme.brightness == Brightness.dark;

        final Color background =
            isDark
                ? const Color(0xFF08051F)
                : const Color(0xFFF7F5FC);

        final Color card =
            isDark
                ? const Color(0xFF151033)
                : Colors.white;

        final Color border =
            isDark
                ? const Color(0xFF29204F)
                : const Color(0xFFE0DBEA);

        final Color primaryText =
            isDark
                ? Colors.white
                : const Color(0xFF171326);

        final Color secondaryText =
            isDark
                ? const Color(0xFFAAA4C2)
                : const Color(0xFF686274);

        return Scaffold(
          backgroundColor: background,

          appBar: AppBar(
            backgroundColor: card,
            foregroundColor: primaryText,
            elevation: 0,
            title: const Text(
              'Appearance',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Customize Closetly',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Change how Closetly looks and behaves.',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  'Theme',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                _buildOptionCard(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark',
                  subtitle: 'Use Closetly dark mode',
                  selected:
                      appearanceService.themeMode ==
                          ThemeMode.dark,
                  onTap: () async {
                    await appearanceService
                        .setThemeMode(
                      ThemeMode.dark,
                    );
                  },
                  cardColor: card,
                  borderColor: border,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                  accent: accent,
                ),

                const SizedBox(height: 8),

                _buildOptionCard(
                  icon: Icons.light_mode_outlined,
                  title: 'Light',
                  subtitle: 'Use a light interface',
                  selected:
                      appearanceService.themeMode ==
                          ThemeMode.light,
                  onTap: () async {
                    await appearanceService
                        .setThemeMode(
                      ThemeMode.light,
                    );
                  },
                  cardColor: card,
                  borderColor: border,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                  accent: accent,
                ),

                const SizedBox(height: 8),

                _buildOptionCard(
                  icon: Icons.brightness_auto_outlined,
                  title: 'System',
                  subtitle:
                      'Follow your device theme',
                  selected:
                      appearanceService.themeMode ==
                          ThemeMode.system,
                  onTap: () async {
                    await appearanceService
                        .setThemeMode(
                      ThemeMode.system,
                    );
                  },
                  cardColor: card,
                  borderColor: border,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                  accent: accent,
                ),

                const SizedBox(height: 30),

                Text(
                  'Accent Color',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Choose the main color used by Closetly.',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 14),

                _buildColorOption(
                  name: 'Purple',
                  value: 'purple',
                  color: const Color(0xFF7C4DFF),
                  cardColor: card,
                  borderColor: border,
                  primaryText: primaryText,
                ),

                _buildColorOption(
                  name: 'Blue',
                  value: 'blue',
                  color: Colors.blue,
                  cardColor: card,
                  borderColor: border,
                  primaryText: primaryText,
                ),

                _buildColorOption(
                  name: 'Green',
                  value: 'green',
                  color: Colors.green,
                  cardColor: card,
                  borderColor: border,
                  primaryText: primaryText,
                ),

                _buildColorOption(
                  name: 'Pink',
                  value: 'pink',
                  color: Colors.pink,
                  cardColor: card,
                  borderColor: border,
                  primaryText: primaryText,
                ),

                _buildColorOption(
                  name: 'Orange',
                  value: 'orange',
                  color: Colors.orange,
                  cardColor: card,
                  borderColor: border,
                  primaryText: primaryText,
                ),

                const SizedBox(height: 30),

                Text(
                  'Interface',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius:
                        BorderRadius.circular(16),
                    border: Border.all(
                      color: border,
                    ),
                  ),
                  child: SwitchListTile(
                    value:
                        appearanceService
                            .animationsEnabled,
                    onChanged: (value) {
                      appearanceService
                          .setAnimations(value);
                    },
                    activeThumbColor: accent,
                    title: Text(
                      'Animations',
                      style: TextStyle(
                        color: primaryText,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Enable interface animations',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Container(
                  padding:
                      const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius:
                        BorderRadius.circular(16),
                    border: Border.all(
                      color: border,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: accent,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your appearance preferences are stored locally on this device.',
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
    required Color cardColor,
    required Color borderColor,
    required Color primaryText,
    required Color secondaryText,
    required Color accent,
  }) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color:
                  selected ? accent : borderColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isColorDark(cardColor)
                      ? const Color(0xFF211642)
                      : const Color(0xFFF0ECF7),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: accent,
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
                        color: primaryText,
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

              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: accent,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorOption({
    required String name,
    required String value,
    required Color color,
    required Color cardColor,
    required Color borderColor,
    required Color primaryText,
  }) {
    final bool selected =
        appearanceService.accentColor == value;

    return Padding(
      padding:
          const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            appearanceService
                .setAccentColor(value);
          },
          borderRadius:
              BorderRadius.circular(16),
          child: Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color:
                    selected ? color : borderColor,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: primaryText,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),

                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: color,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool isColorDark(Color color) {
    return ThemeData.estimateBrightnessForColor(
          color,
        ) ==
        Brightness.dark;
  }
}