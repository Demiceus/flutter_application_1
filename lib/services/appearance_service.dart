import 'package:flutter/material.dart';

import 'database_service.dart';

class AppearanceService extends ChangeNotifier {
  AppearanceService._();

  static final AppearanceService instance =
      AppearanceService._();

  ThemeMode themeMode = ThemeMode.dark;

  String accentColor = 'purple';

  bool animationsEnabled = true;

  bool isLoaded = false;

  Future<void> load() async {
    final Map<String, String> settings =
        await DatabaseService.instance
            .getAppearanceSettings();

    final String theme =
        settings['themeMode'] ?? 'dark';

    final String accent =
        settings['accentColor'] ?? 'purple';

    final String animations =
        settings['animations'] ?? 'true';

    themeMode = _parseThemeMode(theme);
    accentColor = accent;
    animationsEnabled =
        animations == 'true';

    isLoaded = true;

    notifyListeners();
  }

  Future<void> setThemeMode(
    ThemeMode mode,
  ) async {
    themeMode = mode;

    await DatabaseService.instance
        .saveAppearanceSetting(
      key: 'themeMode',
      value: _themeModeToString(mode),
    );

    notifyListeners();
  }

  Future<void> setAccentColor(
    String color,
  ) async {
    accentColor = color;

    await DatabaseService.instance
        .saveAppearanceSetting(
      key: 'accentColor',
      value: color,
    );

    notifyListeners();
  }

  Future<void> setAnimations(
    bool enabled,
  ) async {
    animationsEnabled = enabled;

    await DatabaseService.instance
        .saveAppearanceSetting(
      key: 'animations',
      value: enabled.toString(),
    );

    notifyListeners();
  }

  ThemeMode _parseThemeMode(
    String value,
  ) {
    switch (value) {
      case 'light':
        return ThemeMode.light;

      case 'system':
        return ThemeMode.system;

      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  String _themeModeToString(
    ThemeMode mode,
  ) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';

      case ThemeMode.system:
        return 'system';

      case ThemeMode.dark:
        return 'dark';
    }
  }

  Color get accent {
    switch (accentColor) {
      case 'blue':
        return Colors.blue;

      case 'green':
        return Colors.green;

      case 'pink':
        return Colors.pink;

      case 'orange':
        return Colors.orange;

      case 'purple':
      default:
        return const Color(0xFF7C4DFF);
    }
  }
}