import 'package:flutter/material.dart';
import '../core/models/stock_model.dart';
import '../core/services/stock_service.dart';
import '../core/services/favorites_service.dart';
import '../core/utils/constants.dart';
import '../animations/fade_animation.dart';
import '../widgets/stock_list_item.dart';
import 'stock_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<StockModel> _favoriteStocks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final favoriteSymbols = await FavoritesService.getFavorites();
      
      if (favoriteSymbols.isEmpty) {
        if (!mounted) return;
        setState(() {
          _favoriteStocks = [];
          _loading = false;
        });
        return;
      }

      // جلب تفاصيل كل سهم مفضل
      List<StockModel> stocks = [];
      for (String symbol in favoriteSymbols) {
        try {
          final stock = await StockService.getStockDetail(symbol);
          stocks.add(stock);
        } catch (e) {
          print('⚠️ فشل تحميل السهم $symbol');
        }
      }

      if (! mounted) return;
      setState(() {
        _favoriteStocks = stocks;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'فشل تحميل المفضلة';
        _loading = false;
      });
    }
  }

  Future<void> _removeFavorite(StockModel stock) async {
    await FavoritesService.removeFavorite(stock.symbol);
    await _loadFavorites();
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم إزالة ${stock.displayName} من المفضلة',
          style:  const TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child:  CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    if (_favoriteStocks.isEmpty) {
      return _buildEmpty();
    }

    return FadeAnimation(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteStocks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final stock = _favoriteStocks[index];
          return StockListItem(
            stock:  stock,
            showFavoriteButton: true,
            isFavorite: true,
            onFavoriteTap: () => _removeFavorite(stock),
            onTap: () => _openStockDetail(stock),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
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
          const SizedBox(height:  20),
          Text(
            'لا توجد أسهم مفضلة',
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height:  8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'قم بإضافة الأسهم التي تتابعها إلى المفضلة لسهولة الوصول إليها',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
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
          const SizedBox(height:  16),
          Text(
            _error!,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadFavorites,
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

  void _openStockDetail(StockModel stock) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StockDetailScreen(stock: stock),
      ),
    ).then((_) => _loadFavorites()); // تحديث عند العودة
  }
}