import 'package:flutter/material.dart';

import 'screens/closetly_ai_screen.dart';
import 'screens/home_screen.dart';
import 'screens/user_screen.dart';
import 'screens/wardrobe_screen.dart';
import 'services/appearance_service.dart';
import 'services/database_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize local database for now.
  await DatabaseService.instance.database;


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AppearanceService appearance =
        AppearanceService.instance;

    return AnimatedBuilder(
      animation: appearance,
      builder: (context, _) {
        final Color accent = appearance.accent;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Closetly',

          // Use saved theme mode.
          themeMode: appearance.themeMode,

          // Animate theme changes only when enabled.
          themeAnimationDuration:
              appearance.animationsEnabled
                  ? const Duration(milliseconds: 300)
                  : Duration.zero,

          // LIGHT THEME
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: accent,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),

          // DARK THEME
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: accent,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor:
                const Color(0xFF08051F),
            useMaterial3: true,
          ),

          home: const AuthGate(),
        );
      },
    );
  }
}

class ClosetlyApp extends StatefulWidget {
  const ClosetlyApp({super.key});

  @override
  State<ClosetlyApp> createState() =>
      _ClosetlyAppState();
}

class _ClosetlyAppState extends State<ClosetlyApp> {
  int selectedIndex = 0;

  final GlobalKey<HomeScreenState> homeKey =
      GlobalKey<HomeScreenState>();

  final GlobalKey<WardrobeScreenState> wardrobeKey =
      GlobalKey<WardrobeScreenState>();

  @override
  void initState() {
    super.initState();

    AppearanceService.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final List<Widget> screens = [
    HomeScreen(
      key: homeKey,
      onOpenAI: () {
        setState(() {
          selectedIndex = 2;
        });
      },
    ),

    WardrobeScreen(
    key: wardrobeKey,
    onOpenAI: () {
      setState(() {
        selectedIndex = 2;
      });
    },
  ),

    const ClosetlyAIScreen(),

    const UserScreen(),
  ];
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),

      bottomNavigationBar: NavigationBar(
        backgroundColor: colors.surface,

        indicatorColor:
            colors.primary.withValues(
          alpha: 0.15,
        ),

        selectedIndex: selectedIndex,

        height: 70,

        onDestinationSelected: (int index) {
        setState(() {
          selectedIndex = index;
        });

        if (index == 0) {
          homeKey.currentState?.loadHomeData();
        }

        if (index == 1) {
          wardrobeKey.currentState?.refreshWardrobe();
        }
      },

        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
              color: colors.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.home_rounded,
              color: colors.primary,
            ),
            label: 'Home',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.checkroom_outlined,
              color: colors.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.checkroom_rounded,
              color: colors.primary,
            ),
            label: 'Wardrobe',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.auto_awesome_outlined,
              color: colors.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.auto_awesome_rounded,
              color: colors.primary,
            ),
            label: 'AI',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.person_outline_rounded,
              color: colors.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.person_rounded,
              color: colors.primary,
            ),
            label: 'User',
          ),
        ],
      ),
    );
  }
}