import 'package:flutter/material.dart';

class AppColors {
  // ==========================================================
  // ✅ الهوية الجديدة: #028800 (أخضر)
  // - نحافظ على اسم primaryBlue للتوافق مع الأكواد القديمة
  // ==========================================================
  static const Color primaryBlue = Color(0xFF028800); // Brand Green #028800
  static const Color darkBlue = Color(0xFF016500); // Darker shade
  static const Color lightBlue = Color(0xFF37A437); // Lighter tint

  // ✅ خلفيات لايت (تماشي مع الأخضر)
  static const Color background = Color(0xFFF4FFF4);
  static const Color scaffold = background;

  // ✅ كروت
  static const Color cardDark = Color(0xFFFFFFFF); // Card أبيض
  static const Color cardLight = Color(0xFFE9F8E9); // Surface فاتح أخضر

  // ✅ حدود/فواصل/ظل
  static const Color border = Color(0xFFD6EED6);
  static const Color shadow = Color(0x14000000);

  // ✅ نصوص
  static const Color textPrimary = Color(0xFF102010);
  static const Color textSecondary = Color(0xFF5F6A5F);

  // ✅ حالات
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);

  // ✅ تدرج (الاسم الأزرق قديم لكن نخليه أخضر)
  static const Gradient blueGradient = LinearGradient(
    colors: [primaryBlue, darkBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==========================================================
  // ✅ Aliases لتوافق الأكواد القديمة اللي كانت بتستخدم gold
  // ==========================================================
  static const Color primaryGold = primaryBlue;
  static const Color darkGold = darkBlue;
  static const Color lightGold = lightBlue;

  static const Gradient goldGradient = blueGradient;

  // ==========================================================
  // ✅ إضافات مفيدة للسوق: ألوان الربح/الخسارة
  // ==========================================================
  static const Color gain = Color(0xFF16A34A); // أخضر ربح
  static const Color loss = Color(0xFFDC2626); // أحمر خسارة
  static const Color neutral = Color(0xFF6B7280); // رمادي محايد
}

class AppTextStyles {
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    fontFamily: 'Tajawal',
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFamily: 'Tajawal',
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFamily: 'Tajawal',
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
    fontFamily: 'Tajawal',
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
    fontFamily: 'Tajawal',
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
    fontFamily: 'Tajawal',
  );
}

class AppDimensions {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  static const double borderRadius = 16.0;
  static const double borderRadiusLarge = 24.0;
}

class AppAnimations {
  static const Duration pageTransition = Duration(milliseconds: 350);
  static const Duration buttonAnimation = Duration(milliseconds: 200);
  static const Duration shimmerDuration = Duration(milliseconds: 1000);
}
