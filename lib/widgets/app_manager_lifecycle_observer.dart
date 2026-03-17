import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/favorites_service.dart';
import '../providers/app_manager_provider.dart';
import '../services/push_notification_service.dart';

class AppManagerLifecycleObserver extends StatefulWidget {
  const AppManagerLifecycleObserver({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AppManagerLifecycleObserver> createState() =>
      _AppManagerLifecycleObserverState();
}

class _AppManagerLifecycleObserverState extends State<AppManagerLifecycleObserver>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _tokenRefreshSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final manager = context.read<AppManagerProvider>();
      FavoritesService.bindSyncHandler(
        (symbols) => manager.syncFavoriteSymbols(symbols.toList()),
      );
      manager.startSessionIfNeeded();
      manager.refreshAd();
      _bindPushToken(manager);
    });
  }

  @override
  void dispose() {
    _tokenRefreshSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final manager = context.read<AppManagerProvider>();
    if (state == AppLifecycleState.resumed) {
      manager.startSessionIfNeeded(forceRestart: true);
      manager.refreshAd();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      manager.endSession();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;

  Future<void> _bindPushToken(AppManagerProvider manager) async {
    try {
      await PushNotificationService.instance.initialize();
      final token = await PushNotificationService.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await manager.registerPushToken(token);
      }

      _tokenRefreshSub?.cancel();
      _tokenRefreshSub =
          PushNotificationService.instance.onTokenRefresh.listen((newToken) {
        if (kDebugMode && newToken.trim().isNotEmpty) {
          debugPrint('FCM Token refreshed: $newToken');
        }
        manager.registerPushToken(newToken);
      });
    } catch (_) {}
  }
}
