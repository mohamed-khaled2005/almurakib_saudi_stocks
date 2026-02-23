import 'package:flutter/material.dart';

import '../core/utils/constants.dart';
import '../animations/scale_animation.dart';

Color _a(Color c, double opacity) =>
    c.withAlpha((opacity.clamp(0.0, 1.0) * 255).round());

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );

    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.15, 1.0)),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 1.6,
            colors: [
              _a(cs.primary, 0.10),
              bg,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleAnimation(
                  child: SizedBox(
                    width: 122,
                    height: 122,
                    child: Image.asset(
                      'assets/images/icon.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _a(cs.primary, 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.assessment_rounded,
                            size: 58,
                            color: cs.primary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SlideTransition(
                  position: _slide,
                  child: Text(
                    'مراقب الأسهم السعودية',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
