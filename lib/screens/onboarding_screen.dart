import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/constants.dart';
import 'app_shell_screen.dart';

const Color _stockAccent = AppColors.primaryGold;
const Color _onboardingTop = Color(0xFFF9FFF8);
const Color _onboardingBottom = Color(0xFFE7F5E7);
const Color _cardColor = Color(0xFFFFFFFF);

const List<_OnboardingFeature> _features = [
  _OnboardingFeature(
    icon: Icons.candlestick_chart_rounded,
    title: 'متابعة السوق السعودي لحظيا',
    description:
        'راقب مؤشر تاسي وحركة الأسهم السعودية بشكل سريع وواضح مع واجهة مختصرة تركّز على الأرقام المهمة.',
    tag: 'Live',
  ),
  _OnboardingFeature(
    icon: Icons.trending_up_rounded,
    title: 'أقوى الرابحين والخاسرين',
    description:
        'اعرف مباشرة الأسهم الأكثر ارتفاعا والأكثر انخفاضا لتكوين صورة سريعة عن مزاج السوق.',
    tag: 'Market',
  ),
  _OnboardingFeature(
    icon: Icons.star_rounded,
    title: 'قائمة مراقبة ومزامنة',
    description:
        'احفظ أسهمك المفضلة وسجّل دخولك لمزامنة قائمتك وإعداداتك بين أجهزتك بسهولة.',
    tag: 'Sync',
  ),
  _OnboardingFeature(
    icon: Icons.analytics_rounded,
    title: 'تفاصيل ومؤشرات فنية',
    description:
        'افتح أي سهم لتشاهد الأداء والمؤشرات الفنية والبيانات الأساسية في مكان واحد.',
    tag: 'Insight',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const String _prefsKeyOnboarding = 'onboarding_completed';
  bool _saving = false;

  Future<void> _continue() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKeyOnboarding, true);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: const AppShellScreen(),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ، حاول مرة أخرى')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            const _OnboardingBackdrop(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _saving ? null : _continue,
                        style: TextButton.styleFrom(
                          foregroundColor: _stockAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                        icon: const Icon(Icons.skip_next_rounded, size: 18),
                        label: const Text(
                          'تخطي',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHero(),
                              const SizedBox(height: 16),
                              Text(
                                'ما الذي ستجده داخل التطبيق؟',
                                style: AppTextStyles.headingSmall.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'واجهة سريعة ومرتبة لتتبع السوق السعودي والأسهم المهمة بدون تشتيت.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ..._features.map(_buildFeatureCard),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _continue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _stockAccent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              _stockAccent.withValues(alpha: 0.55),
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'ابدأ الآن',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            _cardColor,
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
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 66,
            height: 66,
            padding: const EdgeInsets.all(13),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحبا بك في مراقب الأسهم السعودية',
                  style: AppTextStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'تطبيق عملي لمتابعة الأسهم السعودية، حفظ قائمتك المفضلة، واستقبال التنبيهات بعد تسجيل الدخول.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(_OnboardingFeature feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: _stockAccent.withValues(alpha: 0.14),
              ),
              child: Icon(
                feature.icon,
                size: 20,
                color: _stockAccent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          feature.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _stockAccent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          feature.tag,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _stockAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    feature.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingBackdrop extends StatelessWidget {
  const _OnboardingBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_onboardingTop, _onboardingBottom],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -115,
            right: -70,
            child: _GlowCircle(
              size: 260,
              color: _stockAccent.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: 320,
            left: -90,
            child: _GlowCircle(
              size: 230,
              color: _stockAccent.withValues(alpha: 0.05),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -40,
            child: _GlowCircle(
              size: 220,
              color: _stockAccent.withValues(alpha: 0.06),
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
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 80,
            spreadRadius: 16,
          ),
        ],
      ),
    );
  }
}

class _OnboardingFeature {
  const _OnboardingFeature({
    required this.icon,
    required this.title,
    required this.description,
    required this.tag,
  });

  final IconData icon;
  final String title;
  final String description;
  final String tag;
}
