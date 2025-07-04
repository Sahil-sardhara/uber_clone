class PlaceSuggestion {
  final String description;
  final String placeId;
  final String mainText;
  final String secondaryText;

  PlaceSuggestion({
    required this.description,
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceSuggestion.fromGoMap(Map<String, dynamic> json) {
    return PlaceSuggestion(
      description: json['description'],
      placeId: json['place_id'],
      mainText: json['structured_formatting']['main_text'],
      secondaryText: json['structured_formatting']['secondary_text'],
    );
  }
}
