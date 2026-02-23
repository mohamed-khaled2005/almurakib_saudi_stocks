import 'package:flutter/widgets.dart';
import 'constants.dart';

class Responsive {
  static double _screenWidth(BuildContext context) => MediaQuery.of(context).size.width;

  static bool isMobile(BuildContext context) => _screenWidth(context) < 600;
  static bool isTablet(BuildContext context) => _screenWidth(context) >= 600 && _screenWidth(context) < 1200;
  static bool isDesktop(BuildContext context) => _screenWidth(context) >= 1200;

  static double responsiveValue(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  static EdgeInsets responsivePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: responsiveValue(
        context,
        mobile: AppDimensions.paddingMedium,
        tablet: AppDimensions.paddingLarge,
        desktop: 32.0,
      ),
      vertical: AppDimensions.paddingMedium,
    );
  }

  static double responsiveFontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return responsiveValue(
      context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.2,
      desktop: desktop ?? mobile * 1.4,
    );
  }
}
