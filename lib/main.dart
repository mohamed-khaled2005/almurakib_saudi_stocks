// lib/main.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

// ✅ OneSignal
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'core/utils/constants.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/app_shell_screen.dart';

// ✅ ADD
import 'core/utils/app_lifecycle_refresh.dart';

/// ✅ OneSignal App ID (اللي العميل بعته)
const String _oneSignalAppId = 'ef2e7d49-1693-4ba4-9691-c5a06cebc6fa';

/// ✅ Flags بسيطة عشان نقرر نضيف Analytics observer ولا لأ
bool _firebaseReady = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ ADD: تفعيل مراقبة دورة حياة التطبيق (Resume/Foreground)
  AppLifecycleSignals.ensureInitialized();

  // ✅ Firebase init (safe)
  await _initFirebaseSafely();

  // تحديد اتجاه الشاشة
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // تخصيص شريط الحالة
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());

  // ✅ OneSignal init بعد تشغيل الـ UI مباشرة (من غير ما يعطل الإقلاع)
  Future.microtask(_initOneSignalSafely);
}

/// ✅ Initialize Firebase بدون ما يعمل crash لو فيه مشكلة إعداد/ملف
Future<void> _initFirebaseSafely() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    _firebaseReady = true;

    // حدث فتح التطبيق
    await FirebaseAnalytics.instance.logAppOpen();
  } catch (e) {
    _firebaseReady = false;
    // ignore: avoid_print
    print('⚠️ Firebase init failed: $e');
  }
}

/// ✅ Initialize OneSignal بشكل آمن + listeners
Future<void> _initOneSignalSafely() async {
  try {
    // Logging (خليه Debug فقط)
    if (kDebugMode) {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    } else {
      OneSignal.Debug.setLogLevel(OSLogLevel.none);
    }

    // ✅ Initialize SDK with App ID
    OneSignal.initialize(_oneSignalAppId);

    // ✅ اطلب صلاحية الإشعارات
    await OneSignal.Notifications.requestPermission(false);

    // ✅ لو الإشعار وصل والتطبيق مفتوح (Foreground)
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.preventDefault();
      event.notification.display();
    });

    // ✅ عند الضغط على الإشعار
    OneSignal.Notifications.addClickListener((event) async {
      try {
        final nid = event.notification.notificationId;
        // ignore: avoid_print
        print('🔔 OneSignal clicked: $nid');

        // اربطها مع Firebase Analytics (اختياري)
        if (_firebaseReady) {
          await FirebaseAnalytics.instance.logEvent(
            name: 'onesignal_notification_open',
            parameters: {
              'notification_id': nid,
            },
          );
        }
      } catch (e) {
        // ignore: avoid_print
        print('⚠️ OneSignal click handler error: $e');
      }
    });
  } catch (e) {
    // ignore: avoid_print
    print('⚠️ OneSignal init failed: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver _observer =
      FirebaseAnalyticsObserver(analytics: _analytics);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مراقب الأسهم السعودية',
      debugShowCheckedModeBanner: false,

      navigatorObservers:
          _firebaseReady ? <NavigatorObserver>[_observer] : const <NavigatorObserver>[],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ar', 'SA'),

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Tajawal',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          primary: AppColors.primaryBlue,
          secondary: AppColors.lightBlue,
        ),
        scaffoldBackgroundColor: AppColors.scaffold,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
      ),

      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },

      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return onboardingCompleted ? const AppShellScreen() : const OnboardingScreen();
        },
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
