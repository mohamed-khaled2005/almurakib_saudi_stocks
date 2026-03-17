import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _key = 'favorite_stocks';

  /// ✅ مصدر حالة مشترك بين كل الشاشات
  static final ValueNotifier<Set<String>> favoritesNotifier =
      ValueNotifier<Set<String>>(<String>{});

  static bool _initialized = false;
  static Future<void> Function(Set<String> favorites)? _syncHandler;

  /// ✅ نادِها مرة عند فتح التطبيق
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await getFavorites(forceReload: true);
  }

  static String _norm(String s) => s.trim().toUpperCase();

  static void bindSyncHandler(
    Future<void> Function(Set<String> favorites)? handler,
  ) {
    _syncHandler = handler;
  }

  static Future<void> replaceFavorites(
    Iterable<String> symbols, {
    bool syncRemote = true,
  }) async {
    final next = symbols.map(_norm).where((e) => e.isNotEmpty).toSet();
    await _commit(next, syncRemote: syncRemote);
  }

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
    await _commit(next);
  }

  static Future<void> removeFavorite(String symbol) async {
    final s = _norm(symbol);
    if (s.isEmpty) return;

    if (!_initialized) await init();

    final current = favoritesNotifier.value;
    if (!current.contains(s)) return;

    final next = <String>{...current}..remove(s);
    await _commit(next);
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

    await _commit(next);
  }

  static Future<void> clearAll() async {
    await _commit(<String>{});
  }

  static Future<void> _commit(
    Set<String> next, {
    bool syncRemote = true,
  }) async {
    favoritesNotifier.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList()..sort());

    if (syncRemote && _syncHandler != null) {
      await _syncHandler!(next);
    }
  }
}
