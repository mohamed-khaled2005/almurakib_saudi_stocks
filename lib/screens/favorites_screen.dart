import 'package:flutter/material.dart';

import '../animations/fade_animation.dart';
import '../core/models/stock_model.dart';
import '../core/services/favorites_service.dart';
import '../core/services/stock_service.dart';
import '../core/utils/constants.dart';
import '../widgets/stock_list_item.dart';
import 'stock_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final List<StockModel> _favoriteStocks = <StockModel>[];
  VoidCallback? _favoritesListener;
  bool _loadInProgress = false;
  bool _reloadQueued = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeFavorites();
  }

  @override
  void dispose() {
    final listener = _favoritesListener;
    if (listener != null) {
      FavoritesService.favoritesNotifier.removeListener(listener);
    }
    super.dispose();
  }

  String _normalizeSymbol(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized.isEmpty) return '';
    return normalized.contains(':')
        ? normalized.split(':').last.trim()
        : normalized;
  }

  void _indexStock(Map<String, StockModel> byKey, StockModel stock) {
    final keys = <String>{
      stock.symbol.trim().toUpperCase(),
      stock.id.trim().toUpperCase(),
      _normalizeSymbol(stock.symbol),
      _normalizeSymbol(stock.id),
    };

    for (final key in keys) {
      if (key.isEmpty) continue;
      byKey.putIfAbsent(key, () => stock);
    }
  }

  Future<void> _initializeFavorites() async {
    await _loadFavorites(forceReload: true);
    if (!mounted) return;

    _favoritesListener = () => _loadFavorites();
    FavoritesService.favoritesNotifier.addListener(_favoritesListener!);
  }

  Future<void> _loadFavorites({bool forceReload = false}) async {
    if (_loadInProgress) {
      _reloadQueued = true;
      return;
    }

    _loadInProgress = true;

    if (!mounted) {
      _loadInProgress = false;
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final favoriteSymbols =
          await FavoritesService.getFavorites(forceReload: forceReload);

      if (favoriteSymbols.isEmpty) {
        if (!mounted) return;
        setState(() {
          _favoriteStocks.clear();
          _loading = false;
        });
        return;
      }

      final stocksByKey = <String, StockModel>{};

      try {
        final stocks = await StockService.getBySymbols(favoriteSymbols);
        for (final stock in stocks) {
          _indexStock(stocksByKey, stock);
        }
      } catch (_) {}

      final missingSymbols = favoriteSymbols.where((symbol) {
        final normalized = _normalizeSymbol(symbol);
        return !stocksByKey.containsKey(symbol.trim().toUpperCase()) &&
            !stocksByKey.containsKey(normalized);
      }).toList();

      if (missingSymbols.isNotEmpty) {
        try {
          final allStocks =
              await StockService.getStocksList(perPage: 500, page: 1);
          for (final stock in allStocks) {
            _indexStock(stocksByKey, stock);
          }
        } catch (_) {}
      }

      final resolvedStocks = <StockModel>[];
      final seenKeys = <String>{};

      for (final symbol in favoriteSymbols) {
        final normalized = _normalizeSymbol(symbol);
        StockModel? stock =
            stocksByKey[symbol.trim().toUpperCase()] ?? stocksByKey[normalized];

        if (stock == null) {
          try {
            stock = await StockService.getStockDetail(symbol);
            _indexStock(stocksByKey, stock);
          } catch (_) {}
        }

        if (stock == null) continue;

        final stockKey = _normalizeSymbol(stock.symbol);
        if (seenKeys.add(stockKey.isEmpty ? stock.symbol : stockKey)) {
          resolvedStocks.add(stock);
        }
      }

      if (!mounted) return;
      setState(() {
        _favoriteStocks
          ..clear()
          ..addAll(resolvedStocks);
        _loading = false;
        _error = resolvedStocks.isEmpty
            ? 'تعذر تحميل بيانات الأسهم المفضلة حاليًا.'
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذر تحميل المفضلة حاليًا.';
        _loading = false;
      });
    } finally {
      _loadInProgress = false;
      if (_reloadQueued && mounted) {
        _reloadQueued = false;
        await _loadFavorites();
      }
    }
  }

  Future<void> _removeFavorite(StockModel stock) async {
    await FavoritesService.removeFavorite(stock.symbol);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تمت إزالة ${stock.displayName} من المفضلة',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openStockDetail(StockModel stock) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => StockDetailScreen(stock: stock),
      ),
    ).then((_) => _loadFavorites(forceReload: true));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    return FadeAnimation(
      child: RefreshIndicator(
        onRefresh: () => _loadFavorites(forceReload: true),
        color: AppColors.primaryBlue,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'المفضلة',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _loadFavorites(forceReload: true),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('تحديث'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_favoriteStocks.isEmpty)
              _buildEmpty()
            else
              ...List<Widget>.generate(_favoriteStocks.length, (index) {
                final stock = _favoriteStocks[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == _favoriteStocks.length - 1 ? 0 : 10,
                  ),
                  child: StockListItem(
                    stock: stock,
                    showFavoriteButton: true,
                    isFavorite: true,
                    onFavoriteTap: () => _removeFavorite(stock),
                    onTap: () => _openStockDetail(stock),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.border.withAlpha(100),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star_border_rounded,
                size: 50,
                color: AppColors.textSecondary.withAlpha(150),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'لا توجد أسهم مفضلة',
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'أضف الأسهم التي تتابعها إلى المفضلة لتصل إليها بسرعة في أي وقت.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 60,
            color: AppColors.error.withAlpha(150),
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _loadFavorites(forceReload: true),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
