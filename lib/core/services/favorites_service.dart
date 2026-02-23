import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _key = 'favorite_stocks';

  /// ✅ مصدر حالة مشترك بين كل الشاشات
  static final ValueNotifier<Set<String>> favoritesNotifier =
      ValueNotifier<Set<String>>(<String>{});

  static bool _initialized = false;

  /// ✅ نادِها مرة عند فتح التطبيق
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await getFavorites(forceReload: true);
  }

  static String _norm(String s) => s.trim().toUpperCase();

  static Future<List<String>> getFavorites({bool forceReload = false}) async {
    // لو عندنا قيمة في الذاكرة ومش طالب إعادة تحميل
    if (!forceReload && favoritesNotifier.value.isNotEmpty) {
      return favoritesNotifier.value.toList()..sort();
    }

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];

    final set = list
        .map(_norm)
        .where((e) => e.isNotEmpty)
        .toSet();

    favoritesNotifier.value = set;
    return set.toList()..sort();
  }

  static bool isFavoriteSync(String symbol) {
    final s = _norm(symbol);
    return s.isNotEmpty && favoritesNotifier.value.contains(s);
  }

  static Future<bool> isFavorite(String symbol) async {
    // لضمان إننا محملين مرة واحدة على الأقل
    if (!_initialized) await init();
    return isFavoriteSync(symbol);
  }

  static Future<void> addFavorite(String symbol) async {
    final s = _norm(symbol);
    if (s.isEmpty) return;

    if (!_initialized) await init();

    final current = favoritesNotifier.value;
    if (current.contains(s)) return;

    final next = <String>{...current, s};
    favoritesNotifier.value = next; // ✅ تحديث UI فورًا

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList()..sort());
  }

  static Future<void> removeFavorite(String symbol) async {
    final s = _norm(symbol);
    if (s.isEmpty) return;

    if (!_initialized) await init();

    final current = favoritesNotifier.value;
    if (!current.contains(s)) return;

    final next = <String>{...current}..remove(s);
    favoritesNotifier.value = next; // ✅ تحديث UI فورًا

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList()..sort());
  }

  static Future<void> toggleFavorite(String symbol) async {
    final s = _norm(symbol);
    if (s.isEmpty) return;

    if (!_initialized) await init();

    final current = favoritesNotifier.value;
    final next = <String>{...current};

    if (next.contains(s)) {
      next.remove(s);
    } else {
      next.add(s);
    }

    favoritesNotifier.value = next; // ✅ تحديث UI فورًا

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList()..sort());
  }

  static Future<void> clearAll() async {
    favoritesNotifier.value = <String>{};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
