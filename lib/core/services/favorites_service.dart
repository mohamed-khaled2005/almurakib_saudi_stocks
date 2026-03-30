import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _key = 'favorite_stocks';
  static Future<void> Function(Set<String> favorites)? _syncHandler;
  static bool _suppressSyncHandler = false;

  static final ValueNotifier<Set<String>> favoritesNotifier =
      ValueNotifier<Set<String>>(<String>{});

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await getFavorites(forceReload: true);
  }

  static void bindSyncHandler(
    Future<void> Function(Set<String> favorites)? handler,
  ) {
    _syncHandler = handler;
  }

  static String _norm(String s) => s.trim().toUpperCase();

  static bool _sameSymbols(Set<String> a, Set<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final value in a) {
      if (!b.contains(value)) return false;
    }
    return true;
  }

  static void _updateNotifierIfChanged(Set<String> next) {
    if (_sameSymbols(favoritesNotifier.value, next)) return;
    favoritesNotifier.value = next;
  }

  static Future<List<String>> getFavorites({bool forceReload = false}) async {
    if (!forceReload && favoritesNotifier.value.isNotEmpty) {
      return favoritesNotifier.value.toList()..sort();
    }

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];

    final next = list.map(_norm).where((e) => e.isNotEmpty).toSet();
    _updateNotifierIfChanged(next);
    return next.toList()..sort();
  }

  static bool isFavoriteSync(String symbol) {
    final s = _norm(symbol);
    return s.isNotEmpty && favoritesNotifier.value.contains(s);
  }

  static Future<bool> isFavorite(String symbol) async {
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
    _updateNotifierIfChanged(next);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList()..sort());
    await _notifySyncHandler(next);
  }

  static Future<void> removeFavorite(String symbol) async {
    final s = _norm(symbol);
    if (s.isEmpty) return;

    if (!_initialized) await init();

    final current = favoritesNotifier.value;
    if (!current.contains(s)) return;

    final next = <String>{...current}..remove(s);
    _updateNotifierIfChanged(next);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList()..sort());
    await _notifySyncHandler(next);
  }

  static Future<void> toggleFavorite(String symbol) async {
    final s = _norm(symbol);
    if (s.isEmpty) return;

    if (!_initialized) await init();

    final next = <String>{...favoritesNotifier.value};
    if (next.contains(s)) {
      next.remove(s);
    } else {
      next.add(s);
    }

    _updateNotifierIfChanged(next);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList()..sort());
    await _notifySyncHandler(next);
  }

  static Future<void> replaceFavorites(
    Iterable<String> symbols, {
    bool syncRemote = true,
  }) async {
    final next = symbols.map(_norm).where((e) => e.isNotEmpty).toSet();

    _updateNotifierIfChanged(next);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList()..sort());

    if (_suppressSyncHandler || !syncRemote) return;

    _suppressSyncHandler = true;
    try {
      await _notifySyncHandler(next);
    } finally {
      _suppressSyncHandler = false;
    }
  }

  static Future<void> clearAll() async {
    const next = <String>{};
    _updateNotifierIfChanged(next);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await _notifySyncHandler(next);
  }

  static Future<void> _notifySyncHandler(Set<String> symbols) async {
    if (_suppressSyncHandler) return;
    final handler = _syncHandler;
    if (handler == null) return;
    await handler(symbols);
  }
}
