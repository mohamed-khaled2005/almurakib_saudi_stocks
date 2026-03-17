import 'package:flutter/material.dart';

import '../core/utils/constants.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 4,
            height: 22,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryGold,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              strutStyle: const StrutStyle(
                fontFamily: 'Tajawal',
                fontSize: 20,
                height: 1.15,
                forceStrutHeight: true,
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
