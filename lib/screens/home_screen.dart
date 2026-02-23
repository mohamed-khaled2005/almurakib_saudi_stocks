import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/models/tasi_index_model.dart';
import '../core/models/stock_model.dart';
import '../core/services/stock_service.dart';
import '../core/services/favorites_service.dart';
import '../core/services/translation_service.dart';
import '../core/utils/constants.dart';
import '../core/utils/server_time_utils.dart';

import '../animations/fade_animation.dart';
import '../animations/slide_animation.dart';
import '../widgets/tasi_card.dart';
import '../widgets/top_stock_card.dart';
import '../widgets/stock_list_item.dart';
import '../widgets/last_update_banner.dart';
import 'stock_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TasiIndexModel? _tasiIndex;
  StockModel? _topGainer;
  StockModel? _topLoser;

  List<StockModel> _favoriteStocks = [];

  bool _loading = true;
  String? _error;
  bool _translationsAvailable = false;

  bool _busy = false;

  // ✅ Tunables
  static const int _perPage = 500;
  static const int _favoritesPreview = 5;

  VoidCallback? _favListener;
  Timer? _favDebounce;
  bool _loadingFavsOnly = false;

  @override
  void initState() {
    super.initState();

    _favListener = () {
      _favDebounce?.cancel();
      _favDebounce = Timer(const Duration(milliseconds: 80), () {
        _refreshFavoritesOnly(FavoritesService.favoritesNotifier.value);
      });
    };
    FavoritesService.favoritesNotifier.addListener(_favListener!);

    _loadData();
  }

  @override
  void dispose() {
    _favDebounce?.cancel();
    if (_favListener != null) {
      FavoritesService.favoritesNotifier.removeListener(_favListener!);
    }
    super.dispose();
  }

  Future<void> _refreshFavoritesOnly(Set<String> symbols) async {
    if (!mounted) return;

    if (_loadingFavsOnly) return;
    _loadingFavsOnly = true;

    try {
      final take = symbols.take(_favoritesPreview).toList();
      List<StockModel> favStocks = [];

      if (take.isNotEmpty) {
        favStocks = await StockService.getBySymbols(take);
        if (_translationsAvailable) {
          favStocks = await StockService.attachArabicNames(favStocks);
        }
      }

      if (!mounted) return;
      setState(() {
        _favoriteStocks = favStocks;
      });
    } catch (_) {
      // تجاهل
    } finally {
      _loadingFavsOnly = false;
    }
  }

  Future<void> _loadData() async {
    if (_busy) return;
    _busy = true;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final translationsFuture = TranslationService.getTranslations();

      final tasiFuture = StockService.getTasiIndex();

      // ✅ حمل المفضلة من notifier/SharedPreferences
      final favFuture = FavoritesService.getFavorites(forceReload: true);

      final allStocksFuture =
          StockService.getStocksList(perPage: _perPage, page: 1);

      final tasi = await tasiFuture;
      final favoriteSymbolsList = await favFuture;
      final allStocks = await allStocksFuture;

      final favoriteSymbols = favoriteSymbolsList.toSet();

      final gainers = allStocks.where((s) => s.changePercent > 0).toList()
        ..sort((a, b) => b.changePercent.compareTo(a.changePercent));

      final losers = allStocks.where((s) => s.changePercent < 0).toList()
        ..sort((a, b) => a.changePercent.compareTo(b.changePercent));

      final topGainer = gainers.isNotEmpty ? gainers.first : null;
      final topLoser = losers.isNotEmpty ? losers.first : null;

      List<StockModel> favStocks = [];
      if (favoriteSymbols.isNotEmpty) {
        favStocks = await StockService.getBySymbols(
          favoriteSymbols.take(_favoritesPreview).toList(),
        );
      }

      final translations = await translationsFuture;
      _translationsAvailable = translations != null;

      if (translations != null) {
        favStocks = await StockService.attachArabicNames(favStocks);

        StockModel? g = topGainer;
        StockModel? l = topLoser;

        if (g != null) {
          final gg = await StockService.attachArabicNames([g]);
          g = gg.isNotEmpty ? gg.first : g;
        }
        if (l != null) {
          final ll = await StockService.attachArabicNames([l]);
          l = ll.isNotEmpty ? ll.first : l;
        }

        if (!mounted) return;
        setState(() {
          _tasiIndex = tasi;
          _topGainer = g;
          _topLoser = l;
          _favoriteStocks = favStocks;
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _tasiIndex = tasi;
          _topGainer = topGainer;
          _topLoser = topLoser;
          _favoriteStocks = favStocks;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    } finally {
      _busy = false;
    }
  }

  void _navigateToAllStocks() {
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(2);
    }
  }

  DateTime? _latestUpdateUtc() {
    final favoriteUpdates = _favoriteStocks.map((s) => s.lastUpdateUtc);
    return ServerTimeUtils.pickLatest([
      _tasiIndex?.updateTimeUtc,
      _topGainer?.lastUpdateUtc,
      _topLoser?.lastUpdateUtc,
      ...favoriteUpdates,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    String currentDate =
        DateFormat('EEEE, d MMMM y', 'ar').format(DateTime.now());
    currentDate = currentDate
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        top: false,
        child: _loading
            ? _buildLoadingState()
            : _error != null
                ? _buildErrorState()
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: AppColors.primaryBlue,
                    backgroundColor: Colors.white,
                    child: FadeAnimation(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        children: [
                          _buildHeader(currentDate, _latestUpdateUtc()),
                          const SizedBox(height: 24),
                          if (!_translationsAvailable) _buildTranslationAlert(),
                          if (_tasiIndex != null)
                            SlideAnimation(
                              child: Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryBlue
                                          .withOpacity(0.15),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: TasiCard(
                                    tasi: _tasiIndex!, onRefresh: _loadData),
                              ),
                            ),
                          const SizedBox(height: 32),
                          _buildUnifiedTitle(title: 'أداء السوق اليوم'),
                          const SizedBox(height: 16),
                          if (_topGainer != null || _topLoser != null)
                            Column(
                              children: [
                                if (_topGainer != null)
                                  SlideAnimation(
                                    delay: const Duration(milliseconds: 150),
                                    child: _buildLabeledStockSection(
                                      title: 'الأكثر ارتفاعاً',
                                      stock: _topGainer!,
                                      isGainer: true,
                                    ),
                                  ),
                                if (_topGainer != null && _topLoser != null)
                                  const SizedBox(height: 20),
                                if (_topLoser != null)
                                  SlideAnimation(
                                    delay: const Duration(milliseconds: 200),
                                    child: _buildLabeledStockSection(
                                      title: 'الأكثر انخفاضاً',
                                      stock: _topLoser!,
                                      isGainer: false,
                                    ),
                                  ),
                              ],
                            ),
                          const SizedBox(height: 32),
                          _buildUnifiedTitle(
                            title: 'مفضلتك',
                            action: InkWell(
                              onTap: _navigateToAllStocks,
                              borderRadius: BorderRadius.circular(20),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      'عرض الكل',
                                      style: TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_rounded,
                                        size: 16, color: AppColors.primaryBlue),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_favoriteStocks.isNotEmpty)
                            ...List.generate(_favoriteStocks.length, (index) {
                              final stock = _favoriteStocks[index];
                              return SlideAnimation(
                                delay:
                                    Duration(milliseconds: 300 + (index * 50)),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: StockListItem(
                                    stock: stock,
                                    showFavoriteButton: true,
                                    isFavorite: true,
                                    onFavoriteTap: () async {
                                      // ✅ فوري + بدون reload شامل
                                      await FavoritesService.toggleFavorite(
                                          stock.symbol);
                                    },
                                    onTap: () => _openStockDetail(stock),
                                  ),
                                ),
                              );
                            })
                          else
                            SlideAnimation(
                              delay: const Duration(milliseconds: 250),
                              child: _buildEmptyFavoritesState(),
                            ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeader(String date, DateTime? lastUpdateUtc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          date,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        LastUpdateBanner(
          updateUtc: lastUpdateUtc,
          loading: _loading,
        ),
      ],
    );
  }

  Widget _buildUnifiedTitle({required String title, Widget? action}) {
    return SlideAnimation(
      delay: const Duration(milliseconds: 100),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
              Text(
                title,
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  Widget _buildLabeledStockSection({
    required String title,
    required StockModel stock,
    required bool isGainer,
  }) {
    final color = isGainer ? AppColors.gain : AppColors.loss;
    final icon =
        isGainer ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 4, left: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ).copyWith(color: color),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: TopStockCard(
            stock: stock,
            isGainer: isGainer,
            onTap: () => _openStockDetail(stock),
          ),
        ),
      ],
    );
  }

  Widget _buildTranslationAlert() {
    return SlideAnimation(
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFCC80).withOpacity(0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: Colors.orange, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'يتم عرض الأسماء باللغة الإنجليزية حالياً',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.brown,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFavoritesState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.star_rounded, size: 40, color: Colors.amber),
          ),
          const SizedBox(height: 16),
          Text(
            'قائمة المراقبة فارغة',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'قم بإضافة الأسهم التي تهمك لمتابعتها بشكل أسرع من هنا.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _navigateToAllStocks,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'استكشاف السوق',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
          color: AppColors.primaryBlue, strokeWidth: 2.5),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text('عذراً، حدث خطأ ما', style: AppTextStyles.headingSmall),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تحديث الصفحة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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
    ).then((_) => _loadData());
  }
}
