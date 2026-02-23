class TranslationModel {
  final Map<String, String> stocksById;
  final Map<String, String> stocksBySymbol;
  final String version;
  final String updatedAt;

  TranslationModel({
    required this.stocksById,
    required this.stocksBySymbol,
    required this.version,
    required this.updatedAt,
  });

  factory TranslationModel.fromJson(Map<String, dynamic> json) {
    Map<String, String> byId = {};
    Map<String, String> bySymbol = {};

    final stocksById = json['stocks_by_id'] ??  {};
    final stocksBySymbol = json['stocks_by_symbol'] ?? {};

    stocksById.forEach((key, value) {
      if (value is Map && value['ar'] != null) {
        byId[key] = value['ar'].toString();
      }
    });

    stocksBySymbol.forEach((key, value) {
      if (value is Map && value['ar'] != null) {
        bySymbol[key] = value['ar'].toString();
      }
    });

    return TranslationModel(
      stocksById: byId,
      stocksBySymbol: bySymbol,
      version: json['meta']?['version']?.toString() ?? '1',
      updatedAt: json['meta']?['updated_at']?.toString() ?? '',
    );
  }

  String?  getArabicName({String? id, String? symbol}) {
    if (id != null && stocksById.containsKey(id)) {
      return stocksById[id];
    }
    if (symbol != null && stocksBySymbol.containsKey(symbol)) {
      return stocksBySymbol[symbol];
    }
    return null;
  }
}