import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/clothing_item.dart';
import '../models/outfit_suggestion.dart';
import 'closetly_ai_rules.dart';

class AIService {
  // ==========================================================
  // CLOUDFLARE WORKER
  // ==========================================================

  static const String baseUrl =
      'https://closetly-ai.joshuareinbetis.workers.dev';

  // ==========================================================
  // CLOUDFLARE LLAMA REQUEST
  // ==========================================================

  Future<String> generateResponse({
    required String message,
    required String wardrobe,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'message': message,
              'wardrobe': wardrobe,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
          );

      if (response.statusCode != 200) {
        throw AIServiceException(
          AIErrorType.serviceUnavailable,
        );
      }

      final dynamic decoded =
          jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw AIServiceException(
          AIErrorType.invalidResponse,
        );
      }

      final dynamic aiResponse =
          decoded['response'];

      if (aiResponse is! String ||
          aiResponse.trim().isEmpty) {
        throw AIServiceException(
          AIErrorType.invalidResponse,
        );
      }

      return aiResponse;
    } on TimeoutException {
      throw const AIServiceException(
        AIErrorType.timeout,
      );
    } on http.ClientException {
      throw const AIServiceException(
        AIErrorType.noInternet,
      );
    } on AIServiceException {
      rethrow;
    } catch (e) {
      throw AIServiceException(
        AIErrorType.unexpected,
        debugMessage: e.toString(),
      );
    }
  }

    String normalizeClothingName(String value) {
      return value
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
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
- Custom user-provided color names are valid colors.
- If the user asks for outfit generation, the app may route the request through the structured outfit generator.
- Use Markdown-style **bold** when emphasis is helpful.
''';

    return generateResponse(
      message: prompt,
      wardrobe: wardrobe,
    );
  }

  // ==========================================================
  // OUTFIT CATEGORY HELPERS
  // ==========================================================

  String _category(ClothingItem item) {
    return item.category.trim().toLowerCase();
  }

  bool _isTop(ClothingItem item) {
    final String category = _category(item);

    return category == 'top' ||
        category == 'tops';
  }

  bool _isBottom(ClothingItem item) {
    final String category = _category(item);

    return category == 'bottom' ||
        category == 'bottoms';
  }

  bool _isShoes(ClothingItem item) {
    final String category = _category(item);

    return category == 'shoe' ||
        category == 'shoes';
  }

  bool _isOuterwear(ClothingItem item) {
    final String category = _category(item);

    return category == 'outerwear' ||
        category == 'jacket' ||
        category == 'jackets';
  }

  bool _isAccessory(ClothingItem item) {
    final String category = _category(item);

    return category == 'accessory' ||
        category == 'accessories';
  }

  Future<Map<String, dynamic>?> detectWardrobeAction(
  String message, {
  String wardrobe = '',
}) async {
  try {
    final response = await http
        .post(
          Uri.parse('$baseUrl/wardrobe-action'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'message': message,
            'wardrobe': wardrobe,
          }),
        )
        .timeout(
          const Duration(seconds: 30),
        );

    if (response.statusCode != 200) {
      return null;
    }

    final dynamic decoded =
        jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    if (decoded['success'] != true) {
      return null;
    }

    final String action =
        decoded['action']
                ?.toString()
                .trim()
                .toLowerCase() ??
            'none';

    String convertedAction;

    switch (action) {
      case 'add':
        convertedAction = 'add_clothing';
        break;

      case 'delete':
      case 'remove':
        convertedAction = 'remove_clothing';
        break;

      case 'update':
      case 'edit':
        convertedAction = 'update_clothing';
        break;

      default:
        return {
          'action': 'none',
        };
    }

    return {
      'action': convertedAction,

      // Existing clothing item name.
      'name':
          decoded['item']
              ?.toString()
              .trim(),

      // ADD / existing item information.
      'category':
          decoded['category']
              ?.toString()
              .trim(),

      'color':
          decoded['color']
              ?.toString()
              .trim(),

      // UPDATE values.
      'new_name':
          decoded['new_name']
              ?.toString()
              .trim(),

      'new_category':
          decoded['new_category']
              ?.toString()
              .trim(),

      'new_color':
          decoded['new_color']
              ?.toString()
              .trim(),

      'confidence':
          decoded['confidence'],
    };
  } on TimeoutException {
    return null;
  } catch (error) {
    return null;
  }
}

Future<Map<String, dynamic>?> detectDeleteClothingAction(
  String message,
) async {
  try {
    final String prompt = '''
You are the command parser for Closetly AI.

Determine whether the user is explicitly asking Closetly
to DELETE or REMOVE A CLOTHING ITEM from their wardrobe.

Examples that ARE a delete request:
- "Delete my black shirt"
- "Remove my blue jeans"
- "Take out my white sneakers"
- "Delete the black oversized t-shirt from my wardrobe"

Examples that are NOT a delete request:
- "What should I wear?"
- "Do I have a black shirt?"
- "What goes with my jeans?"
- "Show me my wardrobe"

Only return a delete action when the user clearly wants
the item removed from the wardrobe.

Return ONLY valid JSON.

If this IS a delete request:

{
  "action": "delete_clothing",
  "name": "Black T-Shirt"
}

If this is NOT a delete request:

{
  "action": "none"
}

Rules:
- The name must describe the clothing item the user wants deleted.
- Do not invent extra clothing information.
- Do not use markdown.
- Do not use code fences.
- Do not add explanations.

USER MESSAGE:
$message
''';

    final String response = await generateResponse(
      message: prompt,
      wardrobe: 'No wardrobe context is needed for this command.',
    );

    String cleaned = response.trim();

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

    final int start = cleaned.indexOf('{');
    final int end = cleaned.lastIndexOf('}');

    if (start == -1 || end == -1 || end <= start) {
      return null;
    }

    cleaned = cleaned.substring(start, end + 1);

    final dynamic decoded = jsonDecode(cleaned);

    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return decoded;
  } catch (_) {
    return null;
  }
}
  // ==========================================================
  // LLAMA VISION
  // ==========================================================

  Future<Map<String, dynamic>> analyzeClothingImage({
    required String imageBase64,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '${AIService.baseUrl}/vision',
            ),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'image': imageBase64,
            }),
          )
          .timeout(
            const Duration(seconds: 45),
          );

      if (response.statusCode != 200) {
        throw const AIServiceException(
          AIErrorType.serviceUnavailable,
        );
      }

      final dynamic decoded =
          jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const AIServiceException(
          AIErrorType.invalidResponse,
        );
      }

      final dynamic clothing =
          decoded['clothing'];

      if (clothing is! Map<String, dynamic>) {
        throw const AIServiceException(
          AIErrorType.invalidResponse,
        );
      }

      return clothing;
    } on TimeoutException {
      throw const AIServiceException(
        AIErrorType.timeout,
      );
    } on http.ClientException {
      throw const AIServiceException(
        AIErrorType.noInternet,
      );
    } on AIServiceException {
      rethrow;
    } catch (e) {
      throw AIServiceException(
        AIErrorType.unexpected,
        debugMessage: e.toString(),
      );
    }
  }
  // ==========================================================
  // COLOR COMPATIBILITY
  // ==========================================================

  String _normalizeColor(String? color) {
    return (color ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[-_/]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _colorIsNeutral(String color) {
    const Set<String> neutrals = {
      'black',
      'white',
      'gray',
      'grey',
      'beige',
      'cream',
      'brown',
      'tan',
      'navy',
      'charcoal',
      'stone',
      'khaki',
    };

    return neutrals.contains(color);
  }

  String _colorFamily(String color) {
    if (color.contains('blue') ||
        color == 'navy' ||
        color == 'teal') {
      return 'blue';
    }

    if (color.contains('green') ||
        color == 'olive') {
      return 'green';
    }

    if (color.contains('red') ||
        color == 'burgundy' ||
        color == 'maroon') {
      return 'red';
    }

    if (color.contains('purple') ||
        color == 'violet') {
      return 'purple';
    }

    if (color.contains('yellow') ||
        color == 'mustard') {
      return 'yellow';
    }

    if (color.contains('orange')) {
      return 'orange';
    }

    if (color.contains('pink')) {
      return 'pink';
    }

    return color;
  }

  int _colorCompatibilityScore(
  String? first,
  String? second,
) {
  final String a = _normalizeColor(first);
  final String b = _normalizeColor(second);

  if (a.isEmpty || b.isEmpty) {
    return 3;
  }

  // Same color
  if (a == b) {
    return 5;
  }

  final bool aNeutral = _colorIsNeutral(a);
  final bool bNeutral = _colorIsNeutral(b);

  // Two neutral colors usually work well together.
  if (aNeutral && bNeutral) {
    return 6;
  }

  // One neutral + one non-neutral color.
  if (aNeutral || bNeutral) {
    return 6;
  }

  final String familyA = _colorFamily(a);
  final String familyB = _colorFamily(b);

  // Same color family.
  if (familyA == familyB) {
    return 5;
  }

  // Common complementary combinations.
  const Set<String> complementaryPairs = {
    'blue/orange',
    'orange/blue',
    'green/red',
    'red/green',
    'purple/yellow',
    'yellow/purple',
  };

  if (complementaryPairs.contains(
    '$familyA/$familyB',
  )) {
    return 5;
  }

  // Some adjacent/compatible color families.
  const Set<String> compatiblePairs = {
    'blue/green',
    'green/blue',
    'red/pink',
    'pink/red',
    'yellow/orange',
    'orange/yellow',
  };

  if (compatiblePairs.contains(
    '$familyA/$familyB',
  )) {
    return 4;
  }

  // Unknown or potentially difficult combination.
  return 2;
}

Map<String, dynamic> checkOutfitCompatibility({
  required ClothingItem top,
  required ClothingItem bottom,
  required ClothingItem shoes,
  ClothingItem? outerwear,
  ClothingItem? accessory,
}) {
  final int topBottomScore =
      _colorCompatibilityScore(
    top.color,
    bottom.color,
  );

  final int topShoesScore =
      _colorCompatibilityScore(
    top.color,
    shoes.color,
  );

  final int bottomShoesScore =
      _colorCompatibilityScore(
    bottom.color,
    shoes.color,
  );

  int totalColorScore =
      topBottomScore +
      topShoesScore +
      bottomShoesScore;

  int maximumScore = 18;

  if (outerwear != null) {
    totalColorScore += _colorCompatibilityScore(
      outerwear.color,
      top.color,
    );

    maximumScore += 6;
  }

  if (accessory != null) {
    totalColorScore += _colorCompatibilityScore(
      accessory.color,
      shoes.color,
    );

    maximumScore += 6;
  }

  final double colorRatio =
      totalColorScore / maximumScore;

  String colorResult;

  if (colorRatio >= 0.75) {
    colorResult = 'Strong';
  } else if (colorRatio >= 0.55) {
    colorResult = 'Good';
  } else if (colorRatio >= 0.40) {
    colorResult = 'Mixed';
  } else {
    colorResult = 'Weak';
  }

  return {
    'colorResult': colorResult,
    'colorScore': totalColorScore,
    'colorMaximum': maximumScore,
    'colorRatio': colorRatio,
  };
}

  // ==========================================================
  // OUTFIT CANDIDATE MODEL
  // ==========================================================

  List<ClothingItem> _candidateItems(
    _OutfitCandidate candidate,
  ) {
    final List<ClothingItem> items = [
      candidate.top,
      candidate.bottom,
      candidate.shoes,
    ];

    if (candidate.outerwear != null) {
      items.add(candidate.outerwear!);
    }

    if (candidate.accessory != null) {
      items.add(candidate.accessory!);
    }

    return items;
  }

  int _scoreOutfit(
    ClothingItem top,
    ClothingItem bottom,
    ClothingItem shoes, {
    ClothingItem? outerwear,
    ClothingItem? accessory,
  }) {
    int score = 0;

    score += 30;
    score += 30;
    score += 30;

    score += _colorCompatibilityScore(
      top.color,
      bottom.color,
    );

    score += _colorCompatibilityScore(
      top.color,
      shoes.color,
    );

    score += _colorCompatibilityScore(
      bottom.color,
      shoes.color,
    );

    if (outerwear != null) {
      score += 4;
      score += _colorCompatibilityScore(
        outerwear.color,
        top.color,
      );
    }

    if (accessory != null) {
      score += 2;
      score += _colorCompatibilityScore(
        accessory.color,
        shoes.color,
      );
    }

    return score;
  }

  List<_OutfitCandidate> _buildOutfitCandidates(
    List<ClothingItem> clothingItems,
  ) {
    final List<ClothingItem> tops =
        clothingItems.where(_isTop).toList();

    final List<ClothingItem> bottoms =
        clothingItems.where(_isBottom).toList();

    final List<ClothingItem> shoes =
        clothingItems.where(_isShoes).toList();

    final List<ClothingItem> outerwear =
        clothingItems.where(_isOuterwear).toList();

    final List<ClothingItem> accessories =
        clothingItems.where(_isAccessory).toList();

    if (tops.isEmpty ||
        bottoms.isEmpty ||
        shoes.isEmpty) {
      return [];
    }

    final List<_OutfitCandidate> candidates = [];

    for (final ClothingItem top in tops) {
      for (final ClothingItem bottom in bottoms) {
        for (final ClothingItem shoe in shoes) {
          candidates.add(
            _OutfitCandidate(
              top: top,
              bottom: bottom,
              shoes: shoe,
              score: _scoreOutfit(
                top,
                bottom,
                shoe,
              ),
            ),
          );

          for (final ClothingItem outer
              in outerwear.take(2)) {
            candidates.add(
              _OutfitCandidate(
                top: top,
                bottom: bottom,
                shoes: shoe,
                outerwear: outer,
                score: _scoreOutfit(
                  top,
                  bottom,
                  shoe,
                  outerwear: outer,
                ),
              ),
            );
          }

          for (final ClothingItem accessory
              in accessories.take(2)) {
            candidates.add(
              _OutfitCandidate(
                top: top,
                bottom: bottom,
                shoes: shoe,
                accessory: accessory,
                score: _scoreOutfit(
                  top,
                  bottom,
                  shoe,
                  accessory: accessory,
                ),
              ),
            );
          }
        }
      }
    }

    return candidates;
  }

  List<_OutfitCandidate> _rankOutfitCandidates(
    List<ClothingItem> clothingItems,
  ) {
    final List<_OutfitCandidate> candidates =
        _buildOutfitCandidates(clothingItems);

    final Map<String, _OutfitCandidate> unique = {};

    for (final _OutfitCandidate candidate
        in candidates) {
      final String key = _candidateKey(candidate);

      final _OutfitCandidate? existing =
          unique[key];

      if (existing == null ||
          candidate.score > existing.score) {
        unique[key] = candidate;
      }
    }

    final List<_OutfitCandidate> ranked =
        unique.values.toList();

    ranked.sort(
      (a, b) => b.score.compareTo(a.score),
    );

    return ranked.take(30).toList();
  }

  String _candidateKey(
    _OutfitCandidate candidate,
  ) {
    final List<String> ids = [
      candidate.top.id,
      candidate.bottom.id,
      candidate.shoes.id,
      candidate.outerwear?.id ?? '',
      candidate.accessory?.id ?? '',
    ];

    return ids.join('|');
  }

  // ==========================================================
  // COMPLETE OUTFIT CHECK
  // ==========================================================

  bool canGenerateCompleteOutfit(
    List<ClothingItem> clothingItems,
  ) {
    return _buildOutfitCandidates(
      clothingItems,
    ).isNotEmpty;
  }

  String getOutfitAvailabilityMessage(
    List<ClothingItem> clothingItems,
  ) {
    final bool hasTop =
        clothingItems.any(_isTop);

    final bool hasBottom =
        clothingItems.any(_isBottom);

    final bool hasShoes =
        clothingItems.any(_isShoes);

    final List<String> missing = [];

    if (!hasTop) {
      missing.add('Top');
    }

    if (!hasBottom) {
      missing.add('Bottom');
    }

    if (!hasShoes) {
      missing.add('Shoes');
    }

    if (missing.isEmpty) {
      return 'I could not find a suitable complete outfit yet.';
    }

    final String missingText;

    if (missing.length == 1) {
      missingText = missing.first;
    } else if (missing.length == 2) {
      missingText =
          '${missing[0]} and ${missing[1]}';
    } else {
      missingText =
          '${missing.sublist(0, missing.length - 1).join(', ')}, and ${missing.last}';
    }

    return '''
I can't create a complete outfit yet.

Your wardrobe is missing:
$missingText

A complete everyday outfit needs:
Top + Bottom + Shoes.

Add the missing item${missing.length == 1 ? '' : 's'} to your wardrobe and try again.
''';
  }

  bool _isCompleteOutfit(
    List<String> itemNames,
    List<ClothingItem> clothingItems,
  ) {
    bool hasTop = false;
    bool hasBottom = false;
    bool hasShoes = false;

    for (final String itemName in itemNames) {
      final String? exactName =
          _findExactWardrobeName(
        itemName,
        clothingItems,
      );

      if (exactName == null) {
        continue;
      }

      final ClothingItem item =
          clothingItems.firstWhere(
        (candidate) =>
            candidate.name == exactName,
      );

      hasTop = hasTop || _isTop(item);
      hasBottom =
          hasBottom || _isBottom(item);
      hasShoes = hasShoes || _isShoes(item);
    }

    return hasTop &&
        hasBottom &&
        hasShoes;
  }

  // ==========================================================
  // OUTFIT CANDIDATE CONTEXT
  // ==========================================================

  String _buildCandidateContext(
    List<_OutfitCandidate> candidates,
  ) {
    return candidates
        .asMap()
        .entries
        .map((entry) {
          final int number = entry.key + 1;
          final _OutfitCandidate candidate =
              entry.value;

          final List<String> itemLines =
              _candidateItems(candidate)
                  .map(
                    (item) =>
                        '- "${item.name}" [${item.category}] color="${item.color ?? 'Not specified'}"',
                  )
                  .toList();

          return '''
CANDIDATE $number
SCORE: ${candidate.score}
${itemLines.join('\n')}
''';
        })
        .join('\n');
  }

  // ==========================================================
  // GENERATE OUTFITS
  // ==========================================================

  Future<String> generateOutfits(
    List<ClothingItem> clothingItems,
  ) async {
    final List<_OutfitCandidate> candidates =
        _rankOutfitCandidates(clothingItems);

    // Never call the AI model when a complete outfit
    // cannot exist. The UI handles the friendly message.
    if (candidates.isEmpty) {
      return jsonEncode({
        'outfits': <Map<String, dynamic>>[],
      });
    }

    final int requestedCount =
        candidates.length >= 3
            ? 3
            : candidates.length;

    final String wardrobe =
        _buildWardrobeContext(clothingItems);

    final String candidateContext =
        _buildCandidateContext(
      candidates.take(requestedCount).toList(),
    );

    final String prompt = '''
You are Closetly AI.

${ClosetlyAIRules.promptRules}

USER'S CURRENT WARDROBE:

$wardrobe

ONLY USE THESE PRECOMPUTED OUTFIT CANDIDATES:

$candidateContext

Create $requestedCount different outfit suggestion${requestedCount == 1 ? '' : 's'} using the candidates above.

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
    }
  ]
}

STRICT RULES:
1. Every item must come from the provided wardrobe.
2. Every item name must be copied EXACTLY.
3. Every outfit must include at least one Top, one Bottom, and one Shoes item.
4. Outerwear and accessories are optional.
5. Do not invent missing clothes.
6. Do not change, shorten, translate, or rename clothing names.
7. Custom user-provided color names are valid colors.
8. Do not reject or rename a custom color just because it is not a predefined color.
9. Treat the color exactly as supplied in the wardrobe.
10. Do not create outfit combinations that are not present in the candidate list.
11. Do not return incomplete outfits.
12. Do not repeat the same exact candidate combination.
13. Never write "Elegance {", "Casual {", or any text before the JSON object.
14. The response must contain exactly one JSON object.
15. The JSON object must start with { and end with }.

WARDROBE:

$wardrobe
''';

    return generateResponse(
      message: prompt,
      wardrobe: wardrobe,
    );
  }

  // ==========================================================
  // JSON EXTRACTION
  // ==========================================================

  String? _extractJsonObject(
    String response,
  ) {
    final String cleaned =
        response.trim();

    if (cleaned.isEmpty) {
      return null;
    }

    final int start =
        cleaned.indexOf('{');

    final int end =
        cleaned.lastIndexOf('}');

    if (start == -1 ||
        end == -1 ||
        end <= start) {
      return null;
    }

    return cleaned.substring(
      start,
      end + 1,
    );
  }

  // ==========================================================
  // PARSE OUTFITS
  // ==========================================================

  List<OutfitSuggestion>? parseOutfitSuggestions(
    String response,
    List<ClothingItem> clothingItems,
  ) {
    try {
      final String? jsonObject =
          _extractJsonObject(response);

      if (jsonObject == null) {
        return null;
      }

      final dynamic decoded =
          jsonDecode(jsonObject);

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

          if (exactName != null &&
              !correctedItems.contains(exactName)) {
            correctedItems.add(exactName);
          }
        }

        if (!_isCompleteOutfit(
          correctedItems,
          clothingItems,
        )) {
          continue;
        }

        suggestions.add(
          OutfitSuggestion(
            name: outfit.name,
            items: correctedItems,
            why: outfit.why,
          ),
        );
      }

      if (suggestions.isEmpty) {
        return null;
      }

      return suggestions.take(3).toList();
    } catch (_) {
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

    if (normalizedAI.isEmpty) {
      return null;
    }

    for (final ClothingItem item
        in clothingItems) {
      final String normalizedName =
          item.name.trim().toLowerCase();

      if (normalizedName == normalizedAI) {
        return item.name;
      }
    }

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

    return null;
  }

  // ==========================================================
  // DETERMINISTIC FALLBACK
  // ==========================================================

  List<OutfitSuggestion>
      buildFallbackOutfitSuggestions(
    List<ClothingItem> clothingItems,
  ) {
    final List<_OutfitCandidate> candidates =
        _rankOutfitCandidates(clothingItems);

    if (candidates.isEmpty) {
      return [];
    }

    final List<String> names = [
      'Casual Everyday',
      'Clean Balanced Look',
      'Relaxed Weekend',
    ];

    final List<OutfitSuggestion> suggestions =
        [];

    for (int i = 0;
        i < candidates.length &&
            suggestions.length < 3;
        i++) {
      final _OutfitCandidate candidate =
          candidates[i];

      final List<ClothingItem> items =
          _candidateItems(candidate);

      final String colorText = items
          .map(
            (item) =>
                item.color == null ||
                        item.color!.trim().isEmpty
                    ? null
                    : item.color!.trim(),
          )
          .whereType<String>()
          .toList()
          .join(', ');

      final String why =
          colorText.isEmpty
              ? 'This pairing includes a complete Top, Bottom, and Shoes combination from your wardrobe.'
              : 'This pairing uses your complete outfit categories with a balanced color combination ($colorText).';

      suggestions.add(
        OutfitSuggestion(
          name: names[suggestions.length],
          items: items
              .map((item) => item.name)
              .toList(),
          why: why,
        ),
      );
    }

    return suggestions;
  }

  // ==========================================================
  // COMPLETE OUTFIT METHOD
  // ==========================================================

  Future<List<OutfitSuggestion>?>
      generateOutfitSuggestions(
    List<ClothingItem> clothingItems,
  ) async {
    if (!canGenerateCompleteOutfit(
      clothingItems,
    )) {
      return null;
    }

    final String response =
        await generateOutfits(
      clothingItems,
    );

    return parseOutfitSuggestions(
      response,
      clothingItems,
    );
  }

    // ==========================================================
  // CURRENT FASHION TRENDS
  // ==========================================================

  Future<String> getTrendingMessage() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/trends'),
          )
          .timeout(
            const Duration(seconds: 30),
          );

      if (response.statusCode != 200) {
        throw const AIServiceException(
          AIErrorType.serviceUnavailable,
        );
      }

      final dynamic decoded =
          jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const AIServiceException(
          AIErrorType.invalidResponse,
        );
      }

      final dynamic trendResponse =
          decoded['response'];

      if (trendResponse is! String ||
          trendResponse.trim().isEmpty) {
        throw const AIServiceException(
          AIErrorType.invalidResponse,
        );
      }

      return trendResponse;
    } on TimeoutException {
      throw const AIServiceException(
        AIErrorType.timeout,
      );
    } on http.ClientException {
      throw const AIServiceException(
        AIErrorType.noInternet,
      );
    } on AIServiceException {
      rethrow;
    } catch (e) {
      throw AIServiceException(
        AIErrorType.unexpected,
        debugMessage: e.toString(),
      );
    }
  }


  // ==========================================================
  // VERSATILE WARDROBE ADDITIONS
  // ==========================================================

  Future<String> recommendWardrobeAdditions(
    List<ClothingItem> clothingItems,
  ) async {
    final String wardrobe =
        _buildWardrobeContext(clothingItems);

    final String prompt = '''
You are Closetly AI, a personal wardrobe planning assistant.

${ClosetlyAIRules.promptRules}

The user wants to know what clothing items they should ADD
to their wardrobe to make their existing wardrobe more versatile.

USER'S CURRENT WARDROBE:

$wardrobe

Analyze the wardrobe carefully.

Identify clothing pieces that could create MORE outfit
combinations with the user's existing clothes.

Prioritize:

1. Versatility
2. Compatibility with existing clothing
3. Ability to create multiple different outfits
4. Useful colors
5. Useful categories
6. Layering possibilities
7. Everyday practicality

Do NOT recommend items simply because they are trendy.

Do NOT recommend clothing that the user already owns.

The recommendation should fill a genuine wardrobe gap.

For every recommendation explain:
- What item to add
- Category
- Suggested color
- Why it is versatile
- Which existing wardrobe items it could work with
- What additional outfit possibilities it creates

Return ONLY valid JSON.

Use exactly this structure:

{
  "recommendations": [
    {
      "item": "Plain White Oversized T-Shirt",
      "category": "Top",
      "color": "White",
      "versatility": "High",
      "reason": "Works with several existing bottoms and can also be layered.",
      "works_with": [
        "Gray Baggy Pants",
        "Black Pants"
      ],
      "outfit_potential": "Can create casual outfits, layered outfits, and relaxed everyday looks."
    }
  ]
}

STRICT RULES:

- Recommend 3 to 5 items.
- Do not recommend an item already in the wardrobe.
- Use realistic clothing items.
- Prefer versatile neutral or adaptable colors when appropriate.
- Do not invent existing wardrobe items.
- Existing wardrobe names must be copied EXACTLY.
- Do not use markdown.
- Do not use code fences.
- Do not add explanations outside the JSON.
- Return exactly one JSON object.

CURRENT WARDROBE:

$wardrobe
''';

    return generateResponse(
      message: prompt,
      wardrobe: wardrobe,
    );
  }

    // ==========================================================
  // PARSE WARDROBE ADDITIONS
  // ==========================================================

List<Map<String, dynamic>>? parseWardrobeAdditions(
  String response,
  List<ClothingItem> clothingItems,
) {
  try {
    final String? jsonObject =
        _extractJsonObject(response);

    if (jsonObject == null) {
      return null;
    }

    final dynamic decoded =
        jsonDecode(jsonObject);

    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final dynamic recommendationData =
        decoded['recommendations'];

    if (recommendationData is! List) {
      return null;
    }

    final List<Map<String, dynamic>> recommendations = [];

    for (final dynamic item in recommendationData) {
      // Make sure this recommendation is an object.
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final dynamic name = item['item'];
      final dynamic category = item['category'];
      final dynamic color = item['color'];

      // Validate required fields before using them.
      if (name is! String ||
          category is! String ||
          color is! String) {
        continue;
      }

      // Skip recommendations the user already owns.
      if (_alreadyOwnsItem(
        name,
        clothingItems,
      )) {
        continue;
      }

      recommendations.add({
        'item': name,
        'category': category,
        'color': color,
        'versatility':
            item['versatility'] ?? 'Medium',
        'reason':
            item['reason'] ?? '',
        'works_with':
            item['works_with'] ?? <dynamic>[],
        'outfit_potential':
            item['outfit_potential'] ?? '',
      });
    }

    if (recommendations.isEmpty) {
      return null;
    }

    return recommendations.take(5).toList();
  } 
  
  catch (_) {
    return null;
  }
}

bool _alreadyOwnsItem(
      String recommendedName,
      List<ClothingItem> clothingItems,
    ) {
      final String recommended =
          recommendedName.trim().toLowerCase();

      return clothingItems.any(
        (item) =>
            item.name.trim().toLowerCase() ==
            recommended,
      );
    }
}



// ==========================================================
// INTERNAL OUTFIT CANDIDATE
// ==========================================================

class _OutfitCandidate {
  final ClothingItem top;
  final ClothingItem bottom;
  final ClothingItem shoes;
  final ClothingItem? outerwear;
  final ClothingItem? accessory;
  final int score;

  const _OutfitCandidate({
    required this.top,
    required this.bottom,
    required this.shoes,
    this.outerwear,
    this.accessory,
    required this.score,
  });
}

// ==========================================================
// AI ERROR TYPES
// ==========================================================

enum AIErrorType {
  noInternet,
  serviceUnavailable,
  timeout,
  invalidResponse,
  unexpected,
}

// ==========================================================
// USER-FRIENDLY AI EXCEPTION
// ==========================================================

class AIServiceException implements Exception {
  final AIErrorType type;
  final String? debugMessage;

  const AIServiceException(
    this.type, {
    this.debugMessage,
  });

  String get userMessage {
    switch (type) {
      case AIErrorType.noInternet:
        return 'Connection unavailable — '
            'Closetly AI needs an internet connection '
            'to respond. Please check your Wi-Fi or '
            'mobile data and try again.';

      case AIErrorType.serviceUnavailable:
        return 'AI service unavailable — '
            'Closetly couldn\'t connect to its AI service '
            'right now. Please try again in a moment.';

      case AIErrorType.timeout:
        return 'Request timed out — '
            'The AI took too long to respond. '
            'Please try again.';

      case AIErrorType.invalidResponse:
        return 'Something went wrong — '
            'Closetly received an invalid response. '
            'Please try again.';

      case AIErrorType.unexpected:
        return 'Something went wrong — '
            'Closetly couldn\'t complete your request. '
            'Please try again.';
    }
  }

  @override
  String toString() {
    return debugMessage ?? userMessage;
  }
}
