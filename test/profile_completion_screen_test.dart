import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:saudi_stock_monitor/models/managed_app_user.dart';
import 'package:saudi_stock_monitor/providers/app_manager_provider.dart';
import 'package:saudi_stock_monitor/screens/profile_completion_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('country alone is enough for required profile data', () {
    const user = ManagedAppUser(
      id: 1,
      email: 'user@example.com',
      fullName: 'Test User',
      countryCode: 'SA',
      countryName: 'السعودية',
      phoneNumber: null,
      status: 'active',
      authProvider: 'password',
      hasPassword: true,
      lastLoginAt: null,
    );

    expect(user.hasRequiredProfileData, isTrue);
  });

  test('skipProfileCompletionPrompt hides the mandatory prompt', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final provider = _PromptAwareAppManagerProvider();

    expect(provider.shouldPromptProfileCompletion, isTrue);

    await provider.skipProfileCompletionPrompt();

    expect(provider.shouldPromptProfileCompletion, isFalse);
  });

  testWidgets('profile completion allows saving without phone number',
      (WidgetTester tester) async {
    final provider = _FakeAppManagerProvider(
      userValue: const ManagedAppUser(
        id: 1,
        email: 'user@example.com',
        fullName: 'Test User',
        countryCode: 'SA',
        countryName: 'السعودية',
        phoneNumber: null,
        status: 'active',
        authProvider: 'password',
        hasPassword: true,
        lastLoginAt: null,
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AppManagerProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ProfileCompletionScreen(mandatory: false),
          ),
        ),
      ),
    );

    await tester.tap(find.text('حفظ والمتابعة'));
    await tester.pumpAndSettle();

    expect(provider.updateProfileCalled, isTrue);
    expect(provider.savedCountryCode, 'SA');
    expect(provider.savedCountryName, 'السعودية');
    expect(provider.savedPhoneNumber, isNull);
  });

  testWidgets('profile completion shows skip action and allows dismissing it',
      (WidgetTester tester) async {
    final provider = _FakeAppManagerProvider(
      userValue: const ManagedAppUser(
        id: 1,
        email: 'user@example.com',
        fullName: 'Test User',
        countryCode: null,
        countryName: null,
        phoneNumber: null,
        status: 'active',
        authProvider: 'password',
        hasPassword: true,
        lastLoginAt: null,
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AppManagerProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const ProfileCompletionScreen(mandatory: true),
                        ),
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('تخطي الآن'), findsOneWidget);

    await tester.tap(find.text('تخطي الآن'));
    await tester.pumpAndSettle();

    expect(provider.skipCalled, isTrue);
    expect(find.text('open'), findsOneWidget);
  });
}

class _FakeAppManagerProvider extends AppManagerProvider {
  _FakeAppManagerProvider({required this.userValue});

  final ManagedAppUser userValue;

  bool updateProfileCalled = false;
  bool skipCalled = false;
  String? savedCountryCode;
  String? savedCountryName;
  String? savedPhoneNumber;

  @override
  bool get isBusy => false;

  @override
  ManagedAppUser? get user => userValue;

  @override
  bool get shouldPromptProfileCompletion => true;

  @override
  Future<bool> updateProfile({
    String? fullName,
    String? countryCode,
    String? countryName,
    String? phoneNumber,
    String? currentPassword,
    String? newPassword,
  }) async {
    updateProfileCalled = true;
    savedCountryCode = countryCode;
    savedCountryName = countryName;
    savedPhoneNumber = phoneNumber;
    return true;
  }

  @override
  Future<void> skipProfileCompletionPrompt() async {
    skipCalled = true;
  }
}

class _PromptAwareAppManagerProvider extends AppManagerProvider {
  static const ManagedAppUser _userValue = ManagedAppUser(
    id: 1,
    email: 'user@example.com',
    fullName: 'Test User',
    countryCode: null,
    countryName: null,
    phoneNumber: null,
    status: 'active',
    authProvider: 'password',
    hasPassword: true,
    lastLoginAt: null,
  );

  @override
  bool get isAuthenticated => true;

  @override
  bool get requiresProfileCompletion => true;

  @override
  ManagedAppUser? get user => _userValue;
}
