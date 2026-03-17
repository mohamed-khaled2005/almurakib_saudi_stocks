import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/models/stock_model.dart';
import '../core/services/favorites_service.dart';
import '../core/services/stock_service.dart';
import '../core/services/translation_service.dart';
import '../core/utils/app_lifecycle_refresh.dart';
import '../core/utils/constants.dart';
import '../core/utils/first_time_hint.dart';
import '../core/utils/server_time_utils.dart';
import '../models/manual_ad_model.dart';
import '../providers/app_manager_provider.dart';
import '../widgets/last_update_banner.dart';
import '../widgets/manual_ad_banner.dart';
import 'about_screen.dart';
import 'account_screen.dart';
import 'all_stocks_screen.dart';
import 'contact_screen.dart';
import 'educational_content_screen.dart';
import 'home_screen.dart';
import 'market_today_screen.dart';
import 'our_apps_screen.dart';
import 'stock_detail_screen.dart';

const Color _headerSurfaceTop = Color(0xFFF9FFF8);
const Color _headerSurfaceBottom = Color(0xFFE8F6E8);
const Color _headerCard = Color(0xFFFFFFFF);

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  static const String _almurakibWebsiteUrl = 'https://almurakib.com/';
  static const int _homeTabIndex = 0;
  static const int _marketTodayTabIndex = 1;
  static const int _allStocksTabIndex = 2;
  static const int _educationTabIndex = 3;

  int _index = _homeTabIndex;
  bool _refreshing = false;
  late final List<Widget> _pages;
  List<StockModel>? _quickSearchStocksCache;
  bool get _showOurAppsTab => defaultTargetPlatform != TargetPlatform.iOS;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final GlobalKey _refreshHintKey = GlobalKey();
  VoidCallback? _resumeListener;
  bool _hintRequested = false;

  @override
  void initState() {
    super.initState();

    AppLifecycleSignals.ensureInitialized();

    _pages = <Widget>[
      HomeScreen(onNavigateToTab: (index) => _setIndex(index)),
      const MarketTodayScreen(),
      const AllStocksScreen(),
      const EducationalContentScreen(),
      if (_showOurAppsTab) const OurAppsScreen(),
      const AboutScreen(),
      const ContactScreen(),
    ];

    FavoritesService.init();
    TranslationService.getTranslations(forceRefresh: true);
    _warmQuickSearchCache();

    _resumeListener = _refreshOnResumeSilent;
    AppLifecycleSignals.resumeTick.addListener(_resumeListener!);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final manager = context.read<AppManagerProvider>();
      manager.refreshAd();
      manager.refreshEducationalContent();
      _showRefreshHintOnce();
      if (!mounted) return;
      manager.trackPageView(_pageTrackingName(_index));
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
      prefsKey: 'hint_stocks_refresh_button_v2',
      message: 'اضغط هنا لتحديث بيانات السوق',
      autoDismiss: const Duration(seconds: 10),
    );
  }

  Future<void> _refreshOnResumeSilent() async {
    if (!mounted || _refreshing) return;
    setState(() => _refreshing = true);

    try {
      await TranslationService.getTranslations(forceRefresh: true);
      await _loadQuickSearchUniverse(forceRefresh: true);
    } catch (_) {
      // Ignore silent refresh failures.
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  Future<void> _onRefresh() async {
    if (_refreshing) return;

    setState(() => _refreshing = true);
    try {
      await TranslationService.getTranslations(forceRefresh: true);
      await _loadQuickSearchUniverse(forceRefresh: true);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'تم تحديث البيانات بنجاح',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: const Color(0xFF2E7D32),
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
            'تعذر تحديث البيانات حاليا',
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
      if (mounted) {
        setState(() => _refreshing = false);
      }
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

  Future<void> _warmQuickSearchCache() async {
    try {
      await _loadQuickSearchUniverse();
      if (mounted) {
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _onQuickSearch() async {
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

  Future<void> _openAccount() async {
    if (!mounted) return;
    await context.read<AppManagerProvider>().trackPageView('account_entry');
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AccountScreen()),
    );
  }

  Future<void> _onLogoTap() async {
    final shouldOpen = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text(
                'فتح موقع المراقب',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: const Text(
                'هل تريد زيارة موقع المراقب الآن؟',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
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
        ) ??
        false;

    if (!shouldOpen || !mounted) return;

    final ok = await launchUrl(
      Uri.parse(_almurakibWebsiteUrl),
      mode: LaunchMode.externalApplication,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الموقع حاليا')),
      );
    }
  }

  void _setIndex(int i) {
    if (_index == i) return;
    setState(() => _index = i);
    context.read<AppManagerProvider>().trackPageView(_pageTrackingName(i));
  }

  String _pageTrackingName(int index) {
    if (_showOurAppsTab) {
      switch (index) {
        case _homeTabIndex:
          return 'home';
        case _marketTodayTabIndex:
          return 'market_today';
        case _allStocksTabIndex:
          return 'all_stocks';
        case _educationTabIndex:
          return 'education_content';
        case 4:
          return 'our_apps';
        case 5:
          return 'about';
        case 6:
          return 'contact';
        default:
          return 'unknown';
      }
    }

    switch (index) {
      case _homeTabIndex:
        return 'home';
      case _marketTodayTabIndex:
        return 'market_today';
      case _allStocksTabIndex:
        return 'all_stocks';
      case _educationTabIndex:
        return 'education_content';
      case 4:
        return 'about';
      case 5:
        return 'contact';
      default:
        return 'unknown';
    }
  }

  DateTime? _headerLastUpdateUtc() {
    final stocks = _quickSearchStocksCache;
    if (stocks == null || stocks.isEmpty) return null;
    return ServerTimeUtils.pickLatest(stocks.map((stock) => stock.lastUpdateUtc));
  }

  bool _showTopUtilityBar() => _index <= _allStocksTabIndex;

  void _openRightMenu() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Drawer _buildSideDrawer(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth > 380 ? 320.0 : screenWidth * 0.86;

    return Drawer(
      width: drawerWidth,
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildSideNavigationPanel(closeOnSelect: true),
    );
  }

  Widget _buildSideNavigationPanel({required bool closeOnSelect}) {
    final items = _navigationItems();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF8FCF8),
            Color(0xFFEEF8EE),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 22,
            spreadRadius: 1.2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(10, 16, 10, 18),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            final isSelected = _index == item.index;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  duration: AppAnimations.buttonAnimation,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              AppColors.primaryGold.withValues(alpha: 0.16),
                              AppColors.primaryGold.withValues(alpha: 0.06),
                            ],
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                          )
                        : null,
                    color: isSelected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryGold.withValues(alpha: 0.34)
                          : AppColors.border,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _navigateToMenuItem(
                        item.index,
                        closeDrawer: closeOnSelect,
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsetsDirectional.fromSTEB(12, 6, 10, 6),
                        leading: Icon(
                          item.icon,
                          size: 22,
                          color: isSelected
                              ? AppColors.primaryGold
                              : AppColors.textSecondary,
                        ),
                        title: Text(
                          item.title,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            );
          },
        ),
      ),
    );
  }

  List<_SideNavItem> _navigationItems() {
    return <_SideNavItem>[
      const _SideNavItem(
        index: _homeTabIndex,
        title: 'الصفحة الرئيسية',
        icon: Icons.home_outlined,
      ),
      const _SideNavItem(
        index: _marketTodayTabIndex,
        title: 'السوق اليوم',
        icon: Icons.trending_up_outlined,
      ),
      const _SideNavItem(
        index: _allStocksTabIndex,
        title: 'جميع الأسهم',
        icon: Icons.list_alt_outlined,
      ),
      const _SideNavItem(
        index: _educationTabIndex,
        title: 'المحتوى التعليمي',
        icon: Icons.menu_book_outlined,
      ),
      if (_showOurAppsTab)
        const _SideNavItem(
          index: 4,
          title: 'تطبيقاتنا',
          icon: Icons.apps_outlined,
        ),
      _SideNavItem(
        index: _showOurAppsTab ? 5 : 4,
        title: 'عن التطبيق',
        icon: Icons.info_outline_rounded,
      ),
      _SideNavItem(
        index: _showOurAppsTab ? 6 : 5,
        title: 'الاتصال بنا',
        icon: Icons.contact_page_outlined,
      ),
    ];
  }

  void _navigateToMenuItem(int index, {required bool closeDrawer}) {
    if (closeDrawer && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    _setIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.select<AppManagerProvider, bool>(
      (manager) => manager.isAuthenticated,
    );
    final activeAd = context.select<AppManagerProvider, ManualAdModel?>(
      (manager) => manager.activeAd,
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF6F8F7),
      drawer: _buildSideDrawer(context),
      drawerEnableOpenDragGesture: false,
      appBar: _buildHeader(isAuthenticated: isAuthenticated),
      body: Column(
        children: [
          if (_showTopUtilityBar()) _buildTopUtilityBar(),
          Expanded(
            child: SafeArea(
              top: false,
              child: IndexedStack(
                index: _index,
                children: _pages,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ManualAdBanner(
        stickyBottom: true,
        ad: activeAd,
      ),
    );
  }

  PreferredSizeWidget _buildHeader({required bool isAuthenticated}) {
    const showMenuButton = true;

    return AppBar(
      leading: const SizedBox.shrink(),
      leadingWidth: 0,
      backgroundColor: _headerCard,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      toolbarHeight: 72,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_headerSurfaceTop, _headerSurfaceBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border(
            bottom: BorderSide(
              color: AppColors.border,
            ),
          ),
        ),
      ),
      titleSpacing: 12,
      title: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              GestureDetector(
                onTap: _onLogoTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 236),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const Spacer(),
              _HeaderIconButton(
                tooltip: 'الرئيسية',
                onTap: () => _setIndex(0),
                icon: _index == 0 ? Icons.home_rounded : Icons.home_outlined,
              ),
              const SizedBox(width: 10),
              _HeaderIconButton(
                tooltip: isAuthenticated ? 'حسابي' : 'تسجيل الدخول',
                onTap: _openAccount,
                icon: isAuthenticated
                    ? Icons.person_outline_rounded
                    : Icons.account_circle_outlined,
              ),
              if (showMenuButton) ...[
                const SizedBox(width: 10),
                _HeaderIconButton(
                  tooltip: 'القائمة',
                  onTap: _openRightMenu,
                  icon: Icons.menu_rounded,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: const [],
    );
  }

  Widget _buildTopUtilityBar() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_headerSurfaceBottom, _headerSurfaceTop],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: LastUpdateBanner(
                updateUtc: _headerLastUpdateUtc(),
                loading: _refreshing || _quickSearchStocksCache == null,
              ),
            ),
            const SizedBox(width: 8),
            _UtilityButton(
              onTap: _onQuickSearch,
              icon: Icons.search_rounded,
            ),
            const SizedBox(width: 8),
            KeyedSubtree(
              key: _refreshHintKey,
              child: _UtilityButton(
                onTap: _refreshing ? null : _onRefresh,
                child: _refreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryGold,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: AppColors.primaryGold,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.onTap,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: _headerCard,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryGold,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _UtilityButton extends StatelessWidget {
  const _UtilityButton({
    this.onTap,
    this.icon,
    this.child,
  }) : assert(icon != null || child != null);

  final Future<void> Function()? onTap;
  final IconData? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _headerCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Center(
            child: child ??
                Icon(
                  icon,
                  color: AppColors.primaryGold,
                  size: 20,
                ),
          ),
        ),
      ),
    );
  }
}

class _QuickSearchBottomSheet extends StatefulWidget {
  const _QuickSearchBottomSheet({
    required this.loadStocks,
  });

  final Future<List<StockModel>> Function({bool forceRefresh}) loadStocks;

  @override
  State<_QuickSearchBottomSheet> createState() =>
      _QuickSearchBottomSheetState();
}

class _QuickSearchBottomSheetState extends State<_QuickSearchBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Map<String, String> _searchIndexCache = <String, String>{};

  List<StockModel> _stocks = const <StockModel>[];
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

  void _dismissKeyboardIfTappedOutside(PointerDownEvent event) {
    if (!_focusNode.hasFocus) return;

    final ctx = _focusNode.context;
    if (ctx != null) {
      final render = ctx.findRenderObject();
      if (render is RenderBox && render.hasSize) {
        final local = render.globalToLocal(event.position);
        if (render.size.contains(local)) return;
      }
    }

    _focusNode.unfocus();
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
        _error = 'تعذر تحميل الأسهم حاليا';
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

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _dismissKeyboardIfTappedOutside,
      child: AnimatedPadding(
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
                      border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.search,
                      onTapOutside: (_) => _focusNode.unfocus(),
                      onSubmitted: (_) => _focusNode.unfocus(),
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: 'ابحث بالاسم أو الرمز أو الرقم...',
                        hintStyle: TextStyle(
                          fontFamily: 'Tajawal',
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
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
      ),
    );
  }
}

class _QuickSearchResults extends StatelessWidget {
  const _QuickSearchResults({
    required this.stocks,
    required this.onSelect,
  });

  final List<StockModel> stocks;
  final ValueChanged<StockModel> onSelect;

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
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
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

class _SideNavItem {
  const _SideNavItem({
    required this.index,
    required this.title,
    required this.icon,
  });

  final int index;
  final String title;
  final IconData icon;
}
