import 'package:flutter/material.dart';
import '../core/models/stock_indicator_model.dart';
import '../core/utils/constants.dart';
import '../core/utils/server_time_utils.dart';

class TechnicalIndicatorsWidget extends StatelessWidget {
  final StockIndicatorModel indicators;

  const TechnicalIndicatorsWidget({
    super.key,
    required this.indicators,
  });

  @override
  Widget build(BuildContext context) {
    final keys = indicators.indicators.keys.toList();

    // ✅ ترتيب مفضل (ثم الباقي أبجدي)
    keys.sort((a, b) {
      final ia = _indicatorPriority(a);
      final ib = _indicatorPriority(b);
      if (ia != ib) return ia.compareTo(ib);
      return a.compareTo(b);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryCard(),
        if (indicators.serverTimeUtc != null) ...[
          const SizedBox(height: 10),
          Text(
            'آخر تحديث: ${ServerTimeUtils.formatLastUpdate(indicators.serverTimeUtc)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'تفاصيل المؤشرات',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: indicators.indicators.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('لا توجد مؤشرات متاحة حالياً',
                      style: AppTextStyles.bodySmall),
                )
              : Column(
                  children: [
                    _buildHeaderRow(),
                    const Divider(
                        height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                    ...List.generate(keys.length, (i) {
                      final name = keys[i];
                      final v = indicators.indicators[name]!;
                      final isLast = i == keys.length - 1;

                      return _buildIndicatorRow(
                        name: name,
                        value: v.value,
                        arabicSignal: v.arabicSignal,
                        originalSignal: v.signal,
                        showDivider: !isLast,
                      );
                    }),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'المؤشر',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'القيمة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 84,
            child: Text(
              'الإشارة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ ملخص المؤشرات: شراء أخضر / بيع أحمر / محايد رمادي
  Widget _buildSummaryCard() {
    final summaryStatus = _summaryStatus(indicators.overallSummary);

    final Color summaryColor;
    final IconData icon;

    switch (summaryStatus) {
      case _SummaryStatus.buy:
        summaryColor = AppColors.gain; // ✅ أخضر
        icon = Icons.arrow_circle_up_rounded;
        break;
      case _SummaryStatus.sell:
        summaryColor = AppColors.loss; // ✅ أحمر
        icon = Icons.arrow_circle_down_rounded;
        break;
      case _SummaryStatus.neutral:
      default:
        summaryColor = Colors.grey; // ✅ رمادي مضمون
        icon = Icons.remove_circle_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [summaryColor, summaryColor.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: summaryColor.withOpacity(0.28),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ملخص المؤشرات الفنية',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.92),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _translateSummary(indicators.overallSummary),
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(icon, color: Colors.white.withOpacity(0.92), size: 48),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniStat('شراء', indicators.totalBuy),
                Container(width: 1, height: 20, color: Colors.white24),
                _buildMiniStat('بيع', indicators.totalSell),
                Container(width: 1, height: 20, color: Colors.white24),
                _buildMiniStat('محايد', indicators.totalNeutral),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 11,
            color: Colors.white.withOpacity(0.85),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildIndicatorRow({
    required String name,
    required double value,
    required String arabicSignal,
    required String originalSignal,
    bool showDivider = true,
  }) {
    final signalLower = originalSignal.toLowerCase().trim();

    Color signalColor = Colors.grey; // ✅ رمادي مضمون
    Color bgSignalColor = Colors.grey.withOpacity(0.10);

    if (_isBuy(signalLower)) {
      signalColor = AppColors.gain;
      bgSignalColor = AppColors.gain.withOpacity(0.10);
    } else if (_isSell(signalLower)) {
      signalColor = AppColors.loss;
      bgSignalColor = AppColors.loss.withOpacity(0.10);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  _translateIndicatorName(name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _formatValue(value),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                width: 84,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: bgSignalColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  arabicSignal,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: signalColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
      ],
    );
  }

  // ====== Helpers ======

  bool _isBuy(String s) => s.contains('buy') || s.contains('شراء');
  bool _isSell(String s) => s.contains('sell') || s.contains('بيع');

  _SummaryStatus _summaryStatus(String summary) {
    final s = summary.toLowerCase().trim();

    // Buy
    if (s.contains('strong buy') || s == 'buy' || s.contains('شراء')) {
      return _SummaryStatus.buy;
    }

    // Sell
    if (s.contains('strong sell') || s == 'sell' || s.contains('بيع')) {
      return _SummaryStatus.sell;
    }

    // Neutral (anything else)
    return _SummaryStatus.neutral;
  }

  String _translateSummary(String summary) {
    final s = summary.toLowerCase().trim();
    if (s.contains('strong buy')) return 'شراء قوي';
    if (s == 'buy') return 'شراء';
    if (s.contains('strong sell')) return 'بيع قوي';
    if (s == 'sell') return 'بيع';
    return 'محايد';
  }

  String _formatValue(double v) {
    if (v.abs() >= 1000) return v.toStringAsFixed(0);
    if (v.abs() >= 100) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }

  int _indicatorPriority(String indicator) {
    const order = {
      'RSI14': 1,
      'MACD12_26': 2,
      'STOCH9_6': 3,
      'STOCHRSI14': 4,
      'ADX14': 5,
      'CCI14': 6,
      'ATR14': 7,
      'WilliamsR': 8,
      'ROC': 9,
      'ParabolicSAR': 10,
      'UltimateOscillator': 11,
      'BullBearPower': 12,
    };
    return order[indicator] ?? 999;
  }

  String _translateIndicatorName(String indicator) {
    const map = {
      'RSI14': 'RSI (14)',
      'STOCH9_6': 'Stochastic',
      'STOCHRSI14': 'Stoch RSI',
      'MACD12_26': 'MACD',
      'WilliamsR': 'Williams %R',
      'CCI14': 'CCI (14)',
      'ATR14': 'ATR (14)',
      'UltimateOscillator': 'Ultimate Osc',
      'ROC': 'ROC',
      'BullBearPower': 'Bull/Bear Power',
      'ADX14': 'ADX (14)',
      'ParabolicSAR': 'Parabolic SAR',
    };
    return map[indicator] ?? indicator;
  }
}

enum _SummaryStatus { buy, sell, neutral }
