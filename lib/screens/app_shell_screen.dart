import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/stock_model.dart';
import '../core/utils/constants.dart';
import '../core/services/stock_service.dart';
import '../core/services/translation_service.dart';
import '../core/services/favorites_service.dart';

import '../core/utils/app_lifecycle_refresh.dart'; // ✅ ADD
import '../core/utils/first_time_hint.dart'; // ✅ ADD

import 'home_screen.dart';
import 'market_today_screen.dart';
import 'all_stocks_screen.dart';
import 'our_apps_screen.dart';
import 'about_screen.dart';
import 'contact_screen.dart';
import 'stock_detail_screen.dart';

Color _o(Color c, double opacity) =>
    c.withAlpha((opacity.clamp(0.0, 1.0) * 255).round());

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  static const String _almurakibWebsiteUrl = 'https://almurakib.com/';

  int _index = 0;
  bool _refreshing = false;
  late final List<Widget> _pages;
  List<StockModel>? _quickSearchStocksCache;

  // ✅ Key لزر الريفريش عشان الـ Spotlight
  final GlobalKey _refreshHintKey = GlobalKey();

  // ✅ Listener للـ resume
  VoidCallback? _resumeListener;

  // ✅ منع تكرار hint في نفس الجلسة
  bool _hintRequested = false;

  @override
  void initState() {
    super.initState();

    // ✅ تأكيد تفعيل مراقبة دورة حياة التطبيق (حتى لو اتنسى في main)
    AppLifecycleSignals.ensureInitialized();

    _pages = <Widget>[
      HomeScreen(onNavigateToTab: (index) => setState(() => _index = index)),
      const MarketTodayScreen(),
      const AllStocksScreen(),
      const OurAppsScreen(),
      const AboutScreen(),
      const ContactScreen(),
    ];

    // ✅ تحميل favorites مرة واحدة (عشان notifier يبقى جاهز لكل tabs)
    FavoritesService.init();

    // ✅ تحميل الترجمات عند فتح التطبيق
    TranslationService.getTranslations(forceRefresh: true);
    _warmQuickSearchCache();

    // ✅ Refresh تلقائي عند رجوع التطبيق foreground/resume
    _resumeListener = () {
      _refreshOnResumeSilent();
    };
    AppLifecycleSignals.resumeTick.addListener(_resumeListener!);

    // ✅ Hint مرة واحدة فقط على زر التحديث
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showRefreshHintOnce();
    });
  }

  @override
  void dispose() {
    if (_resumeListener != null) {
      AppLifecycleSignals.resumeTick.removeListener(_resumeListener!);
    }
    super.dispose();
  }

  Future<void> _showRefreshHintOnce() async {
    if (_hintRequested) return;
    _hintRequested = true;
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    if (!onboardingCompleted || !mounted) return;

    FirstTimeHint.showRefreshHint(
      context: context,
      targetKey: _refreshHintKey,
      prefsKey: 'hint_stocks_refresh_button_v1',
      message: 'اضغط هنا لتحديث البيانات (سيظهر هذا التنبيه مرة واحدة فقط)',
      autoDismiss: const Duration(seconds: 10),
    );
  }

  Future<void> _refreshOnResumeSilent() async {
    if (!mounted) return;
    if (_refreshing) return;

    setState(() => _refreshing = true);

    try {
      // ✅ تحديث صامت بدون SnackBar
      await TranslationService.getTranslations(forceRefresh: true);
    } catch (_) {
      // تجاهل الأخطاء في التحديث الصامت
    } finally {
      if (!mounted) return;
      setState(() => _refreshing = false);
    }
  }

  Future<void> _onRefresh() async {
    if (_refreshing) return;

    setState(() => _refreshing = true);

    try {
      await TranslationService.getTranslations(forceRefresh: true);
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'تم تحديث البيانات بنجاح',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: const Color(0xFF388E3C),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'تعذر تحديث البيانات حالياً',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => _refreshing = false);
    }
  }

  Future<List<StockModel>> _loadQuickSearchUniverse({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _quickSearchStocksCache != null) {
      return _quickSearchStocksCache!;
    }

    final stocks = await StockService.getStocksList(perPage: 500, page: 1);
    _quickSearchStocksCache = stocks;
    return stocks;
  }

  void _warmQuickSearchCache() async {
    try {
      await _loadQuickSearchUniverse();
    } catch (_) {}
  }

  void _onQuickSearch() async {
    final selectedStock = await showModalBottomSheet<StockModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickSearchBottomSheet(
        loadStocks: _loadQuickSearchUniverse,
      ),
    );

    if (!mounted || selectedStock == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StockDetailScreen(stock: selectedStock),
      ),
    );
  }

  Future<void> _onLogoTap() async {
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text(
            'فتح موقع المراقب',
            style:
                TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'هل تريد زيارة موقع المراقب الآن؟',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child:
                  const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'زيارة الموقع',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
          ],
        );
      },
    );

    if (shouldOpen != true || !mounted) return;

    final ok = await launchUrl(
      Uri.parse(_almurakibWebsiteUrl),
      mode: LaunchMode.externalApplication,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الموقع حالياً')),
      );
    }
  }

  void _setIndex(int i) {
    if (_index == i) return;
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: _buildHeader(),
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: _index,
          children: _pages,
        ),
      ),
      bottomNavigationBar: _BottomNav(
        index: _index,
        onTap: _setIndex,
      ),
    );
  }

  PreferredSizeWidget _buildHeader() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: _o(Colors.black, 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: _HeaderContent(
            refreshing: _refreshing,
            onRefresh: _onRefresh,
            onQuickSearch: _onQuickSearch,
            onLogoTap: _onLogoTap,
            refreshHintKey: _refreshHintKey, // ✅ ADD
          ),
        ),
      ),
    );
  }
}

class _HeaderContent extends StatelessWidget {
  final bool refreshing;
  final Future<void> Function() onRefresh;
  final VoidCallback onQuickSearch;
  final Future<void> Function() onLogoTap;

  // ✅ ADD
  final GlobalKey refreshHintKey;

  const _HeaderContent({
    required this.refreshing,
    required this.onRefresh,
    required this.onQuickSearch,
    required this.onLogoTap,
    required this.refreshHintKey,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final logoMaxW = math.min(220.0, math.max(120.0, c.maxWidth * 0.56));

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            textDirection: TextDirection.ltr,
            children: [
              // ✅ Wrap button with KeyedSubtree for spotlight
              KeyedSubtree(
                key: refreshHintKey,
                child: _HeaderRefreshButton(
                  loading: refreshing,
                  onTap: refreshing ? null : () async => onRefresh(),
                ),
              ),
              const SizedBox(width: 8),
              _HeaderSearchButton(onTap: onQuickSearch),
              const Spacer(),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: logoMaxW),
                child: SizedBox(
                  height: 48,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onLogoTap(),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          alignment: Alignment.centerRight,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.assessment_rounded,
                                  color: AppColors.primaryBlue,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'مراقب الأسهم',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderSearchButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _HeaderSearchButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _o(AppColors.primaryBlue, 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _o(AppColors.primaryBlue, 0.20)),
          ),
          child: const Center(
            child: Icon(
              Icons.search_rounded,
              size: 22,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickSearchBottomSheet extends StatefulWidget {
  final Future<List<StockModel>> Function({bool forceRefresh}) loadStocks;

  const _QuickSearchBottomSheet({
    required this.loadStocks,
  });

  @override
  State<_QuickSearchBottomSheet> createState() =>
      _QuickSearchBottomSheetState();
}

class _QuickSearchBottomSheetState extends State<_QuickSearchBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Map<String, String> _searchIndexCache = {};

  List<StockModel> _stocks = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStocks();
    _controller.addListener(_onQueryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadStocks({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final stocks = await widget.loadStocks(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _stocks = stocks;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذر تحميل الأسهم حالياً';
        _loading = false;
      });
    }
  }

  String _normalize(String input) {
    var s = input.toLowerCase();

    s = s.replaceAll(
      RegExp(r'[\u200E\u200F\u202A-\u202E\u2066-\u2069]'),
      '',
    );

    s = s.replaceAll(
      RegExp(r'[^a-z0-9\u0621-\u064A\u0660-\u0669\u06F0-\u06F9]+'),
      ' ',
    );

    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _searchIndexFor(StockModel stock) {
    final key = stock.symbol.isNotEmpty ? stock.symbol : stock.id;
    return _searchIndexCache.putIfAbsent(key, () {
      final raw =
          '${stock.displayName} ${stock.name} ${stock.symbol} ${stock.id}';
      return _normalize(raw);
    });
  }

  bool _matches(StockModel stock, String normalizedQuery) {
    if (normalizedQuery.isEmpty) return true;

    final idx = _searchIndexFor(stock);
    if (idx.contains(normalizedQuery)) return true;

    final compactIdx = idx.replaceAll(' ', '');
    final compactQ = normalizedQuery.replaceAll(' ', '');
    if (compactQ.isNotEmpty && compactIdx.contains(compactQ)) return true;

    final tokens = normalizedQuery.split(' ').where((t) => t.isNotEmpty);
    return tokens.every((t) => idx.contains(t));
  }

  List<StockModel> _results() {
    final normalizedQuery = _normalize(_controller.text.trim());

    if (normalizedQuery.isEmpty) {
      return _stocks.take(40).toList();
    }

    return _stocks.where((s) => _matches(s, normalizedQuery)).take(60).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasText = _controller.text.trim().isNotEmpty;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'بحث سريع عن سهم',
                        style: AppTextStyles.headingSmall.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      splashRadius: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _o(Colors.black, 0.06)),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: 'ابحث بالاسم أو الرمز أو الرقم...',
                      hintStyle: TextStyle(
                        fontFamily: 'Tajawal',
                        color: AppColors.textSecondary.withOpacity(0.7),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: hasText
                          ? IconButton(
                              onPressed: _controller.clear,
                              icon: const Icon(Icons.clear_rounded, size: 18),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_loading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  )
                else if (_error != null)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            size: 34,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => _loadStocks(forceRefresh: true),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  _QuickSearchResults(
                    stocks: _results(),
                    onSelect: (stock) => Navigator.pop(context, stock),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickSearchResults extends StatelessWidget {
  final List<StockModel> stocks;
  final ValueChanged<StockModel> onSelect;

  const _QuickSearchResults({
    required this.stocks,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (stocks.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'لا توجد نتائج مطابقة',
            style: TextStyle(
              fontFamily: 'Tajawal',
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.separated(
        itemCount: stocks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final stock = stocks[i];
          final isGain = stock.changePercent >= 0;
          final sign = isGain ? '+' : '';
          final color = isGain ? AppColors.gain : AppColors.loss;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelect(stock),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _o(Colors.black, 0.05)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stock.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${stock.symbol} • ${stock.id}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          stock.price.toStringAsFixed(2),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$sign${stock.changePercent.toStringAsFixed(2)}%',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeaderRefreshButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onTap;

  const _HeaderRefreshButton({
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _o(AppColors.primaryBlue, 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _o(AppColors.primaryBlue, 0.20)),
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryBlue,
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    size: 22,
                    color: AppColors.primaryBlue,
                  ),
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItemData(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
          label: 'الرئيسية'),
      _NavItemData(
          icon: Icons.trending_up_outlined,
          selectedIcon: Icons.trending_up_rounded,
          label: 'السوق'),
      _NavItemData(
          icon: Icons.list_alt_outlined,
          selectedIcon: Icons.list_alt_rounded,
          label: 'الأسهم'),
      _NavItemData(
          icon: Icons.apps_outlined,
          selectedIcon: Icons.apps_rounded,
          label: 'تطبيقاتنا'),
      _NavItemData(
          icon: Icons.info_outline_rounded,
          selectedIcon: Icons.info_rounded,
          label: 'عنا'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: _o(Colors.black, 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++)
                Expanded(
                  child: _BottomNavItem(
                    data: items[i],
                    selected: i == 4 ? (index == 4 || index == 5) : index == i,
                    onTap: () {
                      if (i == 4) {
                        _openAboutMenu(context);
                        return;
                      }
                      onTap(i);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAboutMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _o(Colors.black, 0.05)),
                boxShadow: [
                  BoxShadow(
                    color: _o(Colors.black, 0.22),
                    blurRadius: 18,
                    spreadRadius: 0.8,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 56,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.30),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _BottomNavMenuTile(
                    title: 'من نحن',
                    icon: Icons.info_outline_rounded,
                    onTap: () {
                      Navigator.pop(ctx);
                      onTap(4);
                    },
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.textSecondary.withOpacity(0.14),
                  ),
                  _BottomNavMenuTile(
                    title: 'الاتصال بنا',
                    icon: Icons.support_agent_rounded,
                    onTap: () {
                      Navigator.pop(ctx);
                      onTap(5);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItemData(
      {required this.icon, required this.selectedIcon, required this.label});
}

class _BottomNavItem extends StatelessWidget {
  final _NavItemData data;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = selected ? AppColors.primaryBlue : Colors.transparent;
    final contentColor = selected ? Colors.white : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? data.selectedIcon : data.icon,
              size: 22,
              color: contentColor,
            ),
            const SizedBox(height: 2),
            Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 9,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                color: contentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavMenuTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _BottomNavMenuTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.textSecondary.withOpacity(0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
