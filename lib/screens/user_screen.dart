import 'package:flutter/material.dart';

import '../services/database_service.dart';
import 'profile_screen.dart';
import 'appearance_screen.dart';

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
        builder: (context) =>
            const ProfileScreen(),
      ),
    );

    // Reload nickname after returning from Profile.
    if (result == true) {
      await loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08051F),

      body: SafeArea(
        child: Container(
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
                        color: const Color(0xFF7C4DFF),
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),

                    const SizedBox(width: 13),

                    const Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Manage your Closetly',
                          style: TextStyle(
                            color: Color(0xFFAAA4C2),
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
                    color: const Color(0xFF151033),
                    borderRadius:
                        BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFF29204F),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient:
                              const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF8A5CFF),
                              Color(0xFF5E35B1),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 43,
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        nickname,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Your wardrobe profile',
                        style: TextStyle(
                          color: Color(0xFFAAA4C2),
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
                          color: const Color(0xFF211642),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              color:
                                  Color(0xFF56E39F),
                              size: 8,
                            ),
                            SizedBox(width: 7),
                            Text(
                              'Local profile',
                              style: TextStyle(
                                color:
                                    Color(0xFFB99AFF),
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

                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
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
                subtitle: 'Customize your Closetly experience',
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

                const SizedBox(height: 10),

                // LOCAL STORAGE
                _buildSettingCard(
                  icon: Icons.storage_outlined,
                  title: 'Local Storage',
                  subtitle:
                      'Your wardrobe is stored locally',
                  onTap: () {},
                ),

                const SizedBox(height: 24),

                const Text(
                  'About',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151033),
                    borderRadius:
                        BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF29204F),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFFB99AFF),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Closetly',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 10),

                      Text(
                        'Your personal wardrobe assistant.',
                        style: TextStyle(
                          color: Color(0xFFAAA4C2),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),

                      SizedBox(height: 8),

                      Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          color: Color(0xFF6F6887),
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
    return Material(
      color: const Color(0xFF151033),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF29204F),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFF211642),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFB99AFF),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFAAA4C2),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF6F6887),
              ),
            ],
          ),
        ),
      ),
    );
  }
}