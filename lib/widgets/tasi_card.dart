import 'package:flutter/material.dart';
import '../core/models/tasi_index_model.dart';
import '../core/utils/formatters.dart';
import '../core/utils/constants.dart';

class TasiCard extends StatelessWidget {
  final TasiIndexModel tasi;
  final VoidCallback? onRefresh;

  const TasiCard({
    super.key,
    required this.tasi,
    this.onRefresh,
  });

  bool _isSaudiMarketOpen() {
    // نحسب الوقت على توقيت السعودية (UTC+3) بشكل ثابت
    final nowKsa = DateTime.now().toUtc().add(const Duration(hours: 3));

    // تداول السعودية: الأحد إلى الخميس
    final wd = nowKsa.weekday; // Mon=1 .. Sun=7
    final isTradingDay = (wd == DateTime.sunday) ||
        (wd >= DateTime.monday && wd <= DateTime.thursday);

    // ساعات تداول (تقريب عملي): 10:00 إلى 15:00 بتوقيت السعودية
    final minutes = nowKsa.hour * 60 + nowKsa.minute;
    final openMinutes = 10 * 60; // 10:00
    final closeMinutes = 15 * 60; // 15:00

    return isTradingDay && minutes >= openMinutes && minutes < closeMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final isGain = tasi.change >= 0;
    final isOpen = _isSaudiMarketOpen();
    final themeColor = isGain ? AppColors.gain : AppColors.loss;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: [
                      themeColor.withOpacity(0.05),
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -20,
              child: Icon(
                Icons.show_chart_rounded,
                size: 150,
                color: themeColor.withOpacity(0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_graph_rounded,
                              color: AppColors.primaryBlue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'المؤشر العام',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'TASI',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color:
                                      AppColors.textSecondary.withOpacity(0.5),
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      _buildStatusBadge(isOpen),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        Formatters.formatNumber(tasi.value),
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ريال سعودي',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isGain
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              size: 18,
                              color: themeColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              Formatters.formatPercent(tasi.changePercent),
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: themeColor,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: 1,
                              height: 12,
                              color: themeColor.withOpacity(0.3),
                            ),
                            Text(
                              Formatters.formatChange(tasi.change),
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: themeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (onRefresh != null)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onRefresh,
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(
                                Icons.refresh_rounded,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isOpen) {
    final icon = isOpen ? Icons.lock_open_rounded : Icons.lock_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isOpen
              ? Colors.green.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isOpen ? Colors.green[700] : Colors.grey[600],
          ),
          const SizedBox(width: 6),
          Text(
            isOpen ? 'السوق مفتوح' : 'السوق مغلق',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isOpen ? Colors.green[700] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
