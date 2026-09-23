import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/clothing_item.dart';
import '../models/outfit_suggestion.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../services/local_wardrobe_service.dart';

class ClosetlyAIMessage {
  final String text;
  final bool isUser;
  final List<OutfitSuggestion>? outfits;

  const ClosetlyAIMessage({
    required this.text,
    required this.isUser,
    this.outfits,
  });
}

class ClosetlyAIScreen extends StatefulWidget {
  const ClosetlyAIScreen({super.key});

  @override
  State<ClosetlyAIScreen> createState() =>
      _ClosetlyAIScreenState();
}

class _ClosetlyAIScreenState
    extends State<ClosetlyAIScreen> {
  final AIService aiService = AIService();
  final LocalWardrobeService wardrobeService =
      LocalWardrobeService();
  final DatabaseService databaseService =
      DatabaseService.instance;

  final TextEditingController messageController =
      TextEditingController();

  final ScrollController scrollController =
      ScrollController();

  final FocusNode messageFocusNode =
      FocusNode();

  final List<ClosetlyAIMessage> messages = [];

  List<ClothingItem> currentWardrobe = [];

  bool isLoading = false;
  bool isConversationLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    messageFocusNode.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // LOAD SAVED CONVERSATION
  // --------------------------------------------------

  Future<void> _loadConversation() async {
    try {
      final List<Map<String, dynamic>> savedMessages =
          await databaseService.getAIMessages();

      final List<ClosetlyAIMessage> loadedMessages = [];

      for (final Map<String, dynamic> saved
          in savedMessages) {
        final bool isUser =
            (saved['isUser'] as int) == 1;

        final String type =
            saved['messageType'] as String;

        final String content =
            saved['content'] as String;

        if (type == 'outfit') {
          try {
            final dynamic decoded =
                jsonDecode(content);

            if (decoded is List) {
              final List<OutfitSuggestion> outfits =
                  decoded
                      .whereType<Map<String, dynamic>>()
                      .map(
                        OutfitSuggestion.fromJson,
                      )
                      .toList();

              loadedMessages.add(
                ClosetlyAIMessage(
                  text: '',
                  isUser: isUser,
                  outfits: outfits,
                ),
              );
            }
          } catch (_) {
            loadedMessages.add(
              ClosetlyAIMessage(
                text: content,
                isUser: isUser,
              ),
            );
          }
        } else {
          loadedMessages.add(
            ClosetlyAIMessage(
              text: content,
              isUser: isUser,
            ),
          );
        }
      }

      if (!mounted) return;

      setState(() {
        messages.clear();
        messages.addAll(loadedMessages);
        isConversationLoading = false;
      });

      if (messages.isEmpty) {
        _showWelcome();
      }

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isConversationLoading = false;
      });

      _showWelcome();
    }
  }

  void _showWelcome() {
    setState(() {
      messages.add(
        const ClosetlyAIMessage(
          text:
              "Hi! I'm Closetly AI ✨\n\n"
              "I'm your personal wardrobe assistant. "
              "I can help you create outfits and make "
              "the most out of the clothes you already own.",
          isUser: false,
        ),
      );
    });
  }

  // --------------------------------------------------
  // CLEAR CONVERSATION
  // --------------------------------------------------

  Future<void> _confirmClearConversation() async {
    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF171331),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text(
            'Clear Conversation?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to clear your '
            'Closetly AI conversation?\n\n'
            'This cannot be undone.',
            style: TextStyle(
              color: Color(0xFFB9B4D0),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: Color(0xFFB8A7FF),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'CLEAR',
                style: TextStyle(
                  color: Color(0xFFFF8A9B),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await databaseService.clearAIMessages();

    if (!mounted) return;

    setState(() {
      messages.clear();
    });

    _showWelcome();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Conversation cleared.',
        ),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // --------------------------------------------------
  // SEND NORMAL MESSAGE
  // --------------------------------------------------

  Future<void> sendMessage() async {
    final String message =
        messageController.text.trim();

    if (message.isEmpty || isLoading) {
      return;
    }

    messageController.clear();

    setState(() {
      messages.add(
        ClosetlyAIMessage(
          text: message,
          isUser: true,
        ),
      );

      isLoading = true;
    });

    await databaseService.saveAIMessage(
      isUser: true,
      messageType: 'text',
      content: message,
    );

    _scrollToBottom();

    try {
      final List<ClothingItem> wardrobe =
          await wardrobeService
              .getClothingItems();

      final String response =
          await aiService.chatWithWardrobe(
        message: message,
        clothingItems: wardrobe,
      );

      final List<OutfitSuggestion>? suggestions =
          aiService.parseOutfitSuggestions(
        response,
        wardrobe,
      );

      if (suggestions != null &&
          suggestions.isNotEmpty) {
        await _saveOutfitMessage(
          suggestions,
        );

        if (!mounted) return;

        setState(() {
          messages.add(
            ClosetlyAIMessage(
              text: '',
              isUser: false,
              outfits: suggestions,
            ),
          );

          currentWardrobe = wardrobe;
          isLoading = false;
        });

        _scrollToBottom();
        return;
      }

      await databaseService.saveAIMessage(
        isUser: false,
        messageType: 'text',
        content: response,
      );

      if (!mounted) return;

      setState(() {
        messages.add(
          ClosetlyAIMessage(
            text: response,
            isUser: false,
          ),
        );

        currentWardrobe = wardrobe;
        isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      final String errorMessage =
          'Sorry, I could not connect to Closetly AI.\n\n$e';

      await databaseService.saveAIMessage(
        isUser: false,
        messageType: 'text',
        content: errorMessage,
      );

      if (!mounted) return;

      setState(() {
        messages.add(
          ClosetlyAIMessage(
            text: errorMessage,
            isUser: false,
          ),
        );

        isLoading = false;
      });

      _scrollToBottom();
    }
  }

  // --------------------------------------------------
  // GENERATE OUTFITS
  // --------------------------------------------------

  Future<void> generateOutfits() async {
    if (isLoading) return;

    const String request =
        'Give me outfit ideas from my wardrobe.';

    setState(() {
      messages.add(
        const ClosetlyAIMessage(
          text: request,
          isUser: true,
        ),
      );

      isLoading = true;
    });

    await databaseService.saveAIMessage(
      isUser: true,
      messageType: 'text',
      content: request,
    );

    _scrollToBottom();

    try {
      final List<ClothingItem> wardrobe =
          await wardrobeService
              .getClothingItems();

      final String response =
          await aiService.generateOutfits(
        wardrobe,
      );

      final List<OutfitSuggestion>? suggestions =
          aiService.parseOutfitSuggestions(
        response,
        wardrobe,
      );

      if (suggestions != null &&
          suggestions.isNotEmpty) {
        await _saveOutfitMessage(
          suggestions,
        );

        if (!mounted) return;

        setState(() {
          currentWardrobe = wardrobe;

          messages.add(
            ClosetlyAIMessage(
              text: '',
              isUser: false,
              outfits: suggestions,
            ),
          );

          isLoading = false;
        });

        _scrollToBottom();
        return;
      }

      await databaseService.saveAIMessage(
        isUser: false,
        messageType: 'text',
        content: response,
      );

      if (!mounted) return;

      setState(() {
        currentWardrobe = wardrobe;

        messages.add(
          ClosetlyAIMessage(
            text: response,
            isUser: false,
          ),
        );

        isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      final String errorMessage =
          'Error generating outfits:\n\n$e';

      await databaseService.saveAIMessage(
        isUser: false,
        messageType: 'text',
        content: errorMessage,
      );

      if (!mounted) return;

      setState(() {
        messages.add(
          ClosetlyAIMessage(
            text: errorMessage,
            isUser: false,
          ),
        );

        isLoading = false;
      });

      _scrollToBottom();
    }
  }

  Future<void> _saveOutfitMessage(
    List<OutfitSuggestion> outfits,
  ) async {
    await databaseService.saveAIMessage(
      isUser: false,
      messageType: 'outfit',
      content: jsonEncode(
        outfits
            .map(
              (outfit) => outfit.toJson(),
            )
            .toList(),
      ),
    );
  }

  // --------------------------------------------------
  // QUICK ACTIONS
  // --------------------------------------------------

  void _askAboutClothes() {
    messageFocusNode.requestFocus();
  }

  void _checkOutfit() {
    messageController.text =
        'Can you check an outfit for me?';

    messageFocusNode.requestFocus();
  }

  void _askTrending() {
    messageController.text =
        "What's trending right now?";

    messageFocusNode.requestFocus();
  }

  // --------------------------------------------------
  // SCROLL
  // --------------------------------------------------

  void _scrollToBottom() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!scrollController.hasClients) {
        return;
      }

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration:
            const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF08051F),

      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child:
                  isConversationLoading
                      ? const Center(
                          child:
                              CircularProgressIndicator(
                            color:
                                Color(0xFF8A5CFF),
                          ),
                        )
                      : _buildMainContent(),
            ),

            _buildInputBar(),
          ],
        ),
      ),

      bottomNavigationBar:
          _buildBottomNavigation(),
    );
  }

  // --------------------------------------------------
  // HEADER
  // --------------------------------------------------

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        12,
        12,
        12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF100B31),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF241B4A),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  const Color(0xFF7C4DFF),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.checkroom_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Closetly AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color:
                          Color(0xFF56E39F),
                      size: 7,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Your wardrobe assistant',
                      style: TextStyle(
                        color:
                            Color(0xFFAAA4C2),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'AI Information',
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) {
                  return AlertDialog(
                    backgroundColor:
                        const Color(
                      0xFF171331,
                    ),
                    title: const Text(
                      'Closetly AI',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    content:
                        const Text(
                      'Your personal wardrobe assistant. '
                      'Closetly AI uses the clothes saved '
                      'in your wardrobe to help create '
                      'outfit ideas.',
                      style: TextStyle(
                        color:
                            Color(0xFFB9B4D0),
                      ),
                    ),
                  );
                },
              );
            },
            icon: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFC5BDD9),
            ),
          ),

          IconButton(
            tooltip: 'Clear Conversation',
            onPressed:
                _confirmClearConversation,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFC5BDD9),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // MAIN CONTENT
  // --------------------------------------------------

  Widget _buildMainContent() {
    final bool showWelcome =
        messages.length <= 1 &&
        !messages.any(
          (message) => message.isUser,
        );

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        20,
        28,
        20,
        24,
      ),
      children: [
        if (showWelcome)
          _buildWelcomeSection(),

        if (!showWelcome)
          ...messages.map(
            _buildMessage,
          ),

        if (isLoading)
          _buildLoadingMessage(),
      ],
    );
  }

  // --------------------------------------------------
  // WELCOME
  // --------------------------------------------------

  Widget _buildWelcomeSection() {
    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                const Color(0xFF21164C),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF8A5CFF,
                ).withValues(
                  alpha: 0.22,
                ),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFFB99AFF),
            size: 45,
          ),
        ),

        const SizedBox(height: 22),

        const Text(
          "Hi! I'm Closetly AI ✨",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Your personal wardrobe assistant',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFAAA4C2),
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 28),

        _buildQuickAction(
          icon: Icons.auto_awesome_rounded,
          label: 'Generate outfits',
          onTap: generateOutfits,
        ),

        _buildQuickAction(
          icon: Icons.local_fire_department_rounded,
          label: "What's trending?",
          onTap: _askTrending,
        ),

        _buildQuickAction(
          icon: Icons.checkroom_rounded,
          label: 'Check this outfit',
          onTap: _checkOutfit,
        ),

        _buildQuickAction(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Ask about my clothes',
          onTap: _askAboutClothes,
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      width: double.infinity,
      child: Material(
        color: const Color(0xFF151033),
        borderRadius:
            BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(16),
          child: Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color:
                    const Color(0xFF29204F),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFF261858,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      11,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color:
                        const Color(
                      0xFFB89AFF,
                    ),
                    size: 20,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Text(
                    label,
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color:
                      Color(0xFF71688F),
                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // MESSAGE
  // --------------------------------------------------

  Widget _buildMessage(
    ClosetlyAIMessage message,
  ) {
    if (message.outfits != null &&
        message.outfits!.isNotEmpty) {
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Padding(
            padding:
                EdgeInsets.only(
              left: 4,
              bottom: 12,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color:
                      Color(0xFFAA88FF),
                  size: 18,
                ),
                SizedBox(width: 7),
                Text(
                  'Closetly AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          ...message.outfits!.map(
            _buildOutfitCard,
          ),

          const SizedBox(height: 18),
        ],
      );
    }

    return Align(
      alignment: message.isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints:
            const BoxConstraints(
          maxWidth: 620,
        ),
        margin:
            const EdgeInsets.only(
          bottom: 14,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? const Color(0xFF7447F7)
              : const Color(0xFF151033),
          borderRadius:
              BorderRadius.circular(18),
          border: message.isUser
              ? null
              : Border.all(
                  color:
                      const Color(
                    0xFF29204F,
                  ),
                ),
        ),
        child: Text(
          message.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // OUTFIT CARD
  // --------------------------------------------------

  Widget _buildOutfitCard(
    OutfitSuggestion outfit,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151033),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF30245A),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFF7549F5,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  outfit.name,
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ...outfit.items.map(
            (String item) {
              return Container(
                margin:
                    const EdgeInsets.only(
                  bottom: 8,
                ),
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFF0E0A25,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.checkroom_outlined,
                      color:
                          Color(0xFFA98AFF),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style:
                            const TextStyle(
                          color:
                              Color(0xFFE8E4F2),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          if (outfit.why.isNotEmpty) ...[
            const SizedBox(height: 6),

            const Text(
              'Why it works',
              style: TextStyle(
                color:
                    Color(0xFFB394FF),
                fontSize: 12,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              outfit.why,
              style:
                  const TextStyle(
                color:
                    Color(0xFFAAA4C2),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --------------------------------------------------
  // LOADING
  // --------------------------------------------------

  Widget _buildLoadingMessage() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 14,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF151033),
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
                color:
                    Color(0xFFA98AFF),
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Closetly AI is thinking...',
              style: TextStyle(
                color:
                    Color(0xFFAAA4C2),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // INPUT
  // --------------------------------------------------

  Widget _buildInputBar() {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0928),
        border: Border(
          top: BorderSide(
            color: Color(0xFF241B4A),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFF151033,
                ),
                borderRadius:
                    BorderRadius.circular(
                  25,
                ),
                border: Border.all(
                  color:
                      const Color(
                    0xFF30265A,
                  ),
                ),
              ),
              child: TextField(
                controller:
                    messageController,
                focusNode:
                    messageFocusNode,
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textInputAction:
                    TextInputAction.send,
                onSubmitted: (_) {
                  sendMessage();
                },
                decoration:
                    const InputDecoration(
                  hintText:
                      'Ask Closetly AI...',
                  hintStyle:
                      TextStyle(
                    color:
                        Color(0xFF77718E),
                  ),
                  border:
                      InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          Material(
            color:
                const Color(0xFF7C4DFF),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: isLoading
                  ? null
                  : sendMessage,
              customBorder:
                  const CircleBorder(),
              child: const Padding(
                padding:
                    EdgeInsets.all(14),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // BOTTOM NAVIGATION
  // --------------------------------------------------

  Widget _buildBottomNavigation() {
    return NavigationBar(
      backgroundColor:
          const Color(0xFF100B31),
      indicatorColor:
          const Color(0xFF2B1C59),
      selectedIndex: 2,
      height: 68,
      onDestinationSelected:
          (int index) {
        if (index == 2) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              index == 0
                  ? 'Home navigation'
                  : index == 1
                      ? 'Wardrobe navigation'
                      : 'Profile navigation',
            ),
            behavior:
                SnackBarBehavior.floating,
          ),
        );
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(
            Icons.home_outlined,
          ),
          selectedIcon: Icon(
            Icons.home_rounded,
          ),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.checkroom_outlined,
          ),
          selectedIcon: Icon(
            Icons.checkroom_rounded,
          ),
          label: 'Wardrobe',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.auto_awesome_outlined,
          ),
          selectedIcon: Icon(
            Icons.auto_awesome_rounded,
          ),
          label: 'AI',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.person_outline_rounded,
          ),
          selectedIcon: Icon(
            Icons.person_rounded,
          ),
          label: 'User',
        ),
      ],
    );
  }
}