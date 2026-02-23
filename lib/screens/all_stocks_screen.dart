// lib/screens/all_stocks_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/models/stock_model.dart';
import '../core/services/stock_service.dart';
import '../core/services/favorites_service.dart';
import '../core/utils/constants.dart';
import '../core/utils/server_time_utils.dart';
import '../widgets/tab_page_header.dart';
import '../widgets/last_update_banner.dart';
import 'stock_detail_screen.dart';

// --- Enums ---
enum StockSortType {
  nameAsc,
  nameDesc,
  priceAsc,
  priceDesc,
  changeAsc,
  changeDesc,
}

enum StockFilterType {
  all,
  gainers,
  losers,
  favorites,
}

class AllStocksScreen extends StatefulWidget {
  const AllStocksScreen({super.key});

  @override
  State<AllStocksScreen> createState() => _AllStocksScreenState();
}

class _AllStocksScreenState extends State<AllStocksScreen> {
  // --- Data ---
  final List<StockModel> _allStocks = [];
  List<StockModel> _filteredStocks = [];
  Set<String> _favoriteSymbols = {};
  DateTime? _lastUpdateUtc;

  // --- UI / State ---
  bool _loading = true;
  String? _error;

  // Pagination
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;

  // Tunables
  static const int _perPage = 500;

  final TextEditingController _searchController = TextEditingController();
  StockSortType _sortType = StockSortType.nameAsc;
  StockFilterType _filterType = StockFilterType.all;

  // ✅ Cache للـ search index (يحسن الأداء أثناء الكتابة)
  final Map<String, String> _searchIndexCache = {};

  // --- Lifecycle ---
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // --- Pagination Logic ---
  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _loading) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
      _hasMore = true;
    });

    try {
      final results = await Future.wait([
        StockService.getStocksList(perPage: _perPage, page: 1),
        FavoritesService.getFavorites(),
      ]);

      if (!mounted) return;

      _allStocks
        ..clear()
        ..addAll(results[0] as List<StockModel>);

      _favoriteSymbols = (results[1] as List<String>).toSet();
      _lastUpdateUtc =
          ServerTimeUtils.pickLatest(_allStocks.map((s) => s.lastUpdateUtc));

      _hasMore = _allStocks.length >= _perPage;

      // ✅ clear cache لأن الداتا اتغيرت
      _searchIndexCache.clear();

      setState(() {
        _loading = false;
      });

      _applyFilters();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذر تحميل بيانات الأسهم';
        _lastUpdateUtc = null;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _page + 1;
      final more = await StockService.getStocksList(
        perPage: _perPage,
        page: nextPage,
      );

      if (!mounted) return;

      if (more.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
        return;
      }

      // منع التكرار (احتياط)
      final existingSymbols = _allStocks.map((e) => e.symbol).toSet();
      final deduped =
          more.where((s) => !existingSymbols.contains(s.symbol)).toList();

      _allStocks.addAll(deduped);
      _page = nextPage;
      _lastUpdateUtc =
          ServerTimeUtils.pickLatest(_allStocks.map((s) => s.lastUpdateUtc));

      if (more.length < _perPage) _hasMore = false;

      // ✅ clear cache لأن القائمة زادت
      _searchIndexCache.clear();

      setState(() => _isLoadingMore = false);
      _applyFilters();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  // --- Search / Filter / Sort ---
  void _onSearchChanged() => _applyFilters();

  void _updateFilter(StockFilterType type) {
    setState(() => _filterType = type);
    _applyFilters();
  }

  // ✅ Normalize للنص: يشيل الاقتباسات + علامات اتجاه النص + الرموز
  String _normalizeForSearch(String input) {
    var s = input.toLowerCase();

    // remove bidi/direction marks
    s = s.replaceAll(
      RegExp(r'[\u200E\u200F\u202A-\u202E\u2066-\u2069]'),
      '',
    );

    // remove quotes/apostrophes variants
    s = s.replaceAll(RegExp(r'[\"“”„‟«»‹›]'), '');
    s = s.replaceAll(RegExp(r"[\'’`´]"), '');

    // replace non alnum (english/ar) with space
    s = s.replaceAll(
      RegExp(r'[^a-z0-9\u0621-\u064A\u0660-\u0669\u06F0-\u06F9]+'),
      ' ',
    );

    // collapse spaces
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  String _cacheKey(StockModel s) => (s.symbol.isNotEmpty ? s.symbol : s.id);

  String _searchIndexFor(StockModel s) {
    final key = _cacheKey(s);
    return _searchIndexCache.putIfAbsent(key, () {
      final raw = '${s.displayName} ${s.symbol} ${s.id}';
      return _normalizeForSearch(raw);
    });
  }

  bool _matchesQuery(StockModel s, String normalizedQuery) {
    if (normalizedQuery.isEmpty) return true;

    final idx = _searchIndexFor(s);

    // 1) contains مباشر
    if (idx.contains(normalizedQuery)) return true;

    // 2) contains بدون مسافات (لو المستخدم كتب الاسم ككتلة واحدة)
    final compactIdx = idx.replaceAll(' ', '');
    final compactQ = normalizedQuery.replaceAll(' ', '');
    if (compactQ.isNotEmpty && compactIdx.contains(compactQ)) return true;

    // 3) كل كلمات البحث موجودة بأي ترتيب
    final tokens =
        normalizedQuery.split(' ').where((t) => t.trim().isNotEmpty).toList();
    if (tokens.isEmpty) return true;
    return tokens.every((t) => idx.contains(t));
  }

  void _applyFilters() {
    List<StockModel> temp = List.from(_allStocks);

    switch (_filterType) {
      case StockFilterType.gainers:
        temp = temp.where((s) => s.changePercent > 0).toList();
        break;
      case StockFilterType.losers:
        temp = temp.where((s) => s.changePercent < 0).toList();
        break;
      case StockFilterType.favorites:
        temp = temp.where((s) => _favoriteSymbols.contains(s.symbol)).toList();
        break;
      case StockFilterType.all:
        break;
    }

    // ✅ البحث بعد التطبيع
    final normalizedQuery = _normalizeForSearch(_searchController.text.trim());
    if (normalizedQuery.isNotEmpty) {
      temp = temp.where((s) => _matchesQuery(s, normalizedQuery)).toList();
    }

    switch (_sortType) {
      case StockSortType.nameAsc:
        temp.sort((a, b) => a.displayName.compareTo(b.displayName));
        break;
      case StockSortType.nameDesc:
        temp.sort((a, b) => b.displayName.compareTo(a.displayName));
        break;
      case StockSortType.priceAsc:
        temp.sort((a, b) => a.price.compareTo(b.price));
        break;
      case StockSortType.priceDesc:
        temp.sort((a, b) => b.price.compareTo(a.price));
        break;
      case StockSortType.changeAsc:
        temp.sort((a, b) => a.changePercent.compareTo(b.changePercent));
        break;
      case StockSortType.changeDesc:
        temp.sort((a, b) => b.changePercent.compareTo(a.changePercent));
        break;
    }

    setState(() {
      _filteredStocks = temp;
    });
  }

  Future<void> _toggleFavorite(StockModel stock) async {
    await FavoritesService.toggleFavorite(stock.symbol);
    final newFavs = await FavoritesService.getFavorites();
    if (!mounted) return;

    setState(() {
      _favoriteSymbols = newFavs.toSet();
    });

    if (_filterType == StockFilterType.favorites) {
      _applyFilters();
    }
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
      _applyFilters();
    });
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FC),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              _buildTopControlPanel(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopControlPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabPageHeaderBlock(
            title: 'جميع الأسهم',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error != null ? '' : '${_filteredStocks.length} شركة',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                _CircleIconButton(
                  onTap: _loading ? null : _loadInitial,
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryBlue,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded,
                          color: AppColors.primaryBlue, size: 20),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 2),
            child: LastUpdateBanner(
              updateUtc: _lastUpdateUtc,
              loading: _loading,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _SearchField(
                  controller: _searchController,
                  onClear: () {
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _FilterPill(
                              label: 'الكل',
                              isSelected: _filterType == StockFilterType.all,
                              onTap: () => _updateFilter(StockFilterType.all),
                            ),
                            const SizedBox(width: 8),
                            _FilterPill(
                              label: 'الأكثر ربحاً',
                              isSelected:
                                  _filterType == StockFilterType.gainers,
                              color: AppColors.gain,
                              onTap: () =>
                                  _updateFilter(StockFilterType.gainers),
                            ),
                            const SizedBox(width: 8),
                            _FilterPill(
                              label: 'الأكثر خسارة',
                              isSelected: _filterType == StockFilterType.losers,
                              color: AppColors.loss,
                              onTap: () =>
                                  _updateFilter(StockFilterType.losers),
                            ),
                            const SizedBox(width: 8),
                            _FilterPill(
                              label: 'المفضلة',
                              icon: Icons.star_rounded,
                              isSelected:
                                  _filterType == StockFilterType.favorites,
                              color: Colors.amber,
                              onTap: () =>
                                  _updateFilter(StockFilterType.favorites),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _SortButton(
                      currentSort: _sortType,
                      onTap: _showSortBottomSheet,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error!, style: AppTextStyles.bodyLarge),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadInitial,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredStocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            Text(
              'لا توجد نتائج مطابقة',
              style: AppTextStyles.headingSmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitial,
      color: AppColors.primaryBlue,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: _filteredStocks.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == _filteredStocks.length) {
            if (!_hasMore) return const SizedBox(height: 10);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: _isLoadingMore
                    ? const CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                        strokeWidth: 2.5,
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }

          final stock = _filteredStocks[index];
          final isFav = _favoriteSymbols.contains(stock.symbol);

          return _StockCard(
            stock: stock,
            isFavorite: isFav,
            onTap: () => _openStockDetail(stock),
            onFavoriteToggle: () => _toggleFavorite(stock),
          );
        },
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child:
                  Text('ترتيب النتائج حسب', style: AppTextStyles.headingSmall),
            ),
            _SortOption(
              label: 'الاسم (أ - ي)',
              isSelected: _sortType == StockSortType.nameAsc,
              onTap: () {
                setState(() => _sortType = StockSortType.nameAsc);
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            _SortOption(
              label: 'الاسم (ي - أ)',
              isSelected: _sortType == StockSortType.nameDesc,
              onTap: () {
                setState(() => _sortType = StockSortType.nameDesc);
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            _SortOption(
              label: 'السعر (الأعلى أولاً)',
              isSelected: _sortType == StockSortType.priceDesc,
              onTap: () {
                setState(() => _sortType = StockSortType.priceDesc);
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            _SortOption(
              label: 'السعر (الأقل أولاً)',
              isSelected: _sortType == StockSortType.priceAsc,
              onTap: () {
                setState(() => _sortType = StockSortType.priceAsc);
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            _SortOption(
              label: 'الأكثر ربحاً',
              isSelected: _sortType == StockSortType.changeDesc,
              onTap: () {
                setState(() => _sortType = StockSortType.changeDesc);
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            _SortOption(
              label: 'الأكثر خسارة',
              isSelected: _sortType == StockSortType.changeAsc,
              onTap: () {
                setState(() => _sortType = StockSortType.changeAsc);
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// --- Helper Widgets ---

class _CircleIconButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _CircleIconButton({
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.04)),
          ),
          child: IconTheme(
            data: const IconThemeData(color: AppColors.textPrimary),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final hasText = value.text.trim().isNotEmpty;
          return TextField(
            controller: controller,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: 'ابحث باسم السهم أو الرمز...',
              hintStyle: TextStyle(
                fontFamily: 'Tajawal',
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 14,
              ),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.textSecondary),
              suffixIcon: hasText
                  ? IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.clear_rounded, size: 18),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          );
        },
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;
  final IconData? icon;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color = AppColors.primaryBlue,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final StockSortType currentSort;
  final VoidCallback onTap;

  const _SortButton({required this.currentSort, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.18)),
        ),
        child: const Icon(
          Icons.sort_rounded,
          color: AppColors.primaryBlue,
          size: 22,
        ),
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  final StockModel stock;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const _StockCard({
    required this.stock,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  bool _isSvg(String url) => url.toLowerCase().contains('.svg');

  Widget _fallbackAvatar() {
    final txt = stock.symbol.isNotEmpty
        ? (stock.symbol.length > 2
            ? stock.symbol.substring(0, 2)
            : stock.symbol)
        : (stock.id.length > 2 ? stock.id.substring(0, 2) : stock.id);

    return Center(
      child: Text(
        txt,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w900,
          color: AppColors.primaryBlue,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _logoWidget() {
    final url = stock.selfLogo?.trim();
    if (url == null || url.isEmpty) return _fallbackAvatar();

    if (_isSvg(url)) {
      return SvgPicture.network(
        url,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallbackAvatar(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryBlue,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGain = stock.changePercent >= 0;
    final color = isGain ? AppColors.gain : AppColors.loss;
    final sign = isGain ? '+' : '';

    // ✅ يحمي النص من ضغط عمود السعر
    final screenW = MediaQuery.of(context).size.width;
    final double priceColMaxW = screenW < 360 ? 95 : 120;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _logoWidget(),
                ),
                const SizedBox(width: 12),

                // Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${stock.symbol} • ${stock.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Price Column
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: priceColMaxW),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        stock.price.toStringAsFixed(2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$sign${stock.changePercent.toStringAsFixed(2)}%',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                IconButton(
                  onPressed: onFavoriteToggle,
                  icon: Icon(
                    isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isFavorite ? Colors.amber : AppColors.border,
                    size: 26,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
          color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primaryBlue)
          : null,
    );
  }
}
