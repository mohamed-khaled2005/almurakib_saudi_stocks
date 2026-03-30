import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/constants.dart';
import '../providers/app_manager_provider.dart';
import 'app_shell_screen.dart';
import 'profile_completion_screen.dart';

const Color _stockAccent = AppColors.primaryGold;
const Color _authTop = Color(0xFFF9FFF8);
const Color _authBottom = Color(0xFFE7F5E7);
const Color _authSurface = Color(0xFFFFFFFF);
const Color _authInput = Color(0xFFF4FBF4);

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.redirectToHomeOnSuccess = false,
  });

  final bool redirectToHomeOnSuccess;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _fullName = TextEditingController();

  bool _isRegisterMode = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    super.dispose();
  }

  Future<void> _submitEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    final manager = context.read<AppManagerProvider>();

    final ok = _isRegisterMode
        ? await manager.register(
            email: _email.text,
            password: _password.text,
            fullName: _fullName.text,
          )
        : await manager.login(
            email: _email.text,
            password: _password.text,
          );

    if (!mounted) return;
    if (ok) {
      await _handleSuccess();
      return;
    }

    _showError(manager.errorMessage ?? 'حدث خطأ أثناء العملية.');
  }

  Future<void> _loginWithGoogle() async {
    final manager = context.read<AppManagerProvider>();
    final ok = await manager.loginWithGoogle();
    if (!mounted) return;
    if (ok) {
      await _handleSuccess();
      return;
    }
    _showError(manager.errorMessage ?? 'تعذر تسجيل الدخول عبر Google.');
  }

  Future<void> _loginWithApple() async {
    final manager = context.read<AppManagerProvider>();
    final ok = await manager.loginWithApple();
    if (!mounted) return;
    if (ok) {
      await _handleSuccess();
      return;
    }
    _showError(manager.errorMessage ?? 'تعذر تسجيل الدخول عبر Apple.');
  }

  Future<void> _handleSuccess() async {
    if (!mounted) return;
    final completed = await ProfileCompletionScreen.ensureCompleted(context);
    if (!mounted || !completed) return;
    if (widget.redirectToHomeOnSuccess) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppShellScreen()),
        (_) => false,
      );
    } else {
      Navigator.pop(context, true);
    }
  }

  void _continueWithoutLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AppShellScreen()),
      (_) => false,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<AppManagerProvider>();
    final canUseApple = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    return PopScope(
      canPop: !widget.redirectToHomeOnSuccess,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            const _AuthBackground(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: widget.redirectToHomeOnSuccess
                              ? TextButton.icon(
                                  onPressed: manager.isBusy
                                      ? null
                                      : _continueWithoutLogin,
                                  style: TextButton.styleFrom(
                                    foregroundColor: _stockAccent,
                                  ),
                                  icon: const Icon(
                                    Icons.home_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'تخطي الدخول',
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  onPressed: manager.isBusy
                                      ? null
                                      : () => Navigator.maybePop(context),
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: AppColors.textPrimary,
                                    size: 18,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 4),
                        _buildHero(),
                        const SizedBox(height: 16),
                        _buildAuthCard(
                          manager: manager,
                          canUseApple: canUseApple,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'بالاستمرار أنت توافق على شروط الاستخدام وسياسة الخصوصية.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall.copyWith(
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.78),
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    final title = _isRegisterMode ? 'إنشاء حساب جديد' : 'تسجيل الدخول';
    final description = _isRegisterMode
        ? 'أنشئ حسابا جديدا لحفظ قائمتك المفضلة ومزامنة بياناتك في تطبيق الأسهم السعودية.'
        : 'سجّل دخولك للوصول إلى قائمتك المفضلة ومزامنة إعداداتك واستقبال التنبيهات.';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            _authSurface,
            Color(0xFFF1FAF1),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF2FBF2),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Image.asset(
              'assets/images/stock_app_icon.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard({
    required AppManagerProvider manager,
    required bool canUseApple,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: _authSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildModeSwitcher(),
            const SizedBox(height: 14),
            _buildSocialButtons(
              busy: manager.isBusy,
              canUseApple: canUseApple,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: _stockAccent.withValues(alpha: 0.18),
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'أو بالبريد الإلكتروني',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.90),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: _stockAccent.withValues(alpha: 0.18),
                    thickness: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_isRegisterMode) ...[
              TextFormField(
                controller: _fullName,
                textInputAction: TextInputAction.next,
                decoration: _fieldDecoration(
                  label: 'الاسم الكامل',
                  icon: Icons.person_outline_rounded,
                ),
                validator: (value) {
                  final input = (value ?? '').trim();
                  if (input.isEmpty) return null;
                  if (input.length < 3) {
                    return 'اكتب اسما واضحا لا يقل عن 3 أحرف.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
            ],
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: _fieldDecoration(
                label: 'البريد الإلكتروني',
                icon: Icons.alternate_email_rounded,
              ),
              validator: (value) {
                final input = (value ?? '').trim();
                if (input.isEmpty) {
                  return 'أدخل البريد الإلكتروني.';
                }
                if (!input.contains('@') || !input.contains('.')) {
                  return 'صيغة البريد الإلكتروني غير صحيحة.';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _password,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submitEmailAuth(),
              decoration: _fieldDecoration(
                label: 'كلمة المرور',
                icon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                final input = value ?? '';
                if (input.isEmpty) {
                  return 'أدخل كلمة المرور.';
                }
                if (input.length < 8) {
                  return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: manager.isBusy ? null : _submitEmailAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _stockAccent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _stockAccent.withValues(alpha: 0.56),
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: manager.isBusy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isRegisterMode
                            ? 'إنشاء الحساب والمتابعة'
                            : 'تسجيل الدخول',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w900,
                          fontSize: 15.5,
                        ),
                      ),
              ),
            ),
            if (widget.redirectToHomeOnSuccess) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: manager.isBusy ? null : _continueWithoutLogin,
                style: TextButton.styleFrom(
                  foregroundColor: _stockAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                icon: const Icon(Icons.skip_next_rounded, size: 18),
                label: const Text(
                  'المتابعة بدون تسجيل',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: AppColors.border,
      ),
    );

    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: _authInput,
      prefixIcon: Icon(
        icon,
        size: 20,
        color: _stockAccent.withValues(alpha: 0.95),
      ),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(
          color: _stockAccent.withValues(alpha: 0.55),
          width: 1.2,
        ),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 1.2,
        ),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 1.4,
        ),
      ),
      errorStyle: AppTextStyles.bodySmall.copyWith(
        color: AppColors.error,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildModeSwitcher() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _authInput,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeItem(
              title: 'تسجيل الدخول',
              selected: !_isRegisterMode,
              onTap: () {
                setState(() => _isRegisterMode = false);
              },
            ),
          ),
          Expanded(
            child: _buildModeItem(
              title: 'إنشاء حساب',
              selected: _isRegisterMode,
              onTap: () {
                setState(() => _isRegisterMode = true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeItem({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: selected ? _stockAccent : Colors.transparent,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButtons({
    required bool busy,
    required bool canUseApple,
  }) {
    return Column(
      children: [
        _socialButton(
          label: 'المتابعة عبر Google',
          icon: Icons.g_mobiledata_rounded,
          brandColor: const Color(0xFF8AB4F8),
          onTap: busy ? null : _loginWithGoogle,
        ),
        if (canUseApple) ...[
          const SizedBox(height: 8),
          _socialButton(
            label: 'المتابعة عبر Apple',
            icon: Icons.apple,
            brandColor: const Color(0xFFE8ECF4),
            onTap: busy ? null : _loginWithApple,
          ),
        ],
      ],
    );
  }

  Widget _socialButton({
    required String label,
    required IconData icon,
    required Color brandColor,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary.withValues(alpha: 0.96),
          backgroundColor: Colors.white,
          side: const BorderSide(
            color: AppColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: brandColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: brandColor,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_authTop, _authBottom],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _GlowCircle(
              size: 290,
              color: _stockAccent.withValues(alpha: 0.09),
            ),
          ),
          Positioned(
            bottom: -130,
            left: -70,
            child: _GlowCircle(
              size: 260,
              color: _stockAccent.withValues(alpha: 0.05),
            ),
          ),
          Positioned(
            top: 210,
            left: -40,
            child: _GlowCircle(
              size: 170,
              color: _stockAccent.withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 90,
            spreadRadius: 12,
          ),
        ],
      ),
    );
  }
}
