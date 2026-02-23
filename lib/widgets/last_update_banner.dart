import 'package:flutter/material.dart';

import '../core/utils/constants.dart';
import '../core/utils/server_time_utils.dart';

class LastUpdateBanner extends StatelessWidget {
  final DateTime? updateUtc;
  final bool loading;
  final String title;

  const LastUpdateBanner({
    super.key,
    required this.updateUtc,
    this.loading = false,
    this.title = 'آخر تحديث:',
  });

  @override
  Widget build(BuildContext context) {
    final value = ServerTimeUtils.formatLastUpdate(updateUtc);

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardLight.withOpacity(0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.14),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 16,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: loading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                    ),
                  )
                : const SizedBox(
                    key: ValueKey('idle'),
                    width: 14,
                    height: 14,
                  ),
          ),
        ],
      ),
    );
  }
}
