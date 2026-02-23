import 'dart:async';
import '../api/api_client.dart';
import '../api/api_keys.dart';

class StockTranslations {
  final Map<String, Map<String, String>> byId;

  StockTranslations(this.byId);

  String _norm(String v) {
    if (v.isEmpty) return v;
    String out = v.trim();
    try {
      out = Uri.decodeComponent(out);
    } catch (_) {}
    return out.toUpperCase();
  }

  String? _getAr(String key) {
    final v = byId[key];
    if (v == null) return null;
    final ar = (v['ar'] ?? '').trim();
    return ar.isEmpty ? null : ar;
  }

  String? getArabicName({required String id, required String symbol}) {
    final sym = _norm(symbol);
    final sid = _norm(id);

    final v1 = _getAr(sym);
    if (v1 != null) return v1;

    final v2 = _getAr(sid);
    if (v2 != null) return v2;

    if (!sid.contains(':') && sid.isNotEmpty) {
      final v3 = _getAr('TADAWUL:$sid');
      if (v3 != null) return v3;
    }

    if (!sym.contains(':') && sym.isNotEmpty) {
      final v4 = _getAr('TADAWUL:$sym');
      if (v4 != null) return v4;
    }

    if (sym.contains(':')) {
      final parts = sym.split(':');
      if (parts.length == 2) {
        final numeric = parts[1].trim();
        final v5 = _getAr(numeric);
        if (v5 != null) return v5;
      }
    }

    return null;
  }
}

class TranslationService {
  /// ✅ Session cache فقط (طول ما التطبيق شغال)
  static StockTranslations? _cache;

  /// يمنع تعدد الطلبات بنفس الوقت
  static Future<StockTranslations?>? _inFlight;

  static bool isTranslationAvailable = false;

  /// ✅ لا TTL — لا 24 ساعة — لا أي صلاحية زمنية
  static Future<StockTranslations?> getTranslations({bool forceRefresh = false}) async {
    // لو عندنا كاش في الرام وطالب مش force -> رجّعه
    if (!forceRefresh && _cache != null) return _cache;

    // لو فيه طلب شغال بالفعل -> رجّعه (لتفادي سبام requests reminder)
    if (!forceRefresh && _inFlight != null) return _inFlight;

    _inFlight = _load();
    final res = await _inFlight;
    _inFlight = null;
    return res;
  }

  static Future<StockTranslations?> _load() async {
    try {
      print('🌐 تحميل ملف الأسماء العربية...');

      final data = await ApiClient.get(ApiKeys.translationUrl);

      dynamic raw = data['stocks_by_id'];
      if (raw == null) raw = data['stocksById'];
      if (raw == null) raw = data; // fallback لِـ JSON shape فقط (مش API fallback)

      if (raw is! Map) {
        isTranslationAvailable = false;
        return null;
      }

      final map = <String, Map<String, String>>{};
      raw.forEach((key, value) {
        if (value is Map) {
          final v = Map<String, dynamic>.from(value);
          final k0 = key.toString().trim();
          if (k0.isEmpty) return;

          String nk = k0;
          try {
            nk = Uri.decodeComponent(nk);
          } catch (_) {}
          nk = nk.trim().toUpperCase();

          map[nk] = {
            'ar': (v['ar'] ?? '').toString(),
            'en': (v['en'] ?? '').toString(),
          };
        }
      });

      _cache = StockTranslations(map);
      isTranslationAvailable = true;

      print('✅ تم تحميل الأسماء: ${map.length} شركة');
      return _cache;
    } catch (e) {
      isTranslationAvailable = false;
      print('❌ فشل تحميل الأسماء العربية: $e');
      return null;
    }
  }

  /// ✅ يمسح session cache (رام فقط)
  static void clearCache() {
    _cache = null;
    _inFlight = null;
    isTranslationAvailable = false;
  }
}
