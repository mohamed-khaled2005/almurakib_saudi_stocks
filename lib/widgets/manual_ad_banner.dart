import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/manual_ad_model.dart';
import '../core/utils/constants.dart';

class ManualAdBanner extends StatelessWidget {
  const ManualAdBanner({
    super.key,
    required this.ad,
    this.stickyBottom = false,
  });

  final ManualAdModel? ad;
  final bool stickyBottom;

  @override
  Widget build(BuildContext context) {
    final adData = ad;
    if (adData == null || adData.imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;
    final stickyImageHeight = (screenHeight * 0.15).clamp(54.0, 84.0);
    const regularImageHeight = 108.0;
    const BorderRadius bannerRadius = BorderRadius.all(Radius.circular(16));

    final double imageHeight =
        stickyBottom ? stickyImageHeight : regularImageHeight;

    final Widget banner = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: bannerRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: bannerRadius,
        child: Material(
          color: AppColors.cardDark,
          child: InkWell(
            onTap: () async {
              final uri = Uri.tryParse(adData.targetUrl);
              if (uri == null) return;
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: Image.network(
              adData.imageUrl,
              height: imageHeight,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) {
                return Container(
                  height: imageHeight,
                  width: double.infinity,
                  color: AppColors.cardLight,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textSecondary,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    if (stickyBottom) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          safeBottomInset > 0 ? safeBottomInset : 8,
        ),
        child: SizedBox(
          width: double.infinity,
          height: imageHeight,
          child: banner,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 14),
      child: banner,
    );
  }
}
