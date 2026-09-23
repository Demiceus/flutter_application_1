import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/clothing_item.dart';
import '../models/outfit_suggestion.dart';
import 'closetly_ai_rules.dart';

class AIService {
  static const String baseUrl =
      'http://localhost:11434';

  // ==========================================================
  // BASIC LLAMA REQUEST
  // ==========================================================

  Future<String> generateResponse(
    String prompt,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/generate'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'llama3:latest',
        'prompt': prompt,
        'stream': false,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Llama request failed: ${response.statusCode}',
      );
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    return data['response'] as String;
  }

  // ==========================================================
  // WARDROBE CONTEXT
  // ==========================================================

  String _buildWardrobeContext(
    List<ClothingItem> clothingItems,
  ) {
    if (clothingItems.isEmpty) {
      return '''
The user currently has no clothing items saved.
Do not invent clothing items.
''';
    }

    return clothingItems
        .asMap()
        .entries
        .map((entry) {
          final int number = entry.key + 1;
          final ClothingItem item = entry.value;

          return '''
$number.
EXACT NAME: "${item.name}"
CATEGORY: "${item.category}"
COLOR: "${item.color ?? 'Not specified'}"
''';
        })
        .join('\n');
  }

  // ==========================================================
  // NORMAL CHAT
  // ==========================================================

  Future<String> chatWithWardrobe({
    required String message,
    required List<ClothingItem> clothingItems,
  }) async {
    final String wardrobe =
        _buildWardrobeContext(clothingItems);

    final String prompt = '''
You are Closetly AI, a personal wardrobe assistant.

${ClosetlyAIRules.promptRules}

USER'S CURRENT WARDROBE:

$wardrobe

USER MESSAGE:
$message

Answer the user's question naturally.

IMPORTANT:
- The wardrobe above is the ONLY clothing the user owns.
- Never invent clothing.
- If you mention a wardrobe item, use its EXACT NAME.
- Do not shorten clothing names.
- Do not replace an exact clothing name with generic words such as "tee", "shirt", "pants", or "shoes".
- If the user asks for outfit ideas, use the exact wardrobe names.
- If the user asks a normal question, answer normally.
''';

    return generateResponse(prompt);
  }

  // ==========================================================
  // GENERATE OUTFITS
  // ==========================================================

  Future<String> generateOutfits(
    List<ClothingItem> clothingItems,
  ) async {
    final String wardrobe =
        _buildWardrobeContext(clothingItems);

    final String prompt = '''
You are Closetly AI.

${ClosetlyAIRules.promptRules}

USER'S CURRENT WARDROBE:

$wardrobe

Create 3 different outfit combinations
using ONLY the clothing items listed above.

RETURN ONLY VALID JSON.

Do not use markdown.
Do not use code fences.
Do not add text before or after the JSON.

Use EXACTLY this structure:

{
  "outfits": [
    {
      "name": "Casual Everyday",
      "items": [
        "EXACT NAME FROM WARDROBE",
        "EXACT NAME FROM WARDROBE"
      ],
      "why": "Short explanation."
    },
    {
      "name": "Smart Casual",
      "items": [
        "EXACT NAME FROM WARDROBE",
        "EXACT NAME FROM WARDROBE"
      ],
      "why": "Short explanation."
    },
    {
      "name": "Relaxed Look",
      "items": [
        "EXACT NAME FROM WARDROBE",
        "EXACT NAME FROM WARDROBE"
      ],
      "why": "Short explanation."
    }
  ]
}

STRICT CLOTHING NAME RULE:

The value inside every "items" array MUST be copied
EXACTLY from one of the EXACT NAME values in the wardrobe.

For example, if the wardrobe contains:

"White Sneakers"

you MUST write:

"White Sneakers"

NEVER write:

"shoes"
"sneakers"
"white shoes"

If the wardrobe contains:

"Black Compression Shirt"

you MUST write:

"Black Compression Shirt"

NEVER write:

"Tee"
"shirt"
"black tee"

If there are not enough suitable clothes,
use fewer items rather than inventing clothes.

WARDROBE:

$wardrobe
''';

    return generateResponse(prompt);
  }

  // ==========================================================
  // PARSE OUTFITS
  // ==========================================================

  List<OutfitSuggestion>? parseOutfitSuggestions(
    String response,
    List<ClothingItem> clothingItems,
  ) {
    try {
      String cleaned = response.trim();

      // Remove markdown code fences if Llama adds them.
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7).trim();
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3).trim();
      }

      if (cleaned.endsWith('```')) {
        cleaned = cleaned
            .substring(
              0,
              cleaned.length - 3,
            )
            .trim();
      }

      final dynamic decoded =
          jsonDecode(cleaned);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final dynamic outfitData =
          decoded['outfits'];

      if (outfitData is! List) {
        return null;
      }

      final List<OutfitSuggestion> suggestions =
          [];

      for (final dynamic rawOutfit
          in outfitData) {
        if (rawOutfit is! Map<String, dynamic>) {
          continue;
        }

        final OutfitSuggestion outfit =
            OutfitSuggestion.fromJson(
          rawOutfit,
        );

        final List<String> correctedItems =
            [];

        for (final String aiName
            in outfit.items) {
          final String? exactName =
              _findExactWardrobeName(
            aiName,
            clothingItems,
          );

          // Only accept clothing that
          // actually exists in the wardrobe.
          if (exactName != null) {
            correctedItems.add(exactName);
          }
        }

        if (correctedItems.isNotEmpty) {
          suggestions.add(
            OutfitSuggestion(
              name: outfit.name,
              items: correctedItems,
              why: outfit.why,
            ),
          );
        }
      }

      return suggestions.isEmpty
          ? null
          : suggestions;
    } catch (_) {
      // Normal AI text is not outfit JSON.
      return null;
    }
  }

  // ==========================================================
  // MATCH AI NAME TO REAL WARDROBE NAME
  // ==========================================================

  String? _findExactWardrobeName(
    String aiName,
    List<ClothingItem> clothingItems,
  ) {
    final String normalizedAI =
        aiName.trim().toLowerCase();

    // --------------------------------------------------------
    // 1. EXACT MATCH
    // --------------------------------------------------------

    for (final ClothingItem item
        in clothingItems) {
      final String normalizedName =
          item.name.trim().toLowerCase();

      if (normalizedName == normalizedAI) {
        return item.name;
      }
    }

    // --------------------------------------------------------
    // 2. SAFE PARTIAL MATCH
    // --------------------------------------------------------
    //
    // Only accept this if exactly ONE wardrobe item
    // matches. This prevents the AI from accidentally
    // selecting the wrong item.
    // --------------------------------------------------------

    final List<ClothingItem> matches =
        clothingItems.where((item) {
      final String name =
          item.name.trim().toLowerCase();

      return name.contains(normalizedAI) ||
          normalizedAI.contains(name);
    }).toList();

    if (matches.length == 1) {
      return matches.first.name;
    }

    // --------------------------------------------------------
    // 3. NO MATCH
    // --------------------------------------------------------
    //
    // Do NOT guess.
    // Do NOT convert "shoes" into a random shoe.
    // Do NOT convert "shirt" into a random shirt.
    // --------------------------------------------------------

    return null;
  }

  // ==========================================================
  // COMPLETE OUTFIT METHOD
  // ==========================================================

  Future<List<OutfitSuggestion>?>
      generateOutfitSuggestions(
    List<ClothingItem> clothingItems,
  ) async {
    final String response =
        await generateOutfits(
      clothingItems,
    );

    return parseOutfitSuggestions(
      response,
      clothingItems,
    );
  }
}