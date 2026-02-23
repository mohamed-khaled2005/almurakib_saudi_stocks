import 'dart:math';
import 'package:flutter/material.dart';

import '../core/models/stock_model.dart';
import '../core/models/stock_performance_model.dart';
import '../core/services/stock_service.dart';
import '../core/utils/constants.dart';
import '../core/utils/formatters.dart';
import '../core/utils/server_time_utils.dart';

class StockPerformanceTab extends StatefulWidget {
  final StockModel stock;
  const StockPerformanceTab({super.key, required this.stock});

  @override
  State<StockPerformanceTab> createState() => _StockPerformanceTabState();
}

class _StockPerformanceTabState extends State<StockPerformanceTab> {
  StockPerformanceModel? _data;
  bool _loading = true;
  String? _error;

  // ✅ Cache بسيط
  static final Map<String, StockPerformanceModel> _cache = {};
  static final Map<String, DateTime> _cacheAt = {};
  static const Duration _ttl = Duration(minutes: 20);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final key = widget.stock.symbol;

    try {
      if (!force) {
        final cached = _cache[key];
        final at = _cacheAt[key];
        if (cached != null &&
            at != null &&
            DateTime.now().difference(at) < _ttl) {
          _data = cached;
          _loading = false;
          if (mounted) setState(() {});
          return;
        }
      } else {
        _cache.remove(key);
        _cacheAt.remove(key);
      }

      final res = await StockService.getPerformance(widget.stock.symbol);

      _cache[key] = res;
      _cacheAt[key] = DateTime.now();

      if (!mounted) return;
      setState(() {
        _data = res;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  // ========= Helpers =========

  double? _n(StockPerformanceModel p, String key) => p.getNum(key);

  Color _valueColor(double? v) {
    if (v == null) return AppColors.neutral;
    if (v > 0) return AppColors.gain;
    if (v < 0) return AppColors.loss;
    return AppColors.neutral;
  }

  String _fmtPercent(double? v) {
    if (v == null) return '—';
    final sign = v > 0 ? '+' : '';
    return '$sign${v.toStringAsFixed(2)}%';
  }

  String _fmtNum3(double? v) {
    if (v == null) return '—';
    return v.toStringAsFixed(3);
  }

  String _fmtPrice(double? v) {
    if (v == null) return '—';
    return Formatters.formatPrice(v);
  }

  String _safeName() {
    final n = widget.stock.displayName.trim();
    if (n.isNotEmpty) return n;
    return widget.stock.symbol;
  }

  Widget _tooltipIcon(String message) {
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      textStyle: const TextStyle(
          fontFamily: 'Tajawal', fontSize: 12, color: Colors.white),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.88),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.info_outline_rounded,
          size: 18, color: AppColors.textSecondary),
    );
  }

  Widget _sectionHeader(String title, {IconData? icon, Widget? trailing}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.primaryBlue),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _appCard(
      {required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: child,
    );
  }

  Widget _actionRefresh() {
    return InkWell(
      onTap: _loading ? null : () => _load(force: true),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.refresh_rounded, size: 18, color: AppColors.primaryBlue),
            SizedBox(width: 6),
            Text(
              'تحديث',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========= UI Components =========

  Widget _metricCard({
    required String label,
    required String valueText,
    required Color valueColor,
    IconData? icon,
    Color? iconBg,
    String? subtitle,
  }) {
    final bg = valueColor == AppColors.neutral
        ? Colors.grey.withOpacity(0.06)
        : valueColor.withOpacity(0.10);

    final brd = valueColor == AppColors.neutral
        ? Colors.black.withOpacity(0.06)
        : valueColor.withOpacity(0.20);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: (iconBg ?? AppColors.primaryBlue.withOpacity(0.10)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: AppColors.primaryBlue),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            valueText,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: valueColor,
              height: 1.0,
            ),
          ),
          if (subtitle != null && subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _gridWrap({
    required List<Widget> children,
    double spacing = 12,
  }) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cols = w >= 720 ? 4 : (w >= 520 ? 3 : 2);
        final itemW = (w - (cols - 1) * spacing) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: itemW, child: child),
          ],
        );
      },
    );
  }

  Widget _kvRow(String label, String value,
      {Color? valueColor, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w900,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ========= Range Bar Painter =========

  Widget _rangeRow({
    required String label,
    required double? low,
    required double? high,
    required double globalMin,
    required double globalMax,
  }) {
    final l = low ?? 0;
    final h = high ?? 0;

    final has =
        (low != null && high != null && globalMax > globalMin && h >= l);
    final vColor = AppColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              'أعلى: ${_fmtPrice(high)}',
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w900, color: vColor),
            ),
            const SizedBox(width: 10),
            Text(
              'أدنى: ${_fmtPrice(low)}',
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w900, color: vColor),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 10,
          child: has
              ? CustomPaint(
                  painter: _RangeBarPainter(
                    globalMin: globalMin,
                    globalMax: globalMax,
                    low: l,
                    high: h,
                    fill: AppColors.primaryBlue,
                  ),
                  child: const SizedBox.expand(),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
        ),
      ],
    );
  }

  // ========= States =========

  Widget _loadingSkeleton() {
    Widget box({double h = 16, double w = double.infinity, double r = 14}) {
      return Container(
        height: h,
        width: w,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(r),
        ),
      );
    }

    Widget card({required Widget child}) => _appCard(
          padding: const EdgeInsets.all(16),
          child: child,
        );

    return Column(
      children: [
        card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              box(h: 16, w: 140),
              const SizedBox(height: 12),
              box(h: 42, w: double.infinity, r: 18),
              const SizedBox(height: 12),
              box(h: 10, w: double.infinity, r: 999),
            ],
          ),
        ),
        const SizedBox(height: 14),
        card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              box(h: 16, w: 120),
              const SizedBox(height: 14),
              _gridWrap(
                children: List.generate(
                  6,
                  (_) => box(h: 74, w: double.infinity, r: 16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              5,
              (i) => Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    box(h: 14, w: 160),
                    const SizedBox(height: 10),
                    box(h: 10, w: double.infinity, r: 999),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorState(String message) {
    return _appCard(
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: AppColors.loss.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_off_rounded,
                size: 34, color: AppColors.error),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => _load(force: true),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة',
                style: TextStyle(fontFamily: 'Tajawal')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return _appCard(
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.insert_chart_outlined,
                size: 34, color: AppColors.primaryBlue),
          ),
          const SizedBox(height: 12),
          Text(
            'لا توجد بيانات أداء متاحة حالياً',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'حاول تحديث الصفحة أو لاحقاً.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ========= Build =========

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _load(force: true),
      color: AppColors.primaryBlue,
      backgroundColor: Colors.white,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أداء السهم',
                      style: AppTextStyles.headingSmall.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_safeName()} • ${widget.stock.symbol}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _actionRefresh(),
            ],
          ),
          const SizedBox(height: 10),

          // ✅ بدل "الملخص السريع" (المحذوف) نعرض سطر تحديث بسيط فقط لو متاح
          if (!_loading &&
              _error == null &&
              (_data?.serverTimeUtc != null ||
                  (_data?.serverTime != null &&
                      _data!.serverTime!.trim().isNotEmpty)))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'آخر تحديث: ${ServerTimeUtils.formatLastUpdate(_data!.serverTimeUtc ?? ServerTimeUtils.parseToUtc(_data!.serverTime))}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),

          const SizedBox(height: 4),

          if (_loading) ...[
            _loadingSkeleton(),
          ] else if (_error != null) ...[
            _errorState(_error!),
          ] else if (_data == null) ...[
            _emptyState(),
          ] else ...[
            ..._buildContent(_data!),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildContent(StockPerformanceModel data) {
    final p = data;

    // ✅ 1) الأداء — العناوين حسب طلب العميل بالضبط
    final perfItems = <_PerfItem>[
      _PerfItem('الأسبوعي', 'perf_1w', Icons.calendar_view_week_rounded),
      _PerfItem('الشهري', 'perf_1m', Icons.calendar_month_rounded),
      _PerfItem('3 شهور', 'perf_3m', Icons.date_range_rounded),
      _PerfItem('6 شهور', 'perf_6m', Icons.event_repeat_rounded),
      _PerfItem('منذ بداية السنة', 'perf_ytd', Icons.flag_rounded),
      _PerfItem('سنة', 'perf_1y', Icons.timelapse_rounded),
      _PerfItem('5 سنوات', 'perf_5y', Icons.auto_graph_rounded),
      _PerfItem('منذ الإدراج', 'perf_all', Icons.rocket_launch_rounded),
    ];

    // 2) النطاق السعري
    final ranges = <_RangeItem>[
      _RangeItem('آخر شهر', 'low_1m', 'high_1m'),
      _RangeItem('آخر 3 شهور', 'low_3m', 'high_3m'),
      _RangeItem('آخر 6 شهور', 'low_6m', 'high_6m'),
      _RangeItem('آخر 52 أسبوع', 'low_52', 'high_52'),
      _RangeItem('الأعلى تاريخياً', 'lowest', 'highest'),
    ];

    // 3) التذبذب والبيتا
    final volatility = <_KVItem>[
      _KVItem('تذبذب يومي', 'volt_d', Icons.bolt_rounded),
      _KVItem('تذبذب أسبوعي', 'volt_w', Icons.show_chart_rounded),
      _KVItem('تذبذب شهري', 'volt_m', Icons.stacked_line_chart_rounded),
    ];

    final betas = <_KVItem>[
      _KVItem('بيتا 1 سنة', 'beta_1y', Icons.tune_rounded),
      _KVItem('بيتا 3 سنوات', 'beta_3y', Icons.tune_rounded),
      _KVItem('بيتا 5 سنوات', 'beta_5y', Icons.tune_rounded),
    ];

    // ✅ 4) تغير القيمة السوقية — العناوين حسب طلب العميل
    final mcap = <_PerfItem>[
      _PerfItem('أسبوع', '1w_marketcap', Icons.timeline_rounded),
      _PerfItem('شهر', '1m_marketcap', Icons.timeline_rounded),
      _PerfItem('3 شهور', '3m_marketcap', Icons.timeline_rounded),
      _PerfItem('6 شهور', '6m_marketcap', Icons.timeline_rounded),
      _PerfItem('منذ بداية السنة', 'ytd_marketcap', Icons.timeline_rounded),
      _PerfItem('سنة', '1y_marketcap', Icons.timeline_rounded),
      _PerfItem('5 سنوات', '5y_marketcap', Icons.timeline_rounded),
    ];

    // ✅ Global range for bars
    final allLows = <double>[];
    final allHighs = <double>[];
    for (final r in ranges) {
      final lo = _n(p, r.lowKey);
      final hi = _n(p, r.highKey);
      if (lo != null) allLows.add(lo);
      if (hi != null) allHighs.add(hi);
    }
    final globalMin = allLows.isEmpty ? 0.0 : allLows.reduce(min);
    final globalMax = allHighs.isEmpty ? 1.0 : allHighs.reduce(max);

    return [
      // ✅ Section 1: Performance
      _sectionHeader('الأداء', icon: Icons.trending_up_rounded),
      const SizedBox(height: 12),
      _appCard(
        child: _gridWrap(
          children: perfItems.map((e) {
            final v = _n(p, e.key);
            final c = _valueColor(v);
            return _metricCard(
              label: e.label,
              valueText: _fmtPercent(v),
              valueColor: c,
              icon: e.icon,
              iconBg: c == AppColors.neutral
                  ? Colors.grey.withOpacity(0.12)
                  : c.withOpacity(0.18),
            );
          }).toList(),
        ),
      ),

      const SizedBox(height: 20),

      // ✅ Section 2: Price Range
      _sectionHeader('النطاق السعري', icon: Icons.price_change_rounded),
      const SizedBox(height: 12),
      _appCard(
        child: Column(
          children: [
            for (int i = 0; i < ranges.length; i++) ...[
              _rangeRow(
                label: ranges[i].label,
                low: _n(p, ranges[i].lowKey),
                high: _n(p, ranges[i].highKey),
                globalMin: globalMin,
                globalMax: globalMax,
              ),
              if (i != ranges.length - 1) ...[
                const SizedBox(height: 14),
                Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.black.withOpacity(0.06)),
                const SizedBox(height: 14),
              ],
            ],
          ],
        ),
      ),

      const SizedBox(height: 20),

      // ✅ Section 3: Risk
      Row(
        children: [
          Expanded(
            child: _sectionHeader(
              'التذبذب والمخاطر',
              icon: Icons.shield_rounded,
              trailing: _tooltipIcon(
                'هذه القيم للمساعدة في فهم تذبذب السهم ومخاطره مقارنة بحركة السوق.',
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),

      LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 560;

          final volCard = _appCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'التذبذب',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _tooltipIcon(
                      'التذبذب (Volatility): مقياس لمدى حركة السعر. كلما زادت القيمة زادت الحركة والمخاطرة.',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (int i = 0; i < volatility.length; i++) ...[
                  _kvRow(
                    volatility[i].label,
                    _fmtNum3(_n(p, volatility[i].key)),
                    icon: volatility[i].icon,
                  ),
                  if (i != volatility.length - 1)
                    Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.black.withOpacity(0.06)),
                ],
              ],
            ),
          );

          final betaCard = _appCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'البيتا',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _tooltipIcon(
                      'البيتا (Beta): تقيس حساسية السهم لحركة السوق.\n'
                      '1 = مثل السوق، أكبر من 1 = أكثر تقلباً، أقل من 1 = أقل تقلباً.',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (int i = 0; i < betas.length; i++) ...[
                  _kvRow(
                    betas[i].label,
                    _fmtNum3(_n(p, betas[i].key)),
                    icon: betas[i].icon,
                  ),
                  if (i != betas.length - 1)
                    Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.black.withOpacity(0.06)),
                ],
              ],
            ),
          );

          if (wide) {
            return Row(
              children: [
                Expanded(child: volCard),
                const SizedBox(width: 12),
                Expanded(child: betaCard),
              ],
            );
          }

          return Column(
            children: [
              volCard,
              const SizedBox(height: 12),
              betaCard,
            ],
          );
        },
      ),

      const SizedBox(height: 20),

      // ✅ Section 4: Market Cap Change
      _sectionHeader('تغير القيمة السوقية',
          icon: Icons.account_balance_rounded),
      const SizedBox(height: 12),
      _appCard(
        child: _gridWrap(
          children: mcap.map((e) {
            final v = _n(p, e.key);
            final c = _valueColor(v);
            return _metricCard(
              label: e.label,
              valueText: _fmtPercent(v),
              valueColor: c,
              icon: e.icon,
              iconBg: c == AppColors.neutral
                  ? Colors.grey.withOpacity(0.12)
                  : c.withOpacity(0.18),
            );
          }).toList(),
        ),
      ),

      // ✅ تم حذف "التحذير/الملاحظة" الموجودة بالآخر حسب طلب العميل
    ];
  }
}

// ===== Models for UI mapping =====

class _PerfItem {
  final String label;
  final String key;
  final IconData icon;
  const _PerfItem(this.label, this.key, this.icon);
}

class _RangeItem {
  final String label;
  final String lowKey;
  final String highKey;
  const _RangeItem(this.label, this.lowKey, this.highKey);
}

class _KVItem {
  final String label;
  final String key;
  final IconData icon;
  const _KVItem(this.label, this.key, this.icon);
}

// ===== Range Bar Painter =====

class _RangeBarPainter extends CustomPainter {
  final double globalMin;
  final double globalMax;
  final double low;
  final double high;
  final Color fill;

  _RangeBarPainter({
    required this.globalMin,
    required this.globalMax,
    required this.low,
    required this.high,
    required this.fill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final track = Paint()
      ..color = Colors.black.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(999),
    );
    canvas.drawRRect(r, track);

    final range = (globalMax - globalMin);
    if (range <= 0) return;

    double start = (low - globalMin) / range;
    double end = (high - globalMin) / range;

    start = start.clamp(0.0, 1.0);
    end = end.clamp(0.0, 1.0);
    if (end < start) {
      final tmp = start;
      start = end;
      end = tmp;
    }

    final x1 = start * size.width;
    final x2 = end * size.width;
    final w = max(4.0, x2 - x1);

    final bar = Paint()
      ..color = fill.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(x1, 0, w, size.height),
      const Radius.circular(999),
    );
    canvas.drawRRect(rr, bar);

    final cap = Paint()
      ..color = fill
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x1, size.height / 2), size.height / 2, cap);
    canvas.drawCircle(Offset(x1 + w, size.height / 2), size.height / 2, cap);
  }

  @override
  bool shouldRepaint(covariant _RangeBarPainter oldDelegate) {
    return oldDelegate.globalMin != globalMin ||
        oldDelegate.globalMax != globalMax ||
        oldDelegate.low != low ||
        oldDelegate.high != high ||
        oldDelegate.fill != fill;
  }
}
