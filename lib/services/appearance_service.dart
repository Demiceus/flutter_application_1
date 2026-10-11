import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppearanceService extends ChangeNotifier {
  AppearanceService._();

  static final AppearanceService instance =
      AppearanceService._();

  ThemeMode themeMode = ThemeMode.dark;

  String accentColor = 'purple';

  bool animationsEnabled = true;

  bool isLoaded = false;

  // ==========================================================
  // FIRESTORE
  // ==========================================================

  CollectionReference<Map<String, dynamic>>
      get _settingsCollection {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('settings');
  }

  // ==========================================================
  // LOAD SETTINGS
  // ==========================================================

  Future<void> load() async {
    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot =
          await _settingsCollection.get();

      String theme = 'dark';
      String accent = 'purple';
      String animations = 'true';

      for (final QueryDocumentSnapshot<
          Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic> data =
            doc.data();

        final String value =
            data['value']?.toString() ?? '';

        switch (doc.id) {
          case 'themeMode':
            theme = value;
            break;

          case 'accentColor':
            accent = value;
            break;

          case 'animations':
            animations = value;
            break;
        }
      }

      themeMode = _parseThemeMode(theme);
      accentColor = accent;
      animationsEnabled = animations == 'true';

      isLoaded = true;

      notifyListeners();
    } catch (e) {
      debugPrint(
        'Error loading appearance settings: $e',
      );

      // Use default settings if loading fails.
      themeMode = ThemeMode.dark;
      accentColor = 'purple';
      animationsEnabled = true;
      isLoaded = true;

      notifyListeners();
    }
  }

  // ==========================================================
  // RESET WHEN LOGGED OUT
  // ==========================================================

  void resetToDefaults() {
    themeMode = ThemeMode.dark;
    accentColor = 'purple';
    animationsEnabled = true;
    isLoaded = false;

    notifyListeners();
  }

  // ==========================================================
  // SAVE SETTING
  // ==========================================================

  Future<void> _saveSetting({
    required String key,
    required String value,
  }) async {
    await _settingsCollection
        .doc(key)
        .set({
      'value': value,
      'updatedAt': Timestamp.now(),
    });
  }

  // ==========================================================
  // THEME
  // ==========================================================

  Future<void> setThemeMode(
    ThemeMode mode,
  ) async {
    themeMode = mode;

    notifyListeners();

    await _saveSetting(
      key: 'themeMode',
      value: _themeModeToString(mode),
    );
  }

  // ==========================================================
  // ACCENT COLOR
  // ==========================================================

  Future<void> setAccentColor(
    String color,
  ) async {
    accentColor = color;

    notifyListeners();

    await _saveSetting(
      key: 'accentColor',
      value: color,
    );
  }

  // ==========================================================
  // ANIMATIONS
  // ==========================================================

  Future<void> setAnimations(
    bool enabled,
  ) async {
    animationsEnabled = enabled;

    notifyListeners();

    await _saveSetting(
      key: 'animations',
      value: enabled.toString(),
    );
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

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

  // ==========================================================
  // ACCENT COLOR
  // ==========================================================

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