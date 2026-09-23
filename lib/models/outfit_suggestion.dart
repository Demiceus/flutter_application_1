class OutfitSuggestion {
  final String name;
  final List<String> items;
  final String why;

  const OutfitSuggestion({
    required this.name,
    required this.items,
    required this.why,
  });

  factory OutfitSuggestion.fromJson(
    Map<String, dynamic> json,
  ) {
    return OutfitSuggestion(
      name:
          json['name'] as String? ??
              'Outfit',
      items:
          (json['items']
                      as List<dynamic>? ??
                  [])
              .map(
                (item) => item.toString(),
              )
              .toList(),
      why:
          json['why'] as String? ??
              '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'items': items,
      'why': why,
    };
  }
}