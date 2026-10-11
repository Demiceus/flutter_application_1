import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';


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
  State<ClosetlyAIScreen> createState() => _ClosetlyAIScreenState();
}

class _ClosetlyAIScreenState extends State<ClosetlyAIScreen> {
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

  final ImagePicker imagePicker = ImagePicker();

  Uint8List? selectedChatImage;
  String? selectedChatImageMimeType;

  final List<ClosetlyAIMessage> messages = [];

  List<ClothingItem> currentWardrobe = [];

  bool _isRetrying = false;
  bool _lastFailureWasTrending = false;
  bool isLoading = false;
  bool isConversationLoading = true;
  int _conversationVersion = 0;

  // Stores the last request so it can be retried.
  String? _lastFailedMessage;
bool _lastFailureWasOutfitRequest = false;

Uint8List? _lastFailedImageBytes;
String? _lastFailedImageMimeType;
    // --------------------------------------------------
  // AI ERROR HANDLING
  // --------------------------------------------------

  String _getFriendlyAIError(Object error) {
  if (error is TimeoutException) {
    return 'Request timed out — The AI took too long to respond. '
        'Please try again.';
  }

  if (error is http.ClientException) {
    return 'Connection unavailable — Closetly AI needs an internet '
        'connection to respond. Please check your Wi-Fi or mobile '
        'data and try again.';
  }

  final String errorText = error.toString().toLowerCase();

  if (errorText.contains('socket') ||
      errorText.contains('connection') ||
      errorText.contains('network') ||
      errorText.contains('failed host lookup') ||
      errorText.contains('clientexception')) {
    return 'Connection unavailable — Closetly AI needs an internet '
        'connection to respond. Please check your Wi-Fi or mobile '
        'data and try again.';
  }

  if (errorText.contains('status code') ||
      errorText.contains('500') ||
      errorText.contains('502') ||
      errorText.contains('503') ||
      errorText.contains('504') ||
      errorText.contains('ai service')) {
    return "AI service unavailable — Closetly couldn't connect to "
        "its AI service right now. Please try again in a moment.";
  }

  return "Something went wrong — Closetly couldn't complete your "
      "request. Please try again.";
}

bool _looksLikeAddClothingRequest(String message) {
  final String text = message.toLowerCase();

  const List<String> actionWords = [
    'add',
    'save',
    'store',
    'put',
    'include',
  ];

  const List<String> clothingWords = [
    'shirt',
    't-shirt',
    'tee',
    'top',
    'pants',
    'jeans',
    'shorts',
    'trousers',
    'shoes',
    'sneakers',
    'sneaker',
    'boots',
    'jacket',
    'hoodie',
    'coat',
    'hat',
    'cap',
    'bag',
    'belt',
    'watch',
    'accessory',
    'clothing',
    'wardrobe',
    'closet',
  ];

  final bool hasActionWord =
      actionWords.any(text.contains);

  final bool hasClothingWord =
      clothingWords.any(text.contains);

  return hasActionWord && hasClothingWord;
}

bool _looksLikeDeleteClothingRequest(
  String message,
) {
  final String text = message.toLowerCase();

  const List<String> actionWords = [
    'remove',
    'delete',
    'take out',
    'take away',
    'get rid of',
  ];

  const List<String> clothingWords = [
    'shirt',
    't-shirt',
    'tee',
    'top',
    'pants',
    'jeans',
    'shorts',
    'trousers',
    'shoes',
    'sneakers',
    'sneaker',
    'boots',
    'jacket',
    'hoodie',
    'coat',
    'hat',
    'cap',
    'bag',
    'belt',
    'watch',
    'accessory',
    'clothing',
    'item',
    'wardrobe',
    'closet',
  ];

  final bool hasActionWord =
      actionWords.any(text.contains);

  final bool hasClothingWord =
      clothingWords.any(text.contains);

  return hasActionWord && hasClothingWord;
}



Future<bool> _tryAddClothingFromChat(
  String message,
) async {
  if (!_looksLikeAddClothingRequest(message)) {
    return false;
  }

  // ----------------------------------------------------------
  // GET CURRENT WARDROBE FIRST
  // ----------------------------------------------------------

  final List<ClothingItem> existingItems =
      await wardrobeService.getClothingItems();

  // Build the wardrobe information for the AI action detector.
  final String wardrobeContext =
      existingItems.isEmpty
          ? 'No clothing items saved.'
          : existingItems
              .asMap()
              .entries
              .map((entry) {
                final int number =
                    entry.key + 1;

                final ClothingItem item =
                    entry.value;

                return '''
$number.
EXACT NAME: "${item.name}"
CATEGORY: "${item.category}"
COLOR: "${item.color ?? 'Not specified'}"
''';
              })
              .join('\n');

  // ----------------------------------------------------------
  // ASK AI TO DETECT THE WARDROBE ACTION
  // ----------------------------------------------------------

  final Map<String, dynamic>? action =
      await aiService.detectWardrobeAction(
    message,
    wardrobe: wardrobeContext,
  );

  if (action == null) {
    return false;
  }

  if (action['action'] != 'add_clothing') {
    return false;
  }

  // ----------------------------------------------------------
  // GET ADD ITEM INFORMATION
  // ----------------------------------------------------------

  final String name =
      action['name']
              ?.toString()
              .trim() ??
          '';

  final String category =
      action['category']
              ?.toString()
              .trim() ??
          '';

  final String? color =
      action['color']
          ?.toString()
          .trim();

  if (name.isEmpty ||
      category.isEmpty) {
    return false;
  }

  // ----------------------------------------------------------
  // VALIDATE CATEGORY
  // ----------------------------------------------------------

  const List<String> allowedCategories = [
    'Top',
    'Bottom',
    'Shoes',
    'Outerwear',
    'Accessories',
  ];

  if (!allowedCategories.contains(category)) {
    return false;
  }

  // ----------------------------------------------------------
  // CHECK DUPLICATE
  // ----------------------------------------------------------

  final bool alreadyExists =
      existingItems.any(
    (item) =>
        aiService.normalizeClothingName(
          item.name,
        ) ==
        aiService.normalizeClothingName(
          name,
        ),
  );

  if (alreadyExists) {
    const String response =
        'That clothing item is already in your wardrobe.';

    await databaseService.saveAIMessage(
      isUser: false,
      messageType: 'text',
      content: response,
    );

    if (!mounted) {
      return true;
    }

    setState(() {
      messages.add(
        const ClosetlyAIMessage(
          text: response,
          isUser: false,
        ),
      );

      currentWardrobe =
          existingItems;

      isLoading = false;
    });

    _scrollToBottom();

    return true;
  }

  // ----------------------------------------------------------
  // CREATE NEW CLOTHING ITEM
  // ----------------------------------------------------------

  final ClothingItem newItem =
      ClothingItem(
    id: DateTime.now()
        .microsecondsSinceEpoch
        .toString(),

    name: name,

    category: category,

    color:
        color == null ||
                color.isEmpty
            ? null
            : color,

    imagePath: null,

    imageBytes: null,
  );

  // ----------------------------------------------------------
  // SAVE TO LOCAL DATABASE
  // ----------------------------------------------------------

  await wardrobeService.addClothing(
    newItem,
  );

  // ----------------------------------------------------------
  // CONFIRMATION MESSAGE
  // ----------------------------------------------------------

  final String confirmation =
      color == null ||
              color.isEmpty
          ? 'Added **$name** to your wardrobe.'
          : 'Added **$name** ($color) to your wardrobe.';

  await databaseService.saveAIMessage(
    isUser: false,
    messageType: 'text',
    content: confirmation,
  );

  // ----------------------------------------------------------
  // REFRESH WARDROBE
  // ----------------------------------------------------------

  final List<ClothingItem>
      updatedWardrobe =
      await wardrobeService
          .getClothingItems();

  if (!mounted) {
    return true;
  }

  setState(() {
    messages.add(
      ClosetlyAIMessage(
        text: confirmation,
        isUser: false,
      ),
    );

    currentWardrobe =
        updatedWardrobe;

    isLoading = false;
  });

  _scrollToBottom();

  return true;
}

Future<bool> _tryDeleteClothingFromChat(
  String message,
) async {
  if (!_looksLikeDeleteClothingRequest(message)) {
    return false;
  }

  final Map<String, dynamic>? action =
      await aiService.detectWardrobeAction(
    message,
  );

  if (action == null) {
    return false;
  }

  if (action['action'] != 'remove_clothing') {
    return false;
  }

  final String name =
      action['name']?.toString().trim() ?? '';

  final String category =
      action['category']?.toString().trim() ?? '';

  final String color =
      action['color']?.toString().trim() ?? '';

  final List<ClothingItem> wardrobe =
      await wardrobeService.getClothingItems();

  List<ClothingItem> candidates =
      wardrobe.where((item) {
    final bool categoryMatches =
        category.isEmpty ||
        item.category.toLowerCase() ==
            category.toLowerCase();

    final bool colorMatches =
        color.isEmpty ||
        (item.color?.toLowerCase() ?? '') ==
            color.toLowerCase();

    return categoryMatches && colorMatches;
  }).toList();

  // First try exact item name.
  if (name.isNotEmpty) {
    final List<ClothingItem> exactMatches =
        wardrobe.where((item) {
      return item.name.trim().toLowerCase() ==
          name.toLowerCase();
    }).toList();

    if (exactMatches.length == 1) {
      candidates = exactMatches;
    }
  }

  if (candidates.isEmpty) {
    const String response =
        'I could not find that item in your wardrobe.';

    await databaseService.saveAIMessage(
      isUser: false,
      messageType: 'text',
      content: response,
    );

    if (!mounted) return true;

    setState(() {
      messages.add(
        const ClosetlyAIMessage(
          text: response,
          isUser: false,
        ),
        );
      isLoading = false;
    });

    _scrollToBottom();

    return true;
  }

  // Don't delete the wrong item when multiple items match.
  if (candidates.length > 1) {
    final String itemList = candidates
        .map((item) => '• ${item.name}')
        .join('\n');

    final String response =
        'I found multiple matching items. Which one should I remove?\n\n'
        '$itemList';

    await databaseService.saveAIMessage(
      isUser: false,
      messageType: 'text',
      content: response,
    );

    if (!mounted) return true;

    setState(() {
      messages.add(
        ClosetlyAIMessage(
          text: response,
          isUser: false,
        ),
      );

      isLoading = false;
    });

    _scrollToBottom();

    return true;
  }

  final ClothingItem itemToDelete =
      candidates.first;

  await wardrobeService.deleteClothing(
    itemToDelete.id,
  );

  final String response =
      'Removed **${itemToDelete.name}** from your wardrobe.';

  await databaseService.saveAIMessage(
    isUser: false,
    messageType: 'text',
    content: response,
  );

  final List<ClothingItem> updatedWardrobe =
      await wardrobeService.getClothingItems();

  if (!mounted) return true;

  setState(() {
    messages.add(
      ClosetlyAIMessage(
        text: response,
        isUser: false,
      ),
    );

    currentWardrobe = updatedWardrobe;
    isLoading = false;
  });

  _scrollToBottom();

  return true;
}

  Future<void> _showAIError({
  required Object error,
  required bool outfitRequest,
  String? failedMessage,
}) async {
  final String errorMessage =
      _getFriendlyAIError(error);

  _lastFailureWasOutfitRequest =
      outfitRequest;

  _lastFailedMessage =
      failedMessage;

  // Log the technical error only during development.
  debugPrint(
    'Closetly AI error: $error',
  );

  if (!mounted) return;

  setState(() {
    // Remove any existing AI service error.
    messages.removeWhere(
      (message) =>
          !message.isUser &&
          _isAIErrorMessage(message.text),
    );

    // Add exactly one error message.
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

Future<void> _retryLastRequest() async {
  // Prevent accidental multiple taps.
  if (isLoading || _isRetrying) return;

  // Start retry state immediately.
  if (mounted) {
    setState(() {
      _isRetrying = true;
      isLoading = true;
    });
  }

  try {
    // ==========================================================
    // REMOVE THE CURRENT ERROR MESSAGE
    // ==========================================================

    if (mounted) {
      setState(() {
        messages.removeWhere(
          (message) =>
              !message.isUser &&
              _isAIErrorMessage(message.text),
        );
      });
    }

    // ==========================================================
    // RETRY FAILED IMAGE REQUEST
    // ==========================================================

    if (_lastFailedImageBytes != null &&
        _lastFailedImageMimeType != null) {
      final Uint8List imageBytes =
          Uint8List.fromList(
        _lastFailedImageBytes!,
      );

      final String mimeType =
          _lastFailedImageMimeType!;

      final String message =
          _lastFailedMessage ?? '';

      _lastFailedImageBytes = null;
      _lastFailedImageMimeType = null;

      await _sendImageToVision(
        message: message,
        imageBytes: imageBytes,
        mimeType: mimeType,
      );

      return;
    }

    // ==========================================================
    // RETRY OUTFIT REQUEST
    // ==========================================================

    if (_lastFailureWasOutfitRequest) {
      await generateOutfits(
        isRetry: true,
      );

      return;
    }

    // ==========================================================
    // RETRY TRENDING REQUEST
    // ==========================================================

    if (_lastFailureWasTrending) {
      _lastFailureWasTrending = false;

      await _askTrending();

      return;
    }

    // ==========================================================
    // RETRY NORMAL TEXT REQUEST
    // ==========================================================

    final String? failedMessage =
        _lastFailedMessage;

    if (failedMessage == null ||
        failedMessage.trim().isEmpty) {
      return;
    }

    await _sendMessageRequest(
      failedMessage,
      isRetry: true,
    );
  } finally {
    // Retry has finished.
    if (mounted) {
      setState(() {
        _isRetrying = false;
        isLoading = false;
      });
    }
  }
}

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

      for (final Map<String, dynamic> saved in savedMessages) {
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
                      .map(OutfitSuggestion.fromJson)
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
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isConversationLoading = false;
      });

      _showWelcome();
    }
  }

  Future<void> _showWelcome() async {
  const String welcomeMessage =
      "Hi! I'm Closetly AI ✨\n\n"
      "I'm your personal wardrobe assistant. "
      "I can help you create outfits and make "
      "the most out of the clothes you already own.";

  // Add it to the current screen.
  if (mounted) {
    setState(() {
      messages.add(
        const ClosetlyAIMessage(
          text: welcomeMessage,
          isUser: false,
        ),
      );
    });
  }

  // Save it permanently.
  await databaseService.saveAIMessage(
    isUser: false,
    messageType: 'welcome',
    content: welcomeMessage,
  );
}

  // --------------------------------------------------
  // CLEAR CONVERSATION
  // --------------------------------------------------

  Future<void> _confirmClearConversation() async {
  final ThemeData theme = Theme.of(context);
  final ColorScheme colors = theme.colorScheme;

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Clear Conversation?',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to clear your '
          'Closetly AI conversation?\n\n'
          'This cannot be undone.',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: Text(
              'CANCEL',
              style: TextStyle(
                color: colors.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: Text(
              'CLEAR',
              style: TextStyle(
                color: theme.brightness == Brightness.dark
                    ? Colors.red.shade200
                    : Colors.red.shade700,
              ),
            ),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;

  // Invalidate any request that is currently running.
  _conversationVersion++;

  // Clear the database first.
  await databaseService.clearAIMessages();

  if (!mounted) return;

  setState(() {
    messages.clear();

    // IMPORTANT: remove the thinking indicator.
    isLoading = false;

    // Clear retry information.
    _lastFailedMessage = null;
    _lastFailureWasOutfitRequest = false;
  });

  await _showWelcome();

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Conversation cleared.'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}


  // --------------------------------------------------
  // SEND NORMAL MESSAGE
  // --------------------------------------------------

  bool _isOutfitGenerationRequest(String message) {
    final String text = message.toLowerCase().trim();

    return text.contains('generate outfit') ||
        text.contains('generate outfits') ||
        text.contains('outfit ideas') ||
        text.contains('suggest an outfit') ||
        text.contains('suggest outfits') ||
        text.contains('give me an outfit') ||
        text.contains('give me outfit') ||
        text.contains('make me an outfit') ||
        text.contains('create an outfit') ||
        text.contains('create outfit');
  }

  Future<void> _pickChatImage() async {
  final XFile? image = await imagePicker.pickImage(
    source: ImageSource.gallery,
  );

  if (image == null) return;

  final Uint8List bytes =
      await image.readAsBytes();

  if (!mounted) return;

  setState(() {
    selectedChatImage = bytes;
    selectedChatImageMimeType =
        image.mimeType ?? 'image/jpeg';
  });
}

  Future<void> sendMessage() async {
  final String message =
      messageController.text.trim();

  // Allow either text OR an image.
  if ((message.isEmpty &&
          selectedChatImage == null) ||
      isLoading) {
    return;
  }

  // --------------------------------------------------
  // IMAGE MESSAGE
  // --------------------------------------------------

  if (selectedChatImage != null) {
    await _sendImageToVision(
      message: message,
      imageBytes: selectedChatImage!,
      mimeType:
          selectedChatImageMimeType ??
              'image/jpeg',
    );

    return;
  }

  // --------------------------------------------------
  // NORMAL TEXT MESSAGE
  // --------------------------------------------------

  messageController.clear();

  if (_isOutfitGenerationRequest(message)) {
    await generateOutfits(
      isRetry: false,
      userRequest: message,
    );
    return;
  }

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

await _sendMessageRequest(
  message,
  isRetry: false,
);
}

Future<void> _sendImageToVision({
  required String message,
  required Uint8List imageBytes,
  required String mimeType,
}) async {
  if (isLoading) return;

  final int requestVersion = _conversationVersion;

  setState(() {
    isLoading = true;
  });

  try {
    // ==========================================================
    // 1. CONVERT IMAGE TO BASE64
    // ==========================================================

    final String base64Data =
        base64Encode(imageBytes);

    final String imageDataUrl =
        'data:$mimeType;base64,$base64Data';

    // ==========================================================
    // 2. SEND IMAGE TO AI VISION
    // ==========================================================

    final Map<String, dynamic> result =
        await aiService.analyzeClothingImage(
      imageBase64: imageDataUrl,
    );

    // Make sure this request is still relevant.
    if (!mounted ||
        requestVersion != _conversationVersion) {
      return;
    }

    // ==========================================================
    // 3. CHECK IF IMAGE IS ACTUALLY CLOTHING
    // ==========================================================

    final bool isClothing =
        result['is_clothing'] == true;

    if (!isClothing) {
      const String response =
          "I couldn't identify a clothing item in this photo.\n\n"
          "Please upload a clear photo of a shirt, pants, "
          "shoes, jacket, or accessory.";

      await databaseService.saveAIMessage(
        isUser: true,
        messageType: 'image',
        content: '📷 Clothing photo',
      );

      await databaseService.saveAIMessage(
        isUser: false,
        messageType: 'validation',
        content: response,
      );

      if (!mounted ||
          requestVersion != _conversationVersion) {
        return;
      }

      setState(() {
        messages.add(
          const ClosetlyAIMessage(
            text: '📷 Clothing photo',
            isUser: true,
          ),
        );

        messages.add(
          const ClosetlyAIMessage(
            text: response,
            isUser: false,
          ),
        );

        selectedChatImage = null;
        selectedChatImageMimeType = null;

        _lastFailedImageBytes = null;
        _lastFailedImageMimeType = null;
        _lastFailedMessage = null;

        isLoading = false;
      });

      _scrollToBottom();

      return;
    }

    // ==========================================================
    // 4. READ AI DETECTION
    // ==========================================================

    final String name =
        result['name']?.toString().trim() ?? '';

    final String category =
        result['category']?.toString().trim() ?? '';

    final String color =
        result['color']?.toString().trim() ?? '';

    // ==========================================================
    // 5. VALIDATE AI RESPONSE
    // ==========================================================

    if (name.isEmpty ||
        category.isEmpty ||
        color.isEmpty) {
      const String response =
          "I couldn't identify the clothing details clearly.\n\n"
          "Please upload a clearer photo and try again.";

      await databaseService.saveAIMessage(
        isUser: true,
        messageType: 'image',
        content: '📷 Clothing photo',
      );

      await databaseService.saveAIMessage(
        isUser: false,
        messageType: 'validation',
        content: response,
      );

      if (!mounted ||
          requestVersion != _conversationVersion) {
        return;
      }

      setState(() {
        messages.add(
          const ClosetlyAIMessage(
            text: '📷 Clothing photo',
            isUser: true,
          ),
        );

        messages.add(
          const ClosetlyAIMessage(
            text: response,
            isUser: false,
          ),
        );

        selectedChatImage = null;
        selectedChatImageMimeType = null;
        isLoading = false;
      });

      _scrollToBottom();

      return;
    }

    // ==========================================================
    // 6. NORMALIZE CATEGORY
    // ==========================================================

    const List<String> allowedCategories = [
      'Top',
      'Bottom',
      'Shoes',
      'Outerwear',
      'Accessories',
    ];

    String finalCategory = category;

    final String matchedCategory =
        allowedCategories.firstWhere(
      (allowedCategory) =>
          allowedCategory.toLowerCase() ==
          category.toLowerCase(),
      orElse: () => '',
    );

    if (matchedCategory.isNotEmpty) {
      finalCategory = matchedCategory;
    } else {
      // AI returned an unknown category.
      const String response =
          "I identified the clothing item, but I couldn't "
          "determine a valid category for it.";

      await databaseService.saveAIMessage(
        isUser: true,
        messageType: 'image',
        content: '📷 Clothing photo',
      );

      await databaseService.saveAIMessage(
        isUser: false,
        messageType: 'validation',
        content: response,
      );

      if (!mounted ||
          requestVersion != _conversationVersion) {
        return;
      }

      setState(() {
        messages.add(
          const ClosetlyAIMessage(
            text: '📷 Clothing photo',
            isUser: true,
          ),
        );

        messages.add(
          const ClosetlyAIMessage(
            text: response,
            isUser: false,
          ),
        );

        selectedChatImage = null;
        selectedChatImageMimeType = null;
        isLoading = false;
      });

      _scrollToBottom();

      return;
    }

    // ==========================================================
    // 7. LOAD CURRENT WARDROBE
    // ==========================================================

    final List<ClothingItem> wardrobe =
        await wardrobeService.getClothingItems();
        
    // ==========================================================
    // 8. CHECK FOR DUPLICATE
    // ==========================================================

    final String normalizedDetectedName =
        aiService.normalizeClothingName(name);

    ClothingItem? existingItem;

    // First check normalized clothing name.
    for (final ClothingItem item in wardrobe) {
      if (aiService.normalizeClothingName(item.name) ==
          normalizedDetectedName) {
        existingItem = item;
        break;
      }
    }

    // If the name does not match, check the actual image.
    if (existingItem == null) {
      for (final ClothingItem item in wardrobe) {
        if (item.imageBytes == null) {
          continue;
        }

        if (_imagesAreIdentical(
          item.imageBytes!,
          imageBytes,
        )) {
          existingItem = item;
          break;
        }
      }
    }

    final bool alreadyExists =
        existingItem != null;
    // ==========================================================
    // 9. SAVE NEW CLOTHING ITEM
    // ==========================================================

    if (!alreadyExists) {
      final ClothingItem newItem =
          ClothingItem(
        id: DateTime.now()
            .microsecondsSinceEpoch
            .toString(),
        name: name,
        category: finalCategory,
        color: color,
        imagePath: null,
        imageBytes: Uint8List.fromList(
          imageBytes,
        ),
      );

      await wardrobeService.addClothing(
        newItem,
      );
    }

    // ==========================================================
    // 10. GET UPDATED WARDROBE
    // ==========================================================

    final List<ClothingItem> updatedWardrobe =
        await wardrobeService.getClothingItems();

    // ==========================================================
    // 11. CREATE AI RESPONSE
    // ==========================================================

   final String visionMessage;

if (existingItem != null) {
  final String existingColor =
      existingItem.color?.trim().isNotEmpty == true
          ? existingItem.color!.trim()
          : 'Not specified';

  visionMessage =
      'I identified this clothing item as:\n\n'
      '**${existingItem.name}**\n'
      'Category: ${existingItem.category}\n'
      'Color: $existingColor\n\n'
      'You already have this item in your wardrobe, '
      'so I did not add a duplicate.';
} else {
  visionMessage =
      'I identified and added this clothing item '
      'to your wardrobe:\n\n'
      '**$name**\n'
      'Category: $finalCategory\n'
      'Color: $color';
}
    // ==========================================================
    // 12. SAVE CHAT HISTORY
    // ==========================================================

    final String userMessage =
        message.trim().isEmpty
            ? '📷 Clothing photo'
            : message;

    await databaseService.saveAIMessage(
      isUser: true,
      messageType: 'image',
      content: userMessage,
    );

    await databaseService.saveAIMessage(
      isUser: false,
      messageType: 'text',
      content: visionMessage,
    );

    // ==========================================================
    // 13. UPDATE SCREEN
    // ==========================================================

    if (!mounted ||
        requestVersion != _conversationVersion) {
      return;
    }

    setState(() {
      messages.add(
        ClosetlyAIMessage(
          text: userMessage,
          isUser: true,
        ),
      );

      messages.add(
        ClosetlyAIMessage(
          text: visionMessage,
          isUser: false,
        ),
      );

      currentWardrobe = updatedWardrobe;

      selectedChatImage = null;
      selectedChatImageMimeType = null;

      isLoading = false;
    });

    _scrollToBottom();
  } catch (e) {
  _lastFailedImageBytes =
      Uint8List.fromList(imageBytes);

  _lastFailedImageMimeType =
      mimeType;

  _lastFailedMessage =
      message;

  await _showAIError(
    error: e,
    outfitRequest: false,
    failedMessage: message,
  );

  if (!mounted) return;

  setState(() {
    selectedChatImage = null;
    selectedChatImageMimeType = null;
    isLoading = false;
  });
}
}

bool _imagesAreIdentical(
  Uint8List first,
  Uint8List second,
) {
  if (first.length != second.length) {
    return false;
  }

  for (int i = 0; i < first.length; i++) {
    if (first[i] != second[i]) {
      return false;
    }
  }

  return true;
}

 Future<bool> _tryUpdateClothingFromChat(
  String message,
) async {
  final String lowerMessage = message.toLowerCase();

  final bool looksLikeUpdate =
      lowerMessage.contains('update') ||
      lowerMessage.contains('edit') ||
      lowerMessage.contains('change') ||
      lowerMessage.contains('rename') ||
      lowerMessage.contains('modify') ||
      lowerMessage.contains('set');

  if (!looksLikeUpdate) {
    return false;
  }

  try {
    final Map<String, dynamic>? action =
        await aiService.detectWardrobeAction(message);

    if (action == null ||
        action['action']?.toString() !=
            'update_clothing') {
      return false;
    }

    // IMPORTANT:
    // Your detectWardrobeAction() returns the existing
    // clothing name under "name".
    final String oldName =
        action['name']?.toString().trim() ?? '';

    if (oldName.isEmpty) {
      return false;
    }

    final List<ClothingItem> wardrobe =
        await wardrobeService.getClothingItems();
        

    final List<ClothingItem> matches =
        wardrobe.where(
      (item) =>
          item.name.trim().toLowerCase() ==
          oldName.toLowerCase(),
    ).toList();

    if (matches.isEmpty) {
  const String response =
      'I could not find that clothing item in your wardrobe.';

      await databaseService.saveAIMessage(
        isUser: false,
        messageType: 'text',
        content: response,
      );

      if (!mounted) return true;

      setState(() {
        messages.add(
          const ClosetlyAIMessage(
            text: response,
            isUser: false,
          ),
        );

        isLoading = false;
      });

      _scrollToBottom();

      return true;
    }

    if (matches.length > 1) {
    const String response =
        'I found multiple clothing items with that name. '
        'Please specify which one you want to update.';

    await databaseService.saveAIMessage(
      isUser: false,
      messageType: 'text',
      content: response,
    );

    if (!mounted) return true;

    setState(() {
      messages.add(
        const ClosetlyAIMessage(
          text: response,
          isUser: false,
        ),
      );

      isLoading = false;
    });

    _scrollToBottom();

    return true;
  }
    final ClothingItem existingItem =
        matches.first;

    String newName =
    action['new_name']?.toString().trim().isNotEmpty == true
        ? action['new_name'].toString().trim()
        : existingItem.name;

    final String newCategory =
        action['new_category']?.toString().trim().isNotEmpty == true
            ? action['new_category'].toString().trim()
            : existingItem.category;

    final String newColor =
        action['new_color']?.toString().trim().isNotEmpty == true
            ? action['new_color'].toString().trim()
            : (existingItem.color ?? '');

    // ==========================================================
// SYNCHRONIZE COLOR WITH CLOTHING NAME
// ==========================================================

final String oldColor =
    existingItem.color?.trim() ?? '';

if (newColor.isNotEmpty &&
    oldColor.isNotEmpty &&
    oldColor.toLowerCase() != newColor.toLowerCase()) {
  final RegExp colorPattern =
      RegExp(
        RegExp.escape(oldColor),
        caseSensitive: false,
      );

  if (colorPattern.hasMatch(newName)) {
    newName = newName.replaceFirst(
      colorPattern,
      newColor,
    );
  }
}
    const List<String> allowedCategories = [
      'Top',
      'Bottom',
      'Shoes',
      'Outerwear',
      'Accessories',
    ];

    if (!allowedCategories.contains(newCategory)) {
      return false;
    }

    final ClothingItem updatedItem =
        ClothingItem(
      id: existingItem.id,
      name: newName,
      category: newCategory,
      color: newColor,
      imagePath: existingItem.imagePath,
      imageBytes: existingItem.imageBytes,
    );

    await wardrobeService.updateClothing(
      updatedItem,
    );

    final List<ClothingItem> updatedWardrobe =
        await wardrobeService.getClothingItems();

    final String response =
        '**Clothing item updated successfully.**\n\n'
        '**$newName**\n'
        'Category: $newCategory\n'
        'Color: $newColor';

    await databaseService.saveAIMessage(
      isUser: false,
      messageType: 'text',
      content: response,
    );

    if (!mounted) return true;

    setState(() {
    messages.add(
      ClosetlyAIMessage(
        text: response,
        isUser: false,
      ),
    );

    currentWardrobe = updatedWardrobe;
    isLoading = false;
  });

    _scrollToBottom();

    return true;
  } catch (e) {
    await _showAIError(
      error: e,
      outfitRequest: false,
      failedMessage: message,
    );

    return true;
  }
}

Future<void> recommendWardrobeAdditionsFromChat({
  bool isRetry = false,
}) async {
  if (isLoading) return;

  const String request =
      'What clothing items should I add to my wardrobe?';

  if (!isRetry) {
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
  } else {
    setState(() {
      isLoading = true;
    });
  }

  try {
    final List<ClothingItem> wardrobe =
        await wardrobeService.getClothingItems();

    final String aiResponse =
    await aiService.recommendWardrobeAdditions(
    wardrobe,
  );

  final List<Map<String, dynamic>>?
      recommendations =
      aiService.parseWardrobeAdditions(
    aiResponse,
    wardrobe,
  );
    if (recommendations == null ||
        recommendations.isEmpty) {
      const String response =
          'Your wardrobe does not have enough information '
          'for me to make useful additions yet.';

      await databaseService.saveAIMessage(
        isUser: false,
        messageType: 'text',
        content: response,
      );

      if (!mounted) return;

      setState(() {
        messages.add(
          const ClosetlyAIMessage(
            text: response,
            isUser: false,
          ),
        );

        isLoading = false;
      });

      _scrollToBottom();
      return;
    }

    final StringBuffer response =
        StringBuffer();

    response.writeln(
      '**Clothing you could add to your wardrobe:**\n',
    );

    for (int i = 0;
        i < recommendations.length;
        i++) {
      final Map<String, dynamic> item =
          recommendations[i];

      final String name =
          item['item']?.toString() ?? '';

      final String category =
          item['category']?.toString() ?? '';

      final String color =
          item['color']?.toString() ?? '';

      final String reason =
          item['reason']?.toString() ?? '';

      response.writeln(
        '**${i + 1}. $name**',
      );

      if (category.isNotEmpty) {
        response.writeln(
          'Category: $category',
        );
      }

      if (color.isNotEmpty) {
        response.writeln(
          'Color: $color',
        );
      }

      if (reason.isNotEmpty) {
        response.writeln(
          'Why: $reason',
        );
      }

      response.writeln();
    }

    final String finalResponse =
        response.toString().trim();

    await databaseService.saveAIMessage(
      isUser: false,
      messageType: 'text',
      content: finalResponse,
    );

    if (!mounted) return;

    setState(() {
      messages.add(
        ClosetlyAIMessage(
          text: finalResponse,
          isUser: false,
        ),
      );

      currentWardrobe = wardrobe;
      isLoading = false;
    });

    _scrollToBottom();
  } catch (e) {
    await _showAIError(
      error: e,
      outfitRequest: false,
      failedMessage: request,
    );
  }
}

  Future<void> _sendMessageRequest(
  String message, {
  required bool isRetry,
  }) async {
    try {
      final bool handledDelete =
    await _tryDeleteClothingFromChat(message);

if (handledDelete) return;

final bool handledUpdate =
    await _tryUpdateClothingFromChat(message);

if (handledUpdate) return;

final bool handledAdd =
    await _tryAddClothingFromChat(message);

if (handledAdd) return;

      final List<ClothingItem> wardrobe =
       await wardrobeService.getClothingItems();

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

      // Request succeeded, so clear the retry state.
      _lastFailedMessage = null;
      _lastFailureWasOutfitRequest = false;

      if (suggestions != null &&
          suggestions.isNotEmpty) {
        await _saveOutfitMessage(suggestions);

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
      await _showAIError(
        error: e,
        outfitRequest: false,
        failedMessage: message,
      );
    }
  }

  // --------------------------------------------------
  // GENERATE OUTFITS
  // --------------------------------------------------

  Future<void> generateOutfits({
    bool isRetry = false,
    String? userRequest,
  }) async {
    if (isLoading) return;

    final String request =
        userRequest ??
        'Give me outfit ideas from my wardrobe.';

    if (!isRetry) {
      setState(() {
        messages.add(
          ClosetlyAIMessage(
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
    } else {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final List<ClothingItem> wardrobe =
          await wardrobeService.getClothingItems();

      currentWardrobe = wardrobe;

      // Do not call Llama when the wardrobe cannot form
      // a complete Top + Bottom + Shoes outfit.
      if (!aiService.canGenerateCompleteOutfit(
        wardrobe,
      )) {
        final String message =
            aiService.getOutfitAvailabilityMessage(
          wardrobe,
        );

        await databaseService.saveAIMessage(
          isUser: false,
          messageType: 'text',
          content: message,
        );

        if (!mounted) return;

        setState(() {
          messages.add(
            ClosetlyAIMessage(
              text: message,
              isUser: false,
            ),
          );

          isLoading = false;

          _lastFailedMessage = null;
          _lastFailureWasOutfitRequest = false;
        });

        _scrollToBottom();
        return;
      }

      final String response =
          await aiService
              .generateOutfits(wardrobe)
              .timeout(
                const Duration(seconds: 30),
              );

      List<OutfitSuggestion>? suggestions =
          aiService.parseOutfitSuggestions(
        response,
        wardrobe,
      );

      // If Llama returns malformed JSON, fall back to the
      // deterministic candidates instead of showing raw AI text.
      if (suggestions == null ||
          suggestions.isEmpty) {
        suggestions =
            aiService.buildFallbackOutfitSuggestions(
          wardrobe,
        );
      }

      _lastFailedMessage = null;
      _lastFailureWasOutfitRequest = false;

      if (suggestions.isNotEmpty) {
        await _saveOutfitMessage(suggestions);

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

      const String message =
          'I could not create a complete outfit from your current wardrobe yet. '
          'Try adding a top, bottom, and shoes.';

      await databaseService.saveAIMessage(
        isUser: false,
        messageType: 'text',
        content: message,
      );

      if (!mounted) return;

      setState(() {
        currentWardrobe = wardrobe;

        messages.add(
          const ClosetlyAIMessage(
            text: message,
            isUser: false,
          ),
        );

        isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      await _showAIError(
        error: e,
        outfitRequest: true,
        failedMessage: request,
      );
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
    messageController.text =
        'What can I wear from my wardrobe?';

    messageFocusNode.requestFocus();

    messageController.selection =
        TextSelection.fromPosition(
      TextPosition(
        offset: messageController.text.length,
      ),
    );
  }

  void _checkOutfit() {
    messageController.text =
        'Can you check an outfit for me?';

    messageFocusNode.requestFocus();

    messageController.selection =
        TextSelection.fromPosition(
      TextPosition(
        offset: messageController.text.length,
      ),
    );
  }

  Future<void> _askTrending() async {
  // Prevent multiple requests.
  // During a retry, allow _askTrending() to run again.
  if (isLoading && !_isRetrying) return;

  setState(() {
    isLoading = true;
  });

  try {
    final String response =
        await aiService
            .getTrendingMessage()
            .timeout(
              const Duration(seconds: 30),
            );

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

      isLoading = false;

      // Trending request succeeded.
     _lastFailureWasTrending = false;

      _lastFailedMessage = null;
      _lastFailureWasOutfitRequest = false;
    });

    _scrollToBottom();
  } catch (e) {
    final String errorMessage =
        e is AIServiceException
            ? e.userMessage
            : 'Sorry, I could not load the latest trend signals. Please try again.';

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

      // Remember that the failed request was Trending.
      _lastFailureWasTrending = true;
    });

    _scrollToBottom();
  }
}

  // --------------------------------------------------
  // SCROLL
  // --------------------------------------------------

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) {
        return;
      }

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    final Color pageBackground = isDark
        ? const Color(0xFF08051F)
        : colors.surface;

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: isConversationLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: colors.primary,
                      ),
                    )
                  : _buildMainContent(),
            ),

            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // HEADER
  // --------------------------------------------------

  Widget _buildHeader() {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    final Color headerBackground = isDark
        ? const Color(0xFF100B31)
        : colors.surface;

    final Color borderColor = isDark
        ? const Color(0xFF241B4A)
        : colors.outlineVariant;

    final Color secondaryText = isDark
        ? const Color(0xFFAAA4C2)
        : colors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        12,
        12,
        12,
      ),
      decoration: BoxDecoration(
        color: headerBackground,
        border: Border(
          bottom: BorderSide(
            color: borderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.checkroom_rounded,
              color: colors.onPrimary,
              size: 25,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Closetly AI',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Row(
                  children: [
                    const Icon(
                      Icons.circle,
                      color: Color(0xFF56E39F),
                      size: 7,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      'Your wardrobe assistant',
                      style: TextStyle(
                        color: secondaryText,
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
                builder: (context) {
                  final ThemeData dialogTheme =
                      Theme.of(context);

                  final ColorScheme dialogColors =
                      dialogTheme.colorScheme;

                  return AlertDialog(
                    backgroundColor:
                        dialogColors.surface,
                    title: Text(
                      'Closetly AI',
                      style: TextStyle(
                        color:
                            dialogColors.onSurface,
                      ),
                    ),
                    content: Text(
                      'Your personal wardrobe assistant. '
                      'Closetly AI uses the clothes saved '
                      'in your wardrobe to help create '
                      'outfit ideas.',
                      style: TextStyle(
                        color: dialogColors
                            .onSurfaceVariant,
                      ),
                    ),
                  );
                },
              );
            },
            icon: Icon(
              Icons.info_outline_rounded,
              color: secondaryText,
            ),
          ),

          IconButton(
            tooltip: 'Clear Conversation',
            onPressed:
                _confirmClearConversation,
            icon: Icon(
              Icons.delete_outline_rounded,
              color: secondaryText,
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
  return ListView(
    controller: scrollController,
    padding: const EdgeInsets.fromLTRB(
      20,
      28,
      20,
      24,
    ),
    children: [
      _buildWelcomeSection(),

      _buildQuickActionsSection(),

      ...messages.map(_buildMessage),

      if (isLoading) _buildLoadingMessage(),
    ],
  );
}

  // --------------------------------------------------
  // WELCOME
  // --------------------------------------------------

  Widget _buildWelcomeSection() {
  final ThemeData theme = Theme.of(context);
  final ColorScheme colors = theme.colorScheme;

  final bool isDark =
      theme.brightness == Brightness.dark;

  final Color iconBackground = isDark
      ? const Color(0xFF21164C)
      : colors.primaryContainer;

  final Color secondaryText = isDark
      ? const Color(0xFFAAA4C2)
      : colors.onSurfaceVariant;

  return Column(
    children: [
      Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: iconBackground,
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(
                      alpha: 0.22,
                    ),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.auto_awesome_rounded,
          color: colors.primary,
          size: 45,
        ),
      ),

      const SizedBox(height: 22),

      Text(
        "Hi! I'm Closetly AI ✨",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.onSurface,
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 8),

      Text(
        'Your personal wardrobe assistant',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: secondaryText,
          fontSize: 14,
        ),
      ),

      const SizedBox(height: 28),
    ],
  );
}

Widget _buildQuickActionsSection() {
  return Column(
    children: [
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

      // NEW
      _buildQuickAction(
        icon: Icons.add_shopping_cart_rounded,
        label: 'What should I add?',
        onTap: () {
          recommendWardrobeAdditionsFromChat();
        },
      ),

      const SizedBox(height: 8),
    ],
  );
}

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    final Color cardBackground = isDark
        ? const Color(0xFF151033)
        : colors.surfaceContainerHighest;

    final Color borderColor = isDark
        ? const Color(0xFF29204F)
        : colors.outlineVariant;

    final Color iconBackground = isDark
        ? const Color(0xFF261858)
        : colors.primaryContainer;

    final Color secondaryText = isDark
        ? const Color(0xFF71688F)
        : colors.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      width: double.infinity,
      child: Material(
        color: cardBackground,
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
                color: borderColor,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius:
                        BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    color: colors.primary,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: secondaryText,
                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  bool _isAIErrorMessage(String text) {
  return text.startsWith(
        'Connection unavailable',
      ) ||
      text.startsWith(
        'AI service unavailable',
      ) ||
      text.startsWith(
        'Request timed out',
      ) ||
      text.startsWith(
        'Something went wrong',
      );
}

  Widget _buildFormattedAIText(
    String text,
    Color textColor,
  ) {
    final List<TextSpan> spans = [];

    final RegExp pattern = RegExp(
      r'\*\*(.*?)\*\*|\*(.*?)\*',
      dotAll: true,
    );

    int currentIndex = 0;

    for (final RegExpMatch match
        in pattern.allMatches(text)) {
      if (match.start > currentIndex) {
        spans.add(
          TextSpan(
            text: text.substring(
              currentIndex,
              match.start,
            ),
          ),
        );
      }

      final String content =
          match.group(1) ??
          match.group(2) ??
          '';

      spans.add(
        TextSpan(
          text: content,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(
            currentIndex,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          height: 1.45,
        ),
        children: spans,
      ),
    );
  }

  // --------------------------------------------------
  // MESSAGE
  // --------------------------------------------------


  Widget _buildMessage(
    ClosetlyAIMessage message,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    final Color aiBubble = isDark
        ? const Color(0xFF151033)
        : colors.surfaceContainerHighest;

    final Color borderColor = isDark
        ? const Color(0xFF29204F)
        : colors.outlineVariant;

    if (message.outfits != null &&
        message.outfits!.isNotEmpty) {
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 4,
              bottom: 12,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: colors.primary,
                  size: 18,
                ),

                const SizedBox(width: 7),

                Text(
                  'Closetly AI',
                  style: TextStyle(
                    color: colors.onSurface,
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
        margin: const EdgeInsets.only(
          bottom: 14,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? colors.primary
              : aiBubble,
          borderRadius:
              BorderRadius.circular(18),
          border: message.isUser
              ? null
              : Border.all(
                  color: borderColor,
                ),
        ),
       child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormattedAIText(
            message.text,
            message.isUser
                ? colors.onPrimary
                : colors.onSurface,
          ),

          if (!message.isUser &&
              _isAIErrorMessage(message.text)) ...[
            const SizedBox(height: 12),

           OutlinedButton.icon(
          onPressed: isLoading || _isRetrying
              ? null
              : _retryLastRequest,
          icon: Icon(
            _isRetrying
                ? Icons.hourglass_top_rounded
                : Icons.refresh_rounded,
            size: 18,
          ),
          label: Text(
            _isRetrying
                ? 'Retrying...'
                : 'Try Again',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.primary,
            side: BorderSide(
              color: colors.primary.withValues(
                alpha: 0.5,
              ),
            ),
          ),
        ),
          ],
        ],
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    final Color cardBackground = isDark
        ? const Color(0xFF151033)
        : colors.surfaceContainerHighest;

    final Color itemBackground = isDark
        ? const Color(0xFF0E0A25)
        : colors.surface;

    final Color borderColor = isDark
        ? const Color(0xFF30245A)
        : colors.outlineVariant;

    final Color secondaryText = isDark
        ? const Color(0xFFAAA4C2)
        : colors.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
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
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: colors.onPrimary,
                  size: 18,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  outfit.name,
                  style: TextStyle(
                    color: colors.onSurface,
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
                margin: const EdgeInsets.only(
                  bottom: 8,
                ),
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: itemBackground,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.checkroom_outlined,
                      color: colors.primary,
                      size: 18,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: colors.onSurface,
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

            Text(
              'Why it works',
              style: TextStyle(
                color: colors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              outfit.why,
              style: TextStyle(
                color: secondaryText,
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    final Color background = isDark
        ? const Color(0xFF151033)
        : colors.surfaceContainerHighest;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 14,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? const Color(0xFF29204F)
                : colors.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.primary,
              ),
            ),

            const SizedBox(width: 10),

            Text(
              'Closetly AI is thinking...',
              style: TextStyle(
                color:
                    colors.onSurfaceVariant,
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
  final ThemeData theme = Theme.of(context);
  final ColorScheme colors = theme.colorScheme;

  final bool isDark =
      theme.brightness == Brightness.dark;

  final Color barBackground = isDark
      ? const Color(0xFF0D0928)
      : colors.surface;

  final Color inputBackground = isDark
      ? const Color(0xFF151033)
      : colors.surfaceContainerHighest;

  final Color borderColor = isDark
      ? const Color(0xFF30265A)
      : colors.outlineVariant;

  final Color hintColor = isDark
      ? const Color(0xFF77718E)
      : colors.onSurfaceVariant;

  return Container(
    padding: const EdgeInsets.fromLTRB(
      16,
      10,
      16,
      10,
    ),
    decoration: BoxDecoration(
      color: barBackground,
      border: Border(
        top: BorderSide(
          color: isDark
              ? const Color(0xFF241B4A)
              : colors.outlineVariant,
        ),
      ),
    ),
    child: Column(
      children: [
        // --------------------------------------------------
        // SELECTED IMAGE PREVIEW
        // --------------------------------------------------

        if (selectedChatImage != null)
          Container(
            margin: const EdgeInsets.only(
              bottom: 8,
            ),
            height: 70,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(14),
              border: Border.all(
                color: colors.outlineVariant,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(
                  selectedChatImage!,
                  fit: BoxFit.cover,
                ),

                Positioned(
                  top: 5,
                  right: 5,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder:
                          const CircleBorder(),
                      onTap: () {
                        setState(() {
                          selectedChatImage = null;
                          selectedChatImageMimeType = null;
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // --------------------------------------------------
        // MESSAGE INPUT ROW
        // --------------------------------------------------

        Row(
          children: [
            IconButton(
              tooltip: 'Add clothing photo',
              onPressed: isLoading
                  ? null
                  : _pickChatImage,
              icon: Icon(
                Icons.photo_camera_outlined,
                color: colors.primary,
              ),
            ),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: inputBackground,
                  borderRadius:
                      BorderRadius.circular(25),
                  border: Border.all(
                    color: borderColor,
                  ),
                ),
                child: TextField(
                  controller: messageController,
                  focusNode: messageFocusNode,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 14,
                  ),
                  cursorColor: colors.primary,
                  textInputAction:
                      TextInputAction.send,
                  onSubmitted: (_) {
                    sendMessage();
                  },
                  decoration: InputDecoration(
                    hintText:
                        'Ask Closetly AI...',
                    hintStyle: TextStyle(
                      color: hintColor,
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            Material(
              color: isLoading
                  ? colors.surfaceContainerHighest
                  : colors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: isLoading
                    ? null
                    : sendMessage,
                customBorder:
                    const CircleBorder(),
                child: Padding(
                  padding:
                      const EdgeInsets.all(14),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: isLoading
                        ? colors.onSurfaceVariant
                        : colors.onPrimary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
}