import 'package:flutter_test/flutter_test.dart';
import 'package:saudi_stock_monitor/main.dart';
import 'package:saudi_stock_monitor/screens/splash_screen.dart';

void main() {
  testWidgets('App launches and shows SplashScreen', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MyApp());

    // Let first frame render
    await tester.pump();

    // Verify SplashScreen is shown
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
