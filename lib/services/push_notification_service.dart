import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utils/app_manager_config.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService._();

  static const AndroidNotificationChannel _defaultAndroidChannel =
      AndroidNotificationChannel(
    'default_channel',
    'General Notifications',
    description: 'General app notifications',
    importance: Importance.high,
    playSound: true,
  );

  static final PushNotificationService instance = PushNotificationService._();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _messageListenersBound = false;
  bool _localNotificationsReady = false;
  String? _cachedToken;

  static void registerBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> initialize() async {
    if (_initialized) return;

    if (kIsWeb) {
      _initialized = true;
      return;
    }

    final platform = defaultTargetPlatform;
    if (platform != TargetPlatform.android && platform != TargetPlatform.iOS) {
      _initialized = true;
      return;
    }

    await _initializeLocalNotifications();

    final permission = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    if (kDebugMode) {
      debugPrint(
        'FCM permission status: ${permission.authorizationStatus.name}',
      );
    }

    await _requestAndroidNotificationPermission();
    await _messaging.setAutoInitEnabled(true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _subscribeToDefaultTopics();
    await _waitForApnsTokenIfNeeded();
    _cachedToken = await _messaging.getToken();
    _printToken();
    await _bindMessageListeners();
    _initialized = true;
  }

  Future<String?> getToken() async {
    if (!_initialized) {
      await initialize();
    }
    _cachedToken ??= await _messaging.getToken();
    _printToken();
    return _cachedToken;
  }

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  Future<void> _subscribeToDefaultTopics() async {
    const base = AppManagerConfig.appSlug;
    await _messaging.subscribeToTopic('app_${base}_all');

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _messaging.subscribeToTopic('app_${base}_android');
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _messaging.subscribeToTopic('app_${base}_ios');
    }
  }

  Future<void> _waitForApnsTokenIfNeeded() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;

    for (var attempt = 0; attempt < 12; attempt++) {
      final apnsToken = await _messaging.getAPNSToken();
      if (apnsToken != null && apnsToken.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('APNs Token: $apnsToken');
        }
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    if (kDebugMode) {
      debugPrint('APNs token is not ready yet.');
    }
  }

  void _printToken() {
    if (!kDebugMode) return;
    final token = _cachedToken?.trim();
    if (token == null || token.isEmpty) {
      debugPrint('FCM Token is empty.');
      return;
    }
    debugPrint('FCM Token: $token');
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsReady || kIsWeb) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _localNotificationsPlugin.initialize(settings);

      final androidPlugin =
          _localNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_defaultAndroidChannel);
      _localNotificationsReady = true;
    } on MissingPluginException catch (e) {
      _localNotificationsReady = false;
      if (kDebugMode) {
        debugPrint('Local notifications plugin is not available yet: $e');
      }
    } on PlatformException catch (e) {
      _localNotificationsReady = false;
      if (kDebugMode) {
        debugPrint(
          'Local notifications initialization failed: '
          '${e.code} ${e.message ?? ""}',
        );
      }
    }
  }

  Future<void> _requestAndroidNotificationPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (!_localNotificationsReady) return;

    bool? granted;
    try {
      final androidPlugin =
          _localNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      granted = await androidPlugin?.requestNotificationsPermission();
    } on MissingPluginException catch (e) {
      if (kDebugMode) {
        debugPrint('Android notifications permission plugin missing: $e');
      }
      return;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Android notifications permission request failed: '
          '${e.code} ${e.message ?? ""}',
        );
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('Android notification runtime permission granted=$granted');
    }
  }

  Future<void> _bindMessageListeners() async {
    if (_messageListenersBound) return;
    _messageListenersBound = true;

    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? '';
      final body = message.notification?.body ?? '';
      if (kDebugMode) {
        debugPrint(
          'FCM onMessage id=${message.messageId ?? "-"} '
          'title=$title body=$body data=${message.data}',
        );
      }
      _showForegroundNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (kDebugMode) {
        debugPrint(
          'FCM onMessageOpenedApp id=${message.messageId ?? "-"} data=${message.data}',
        );
      }
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null && kDebugMode) {
      debugPrint(
        'FCM initialMessage id=${initialMessage.messageId ?? "-"} data=${initialMessage.data}',
      );
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (!_localNotificationsReady) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final title = (message.notification?.title ?? message.data['title'] ?? '')
        .toString()
        .trim();
    final body = (message.notification?.body ?? message.data['body'] ?? '')
        .toString()
        .trim();

    if (title.isEmpty && body.isEmpty) return;

    try {
      await _localNotificationsPlugin.show(
        message.messageId?.hashCode ??
            DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _defaultAndroidChannel.id,
            _defaultAndroidChannel.name,
            channelDescription: _defaultAndroidChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
          ),
        ),
      );
    } on MissingPluginException catch (e) {
      if (kDebugMode) {
        debugPrint('Unable to show foreground notification: $e');
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Foreground notification error: ${e.code} ${e.message ?? ""}',
        );
      }
    }
  }
}
