import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_keys.dart';
import '../models/stock_model.dart';
import '../models/tasi_index_model.dart';
import '../models/stock_indicator_model.dart';
import '../models/stock_performance_model.dart';
import 'translation_service.dart';

class StockService {
  static Future<TasiIndexModel> getTasiIndex() async {
    print('📊 جلب مؤشر تاسي...');
    try {
      final data = await ApiClient.get(
        ApiEndpoints.indicesLatest(symbol: ApiKeys.tasiSymbol),
      );
      return TasiIndexModel.fromJson(data);
    } catch (_) {
      final data = await ApiClient.get(
        ApiEndpoints.indicesLatest(id: ApiKeys.tasiIndexId),
      );
      return TasiIndexModel.fromJson(data);
    }
  }

  static Future<List<StockModel>> getTopGainers({int limit = 10}) async {
    print('📈 جلب الأسهم الرابحة (API sort)...');
    final data = await ApiClient.get(
      ApiEndpoints.latest(
        country: ApiKeys.saudiCountry,
        sortBy: 'chp_desc',
        perPage: limit,
        page: 1,
        getProfile: true,
        type: 'stock',
        subType: 'common',
      ),
    );
    final stocks = _parseStocks(data);
    return await attachArabicNames(stocks);
  }

  static Future<List<StockModel>> getTopLosers({int limit = 10}) async {
    print('📉 جلب الأسهم الخاسرة (API sort)...');
    final data = await ApiClient.get(
      ApiEndpoints.latest(
        country: ApiKeys.saudiCountry,
        sortBy: 'chp_asc',
        perPage: limit,
        page: 1,
        getProfile: true,
        type: 'stock',
        subType: 'common',
      ),
    );
    final stocks = _parseStocks(data);
    return await attachArabicNames(stocks);
  }

  static Future<List<StockModel>> getBySymbols(List<String> symbols) async {
    if (symbols.isEmpty) return [];
    final joined = symbols.join(',');
    final data = await ApiClient.get(
      ApiEndpoints.latest(
        symbol: joined,
        getProfile: true,
        type: 'stock',
        subType: 'common',
      ),
    );
    final stocks = _parseStocks(data);
    return await attachArabicNames(stocks);
  }

  static String _norm(String s) {
    final t = s.trim();
    if (t.isEmpty) return t;
    return t.contains(':') ? t.split(':').last.trim() : t;
  }

  /// ✅ getStocksList (مضمون للّوجو + الأسعار):
  /// - latest: أسعار/تغيرات صحيحة
  /// - list: meta.self_logo
  /// - merge: بالـ id أو symbol (بدون prefix)
  static Future<List<StockModel>> getStocksList({int perPage = 500, int page = 1}) async {
    print('📊 جلب كل الأسهم (Latest + List logos merge)...');

    final results = await Future.wait([
      // ✅ latest للبيانات السعرية
      ApiClient.get(
        ApiEndpoints.latest(
          country: ApiKeys.saudiCountry,
          perPage: perPage,
          page: page,
          getProfile: true,
          type: 'stock',
          subType: 'common',
        ),
      ),
      // ✅ list للّوجو (meta.self_logo)
      ApiClient.get(
        ApiEndpoints.list(
          country: ApiKeys.saudiCountry,
          perPage: perPage,
          page: page,
        ),
      ),
    ]);

    final latestData = results[0] as Map<String, dynamic>;
    final listData = results[1] as Map<String, dynamic>;

    final latestStocks = _parseStocks(latestData);
    final listStocks = _parseStocks(listData);

    // build logo maps
    final Map<String, String> logoById = {};
    final Map<String, String> logoBySymbol = {};
    final Map<String, String> logoByNormSymbol = {};

    for (final s in listStocks) {
      final logo = s.selfLogo?.trim();
      if (logo == null || logo.isEmpty) continue;

      if (s.id.trim().isNotEmpty) {
        logoById[s.id.trim()] = logo;
        logoById[_norm(s.id)] = logo;
      }

      if (s.symbol.trim().isNotEmpty) {
        logoBySymbol[s.symbol.trim()] = logo;
        logoByNormSymbol[_norm(s.symbol)] = logo;
      }

      final nSym = _norm(s.symbol);
      if (nSym.isNotEmpty) logoByNormSymbol[nSym] = logo;
    }

    final merged = latestStocks.map((s) {
      final existing = s.selfLogo?.trim();
      if (existing != null && existing.isNotEmpty) return s;

      final id = s.id.trim();
      final sym = s.symbol.trim();
      final nId = _norm(id);
      final nSym = _norm(sym);

      final logo = logoById[id] ??
          logoById[nId] ??
          logoBySymbol[sym] ??
          logoByNormSymbol[nSym];

      if (logo == null || logo.trim().isEmpty) return s;
      return s.copyWith(selfLogo: logo);
    }).toList();

    return await attachArabicNames(merged);
  }

  static Future<StockModel> getStockDetail(String symbol) async {
    final data = await ApiClient.get(
      ApiEndpoints.latest(
        symbol: symbol,
        getProfile: true,
        type: 'stock',
        subType: 'common',
      ),
    );
    final list = _parseStocks(data);
    if (list.isEmpty) throw Exception('لم يتم العثور على بيانات السهم');

    final translated = await attachArabicNames([list.first]);
    return translated.first;
  }

  /// ✅ Indicators (AlMurakib ONLY)
  static Future<StockIndicatorModel> getIndicators(String symbol) async {
    print('📊 جلب المؤشرات الفنية (AlMurakib): $symbol');

    try {
      final data = await ApiClient.get(
        ApiEndpoints.indicators(symbol: symbol),
      );
      return StockIndicatorModel.fromJson(data);
    } catch (e) {
      print('❌ Indicators error (AlMurakib): $e');
      throw Exception('تعذر جلب المؤشرات الفنية حالياً');
    }
  }

  /// ✅ Performance (NEW)
  static Future<StockPerformanceModel> getPerformance(String symbol) async {
    print('📊 جلب أداء السهم (Performance): $symbol');

    try {
      final data = await ApiClient.get(
        ApiEndpoints.performance(symbol: symbol),
      );
      return StockPerformanceModel.fromJson(data);
    } catch (e) {
      print('❌ Performance error: $e');
      throw Exception('تعذر جلب أداء السهم حالياً');
    }
  }

  static Future<List<StockModel>> attachArabicNames(List<StockModel> stocks) async {
    final translations = await TranslationService.getTranslations();
    if (translations == null) return stocks;

    return stocks.map((s) {
      final ar = translations.getArabicName(id: s.id, symbol: s.symbol);
      return s.copyWith(arabicName: ar);
    }).toList();
  }

  static List<StockModel> _parseStocks(Map<String, dynamic> data) {
    final resp = data['response'];
    if (resp is! List) throw Exception('صيغة response غير متوقعة');
    if (resp.isEmpty) return [];

    return resp
        .whereType<Map>()
        .map((e) => StockModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
