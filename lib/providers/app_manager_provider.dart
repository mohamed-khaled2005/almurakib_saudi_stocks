import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../core/services/favorites_service.dart';
import '../models/app_preferences_model.dart';
import '../models/educational_article_model.dart';
import '../models/managed_app_user.dart';
import '../models/manual_ad_model.dart';
import '../services/app_manager_api_service.dart';
import '../services/push_notification_service.dart';
import '../utils/app_manager_config.dart';

class AppManagerProvider with ChangeNotifier {
  AppManagerProvider({AppManagerApiService? api})
      : _api = api ?? AppManagerApiService();

  final AppManagerApiService _api;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email'],
    serverClientId: AppManagerConfig.googleServerClientId,
  );

  static const String _tokenKey = 'app_manager_token';
  static const String _deviceIdKey = 'app_manager_device_id';
  static const String _prefsKeyFavoriteItems = 'app_manager_favorite_items';

  bool _initialized = false;
  bool _isBusy = false;
  String? _errorMessage;
  Future<void>? _initializingFuture;

  String? _token;
  ManagedAppUser? _user;
  String? _deviceId;
  AppPreferencesModel _preferences = AppPreferencesModel.empty();
  ManualAdModel? _activeAd;
  List<EducationalArticleSummary> _articles = <EducationalArticleSummary>[];
  final Map<String, EducationalArticleDetail> _articleCache =
      <String, EducationalArticleDetail>{};

  String? _activeSessionUid;
  int _pagesViewedInSession = 0;

  bool get initialized => _initialized;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated =>
      _token != null && _token!.isNotEmpty && _user != null;
  bool get requiresProfileCompletion =>
      isAuthenticated && !(_user?.hasRequiredProfileData ?? false);
  ManagedAppUser? get user => _user;
  String? get token => _token;
  AppPreferencesModel get preferences => _preferences;
  ManualAdModel? get activeAd => _activeAd;
  List<EducationalArticleSummary> get articles => _articles;

  Future<void> initialize() async {
    if (_initialized) return;
    final pending = _initializingFuture;
    if (pending != null) return pending;

    final future = _initializeInternal();
    _initializingFuture = future;
    return future;
  }

  Future<void> _initializeInternal() async {
    _setBusy(true);
    _errorMessage = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await FavoritesService.init();

      _token = prefs.getString(_tokenKey);
      _deviceId = prefs.getString(_deviceIdKey);
      if (_deviceId == null || _deviceId!.isEmpty) {
        _deviceId = _generateDeviceId();
        await prefs.setString(_deviceIdKey, _deviceId!);
      }

      final localFavorites = await FavoritesService.getFavorites(
        forceReload: true,
      );

      _preferences = AppPreferencesModel(
        selectedCurrency: null,
        favoriteItems:
            prefs.getStringList(_prefsKeyFavoriteItems) ?? <String>[],
        watchedSymbols: localFavorites,
        settings: null,
      );

      if (_token != null && _token!.isNotEmpty) {
        try {
          _user = await _api.me(_token!);
          await _pullPreferencesFromServer(localWatchedSymbols: localFavorites);
          await syncPushToken();
        } catch (_) {
          await _clearAuth(prefs);
        }
      }

      await Future.wait(<Future<void>>[
        refreshAd(),
        refreshEducationalContent(),
      ]);

      await startSessionIfNeeded();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _initialized = true;
      _initializingFuture = null;
      _setBusy(false);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    _setBusy(true);
    _errorMessage = null;
    try {
      final result = await _api.register(
        email: email.trim(),
        password: password,
        fullName: fullName?.trim().isEmpty == true ? null : fullName?.trim(),
        platform: _platformName(),
        deviceId: _deviceId,
      );

      await _applyAuthResult(result, eventName: 'user_register');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setBusy(true);
    _errorMessage = null;
    try {
      final result = await _api.login(
        email: email.trim(),
        password: password,
        platform: _platformName(),
        deviceId: _deviceId,
      );
      await _applyAuthResult(result, eventName: 'user_login');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> loginWithGoogle() async {
    _setBusy(true);
    _errorMessage = null;
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        _errorMessage = 'تم إلغاء تسجيل الدخول بجوجل.';
        notifyListeners();
        return false;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        _errorMessage = 'تعذر الحصول على Google ID Token.';
        notifyListeners();
        return false;
      }

      final result = await _api.socialLogin(
        provider: 'google',
        idToken: idToken,
        platform: _platformName(),
        deviceId: _deviceId,
        fullName: account.displayName,
        email: account.email,
      );

      await _applyAuthResult(result, eventName: 'user_login_google');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> loginWithApple() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      _errorMessage = 'تسجيل Apple متاح على iOS فقط.';
      notifyListeners();
      return false;
    }

    _setBusy(true);
    _errorMessage = null;
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: <AppleIDAuthorizationScopes>[
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        _errorMessage = 'تعذر الحصول على Apple ID Token.';
        notifyListeners();
        return false;
      }

      final given = credential.givenName?.trim() ?? '';
      final family = credential.familyName?.trim() ?? '';
      final fullName =
          '$given $family'.trim().isEmpty ? null : '$given $family'.trim();

      final result = await _api.socialLogin(
        provider: 'apple',
        idToken: idToken,
        platform: _platformName(),
        deviceId: _deviceId,
        fullName: fullName,
        email: credential.email,
      );

      await _applyAuthResult(result, eventName: 'user_login_apple');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> logout() async {
    _setBusy(true);
    _errorMessage = null;
    try {
      if (_token != null && _token!.isNotEmpty) {
        await trackEvent(eventName: 'user_logout');
        await _api.logout(_token!);
      }
    } catch (_) {
      // Local logout should still proceed.
    } finally {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final prefs = await SharedPreferences.getInstance();
      await _clearAuth(prefs);
      await endSession();
      _setBusy(false);
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? countryCode,
    String? countryName,
    String? phoneNumber,
    String? currentPassword,
    String? newPassword,
  }) async {
    if (!isAuthenticated) return false;
    _setBusy(true);
    _errorMessage = null;
    try {
      final updated = await _api.updateProfile(
        token: _token!,
        fullName: fullName,
        countryCode: countryCode,
        countryName: countryName,
        phoneNumber: phoneNumber,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _user = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> deleteAccount({String? password}) async {
    if (!isAuthenticated) return false;
    _setBusy(true);
    _errorMessage = null;
    try {
      await trackEvent(eventName: 'user_delete_account');
      await _api.deleteAccount(
        token: _token!,
        password: password,
      );
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      final prefs = await SharedPreferences.getInstance();
      await _clearAuth(prefs);
      await endSession();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> syncFavoriteSymbols(List<String> symbols) async {
    final normalized = symbols
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    _preferences = _preferences.copyWith(watchedSymbols: normalized);
    notifyListeners();

    if (!isAuthenticated) return;
    await _pushPreferencesToServer();
  }

  Future<void> refreshAd() async {
    try {
      _activeAd = await _api.getActiveAd(platform: _platformName());
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshEducationalContent() async {
    try {
      _articles = await _api.getArticles();
      _articleCache.clear();
      notifyListeners();
    } catch (_) {}
  }

  Future<EducationalArticleDetail?> getEducationalArticleDetail(
    String slug,
  ) async {
    if (_articleCache.containsKey(slug)) {
      return _articleCache[slug];
    }

    try {
      final detail = await _api.getArticleDetail(slug);
      _articleCache[slug] = detail;
      return detail;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> syncPushToken() async {
    if (!isAuthenticated) return;
    try {
      final pushToken = await PushNotificationService.instance.getToken();
      if (pushToken == null || pushToken.trim().isEmpty) return;
      await registerPushToken(pushToken);
    } catch (_) {}
  }

  Future<void> registerPushToken(String pushToken) async {
    if (!isAuthenticated || pushToken.trim().isEmpty) return;
    try {
      await _api.registerPushToken(
        token: _token!,
        platform: _platformName(),
        pushToken: pushToken.trim(),
        provider: 'fcm',
        deviceId: _deviceId,
      );
    } catch (_) {}
  }

  Future<void> startSessionIfNeeded({bool forceRestart = false}) async {
    if (_activeSessionUid != null && !forceRestart) return;

    if (forceRestart && _activeSessionUid != null) {
      await endSession();
    }

    _activeSessionUid = _generateSessionUid();
    _pagesViewedInSession = 1;

    try {
      await _api.startSession(
        token: _token,
        sessionUid: _activeSessionUid!,
        platform: _platformName(),
        deviceId: _deviceId,
        metadata: <String, dynamic>{
          'source': 'mobile',
          'app_slug': AppManagerConfig.appSlug,
        },
      );
    } catch (_) {}
  }

  Future<void> endSession() async {
    if (_activeSessionUid == null) return;

    final endedSession = _activeSessionUid!;
    _activeSessionUid = null;

    try {
      await _api.endSession(
        token: _token,
        sessionUid: endedSession,
        pagesViewed: _pagesViewedInSession,
      );
    } catch (_) {}
  }

  Future<void> trackPageView(String pageName) async {
    _pagesViewedInSession += 1;
    await trackEvent(
      eventName: 'page_view',
      metadata: <String, dynamic>{'page': pageName},
    );
  }

  Future<void> trackEvent({
    required String eventName,
    int? durationMs,
    double? value,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _api.trackEvent(
        token: _token,
        eventName: eventName,
        sessionUid: _activeSessionUid,
        platform: _platformName(),
        deviceId: _deviceId,
        durationMs: durationMs,
        value: value,
        metadata: metadata,
      );
    } catch (_) {}
  }

  Future<void> _applyAuthResult(
    AuthResult result, {
    required String eventName,
  }) async {
    _token = result.token;
    _user = result.user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _token!);

    final localFavorites =
        await FavoritesService.getFavorites(forceReload: true);
    await _pullPreferencesFromServer(localWatchedSymbols: localFavorites);
    await _pushPreferencesToServer();
    await startSessionIfNeeded(forceRestart: true);
    await trackEvent(eventName: eventName);
    await syncPushToken();
    notifyListeners();
  }

  Future<void> _pullPreferencesFromServer({
    List<String>? localWatchedSymbols,
  }) async {
    if (!isAuthenticated) return;

    try {
      final remote = await _api.getPreferences(token: _token!);
      final mergedWatched = <String>{
        ...?localWatchedSymbols,
        ..._preferences.watchedSymbols,
        ...remote.watchedSymbols,
      }.toList()
        ..sort();

      _preferences = AppPreferencesModel(
        selectedCurrency:
            remote.selectedCurrency ?? _preferences.selectedCurrency,
        favoriteItems: remote.favoriteItems.isEmpty
            ? _preferences.favoriteItems
            : remote.favoriteItems,
        watchedSymbols: mergedWatched,
        settings: remote.settings,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          _prefsKeyFavoriteItems, _preferences.favoriteItems);
      await FavoritesService.replaceFavorites(
        _preferences.watchedSymbols,
        syncRemote: false,
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _pushPreferencesToServer() async {
    if (!isAuthenticated) return;
    try {
      _preferences = await _api.upsertPreferences(
        token: _token!,
        preferences: _preferences,
      );
      notifyListeners();
    } catch (_) {}
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'unknown';
    }
  }

  String _generateSessionUid() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(999999).toString().padLeft(6, '0');
    return 'session_${now}_$rand';
  }

  String _generateDeviceId() {
    final now = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    final rand = Random().nextInt(0x7fffffff).toRadixString(16);
    return 'dv_${now}_$rand';
  }

  Future<void> _clearAuth(SharedPreferences prefs) async {
    _token = null;
    _user = null;
    await prefs.remove(_tokenKey);
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }
}
