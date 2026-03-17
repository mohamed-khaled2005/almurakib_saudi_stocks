import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

import '../core/models/stock_model.dart';
import '../core/models/stock_indicator_model.dart';
import '../core/services/stock_service.dart';
import '../core/services/favorites_service.dart';
import '../core/utils/formatters.dart';
import '../core/utils/constants.dart';

import '../animations/fade_animation.dart';
import '../animations/slide_animation.dart';
import '../screens/stock_indicators_screen.dart';
import '../widgets/technical_indicators_widget.dart';
import '../widgets/stock_performance_tab.dart';
import '../widgets/last_update_banner.dart';

/// ✅ تم إزالة "يوم" لأن period=1d (شمعة يومية) فغالبًا "يوم" = نقطة واحدة
enum ChartPeriod {
  week('أسبوع'),
  month('شهر'),
  threeMonths('3 أشهر'),
  sixMonths('6 أشهر'),
  year('سنة');

  final String label;
  const ChartPeriod(this.label);
}

/// ✅ Candle محلي للشاشة فقط
class _Candle {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  const _Candle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

class StockDetailScreen extends StatefulWidget {
  final StockModel stock;
  const StockDetailScreen({super.key, required this.stock});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen>
    with SingleTickerProviderStateMixin {
  StockModel? _stock;
  StockIndicatorModel? _indicators;

  List<_Candle> _yearCandles = [];
  List<_Candle> _visibleCandles = [];
  List<FlSpot> _spots = [];

  _Candle? _lastCandle;
  _Candle? _prevCandle;

  bool _loadingStock = true;
  bool _loadingIndicators = true;
  bool _loadingChart = true;

  String? _chartError;

  bool _isFavorite = false;

  ChartPeriod _selectedPeriod = ChartPeriod.month;
  late TabController _tabController;

  int? _touchedIndex;

  /// ✅ قفل سكرول الصفحة + قفل سوايب التبويبات أثناء لمس الشارت
  bool _lockParentGestures = false;

  void _setLockParentGestures(bool v) {
    if (!mounted) return;
    if (_lockParentGestures == v) return;
    setState(() => _lockParentGestures = v);
  }

  // ✅ Formats
  final DateFormat _rangeFmt = DateFormat('d/M/y', 'en');
  final DateFormat _tooltipFmt = DateFormat('d/M/y', 'en');
  final DateFormat _bottomDayMonthFmt = DateFormat('d/M', 'en');
  final DateFormat _bottomMonthYearFmt = DateFormat('M/y', 'en');

  // ✅ Cache بسيط
  static final Map<String, List<_Candle>> _yearCache = {};
  static final Map<String, DateTime> _yearCacheAt = {};
  static const Duration _cacheTtl = Duration(hours: 6);
  static const int _dedicatedIndicatorsThreshold = 8;

  @override
  void initState() {
    super.initState();

    // ✅ المؤشرات تُعرض بشكل ذكي داخل الصفحة أو في صفحة مستقلة حسب كثافة البيانات
    _tabController = TabController(length: 2, vsync: this);

    _stock = widget.stock;

    _checkFavorite();
    _loadStockFresh();
    _loadIndicators();
    _loadYearHistoryOnce();
  }

  StockModel get _safeStock => _stock ?? widget.stock;

  bool get _hasIndicators =>
      _indicators != null && _indicators!.indicators.isNotEmpty;

  bool get _useDedicatedIndicatorsPage =>
      _hasIndicators &&
      _indicators!.indicators.length >= _dedicatedIndicatorsThreshold;

  String _symbolForHistory(String s) {
    var out = s.trim();
    try {
      out = Uri.decodeComponent(out);
    } catch (_) {}
    if (out.contains(':')) {
      out = out.split(':').last.trim();
    }
    return out;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    final s = v.toString().trim();
    return double.tryParse(s) ?? 0.0;
  }

  DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;

    if (v is String) {
      final s = v.trim();
      final asInt = int.tryParse(s);
      if (asInt != null) return _toDateTime(asInt);

      if (RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$').hasMatch(s)) {
        final iso = s.replaceFirst(' ', 'T');
        return DateTime.tryParse(iso);
      }

      return DateTime.tryParse(s);
    }

    if (v is num) {
      final n = v.toInt();
      if (n > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(n, isUtc: false);
      } else if (n > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(n * 1000, isUtc: false);
      }
    }

    return null;
  }

  _Candle? _fixAndBuildCandle({
    required DateTime time,
    required double open,
    required double high,
    required double low,
    required double close,
    required double volume,
  }) {
    if (close <= 0) return null;

    double o = open > 0 ? open : close;
    double h = high > 0 ? high : max(o, close);
    double l = low > 0 ? low : min(o, close);

    h = max(h, max(o, close));
    l = min(l, min(o, close));

    return _Candle(
      time: time,
      open: o,
      high: h,
      low: l,
      close: close,
      volume: volume,
    );
  }

  _Candle? _parseCandle(dynamic item) {
    try {
      if (item is List && item.length >= 5) {
        final dt = _toDateTime(item[0]);
        if (dt == null) return null;

        return _fixAndBuildCandle(
          time: dt,
          open: _toDouble(item[1]),
          high: _toDouble(item[2]),
          low: _toDouble(item[3]),
          close: _toDouble(item[4]),
          volume: item.length >= 6 ? _toDouble(item[5]) : 0.0,
        );
      }

      if (item is Map) {
        final m = Map<String, dynamic>.from(item);

        final dt = _toDateTime(
          m['time'] ??
              m['t'] ??
              m['timestamp'] ??
              m['date'] ??
              m['datetime'] ??
              m['ts'] ??
              m['tm'],
        );
        if (dt == null) return null;

        final open = _toDouble(m['open'] ?? m['o']);
        final high = _toDouble(m['high'] ?? m['h']);
        final low = _toDouble(m['low'] ?? m['l']);
        final close = _toDouble(m['close'] ?? m['c']);
        final vol = _toDouble(m['volume'] ?? m['v'] ?? m['vol']);

        return _fixAndBuildCandle(
          time: dt,
          open: open,
          high: high,
          low: low,
          close: close,
          volume: vol,
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  List<_Candle> _buildFromOhlcArrays(Map raw) {
    final m = Map<String, dynamic>.from(raw);

    final times =
        (m['t'] ?? m['time'] ?? m['timestamp'] ?? m['times']) as List?;
    final opens = (m['o'] ?? m['open'] ?? m['opens']) as List?;
    final highs = (m['h'] ?? m['high'] ?? m['highs']) as List?;
    final lows = (m['l'] ?? m['low'] ?? m['lows']) as List?;
    final closes = (m['c'] ?? m['close'] ?? m['closes']) as List?;
    final vols = (m['v'] ?? m['volume'] ?? m['volumes']) as List?;

    if (times == null || closes == null) return [];

    final len = [
      times.length,
      closes.length,
      opens?.length ?? closes.length,
      highs?.length ?? closes.length,
      lows?.length ?? closes.length,
      vols?.length ?? closes.length,
    ].reduce(min);

    final out = <_Candle>[];
    for (int i = 0; i < len; i++) {
      final dt = _toDateTime(times[i]);
      if (dt == null) continue;

      final c = _fixAndBuildCandle(
        time: dt,
        open: opens != null ? _toDouble(opens[i]) : _toDouble(closes[i]),
        high: highs != null ? _toDouble(highs[i]) : 0.0,
        low: lows != null ? _toDouble(lows[i]) : 0.0,
        close: _toDouble(closes[i]),
        volume: vols != null ? _toDouble(vols[i]) : 0.0,
      );

      if (c != null) out.add(c);
    }
    return out;
  }

  List<_Candle> _dedupeByTime(List<_Candle> list) {
    final map = <int, _Candle>{};
    for (final c in list) {
      final k = DateTime(c.time.year, c.time.month, c.time.day)
          .millisecondsSinceEpoch;
      map[k] = c;
    }
    final out = map.values.toList();
    out.sort((a, b) => a.time.compareTo(b.time));
    return out;
  }

  List<_Candle> _extractCandles(dynamic data) {
    dynamic raw = data;

    if (raw is Map) {
      raw = raw['data'] ??
          raw['result'] ??
          raw['response'] ??
          raw['candles'] ??
          raw['values'] ??
          raw['history'] ??
          raw['chart'] ??
          raw;
    }

    if (raw is List) {
      return raw.map(_parseCandle).whereType<_Candle>().toList();
    }

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);

      final arr1 = _buildFromOhlcArrays(map);
      if (arr1.isNotEmpty) return arr1;

      final inner =
          map['data'] ?? map['result'] ?? map['candles'] ?? map['response'];
      if (inner is Map) {
        final innerMap = Map<String, dynamic>.from(inner);

        final arr2 = _buildFromOhlcArrays(innerMap);
        if (arr2.isNotEmpty) return arr2;

        final out = <_Candle>[];
        for (final entry in innerMap.entries) {
          final v = entry.value;
          if (v is Map) {
            final vv = Map<String, dynamic>.from(v);
            vv.putIfAbsent('t', () => entry.key);
            final c = _parseCandle(vv);
            if (c != null) out.add(c);
          }
        }
        if (out.isNotEmpty) return out;
      }

      final out = <_Candle>[];
      for (final entry in map.entries) {
        final v = entry.value;
        if (v is Map) {
          final vv = Map<String, dynamic>.from(v);
          vv.putIfAbsent('t', () => entry.key);
          final c = _parseCandle(vv);
          if (c != null) out.add(c);
        }
      }
      if (out.isNotEmpty) return out;

      final maybeList =
          map['data'] ?? map['candles'] ?? map['values'] ?? map['response'];
      if (maybeList is List) {
        return maybeList.map(_parseCandle).whereType<_Candle>().toList();
      }
    }

    return [];
  }

  Future<void> _loadStockFresh() async {
    setState(() => _loadingStock = true);
    try {
      final fresh = await StockService.getStockDetail(widget.stock.symbol);
      if (!mounted) return;
      setState(() {
        _stock = fresh;
        _loadingStock = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingStock = false);
    }
  }

  Future<void> _loadIndicators() async {
    setState(() => _loadingIndicators = true);
    try {
      final indicators = await StockService.getIndicators(widget.stock.symbol);
      if (!mounted) return;
      setState(() {
        _indicators = indicators;
        _loadingIndicators = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingIndicators = false);
    }
  }

  Future<void> _checkFavorite() async {
    final isFav = await FavoritesService.isFavorite(widget.stock.symbol);
    if (!mounted) return;
    setState(() => _isFavorite = isFav);
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isFavorite = !_isFavorite);
    await FavoritesService.toggleFavorite(widget.stock.symbol);
    _checkFavorite();
  }

  void _changePeriod(ChartPeriod period) {
    if (_selectedPeriod == period) return;
    setState(() {
      _selectedPeriod = period;
      _touchedIndex = null;
    });
    _applyPeriodFromYear();
  }

  Future<void> _loadYearHistoryOnce({bool forceRefresh = false}) async {
    setState(() {
      _loadingChart = true;
      _chartError = null;
    });

    try {
      final symbol = _symbolForHistory(widget.stock.symbol);

      if (!forceRefresh) {
        final cached = _yearCache[symbol];
        final at = _yearCacheAt[symbol];
        if (cached != null &&
            at != null &&
            DateTime.now().difference(at) < _cacheTtl) {
          _yearCandles = cached;
          _applyPeriodFromYear();
          return;
        }
      } else {
        _yearCache.remove(symbol);
        _yearCacheAt.remove(symbol);
      }

      final url = ApiEndpoints.history(
        symbol: symbol,
        period: '1d',
        length: 520,
      );

      final data = await ApiClient.get(url);

      final candles = _extractCandles(data);
      candles.sort((a, b) => a.time.compareTo(b.time));

      final cleaned = candles.where((c) => c.close > 0).toList();
      final deduped = _dedupeByTime(cleaned);

      if (!mounted) return;

      setState(() => _yearCandles = deduped);

      _yearCache[symbol] = deduped;
      _yearCacheAt[symbol] = DateTime.now();

      _applyPeriodFromYear();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _chartError = 'تعذر تحميل البيانات التاريخية';
        _loadingChart = false;
      });
    }
  }

  void _applyPeriodFromYear() {
    if (_yearCandles.length < 2) {
      setState(() {
        _visibleCandles = [];
        _spots = [];
        _lastCandle = null;
        _prevCandle = null;
        _touchedIndex = null;
        _loadingChart = false;
        _chartError ??= 'لا توجد بيانات تاريخية لهذا السهم';
      });
      return;
    }

    final lastTime = _yearCandles.last.time;
    final from = _periodFromDate(lastTime, _selectedPeriod);

    var slice = _yearCandles.where((c) => !c.time.isBefore(from)).toList();

    if (slice.length < 2) {
      slice = _yearCandles.length >= 14
          ? _yearCandles.sublist(_yearCandles.length - 14)
          : List.of(_yearCandles);
    }

    slice = _downsample(slice, _maxPointsForPeriod(_selectedPeriod));

    final spots = slice
        .map((c) => FlSpot(c.time.millisecondsSinceEpoch.toDouble(), c.close))
        .toList();

    setState(() {
      _visibleCandles = slice;
      _spots = spots;
      _lastCandle = slice.isNotEmpty ? slice.last : null;
      _prevCandle = slice.length >= 2 ? slice[slice.length - 2] : null;
      _touchedIndex = null;
      _loadingChart = false;
      _chartError = null;
    });
  }

  DateTime _periodFromDate(DateTime end, ChartPeriod p) {
    switch (p) {
      case ChartPeriod.week:
        return end.subtract(const Duration(days: 7));
      case ChartPeriod.month:
        return end.subtract(const Duration(days: 30));
      case ChartPeriod.threeMonths:
        return end.subtract(const Duration(days: 90));
      case ChartPeriod.sixMonths:
        return end.subtract(const Duration(days: 180));
      case ChartPeriod.year:
        return end.subtract(const Duration(days: 365));
    }
  }

  int _maxPointsForPeriod(ChartPeriod p) {
    switch (p) {
      case ChartPeriod.week:
        return 80;
      case ChartPeriod.month:
        return 140;
      case ChartPeriod.threeMonths:
        return 180;
      case ChartPeriod.sixMonths:
        return 220;
      case ChartPeriod.year:
        return 260;
    }
  }

  List<_Candle> _downsample(List<_Candle> data, int maxPoints) {
    if (data.length <= maxPoints) return data;
    final step = (data.length / maxPoints).ceil();
    final out = <_Candle>[];
    for (int i = 0; i < data.length; i += step) {
      out.add(data[i]);
    }
    if (out.isNotEmpty && out.last.time != data.last.time) out.add(data.last);
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final stock = _safeStock;
    final changeColor = stock.isGain ? AppColors.gain : AppColors.loss;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FC),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
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
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: Colors.black),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              stock.displayName,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
            ),
            Text(
              stock.symbol,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          if (_useDedicatedIndicatorsPage)
            IconButton(
              tooltip: 'المؤشرات الفنية',
              onPressed: _openIndicatorsScreen,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.12),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: AppColors.primaryBlue,
                  size: 22,
                ),
              ),
            ),
          IconButton(
            onPressed: _toggleFavorite,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Container(
                key: ValueKey(_isFavorite),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _isFavorite
                          ? Colors.amber.withOpacity(0.2)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  color: _isFavorite ? Colors.amber : AppColors.textSecondary,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          SlideAnimation(child: _buildHeroPriceSection(changeColor)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: LastUpdateBanner(
              updateUtc: stock.lastUpdateUtc,
              loading: _loadingStock,
            ),
          ),
          const SizedBox(height: 14),
          SlideAnimation(
              delay: const Duration(milliseconds: 100), child: _buildTabs()),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,

              /// ✅ هنا قفل السوايب الأفقي بين التابات أثناء لمس الشارت
              physics: _lockParentGestures
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              children: [
                _buildChartTab(changeColor),
                StockPerformanceTab(stock: stock),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPriceSection(Color changeColor) {
    final stock = _safeStock;

    return Column(
      children: [
        _loadingStock
            ? const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(
                    color: AppColors.primaryBlue, strokeWidth: 2.5),
              )
            : Text(
                Formatters.formatPrice(stock.price),
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1.0,
                  letterSpacing: -1,
                ),
              ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: changeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                stock.isGain
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 20,
                color: changeColor,
              ),
              const SizedBox(width: 8),
              Text(
                Formatters.formatPercent(stock.changePercent),
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: changeColor,
                ),
              ),
              Container(
                width: 1,
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: changeColor.withOpacity(0.3),
              ),
              Text(
                Formatters.formatChange(stock.change),
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: changeColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ✅ FIXED: Tabs Layout (No more clipping / eaten design)
  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 56, // ✅ أعلى شوية لتفادي قصّ النص
      padding: const EdgeInsets.all(4), // ✅ padding هنا بدل TabBar
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,

        // ✅ مهم جداً لتقليل الهدر ومنع القصّ
        labelPadding: EdgeInsets.zero,
        indicatorPadding: EdgeInsets.zero,

        indicator: BoxDecoration(
          color: AppColors.primaryBlue,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.22),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        // ✅ خط أصغر سنة + FittedBox داخل كل تاب (يضبط تلقائياً)
        labelStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 13.5,
          fontWeight: FontWeight.w900,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 13.0,
          fontWeight: FontWeight.w800,
        ),
        tabs: const [
          Tab(child: _TabLabel('تحليل الأداء')),
          Tab(child: _TabLabel('أداء السهم')),
        ],
      ),
    );
  }

  Widget _buildChartTab(Color trendColor) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),

      /// ✅ هنا قفل السحب الرأسي للصفحة أثناء لمس الشارت
      physics: _lockParentGestures
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      children: [
        _buildUnifiedTitle(title: "إحصائيات الجلسة"),
        const SizedBox(height: 16),
        SlideAnimation(
            delay: const Duration(milliseconds: 200),
            child: _buildStockInfoGrid()),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildUnifiedTitle(title: "المخطط البياني"),
            InkWell(
              onTap: () => _loadYearHistoryOnce(forceRefresh: true),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.refresh_rounded,
                        size: 18, color: AppColors.primaryBlue),
                    const SizedBox(width: 6),
                    Text(
                      'تحديث',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildChartMetaRow(),
        const SizedBox(height: 10),
        SlideAnimation(
          delay: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildPeriodChips(),
                const SizedBox(height: 14),

                /// ✅ أهم جزء: التقاط كل اللمسات على مساحة الشارت (حتى لو شفاف)
                /// وإغلاق/فتح سكرول الـ ListView + سوايب الـ TabBarView بشكل مضمون
                Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (_) => _setLockParentGestures(true),
                  onPointerUp: (_) => _setLockParentGestures(false),
                  onPointerCancel: (_) => _setLockParentGestures(false),
                  child: SizedBox(
                    height: 320,
                    child: _loadingChart
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primaryBlue, strokeWidth: 2.5),
                          )
                        : _buildChart(trendColor),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_loadingIndicators || _hasIndicators) ...[
          const SizedBox(height: 28),
          _buildIndicatorsSection(),
        ],
      ],
    );
  }

  Widget _buildChartMetaRow() {
    if (_visibleCandles.isEmpty) return const SizedBox.shrink();

    final from = _visibleCandles.first.time;
    final to = _visibleCandles.last.time;

    final range = '${_rangeFmt.format(from)}  —  ${_rangeFmt.format(to)}';

    final minP = _visibleCandles.map((e) => e.low).reduce(min);
    final maxP = _visibleCandles.map((e) => e.high).reduce(max);

    final idx = _touchedIndex;
    final rightWidget =
        (idx != null && idx >= 0 && idx < _visibleCandles.length)
            ? _buildTouchedBadge(_visibleCandles[idx])
            : _buildMinMaxBadge(minP, maxP);

    return Row(
      children: [
        Expanded(
          child: Text(
            range,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        rightWidget,
      ],
    );
  }

  Widget _buildTouchedBadge(_Candle c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Text(
        '${c.close.toStringAsFixed(2)} ريال  |  ${_tooltipFmt.format(c.time)}',
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildMinMaxBadge(double minP, double maxP) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Text(
        'أدنى: ${minP.toStringAsFixed(2)}  |  أعلى: ${maxP.toStringAsFixed(2)}',
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildPeriodChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: ChartPeriod.values.map((period) {
          final selected = _selectedPeriod == period;
          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: InkWell(
              onTap: () => _changePeriod(period),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primaryBlue
                      : Colors.grey.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? AppColors.primaryBlue
                        : Colors.black.withOpacity(0.06),
                  ),
                ),
                child: Text(
                  period.label,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUnifiedTitle({required String title}) {
    return Row(
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
        Text(
          title,
          style: AppTextStyles.headingSmall.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildChart(Color color) {
    if (_spots.length < 2) {
      return Center(
        child: Text(
          _chartError ?? 'لا توجد بيانات كافية للرسم',
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
      );
    }

    final minX = _spots.first.x;
    final maxX = _spots.last.x;

    final minY = _spots.map((e) => e.y).reduce(min);
    final maxY = _spots.map((e) => e.y).reduce(max);
    final paddingY = max(0.01, (maxY - minY) * 0.06);

    final intervalY = _leftInterval(minY, maxY);

    return LineChart(
      LineChartData(
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: intervalY,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.black.withOpacity(0.06),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: intervalY,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(
                    value.toStringAsFixed(2),
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (value, meta) {
                final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                if (!_shouldShowBottomTitle(dt, _selectedPeriod)) {
                  return const SizedBox.shrink();
                }

                final label = (_selectedPeriod == ChartPeriod.sixMonths ||
                        _selectedPeriod == ChartPeriod.year)
                    ? _bottomMonthYearFmt.format(dt)
                    : _bottomDayMonthFmt.format(dt);

                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 10,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 9.6,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textSecondary,
                      height: 1.05,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: minX,
        maxX: maxX,
        minY: minY - paddingY,
        maxY: maxY + paddingY,
        lineBarsData: [
          LineChartBarData(
            spots: _spots,
            isCurved: true,
            curveSmoothness: 0.22,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [color.withOpacity(0.16), color.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchSpotThreshold: 40,
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((i) {
              return TouchedSpotIndicatorData(
                FlLine(color: Colors.black.withOpacity(0.16), strokeWidth: 1),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                    radius: 4.8,
                    color: color,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
              );
            }).toList();
          },
          touchCallback: (event, resp) {
            if (!mounted) return;

            if (resp == null ||
                resp.lineBarSpots == null ||
                resp.lineBarSpots!.isEmpty) {
              setState(() => _touchedIndex = null);
              return;
            }

            final idx = resp.lineBarSpots!.first.spotIndex;
            if (idx < 0 || idx >= _visibleCandles.length) {
              setState(() => _touchedIndex = null);
              return;
            }

            setState(() => _touchedIndex = idx);
          },
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 12,
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            tooltipMargin: 10,
            getTooltipColor: (touchedSpot) => Colors.black.withOpacity(0.86),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((s) {
                final dt = DateTime.fromMillisecondsSinceEpoch(s.x.toInt());
                final priceLine = '${s.y.toStringAsFixed(2)} ريال';
                final dateLine = _tooltipFmt.format(dt);
                return LineTooltipItem(
                  '$priceLine\n$dateLine',
                  const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    height: 1.25,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  bool _shouldShowBottomTitle(DateTime dt, ChartPeriod p) {
    if (_visibleCandles.isEmpty) return false;
    final start = _visibleCandles.first.time;
    final days = dt.difference(start).inDays;

    switch (p) {
      case ChartPeriod.week:
        return days % 2 == 0;
      case ChartPeriod.month:
        return days % 7 == 0;
      case ChartPeriod.threeMonths:
        return days % 14 == 0;
      case ChartPeriod.sixMonths:
        return dt.day == 1;
      case ChartPeriod.year:
        return dt.day == 1 && dt.month % 2 == 1;
    }
  }

  double _leftInterval(double minY, double maxY) {
    final range = (maxY - minY).abs();
    if (range <= 0.5) return 0.1;
    if (range <= 2) return 0.5;
    if (range <= 10) return 1;
    if (range <= 30) return 2.5;
    return 5;
  }

  Widget _buildStockInfoGrid() {
    final stock = _safeStock;

    final open = _lastCandle?.open;
    final high = _lastCandle?.high;
    final low = _lastCandle?.low;
    final prev = _prevCandle?.close;
    final vol = _lastCandle?.volume;

    final p = stock.price > 0 ? stock.price : 1.0;

    final items = [
      {
        'label': 'الافتتاح',
        'value': open != null
            ? Formatters.formatPrice(open)
            : Formatters.formatPrice(p * 0.99),
        'icon': Icons.lock_open_rounded,
      },
      {
        'label': 'السابق',
        'value': prev != null
            ? Formatters.formatPrice(prev)
            : Formatters.formatPrice(p),
        'icon': Icons.history_rounded,
      },
      {
        'label': 'الأعلى',
        'value': high != null
            ? Formatters.formatPrice(high)
            : Formatters.formatPrice(p * 1.02),
        'icon': Icons.arrow_upward_rounded,
        'color': AppColors.gain,
      },
      {
        'label': 'الأدنى',
        'value': low != null
            ? Formatters.formatPrice(low)
            : Formatters.formatPrice(p * 0.98),
        'icon': Icons.arrow_downward_rounded,
        'color': AppColors.loss,
      },
      {
        'label': 'الحجم',
        'value': vol != null && vol > 0 ? vol.toStringAsFixed(0) : '—',
        'icon': Icons.bar_chart_rounded,
      },
      {'label': 'الصفقات', 'value': '—', 'icon': Icons.handshake_rounded},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((item) {
        final width = (MediaQuery.of(context).size.width - 52) / 2;
        return Container(
          width: width,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      size: 14,
                      color: (item['color'] as Color?) ?? AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item['label'] as String,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item['value'] as String,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  color: (item['color'] as Color?) ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIndicatorsSection() {
    if (_loadingIndicators) {
      return _buildIndicatorsLoadingCard();
    }

    if (!_hasIndicators) {
      return const SizedBox.shrink();
    }

    if (_useDedicatedIndicatorsPage) {
      return FadeAnimation(child: _buildDedicatedIndicatorsCard());
    }

    return FadeAnimation(
      child: TechnicalIndicatorsWidget(indicators: _indicators!),
    );
  }

  Widget _buildIndicatorsLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: AppColors.primaryBlue,
              strokeWidth: 2.5,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'جارِ تحميل المؤشرات الفنية...',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDedicatedIndicatorsCard() {
    final indicators = _indicators!;
    final summaryColor = _indicatorSummaryColor(indicators.overallSummary);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUnifiedTitle(title: 'المؤشرات الفنية'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: summaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.analytics_rounded,
                    color: summaryColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${indicators.indicators.length} مؤشر متاح لهذا السهم',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'تم فصل المؤشرات في صفحة مستقلة لعرض أوضح وأسرع.',
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
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildIndicatorStatChip(
                label: 'الملخص',
                value: _indicatorSummaryLabel(indicators.overallSummary),
                color: summaryColor,
              ),
              _buildIndicatorStatChip(
                label: 'شراء',
                value: indicators.totalBuy.toString(),
                color: AppColors.gain,
              ),
              _buildIndicatorStatChip(
                label: 'بيع',
                value: indicators.totalSell.toString(),
                color: AppColors.loss,
              ),
              _buildIndicatorStatChip(
                label: 'محايد',
                value: indicators.totalNeutral.toString(),
                color: Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openIndicatorsScreen,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('فتح صفحة المؤشرات الفنية'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorStatChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  String _indicatorSummaryLabel(String summary) {
    final s = summary.toLowerCase().trim();
    if (s.contains('strong buy')) return 'شراء قوي';
    if (s == 'buy') return 'شراء';
    if (s.contains('strong sell')) return 'بيع قوي';
    if (s == 'sell') return 'بيع';
    return 'محايد';
  }

  Color _indicatorSummaryColor(String summary) {
    final s = summary.toLowerCase().trim();
    if (s.contains('buy')) return AppColors.gain;
    if (s.contains('sell')) return AppColors.loss;
    return Colors.grey;
  }

  void _openIndicatorsScreen() {
    if (!_hasIndicators) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StockIndicatorsScreen(
          stock: _safeStock,
          initialIndicators: _indicators!,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _setLockParentGestures(false);
    _tabController.dispose();
    super.dispose();
  }
}

/// ✅ Tab label responsive: prevents clipping on small widths / large font scale
class _TabLabel extends StatelessWidget {
  final String text;
  const _TabLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
      ),
    );
  }
}
