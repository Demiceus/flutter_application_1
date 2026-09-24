import 'package:flutter/material.dart';

import 'screens/closetly_ai_screen.dart';
import 'screens/home_screen.dart';
import 'screens/user_screen.dart';
import 'screens/wardrobe_screen.dart';
import 'services/appearance_service.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseService.instance.database;

  await AppearanceService.instance.load();

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
        final Color accent =
            appearance.accent;

        
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Closetly',

          themeMode:
              appearance.themeMode,

          themeAnimationDuration:
              appearance.animationsEnabled
                  ? const Duration(
                      milliseconds: 300,
                    )
                  : Duration.zero,

          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: accent,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),

          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: accent,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor:
                const Color(0xFF08051F),
            useMaterial3: true,
          ),

          home: const ClosetlyApp(),
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

class _ClosetlyAppState
    extends State<ClosetlyApp> {
  int selectedIndex = 0;

  final List<Widget> screens = const [
    HomeScreen(),
    WardrobeScreen(),
    ClosetlyAIScreen(),
    UserScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

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