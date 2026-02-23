import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/models/stock_model.dart';
import '../core/utils/formatters.dart';
import '../core/utils/constants.dart';

class StockListItem extends StatelessWidget {
  final StockModel stock;
  final VoidCallback? onTap;
  final bool showFavoriteButton;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  const StockListItem({
    super.key,
    required this.stock,
    this.onTap,
    this.showFavoriteButton = false,
    this.isFavorite = false,
    this.onFavoriteTap,
  });

  bool _isSvg(String url) => url.toLowerCase().contains('.svg');

  Widget _buildLogoFallback() {
    final txt = stock.symbol.isNotEmpty
        ? (stock.symbol.length > 2 ? stock.symbol.substring(0, 2) : stock.symbol)
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

  Widget _buildCompanyLogo() {
    final url = stock.selfLogo?.trim();
    if (url == null || url.isEmpty) return _buildLogoFallback();

    if (_isSvg(url)) {
      return SvgPicture.network(
        url,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
          ),
        ),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildLogoFallback(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGain = stock.isGain;
    final changeColor = isGain ? AppColors.gain : AppColors.loss;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              // ✅ 1) Logo Avatar بدل TA
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildCompanyLogo(),
              ),

              const SizedBox(width: 12),

              // 2) اسم الشركة والرمز
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ خلي الاسم ياخد مساحة أكبر بدون تقطيع قوي
                    Text(
                      stock.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            stock.symbol,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isGain ? 'مرتفع' : 'منخفض',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: changeColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3) السعر والتغيير
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.formatNumber(stock.price),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: changeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isGain ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                          size: 16,
                          color: changeColor,
                        ),
                        Text(
                          '${Formatters.formatPercent(stock.changePercent)}',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: changeColor,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 4) زر المفضلة (اختياري)
              if (showFavoriteButton) ...[
                const SizedBox(width: 12),
                InkWell(
                  onTap: onFavoriteTap,
                  borderRadius: BorderRadius.circular(50),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                      color: isFavorite ? Colors.amber : AppColors.border,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
