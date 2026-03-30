import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/app_preferences_model.dart';
import '../models/educational_article_model.dart';
import '../models/managed_app_user.dart';
import '../models/manual_ad_model.dart';
import '../utils/app_manager_config.dart';

class AppManagerApiException implements Exception {
  final String message;
  final int? statusCode;

  const AppManagerApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class AuthResult {
  final String token;
  final ManagedAppUser user;

  const AuthResult({
    required this.token,
    required this.user,
  });
}

class AppManagerApiService {
  AppManagerApiService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Uri get _apiBaseUri {
    final base = AppManagerConfig.apiBaseUrl.endsWith('/')
        ? AppManagerConfig.apiBaseUrl
            .substring(0, AppManagerConfig.apiBaseUrl.length - 1)
        : AppManagerConfig.apiBaseUrl;
    return _platformAwareLoopbackUri(Uri.parse(base));
  }

  Uri get _apiOriginUri => _apiBaseUri.replace(
        path: '/',
        query: null,
        fragment: null,
      );

  bool _isLoopbackHost(String host) {
    final normalized = host.trim().toLowerCase();
    return normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '0.0.0.0' ||
        normalized == '::1';
  }

  Uri _platformAwareLoopbackUri(Uri uri) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return uri;
    }

    if (!_isLoopbackHost(uri.host)) return uri;

    return uri.replace(host: '10.0.2.2');
  }

  String _normalizeAssetUrl(String rawUrl) {
    final url = rawUrl.trim();
    if (url.isEmpty) return '';

    final parsed = Uri.tryParse(url);
    if (parsed == null) return url;

    if (!parsed.hasScheme || parsed.host.isEmpty) {
      return _apiOriginUri.resolveUri(parsed).toString();
    }

    final apiHost = _apiOriginUri.host;
    if (_isLoopbackHost(parsed.host) && !_isLoopbackHost(apiHost)) {
      return _apiOriginUri
          .replace(
            path: parsed.path.isEmpty ? '/' : parsed.path,
            query: parsed.hasQuery ? parsed.query : null,
          )
          .toString();
    }

    return parsed.toString();
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final baseUri = _apiBaseUri;
    final fullPath = path.startsWith('/') ? path : '/$path';
    return baseUri
        .replace(path: '${baseUri.path}$fullPath')
        .replace(queryParameters: query);
  }

  Map<String, String> _headers({String? token}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Map<String, String>? query,
    Map<String, dynamic>? body,
    String? token,
    int retryCount = 2,
  }) async {
    final uri = _uri(path, query);

    for (var attempt = 1; attempt <= retryCount + 1; attempt++) {
      try {
        late http.Response response;
        final encoded = body == null ? null : jsonEncode(body);

        switch (method.toUpperCase()) {
          case 'GET':
            response = await _client
                .get(uri, headers: _headers(token: token))
                .timeout(AppManagerConfig.requestTimeout);
            break;
          case 'POST':
            response = await _client
                .post(uri, headers: _headers(token: token), body: encoded)
                .timeout(AppManagerConfig.requestTimeout);
            break;
          case 'PUT':
            response = await _client
                .put(uri, headers: _headers(token: token), body: encoded)
                .timeout(AppManagerConfig.requestTimeout);
            break;
          case 'PATCH':
            response = await _client
                .patch(uri, headers: _headers(token: token), body: encoded)
                .timeout(AppManagerConfig.requestTimeout);
            break;
          case 'DELETE':
            response = await _client
                .delete(uri, headers: _headers(token: token), body: encoded)
                .timeout(AppManagerConfig.requestTimeout);
            break;
          default:
            throw const AppManagerApiException('Unsupported HTTP method');
        }

        final data = _decode(response);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return data;
        }

        final message = _extractMessage(data) ??
            'Request failed with status ${response.statusCode}.';
        throw AppManagerApiException(message, statusCode: response.statusCode);
      } on AppManagerApiException {
        rethrow;
      } catch (e) {
        if (attempt > retryCount) {
          throw AppManagerApiException(
            'Unable to connect to apps manager API at $uri. $e',
          );
        }
        await Future<void>.delayed(
          Duration(milliseconds: 350 * pow(2, attempt - 1).toInt()),
        );
      }
    }

    throw const AppManagerApiException('Unexpected request failure.');
  }

  Map<String, dynamic> _decode(http.Response response) {
    final rawBody = _decodeBodyText(response);
    if (rawBody.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(rawBody);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{'data': decoded};
  }

  String _decodeBodyText(http.Response response) {
    final bytes = response.bodyBytes;
    if (bytes.isEmpty) return '';

    try {
      return utf8.decode(bytes);
    } catch (_) {
      return response.body;
    }
  }

  String? _extractMessage(Map<String, dynamic> data) {
    final message = data['message'] ?? data['msg'];
    if (message != null) return message.toString();

    final errors = data['errors'];
    if (errors is Map) {
      for (final entry in errors.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
      }
    }
    return null;
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    String? fullName,
    required String platform,
    String? deviceId,
  }) async {
    final data = await _request(
      method: 'POST',
      path: '/auth/register',
      body: <String, dynamic>{
        'email': email,
        'password': password,
        'full_name': fullName,
        'target_app_slug': AppManagerConfig.appSlug,
        'platform': platform,
        'device_id': deviceId,
      },
    );

    return AuthResult(
      token: (data['token'] ?? '').toString(),
      user: ManagedAppUser.fromJson(
        Map<String, dynamic>.from(data['user'] ?? <String, dynamic>{}),
      ),
    );
  }

  Future<AuthResult> login({
    required String email,
    required String password,
    required String platform,
    String? deviceId,
    String? sourceAppSlug,
  }) async {
    final data = await _request(
      method: 'POST',
      path: '/auth/login',
      body: <String, dynamic>{
        'email': email,
        'password': password,
        'target_app_slug': AppManagerConfig.appSlug,
        'source_app_slug': sourceAppSlug,
        'platform': platform,
        'device_id': deviceId,
      },
    );

    return AuthResult(
      token: (data['token'] ?? '').toString(),
      user: ManagedAppUser.fromJson(
        Map<String, dynamic>.from(data['user'] ?? <String, dynamic>{}),
      ),
    );
  }

  Future<AuthResult> socialLogin({
    required String provider,
    required String idToken,
    required String platform,
    String? deviceId,
    String? fullName,
    String? email,
    String? sourceAppSlug,
  }) async {
    final data = await _request(
      method: 'POST',
      path: '/auth/social',
      body: <String, dynamic>{
        'provider': provider,
        'id_token': idToken,
        'email': email,
        'full_name': fullName,
        'target_app_slug': AppManagerConfig.appSlug,
        'source_app_slug': sourceAppSlug,
        'platform': platform,
        'device_id': deviceId,
      },
    );

    return AuthResult(
      token: (data['token'] ?? '').toString(),
      user: ManagedAppUser.fromJson(
        Map<String, dynamic>.from(data['user'] ?? <String, dynamic>{}),
      ),
    );
  }

  Future<ManagedAppUser> me(String token) async {
    final data = await _request(
      method: 'GET',
      path: '/auth/me',
      token: token,
    );
    final userJson =
        Map<String, dynamic>.from(data['user'] ?? <String, dynamic>{});
    return ManagedAppUser.fromJson(userJson);
  }

  Future<void> logout(String token) async {
    await _request(
      method: 'POST',
      path: '/auth/logout',
      token: token,
      body: <String, dynamic>{
        'target_app_slug': AppManagerConfig.appSlug,
      },
    );
  }

  Future<ManagedAppUser> updateProfile({
    required String token,
    String? fullName,
    String? countryCode,
    String? countryName,
    String? phoneNumber,
    String? currentPassword,
    String? newPassword,
  }) async {
    final data = await _request(
      method: 'PATCH',
      path: '/auth/profile',
      token: token,
      body: <String, dynamic>{
        'full_name': fullName,
        'country_code': countryCode,
        'country_name': countryName,
        'phone_number': phoneNumber,
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
    final userJson =
        Map<String, dynamic>.from(data['user'] ?? <String, dynamic>{});
    return ManagedAppUser.fromJson(userJson);
  }

  Future<void> deleteAccount({
    required String token,
    String? password,
  }) async {
    await _request(
      method: 'DELETE',
      path: '/auth/account',
      token: token,
      body: <String, dynamic>{
        if (password != null && password.trim().isNotEmpty)
          'password': password.trim(),
      },
    );
  }

  Future<AppPreferencesModel> getPreferences({
    required String token,
  }) async {
    final data = await _request(
      method: 'GET',
      path: '/preferences',
      token: token,
      query: <String, String>{'app_slug': AppManagerConfig.appSlug},
    );
    final prefsJson =
        Map<String, dynamic>.from(data['preferences'] ?? <String, dynamic>{});
    return AppPreferencesModel.fromJson(prefsJson);
  }

  Future<AppPreferencesModel> upsertPreferences({
    required String token,
    required AppPreferencesModel preferences,
  }) async {
    final data = await _request(
      method: 'PUT',
      path: '/preferences',
      token: token,
      body: <String, dynamic>{
        'app_slug': AppManagerConfig.appSlug,
        ...preferences.toJson(),
      },
    );
    final prefsJson =
        Map<String, dynamic>.from(data['preferences'] ?? <String, dynamic>{});
    return AppPreferencesModel.fromJson(prefsJson);
  }

  Future<void> startSession({
    String? token,
    required String sessionUid,
    required String platform,
    String? deviceId,
    Map<String, dynamic>? metadata,
  }) async {
    await _request(
      method: 'POST',
      path: '/analytics/session/start',
      token: token,
      body: <String, dynamic>{
        'app_slug': AppManagerConfig.appSlug,
        'session_uid': sessionUid,
        'platform': platform,
        'device_id': deviceId,
        'metadata': metadata,
      },
    );
  }

  Future<void> endSession({
    String? token,
    required String sessionUid,
    int? pagesViewed,
    Map<String, dynamic>? metadata,
  }) async {
    await _request(
      method: 'POST',
      path: '/analytics/session/end',
      token: token,
      body: <String, dynamic>{
        'session_uid': sessionUid,
        'pages_viewed': pagesViewed,
        'metadata': metadata,
      },
    );
  }

  Future<void> trackEvent({
    String? token,
    required String eventName,
    String? sessionUid,
    required String platform,
    String? deviceId,
    int? durationMs,
    double? value,
    Map<String, dynamic>? metadata,
  }) async {
    await _request(
      method: 'POST',
      path: '/analytics/event',
      token: token,
      body: <String, dynamic>{
        'app_slug': AppManagerConfig.appSlug,
        'event_name': eventName,
        'session_uid': sessionUid,
        'platform': platform,
        'device_id': deviceId,
        'duration_ms': durationMs,
        'value': value,
        'metadata': metadata,
      },
    );
  }

  Future<ManualAdModel?> getActiveAd({
    required String platform,
    String placement = 'rectangle_main',
  }) async {
    final data = await _request(
      method: 'GET',
      path: '/manual-ads/active',
      query: <String, String>{
        'app_slug': AppManagerConfig.appSlug,
        'platform': platform,
        'placement': placement,
      },
    );
    final ad = data['ad'];
    if (ad is Map<String, dynamic>) {
      final normalized = Map<String, dynamic>.from(ad);
      normalized['image_url'] =
          _normalizeAssetUrl((normalized['image_url'] ?? '').toString());
      return ManualAdModel.fromJson(normalized);
    }
    return null;
  }

  Future<List<EducationalArticleSummary>> getArticles({
    int page = 1,
    int perPage = 20,
  }) async {
    final data = await _request(
      method: 'GET',
      path: '/education/articles',
      query: <String, String>{
        'app_slug': AppManagerConfig.appSlug,
        'page': '$page',
        'per_page': '$perPage',
      },
    );

    final raw = data['data'];
    if (raw is! List) return <EducationalArticleSummary>[];
    return raw
        .whereType<Map>()
        .map((e) =>
            EducationalArticleSummary.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<EducationalArticleDetail> getArticleDetail(String slug) async {
    final data = await _request(
      method: 'GET',
      path: '/education/articles/$slug',
      query: <String, String>{
        'app_slug': AppManagerConfig.appSlug,
      },
    );
    final raw =
        Map<String, dynamic>.from(data['article'] ?? <String, dynamic>{});
    return EducationalArticleDetail.fromJson(raw);
  }

  Future<void> registerPushToken({
    required String token,
    required String platform,
    required String pushToken,
    String provider = 'fcm',
    String? deviceId,
  }) async {
    await _request(
      method: 'POST',
      path: '/push/device-token',
      token: token,
      body: <String, dynamic>{
        'app_slug': AppManagerConfig.appSlug,
        'platform': platform,
        'provider': provider,
        'token': pushToken,
        'device_id': deviceId,
      },
    );
  }
}
