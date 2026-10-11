import 'package:flutter/material.dart';

import '../services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  final DatabaseService databaseService =
      DatabaseService.instance;

  final TextEditingController nicknameController =
      TextEditingController();

  String? selectedGender;

  bool isLoading = true;
  bool isSaving = false;

  final List<String> genderOptions = const [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    nicknameController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    final Map<String, dynamic> profile =
        await databaseService.getUserProfile();

    if (!mounted) return;

    setState(() {
      nicknameController.text =
          profile['nickname'] as String? ??
          'Closetly User';

      selectedGender =
          profile['gender'] as String?;

      isLoading = false;
    });
  }

  Future<void> saveProfile() async {
    final String nickname =
        nicknameController.text.trim();

    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a nickname.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await databaseService.saveUserProfile(
        nickname: nickname,
        gender: selectedGender,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile saved successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save your profile. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
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

    final Color appBarBackground = isDark
        ? const Color(0xFF100B31)
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

    return Scaffold(
      backgroundColor: pageBackground,

      appBar: AppBar(
        backgroundColor: appBarBackground,
        foregroundColor: colors.onSurface,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colors.primary,
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // PROFILE HEADER
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
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
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              color: colors.onPrimary,
                              size: 48,
                            ),
                          ),

                          const SizedBox(height: 14),

                          Text(
                            'Your Profile',
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            'Tell Closetly a little about you.',
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // NICKNAME
                    Text(
                      'Nickname',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller:
                          nicknameController,
                      style: TextStyle(
                        color: colors.onSurface,
                      ),
                      cursorColor: colors.primary,
                      textCapitalization:
                          TextCapitalization.words,
                      decoration: _inputDecoration(
                        context: context,
                        icon:
                            Icons.person_outline,
                        hint:
                            'Enter your nickname',
                      ),
                    ),

                    const SizedBox(height: 24),

                    // GENDER
                    Text(
                      'Gender',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      initialValue: selectedGender,

                      dropdownColor:
                          cardBackground,

                      icon: Icon(
                        Icons
                            .keyboard_arrow_down_rounded,
                        color: secondaryText,
                      ),

                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 15,
                      ),

                      hint: Text(
                        'Select your gender',
                        style: TextStyle(
                          color: secondaryText,
                        ),
                      ),

                      decoration: _inputDecoration(
                        context: context,
                        icon: Icons
                            .person_outline_rounded,
                        hint:
                            'Select your gender',
                      ),

                      items: genderOptions.map(
                        (String gender) {
                          return DropdownMenuItem<
                              String>(
                            value: gender,
                            child: Text(
                              gender,
                              style: TextStyle(
                                color:
                                    colors.onSurface,
                              ),
                            ),
                          );
                        },
                      ).toList(),

                      onChanged:
                          (String? value) {
                        setState(() {
                          selectedGender = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // EXPLANATION
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBackground,
                        borderRadius:
                            BorderRadius.circular(15),
                        border: Border.all(
                          color: borderColor,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: colors.primary,
                            size: 20,
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              'Your gender preference can be used by Closetly AI to make more relevant outfit recommendations.',
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

                    const SizedBox(height: 32),

                    // SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : saveProfile,

                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              colors.primary,

                          foregroundColor:
                              colors.onPrimary,

                          disabledBackgroundColor:
                              colors.onSurface
                                  .withValues(
                            alpha: 0.12,
                          ),

                          disabledForegroundColor:
                              colors.onSurface
                                  .withValues(
                            alpha: 0.38,
                          ),

                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 16,
                          ),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              15,
                            ),
                          ),
                        ),

                        child: isSaving
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      colors.onPrimary,
                                ),
                              )
                            : const Text(
                                'Save Profile',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required IconData icon,
    required String hint,
  }) {
    final ThemeData theme =
        Theme.of(context);

    final ColorScheme colors =
        theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    final Color fillColor = isDark
        ? const Color(0xFF151033)
        : colors.surfaceContainerHighest;

    final Color borderColor = isDark
        ? const Color(0xFF29204F)
        : colors.outlineVariant;

    final Color secondaryText = isDark
        ? const Color(0xFFAAA4C2)
        : colors.onSurfaceVariant;

    return InputDecoration(
      prefixIcon: Icon(
        icon,
        color: colors.primary,
      ),

      hintText: hint,

      hintStyle: TextStyle(
        color: secondaryText,
      ),

      filled: true,

      fillColor: fillColor,

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide: BorderSide(
          color: borderColor,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide: BorderSide(
          color: borderColor,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide: BorderSide(
          color: colors.primary,
          width: 1.5,
        ),
      ),
    );
  }
}