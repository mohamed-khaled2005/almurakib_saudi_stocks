class AppPreferencesModel {
  final String? selectedCurrency;
  final List<String> favoriteItems;
  final List<String> watchedSymbols;
  final Map<String, dynamic>? settings;

  const AppPreferencesModel({
    required this.selectedCurrency,
    required this.favoriteItems,
    required this.watchedSymbols,
    required this.settings,
  });

  factory AppPreferencesModel.empty() {
    return const AppPreferencesModel(
      selectedCurrency: null,
      favoriteItems: <String>[],
      watchedSymbols: <String>[],
      settings: null,
    );
  }

  factory AppPreferencesModel.fromJson(Map<String, dynamic> json) {
    List<String> toStringList(dynamic raw) {
      if (raw is! List) return <String>[];
      return raw.map((e) => e.toString()).toList();
    }

    return AppPreferencesModel(
      selectedCurrency: json['selected_currency']?.toString(),
      favoriteItems: toStringList(json['favorite_items']),
      watchedSymbols: toStringList(json['watched_symbols']),
      settings: json['settings'] is Map
          ? Map<String, dynamic>.from(json['settings'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'selected_currency': selectedCurrency,
      'favorite_items': favoriteItems,
      'watched_symbols': watchedSymbols,
      'settings': settings,
    };
  }

  AppPreferencesModel copyWith({
    String? selectedCurrency,
    List<String>? favoriteItems,
    List<String>? watchedSymbols,
    Map<String, dynamic>? settings,
  }) {
    return AppPreferencesModel(
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      favoriteItems: favoriteItems ?? this.favoriteItems,
      watchedSymbols: watchedSymbols ?? this.watchedSymbols,
      settings: settings ?? this.settings,
    );
  }
}
