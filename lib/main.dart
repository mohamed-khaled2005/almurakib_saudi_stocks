import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/utils/app_lifecycle_refresh.dart';
import 'core/utils/constants.dart';
import 'providers/app_manager_provider.dart';
import 'screens/splash_screen.dart';
import 'services/push_notification_service.dart';
import 'widgets/app_manager_lifecycle_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLifecycleSignals.ensureInitialized();

  await Firebase.initializeApp();
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  PushNotificationService.registerBackgroundHandler();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.scaffold,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver _observer =
      FirebaseAnalyticsObserver(analytics: _analytics);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppManagerProvider>(
          create: (_) => AppManagerProvider()..initialize(),
        ),
      ],
      child: AppManagerLifecycleObserver(
        child: MaterialApp(
          title: 'مراقب الأسهم السعودية',
          debugShowCheckedModeBanner: false,
          navigatorObservers: <NavigatorObserver>[_observer],
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
            final content = child ?? const SizedBox.shrink();
            return _GlobalKeyboardDismiss(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: content,
              ),
            );
          },
          home: const SplashScreen(),
        ),
      ),
    );
  }
}

class _GlobalKeyboardDismiss extends StatelessWidget {
  const _GlobalKeyboardDismiss({required this.child});

  final Widget child;

  bool _isTapInsideFocusedNode(PointerDownEvent event, FocusNode focusNode) {
    final ctx = focusNode.context;
    if (ctx == null) return false;

    final render = ctx.findRenderObject();
    if (render is! RenderBox || !render.hasSize) return false;

    final local = render.globalToLocal(event.position);
    return render.size.contains(local);
  }

  void _handlePointerDown(PointerDownEvent event) {
    final focusedNode = FocusManager.instance.primaryFocus;
    if (focusedNode == null || !focusedNode.hasFocus) return;
    if (_isTapInsideFocusedNode(event, focusedNode)) return;
    focusedNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      child: child,
    );
  }
}
