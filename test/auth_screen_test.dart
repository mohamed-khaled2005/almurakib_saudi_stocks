import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:saudi_stock_monitor/providers/app_manager_provider.dart';
import 'package:saudi_stock_monitor/screens/auth_screen.dart';

void main() {
  testWidgets('hides Google sign in on iOS', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppManagerProvider>(
        create: (_) => AppManagerProvider(),
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: AuthScreen(),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byIcon(Icons.g_mobiledata_rounded), findsNothing);
    expect(find.byIcon(Icons.apple), findsOneWidget);
  },
      variant:
          const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.iOS}));

  testWidgets('shows Google sign in on Android', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppManagerProvider>(
        create: (_) => AppManagerProvider(),
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: AuthScreen(),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byIcon(Icons.g_mobiledata_rounded), findsOneWidget);
    expect(find.byIcon(Icons.apple), findsNothing);
  },
      variant: const TargetPlatformVariant(
          <TargetPlatform>{TargetPlatform.android}));
}
