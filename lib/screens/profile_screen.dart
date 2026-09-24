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
      ScaffoldMessenger.of(context)
          .showSnackBar(
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

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Profile saved successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not save profile: $e',
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
    return Scaffold(
      backgroundColor:
          const Color(0xFF08051F),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF100B31),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8A5CFF),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // Profile header
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration:
                                const BoxDecoration(
                              gradient:
                                  LinearGradient(
                                colors: [
                                  Color(0xFF8A5CFF),
                                  Color(0xFF5E35B1),
                                ],
                              ),
                              shape:
                                  BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),

                          const SizedBox(height: 14),

                          const Text(
                            'Your Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          const Text(
                            'Tell Closetly a little about you.',
                            style: TextStyle(
                              color:
                                  Color(0xFFAAA4C2),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Nickname
                    const Text(
                      'Nickname',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller:
                          nicknameController,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                      textCapitalization:
                          TextCapitalization.words,
                      decoration:
                          _inputDecoration(
                        icon: Icons.person_outline,
                        hint:
                            'Enter your nickname',
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Gender
                    const Text(
                      'Gender',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                    initialValue: selectedGender,
                      dropdownColor:
                          const Color(0xFF151033),
                      icon: const Icon(
                        Icons
                            .keyboard_arrow_down_rounded,
                        color:
                            Color(0xFFAAA4C2),
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      hint: const Text(
                        'Select your gender',
                        style: TextStyle(
                          color:
                              Color(0xFFAAA4C2),
                        ),
                      ),
                      decoration:
                          _inputDecoration(
                        icon: Icons
                            .person_outline_rounded,
                        hint:
                            'Select your gender',
                      ),
                      items: genderOptions
                          .map(
                            (
                              String gender,
                            ) {
                              return DropdownMenuItem<
                                  String>(
                                value: gender,
                                child: Text(
                                  gender,
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white,
                                  ),
                                ),
                              );
                            },
                          )
                          .toList(),
                      onChanged:
                          (String? value) {
                        setState(() {
                          selectedGender =
                              value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // Explanation
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF151033),
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                        border: Border.all(
                          color:
                              const Color(0xFF29204F),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color:
                                Color(0xFFB99AFF),
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your gender preference can be used by Closetly AI to make more relevant outfit recommendations.',
                              style: TextStyle(
                                color:
                                    Color(0xFFAAA4C2),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : saveProfile,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF7C4DFF),
                          foregroundColor:
                              Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFF3A2C62),
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
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      Colors.white,
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
    required IconData icon,
    required String hint,
  }) {
    return InputDecoration(
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF8A5CFF),
      ),
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFAAA4C2),
      ),
      filled: true,
      fillColor: const Color(0xFF151033),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFF29204F),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFF29204F),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFF7C4DFF),
          width: 1.5,
        ),
      ),
    );
  }
}