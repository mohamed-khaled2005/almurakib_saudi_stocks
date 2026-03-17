import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saudi_stock_monitor/main.dart';
import 'package:saudi_stock_monitor/screens/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  testWidgets('App launches and shows SplashScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1900));
  });
}
