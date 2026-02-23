import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/models/stock_model.dart';
import '../core/utils/formatters.dart';
import '../core/utils/constants.dart';

class TopStockCard extends StatelessWidget {
  final StockModel stock;
  final bool isGainer;
  final VoidCallback? onTap;

  const TopStockCard({
    super.key,
    required this.stock,
    this.isGainer = true,
    this.onTap,
  });

  bool _isSvg(String url) => url.toLowerCase().contains('.svg');

  String _safeInitials() {
    // حرفين من ID أو من الرمز كـ fallback محترم
    final raw = (stock.id.isNotEmpty ? stock.id : stock.symbol).trim();
    if (raw.isEmpty) return '?';
    final cleaned = raw.contains(':') ? raw.split(':').last : raw;
    return cleaned.length >= 2 ? cleaned.substring(0, 2) : cleaned.substring(0, 1);
  }

  Widget _fallbackAvatar() {
    return Center(
      child: Text(
        _safeInitials(),
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w900,
          color: AppColors.primaryBlue,
          fontSize: 16,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final url = stock.selfLogo?.trim();
    if (url == null || url.isEmpty) return _fallbackAvatar();

    // SVG
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

    // PNG/JPG
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
    final trendColor = isGainer ? AppColors.gain : AppColors.loss;
    final trendIcon = isGainer ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header: Logo + Percent
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.scaffold,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black.withOpacity(0.05)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildLogo(),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: trendColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(trendIcon, size: 12, color: trendColor),
                          const SizedBox(width: 4),
                          Text(
                            Formatters.formatPercent(stock.changePercent),
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: trendColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Body: Stock Name (✅ سطرين)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stock.symbol,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Footer: Price + Action Arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.formatPrice(stock.price),
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textPrimary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
