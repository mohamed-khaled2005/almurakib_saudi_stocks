import 'package:flutter/material.dart';

import '../core/models/stock_indicator_model.dart';
import '../core/models/stock_model.dart';
import '../core/services/stock_service.dart';
import '../core/utils/constants.dart';
import '../widgets/technical_indicators_widget.dart';

class StockIndicatorsScreen extends StatefulWidget {
  const StockIndicatorsScreen({
    super.key,
    required this.stock,
    required this.initialIndicators,
  });

  final StockModel stock;
  final StockIndicatorModel initialIndicators;

  @override
  State<StockIndicatorsScreen> createState() => _StockIndicatorsScreenState();
}

class _StockIndicatorsScreenState extends State<StockIndicatorsScreen> {
  late StockIndicatorModel _indicators = widget.initialIndicators;
  bool _refreshing = false;
  String? _errorMessage;

  Future<void> _refresh() async {
    if (_refreshing) return;

    setState(() {
      _refreshing = true;
      _errorMessage = null;
    });

    try {
      final next = await StockService.getIndicators(widget.stock.symbol);
      if (!mounted) return;
      setState(() => _indicators = next);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'تعذر تحديث المؤشرات الفنية حالياً.';
      });
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FC),
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المؤشرات الفنية',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${widget.stock.displayName} • ${widget.stock.symbol}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تحديث المؤشرات',
            onPressed: _refreshing ? null : _refresh,
            icon: _refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: AppColors.primaryBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_indicators.indicators.length} مؤشر فني',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'صفحة مستقلة لقراءة المؤشرات بسهولة ومقارنة الإشارات بسرعة.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.loss.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _errorMessage!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.loss,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            TechnicalIndicatorsWidget(indicators: _indicators),
          ],
        ),
      ),
    );
  }
}
