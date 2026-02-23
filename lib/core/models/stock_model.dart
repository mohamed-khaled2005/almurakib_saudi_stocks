import '../utils/server_time_utils.dart';

class StockModel {
  final String id; // رقم الشركة (1010) لو أمكن
  final String symbol; // ticker: TADAWUL:1010
  final String name; // الاسم الإنجليزي
  final double price;
  final double change;
  final double changePercent;
  final DateTime? lastUpdateUtc;
  final String? arabicName;

  // ✅ NEW: logo (prefer meta.self_logo full url)
  final String? selfLogo;

  StockModel({
    required this.id,
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.changePercent,
    this.lastUpdateUtc,
    this.arabicName,
    this.selfLogo,
  });

  factory StockModel.fromJson(Map<String, dynamic> json) {
    final ticker =
        (json['ticker'] ?? json['s'] ?? json['symbol'] ?? '').toString().trim();

    final profile = json['profile'];
    final profileMap = profile is Map
        ? Map<String, dynamic>.from(profile)
        : <String, dynamic>{};

    final meta = json['meta'];
    final metaMap =
        meta is Map ? Map<String, dynamic>.from(meta) : <String, dynamic>{};

    final profileSymbol =
        (profileMap['symbol'] ?? '').toString().trim(); // 1010
    final profileName = (profileMap['name'] ?? '').toString().trim();

    final active = json['active'];
    final activeMap =
        active is Map ? Map<String, dynamic>.from(active) : <String, dynamic>{};

    final price =
        _parseDouble(activeMap['c'] ?? json['c'] ?? json['price'] ?? json['p']);
    final change =
        _parseDouble(activeMap['ch'] ?? json['ch'] ?? json['change']);
    final changePercent = _parseDouble(activeMap['chp'] ??
        json['chp'] ??
        json['cp'] ??
        json['change_percent']);
    final lastUpdateUtc = ServerTimeUtils.pickLatest([
      ServerTimeUtils.parseToUtc(activeMap['update']),
      ServerTimeUtils.parseToUtc(activeMap['updateTime']),
      ServerTimeUtils.parseToUtc(activeMap['tm']),
      ServerTimeUtils.parseToUtc(json['update']),
      ServerTimeUtils.parseToUtc(json['updateTime']),
      ServerTimeUtils.parseToUtc(json['tm']),
      ServerTimeUtils.parseToUtc(json['time']),
      ServerTimeUtils.parseToUtc(json['timestamp']),
    ]);

    // ✅ id: الأفضل رقم السهم
    String id;
    if (profileSymbol.isNotEmpty) {
      id = profileSymbol;
    } else if ((json['id'] ?? '').toString().trim().isNotEmpty) {
      id = (json['id']).toString().trim();
    } else if (ticker.contains(':')) {
      id = ticker.split(':').last.trim(); // TADAWUL:1010 -> 1010
    } else {
      id = ticker;
    }

    final name = profileName.isNotEmpty
        ? profileName
        : (json['name']?.toString().trim() ?? ticker);

    // ✅ symbol fallback لو ticker فاضي
    final finalSymbol = ticker.isNotEmpty
        ? ticker
        : (json['symbol']?.toString().trim() ??
            json['s']?.toString().trim() ??
            json['ticker']?.toString().trim() ??
            '');

    // ✅ logo: prefer meta.self_logo (full), else profile.self_logo (path)
    final rawLogo = metaMap['self_logo'] ??
        profileMap['self_logo'] ??
        json['self_logo'] ??
        metaMap['logo'] ??
        profileMap['logo'] ??
        json['logo'];

    final selfLogo = _normalizeLogoUrl(rawLogo);

    return StockModel(
      id: id,
      symbol: finalSymbol,
      name: name,
      price: price,
      change: change,
      changePercent: changePercent,
      lastUpdateUtc: lastUpdateUtc,
      selfLogo: selfLogo,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d\.-]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  static String? _normalizeLogoUrl(dynamic value) {
    final s = value?.toString().trim();
    if (s == null || s.isEmpty) return null;

    // لو already URL
    if (s.startsWith('http://') || s.startsWith('https://')) return s;

    // لو جالك path زي: stock/ri/riyad-bank
    // أو assets/logos/stock/ri/riyad-bank.svg
    var path = s;
    if (path.startsWith('/')) path = path.substring(1);

    // لو داخل assets/logos بالفعل
    if (path.startsWith('assets/')) {
      // غالبًا domain بتاع الأصول
      return 'https://api-v4.fcsapi.com/$path';
    }

    // لو Path بدون extension
    final lower = path.toLowerCase();
    final hasExt = lower.contains('.svg') ||
        lower.contains('.png') ||
        lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.webp');

    if (!hasExt) path = '$path.svg';

    return 'https://api-v4.fcsapi.com/assets/logos/$path';
  }

  StockModel copyWith({
    String? arabicName,
    String? selfLogo,
    DateTime? lastUpdateUtc,
  }) {
    return StockModel(
      id: id,
      symbol: symbol,
      name: name,
      price: price,
      change: change,
      changePercent: changePercent,
      lastUpdateUtc: lastUpdateUtc ?? this.lastUpdateUtc,
      arabicName: arabicName ?? this.arabicName,
      selfLogo: selfLogo ?? this.selfLogo,
    );
  }

  String get displayName =>
      (arabicName != null && arabicName!.isNotEmpty) ? arabicName! : name;
  bool get hasArabicName => arabicName != null && arabicName!.isNotEmpty;
  bool get isGain => change >= 0;

  @override
  String toString() {
    return 'Stock(id: $id, symbol: $symbol, price: $price, change: $change, changePercent: $changePercent%, lastUpdateUtc: $lastUpdateUtc, selfLogo: $selfLogo)';
  }
}
