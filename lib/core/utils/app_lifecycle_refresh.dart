// lib/core/utils/app_lifecycle_refresh.dart
import 'package:flutter/widgets.dart';

/// إشارات دورة حياة التطبيق (Resume/Foreground) لاستخدامها داخل أي شاشة.
class AppLifecycleSignals {
  AppLifecycleSignals._();

  static final ValueNotifier<int> resumeTick = ValueNotifier<int>(0);

  static bool _initialized = false;

  /// استدعِ هذه الدالة مرة واحدة (يفضل في main) لتفعيل مراقبة دورة الحياة.
  static void ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addObserver(_LifecycleObserver());
  }
}

class _LifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppLifecycleSignals.resumeTick.value++;
    }
  }
}
