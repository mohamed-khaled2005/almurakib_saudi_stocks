import 'package:flutter/material.dart';

import '../core/utils/constants.dart';

const EdgeInsets kTabPageHeaderPadding = EdgeInsets.fromLTRB(20, 16, 20, 8);

class TabPageHeaderBlock extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const TabPageHeaderBlock({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: kTabPageHeaderPadding,
      child: TabPageHeader(
        title: title,
        subtitle: subtitle,
        trailing: trailing,
      ),
    );
  }
}

class TabPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const TabPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
