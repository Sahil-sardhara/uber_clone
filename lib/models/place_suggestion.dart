class PlaceSuggestion {
  final String mainText;
  final String secondaryText;
  final String description;

  PlaceSuggestion({
    required this.mainText,
    required this.secondaryText,
    required this.description,
  });

  factory PlaceSuggestion.fromGoMap(Map<String, dynamic> json) {
    return PlaceSuggestion(
      mainText: json['structured_formatting']?['main_text'] ?? '',
      secondaryText: json['structured_formatting']?['secondary_text'] ?? '',
      description: json['description'] ?? '',
    );
  }
}
