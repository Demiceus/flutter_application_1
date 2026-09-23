import 'package:flutter/material.dart';

import '../models/clothing_item.dart';
import '../models/outfit_suggestion.dart';
import '../services/ai_service.dart';
import '../services/closetly_ai_rules.dart';
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
  const ClosetlyAIScreen({
    super.key,
  });

  @override
  State<ClosetlyAIScreen> createState() =>
      _ClosetlyAIScreenState();
}

class _ClosetlyAIScreenState
    extends State<ClosetlyAIScreen> {
  final AIService aiService = AIService();

  final LocalWardrobeService wardrobeService =
      LocalWardrobeService();

  final TextEditingController messageController =
      TextEditingController();

  final ScrollController scrollController =
      ScrollController();

  final FocusNode messageFocusNode =
      FocusNode();

  final List<ClosetlyAIMessage> messages = [];

  bool isLoading = false;

  List<OutfitSuggestion> outfitSuggestions = [];

  List<ClothingItem> currentWardrobe = [];

  @override
  void initState() {
    super.initState();

    messages.add(
      const ClosetlyAIMessage(
        isUser: false,
        text:
            "Hey! I'm Closetly AI ✨\n\n"
            "I know what's in your wardrobe and can help "
            "you put together outfits, choose what to wear, "
            "or answer questions about your clothes.",
      ),
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    messageFocusNode.dispose();

    super.dispose();
  }

  Future<List<ClothingItem>> getWardrobe() {
    return wardrobeService.getClothingItems();
  }

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
          isUser: true,
          text: message,
        ),
      );

      isLoading = true;
    });

    _scrollToBottom();

    try {
      final List<ClothingItem> wardrobe =
          await getWardrobe();

      final String response =
          await aiService.chatWithWardrobe(
        message: message,
        clothingItems: wardrobe,
      );

      if (!mounted) return;

      final List<OutfitSuggestion>? suggestions =
          aiService.parseOutfitSuggestions(
        response,
        wardrobe,
      );

      if (suggestions != null &&
          suggestions.isNotEmpty) {
        setState(() {
          currentWardrobe = wardrobe;

          messages.add(
            ClosetlyAIMessage(
              isUser: false,
              text: '',
              outfits: suggestions,
            ),
          );

          outfitSuggestions = suggestions;
          isLoading = false;
        });

        _scrollToBottom();
        return;
      }

      setState(() {
        currentWardrobe = wardrobe;

        messages.add(
          ClosetlyAIMessage(
            isUser: false,
            text: response,
          ),
        );

        isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        messages.add(
          ClosetlyAIMessage(
            isUser: false,
            text:
                'I could not connect to Llama.\n\n$e',
          ),
        );

        isLoading = false;
      });

      _scrollToBottom();
    }
  }

  Future<void> generateOutfits() async {
    if (isLoading) {
      return;
    }

    const String userRequest =
        'Give me outfit ideas from my wardrobe.';

    setState(() {
      messages.add(
        const ClosetlyAIMessage(
          isUser: true,
          text: userRequest,
        ),
      );

      isLoading = true;
      outfitSuggestions = [];
    });

    _scrollToBottom();

    try {
      final List<ClothingItem> wardrobe =
          await getWardrobe();

      if (wardrobe.isEmpty) {
        if (!mounted) return;

        setState(() {
          messages.add(
            const ClosetlyAIMessage(
              isUser: false,
              text:
                  "You don't have any clothes saved "
                  "in your wardrobe yet.",
            ),
          );

          isLoading = false;
        });

        _scrollToBottom();
        return;
      }

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
        if (!mounted) return;

        setState(() {
          currentWardrobe = wardrobe;
          outfitSuggestions = suggestions;

          messages.add(
            ClosetlyAIMessage(
              isUser: false,
              text: '',
              outfits: suggestions,
            ),
          );

          isLoading = false;
        });

        _scrollToBottom();
        return;
      }

      if (!mounted) return;

      setState(() {
        currentWardrobe = wardrobe;

        messages.add(
          ClosetlyAIMessage(
            isUser: false,
            text: response,
          ),
        );

        isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        messages.add(
          ClosetlyAIMessage(
            isUser: false,
            text:
                'Error generating outfits:\n\n$e',
          ),
        );

        isLoading = false;
      });

      _scrollToBottom();
    }
  }

  void askQuickQuestion(String question) {
    messageController.text = question;
    messageFocusNode.requestFocus();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  void showAIRules() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              20,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    _AIIcon(size: 44),
                    SizedBox(width: 12),
                    Text(
                      'Closetly AI Rules',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const Text(
                  'Closetly AI follows these rules when '
                  'working with your wardrobe:',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: ListView.separated(
                    itemCount:
                        ClosetlyAIRules.rules.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration:
                                BoxDecoration(
                              color: Colors
                                  .deepPurple
                                  .shade50,
                              shape:
                                  BoxShape.circle,
                            ),
                            alignment:
                                Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors
                                    .deepPurple
                                    .shade700,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              ClosetlyAIRules
                                  .rules[index],
                              style:
                                  const TextStyle(
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F6FC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor:
            Colors.transparent,

        title: Row(
          children: [
            const _AIIcon(size: 42),

            const SizedBox(width: 10),

            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Closetly AI',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                Text(
                  'Your wardrobe assistant',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),

        actions: [
          IconButton(
            onPressed: showAIRules,
            tooltip: 'AI Rules',
            icon: const Icon(
              Icons.info_outline,
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          if (messages.length == 1 &&
              outfitSuggestions.isEmpty &&
              !isLoading)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                4,
                16,
                8,
              ),
              child: _WelcomeCard(
                onGenerateOutfits:
                    generateOutfits,
              ),
            ),

          if (messages.length == 1 &&
              outfitSuggestions.isEmpty &&
              !isLoading)
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection:
                    Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                children: [
                  _PromptChip(
                    icon:
                        Icons.checkroom_outlined,
                    label:
                        'What should I wear?',
                    onTap: () {
                      askQuickQuestion(
                        'What should I wear today?',
                      );
                    },
                  ),

                  _PromptChip(
                    icon:
                        Icons.event_outlined,
                    label:
                        'Outfit for an event',
                    onTap: () {
                      askQuickQuestion(
                        'Help me choose an outfit for an event.',
                      );
                    },
                  ),

                  _PromptChip(
                    icon:
                        Icons.palette_outlined,
                    label:
                        'Match my clothes',
                    onTap: () {
                      askQuickQuestion(
                        'Which clothes in my wardrobe match well together?',
                      );
                    },
                  ),
                ],
              ),
            ),

          if (messages.length == 1 &&
              outfitSuggestions.isEmpty &&
              !isLoading)
            const SizedBox(height: 8),

          Expanded(
            child: ListView(
              controller:
                  scrollController,
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                12,
              ),
              children: [
                if (outfitSuggestions
                    .isNotEmpty) ...[
                  const Padding(
                    padding:
                        EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color:
                              Colors.deepPurple,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Your outfit ideas',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  ...outfitSuggestions.map(
                    (outfit) =>
                        _OutfitCard(
                      outfit: outfit,
                      wardrobe:
                          currentWardrobe,
                    ),
                  ),

                  const SizedBox(height: 16),
                ],

                ...messages.map(
                  (message) {
                    if (message.outfits !=
                            null &&
                        message.outfits!
                            .isNotEmpty) {
                      return Column(
                        children: message
                            .outfits!
                            .map(
                              (outfit) =>
                                  _OutfitCard(
                                outfit: outfit,
                                wardrobe:
                                    currentWardrobe,
                              ),
                            )
                            .toList(),
                      );
                    }

                    return _ChatBubble(
                      message: message,
                    );
                  },
                ),

                if (isLoading)
                  const _ThinkingBubble(),
              ],
            ),
          ),

          SafeArea(
            child: Container(
              padding:
                  const EdgeInsets.fromLTRB(
                12,
                8,
                12,
                12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color:
                        Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller:
                          messageController,
                      focusNode:
                          messageFocusNode,
                      textInputAction:
                          TextInputAction.send,
                      onSubmitted: (_) {
                        sendMessage();
                      },
                      decoration:
                          InputDecoration(
                        hintText:
                            'Ask Closetly AI...',

                        prefixIcon:
                            const Icon(
                          Icons.auto_awesome,
                          size: 20,
                        ),

                        filled: true,

                        fillColor:
                            const Color(
                          0xFFF3F1F7,
                        ),

                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            24,
                          ),
                          borderSide:
                              BorderSide.none,
                        ),

                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 18,
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Container(
                    width: 48,
                    height: 48,
                    decoration:
                        const BoxDecoration(
                      color:
                          Colors.deepPurple,
                      shape:
                          BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: isLoading
                          ? null
                          : sendMessage,
                      icon: const Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// AI ICON
// ============================================================

class _AIIcon extends StatelessWidget {
  final double size;

  const _AIIcon({
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8E6AC8),
            Color(0xFF5E35B1),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.auto_awesome,
        color: Colors.white,
        size: size * 0.48,
      ),
    );
  }
}

// ============================================================
// WELCOME CARD
// ============================================================

class _WelcomeCard extends StatelessWidget {
  final VoidCallback onGenerateOutfits;

  const _WelcomeCard({
    required this.onGenerateOutfits,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEEE7FA),
            Color(0xFFF7F3FC),
          ],
        ),
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _AIIcon(size: 50),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Style starts with\n'
                  'what you already own.',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.bold,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'Ask me anything about your wardrobe '
            'or let me create an outfit for you.',
            style: TextStyle(
              color:
                  Colors.grey.shade700,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child:
                ElevatedButton.icon(
              onPressed:
                  onGenerateOutfits,
              icon: const Icon(
                Icons.auto_awesome,
              ),
              label: const Text(
                'Generate outfit ideas',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.deepPurple,
                foregroundColor:
                    Colors.white,
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// QUICK PROMPT
// ============================================================

class _PromptChip
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PromptChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(
        right: 8,
      ),
      child: ActionChip(
        avatar: Icon(
          icon,
          size: 18,
          color: Colors.deepPurple,
        ),
        label: Text(label),
        onPressed: onTap,
        backgroundColor:
            Colors.white,
        side: BorderSide(
          color:
              Colors.grey.shade200,
        ),
      ),
    );
  }
}

// ============================================================
// THINKING BUBBLE
// ============================================================

class _ThinkingBubble
    extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          Alignment.centerLeft,
      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            18,
          ),
        ),
        child: const Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            SizedBox(
              width: 17,
              height: 17,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Closetly AI is thinking...',
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CHAT BUBBLE
// ============================================================

class _ChatBubble
    extends StatelessWidget {
  final ClosetlyAIMessage message;

  const _ChatBubble({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUser =
        message.isUser;

    return Align(
      alignment: isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints:
            const BoxConstraints(
          maxWidth: 620,
        ),
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
            const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.deepPurple
              : Colors.white,
          borderRadius:
              BorderRadius.only(
            topLeft:
                const Radius.circular(
              18,
            ),
            topRight:
                const Radius.circular(
              18,
            ),
            bottomLeft:
                Radius.circular(
              isUser ? 18 : 5,
            ),
            bottomRight:
                Radius.circular(
              isUser ? 5 : 18,
            ),
          ),
          border: isUser
              ? null
              : Border.all(
                  color:
                      Colors.grey.shade200,
                ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            if (!isUser)
              const Padding(
                padding:
                    EdgeInsets.only(
                  bottom: 7,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color:
                          Colors.deepPurple,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Closetly AI',
                      style:
                          TextStyle(
                        color:
                            Colors.deepPurple,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                color: isUser
                    ? Colors.white
                    : Colors.black87,
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// OUTFIT CARD
// ============================================================

class _OutfitCard
    extends StatelessWidget {
  final OutfitSuggestion outfit;
  final List<ClothingItem> wardrobe;

  const _OutfitCard({
    required this.outfit,
    required this.wardrobe,
  });

  ClothingItem? findClothing(
    String name,
  ) {
    try {
      return wardrobe.firstWhere(
        (item) =>
            item.name
                .toLowerCase()
                .trim() ==
            name
                .toLowerCase()
                .trim(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              Colors.deepPurple.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius: 12,
            offset:
                const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.deepPurple
                          .shade50,
                  shape:
                      BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color:
                      Colors.deepPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  outfit.name,
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 165,
            child:
                ListView.separated(
              scrollDirection:
                  Axis.horizontal,
              itemCount:
                  outfit.items.length,
              separatorBuilder:
                  (_, _) =>
                      const SizedBox(
                width: 10,
              ),
              itemBuilder:
                  (context, index) {
                final String itemName =
                    outfit.items[index];

                final ClothingItem?
                    clothing =
                    findClothing(
                  itemName,
                );

                return _OutfitItem(
                  itemName:
                      itemName,
                  clothing:
                      clothing,
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(12),
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFF7F3FC,
              ),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons
                          .lightbulb_outline,
                      size: 18,
                      color:
                          Colors.deepPurple,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Why it works',
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Colors.deepPurple,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  outfit.why,
                  style:
                      const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// OUTFIT ITEM
// ============================================================

class _OutfitItem
    extends StatelessWidget {
  final String itemName;
  final ClothingItem? clothing;

  const _OutfitItem({
    required this.itemName,
    required this.clothing,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 105,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              child:
                  clothing?.imageBytes !=
                          null
                      ? Image.memory(
                          clothing!
                              .imageBytes!,
                          width: 105,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 105,
                          color: Colors
                              .grey
                              .shade100,
                          child:
                              const Icon(
                            Icons
                                .checkroom,
                            size: 36,
                            color:
                                Colors.grey,
                          ),
                        ),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            itemName,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}