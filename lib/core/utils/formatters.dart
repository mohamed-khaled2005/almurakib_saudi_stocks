class Formatters {
  /// ✅ تنسيق الأرقام لأقرب فاصلتين
  static String formatNumber(double value) {
    return value.toStringAsFixed(2);
  }

  /// ✅ تنسيق السعر مع العملة
  static String formatPrice(double price) {
    return '${formatNumber(price)} ريال';
  }

  /// ✅ تنسيق النسبة المئوية
  static String formatPercent(double percent) {
    final sign = percent >= 0 ? '+' : '';
    return '$sign${formatNumber(percent)}%';
  }

  /// ✅ تنسيق التغيير
  static String formatChange(double change) {
    final sign = change >= 0 ?  '+' : '';
    return '$sign${formatNumber(change)}';
  }

  /// ✅ إصلاح التنوين العربي
  static String fixArabicTanween(String text) {
    return text
        .replaceAll('ـًا', 'اً')
        .replaceAll('ـٌو', 'ٌو')
        .replaceAll('ـٍي', 'ٍي');
  }

  /// ✅ تنسيق رقم كبير (مثل حجم التداول)
  static String formatLargeNumber(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(2)} مليار';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)} مليون';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)} ألف';
    }
    return formatNumber(value);
  }
}