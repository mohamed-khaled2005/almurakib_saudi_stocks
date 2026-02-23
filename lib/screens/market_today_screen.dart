import 'package:flutter/material.dart';
import '../core/models/stock_model.dart';
import '../core/services/stock_service.dart';
import '../core/services/favorites_service.dart';
import '../core/utils/constants.dart';
import '../core/utils/server_time_utils.dart';
import '../widgets/stock_list_item.dart';
import '../widgets/tab_page_header.dart';
import '../widgets/last_update_banner.dart';
import 'stock_detail_screen.dart';

class MarketTodayScreen extends StatefulWidget {
  const MarketTodayScreen({super.key});

  @override
  State<MarketTodayScreen> createState() => _MarketTodayScreenState();
}

class _MarketTodayScreenState extends State<MarketTodayScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<StockModel> _gainers = [];
  List<StockModel> _losers = [];
  Set<String> _favoriteSymbols = {};
  DateTime? _lastUpdateUtc;
  DateTime? _lastFetchUtc;

  bool _loading = true;
  String? _error;

  // ✅ مهم: السعودية حوالي 371 شركة
  static const int _perPage = 500;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // ✅ بدل ما نجيب Gainers/Losers من endpoint منفصل (ممكن يلخبط بسبب sort/sub_type)
      // هنجيب كل الأسهم مرة واحدة من الـ API الجديد ونرتب محليًا
      final results = await Future.wait([
        StockService.getStocksList(perPage: _perPage, page: 1),
        FavoritesService.getFavorites(),
      ]);

      if (!mounted) return;

      final allStocks = results[0] as List<StockModel>;
      final favs = (results[1] as List<String>).toSet();

      // ✅ فلترة وترتيب محلي مضمون
      final gainers = allStocks.where((s) => s.changePercent > 0).toList()
        ..sort((a, b) => b.changePercent.compareTo(a.changePercent));

      final losers = allStocks.where((s) => s.changePercent < 0).toList()
        ..sort((a, b) => a.changePercent.compareTo(b.changePercent));

      setState(() {
        _gainers = gainers.take(_limit).toList();
        _losers = losers.take(_limit).toList();
        _favoriteSymbols = favs;
        _lastUpdateUtc =
            ServerTimeUtils.pickLatest(allStocks.map((s) => s.lastUpdateUtc));
        _lastFetchUtc = DateTime.now().toUtc();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'فشل تحميل بيانات السوق';
        _lastUpdateUtc = null;
        _loading = false;
      });
    }
  }

  Future<void> _toggleFavorite(StockModel stock) async {
    await FavoritesService.toggleFavorite(stock.symbol);
    final favs = await FavoritesService.getFavorites();
    if (!mounted) return;
    setState(() {
      _favoriteSymbols = favs.toSet();
    });
  }

  void _onTabTap(int index) {
    if (_tabController.index == index) return;
    _tabController.animateTo(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildUnifiedHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: LastUpdateBanner(
                title: 'آخر تحديث السوق:',
                updateUtc: _lastUpdateUtc ?? _lastFetchUtc,
                loading: _loading,
              ),
            ),
            _buildSegmentedSwitch(),
            Expanded(
              child: _loading
                  ? _buildLoadingState()
                  : _error != null
                      ? _buildErrorState()
                      : TabBarView(
                          controller: _tabController,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _StockListTab(
                              stocks: _gainers,
                              isGainers: true,
                              favoriteSymbols: _favoriteSymbols,
                              onRefresh: _loadData,
                              onToggleFavorite: _toggleFavorite,
                              onTapStock: _openStockDetail,
                            ),
                            _StockListTab(
                              stocks: _losers,
                              isGainers: false,
                              favoriteSymbols: _favoriteSymbols,
                              onRefresh: _loadData,
                              onToggleFavorite: _toggleFavorite,
                              onTapStock: _openStockDetail,
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnifiedHeader() {
    return const TabPageHeaderBlock(
      title: 'تحركات السوق',
      subtitle: 'تابع الأسهم الأكثر ارتفاعاً وانخفاضاً اليوم',
    );
  }

  Widget _buildSegmentedSwitch() {
    const double height = 52;
    final borderRadius = BorderRadius.circular(16);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: AnimatedBuilder(
            animation: _tabController.animation!,
            builder: (context, _) {
              final t = _tabController.animation!.value.clamp(0.0, 1.0);
              final alignment = Alignment.lerp(
                  Alignment.centerRight, Alignment.centerLeft, t)!;

              // ✅ بدل round اللي ممكن يلمع أثناء السحب
              final currentIndex = (t < 0.5) ? 0 : 1;

              return Stack(
                children: [
                  Align(
                    alignment: alignment,
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      heightFactor: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _SegmentButton(
                          title: 'الأكثر ارتفاعاً',
                          isSelected: currentIndex == 0,
                          onTap: () => _onTabTap(0),
                        ),
                      ),
                      Expanded(
                        child: _SegmentButton(
                          title: 'الأكثر انخفاضاً',
                          isSelected: currentIndex == 1,
                          onTap: () => _onTabTap(1),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primaryBlue,
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text('عذراً، حدث خطأ', style: AppTextStyles.headingSmall),
            const SizedBox(height: 8),
            Text(
              _error ?? 'لا يمكن الوصول للبيانات حالياً',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openStockDetail(StockModel stock) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StockDetailScreen(stock: stock)),
    ).then((_) async {
      final favs = await FavoritesService.getFavorites();
      if (!mounted) return;
      setState(() {
        _favoriteSymbols = favs.toSet();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _StockListTab extends StatefulWidget {
  final List<StockModel> stocks;
  final bool isGainers;
  final Set<String> favoriteSymbols;
  final Future<void> Function() onRefresh;
  final Function(StockModel) onToggleFavorite;
  final Function(StockModel) onTapStock;

  const _StockListTab({
    required this.stocks,
    required this.isGainers,
    required this.favoriteSymbols,
    required this.onRefresh,
    required this.onToggleFavorite,
    required this.onTapStock,
  });

  @override
  State<_StockListTab> createState() => _StockListTabState();
}

class _StockListTabState extends State<_StockListTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.stocks.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppColors.primaryBlue,
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        itemCount: widget.stocks.length,
        itemBuilder: (context, index) {
          final stock = widget.stocks[index];
          final isFav = widget.favoriteSymbols.contains(stock.symbol);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: StockListItem(
              stock: stock,
              showFavoriteButton: true,
              isFavorite: isFav,
              onFavoriteTap: () => widget.onToggleFavorite(stock),
              onTap: () => widget.onTapStock(stock),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.isGainers
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            size: 80,
            color: AppColors.border,
          ),
          const SizedBox(height: 16),
          Text(
            widget.isGainers
                ? 'لا توجد ارتفاعات مسجلة'
                : 'لا توجد انخفاضات مسجلة',
            style: AppTextStyles.headingSmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'قد يكون السوق مغلقاً أو لم تتغير الأسعار بعد',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
