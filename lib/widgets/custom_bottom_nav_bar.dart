import 'package:flutter/material.dart';

import '../core/utils/constants.dart';
import '../core/utils/responsive.dart';

class CustomBottomNavBar extends StatefulWidget {
  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.hideOurAppsTab = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool hideOurAppsTab;

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  static const String _homeLabel = 'الرئيسية';
  static const String _marketLabel = 'السوق';
  static const String _stocksLabel = 'الأسهم';
  static const String _ourAppsLabel = 'تطبيقاتنا';
  static const String _aboutLabel = 'عنا';

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = Responsive.isMobile(context);
    final isCompactNav = isMobile && mediaQuery.size.width < 390;
    final displayIndex = _mapScreenIndexToBarIndex(widget.currentIndex);
    final rawScale = mediaQuery.textScaler.scale(1.0);
    final boundedScale = isCompactNav
        ? 1.0
        : (rawScale.isFinite ? rawScale.clamp(1.0, 1.08).toDouble() : 1.0);

    return Container(
      margin: EdgeInsets.all(isCompactNav ? 8 : (isMobile ? 12 : 20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF8FCF8),
            Color(0xFFEDF8ED),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 22,
            spreadRadius: 1.2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        child: MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(boundedScale),
          ),
          child: BottomNavigationBar(
            currentIndex: displayIndex,
            onTap: (barIndex) {
              widget.onTap(barIndex);
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primaryGold,
            unselectedItemColor: AppColors.textSecondary.withValues(alpha: 0.84),
            selectedFontSize: isCompactNav ? 10 : 12,
            unselectedFontSize: isCompactNav ? 9 : 11,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Tajawal',
            ),
            showSelectedLabels: true,
            showUnselectedLabels: !isCompactNav,
            items: [
              _buildNavItem(
                outlineIcon: Icons.home_outlined,
                filledIcon: Icons.home,
                label: _homeLabel,
                isSelected: widget.currentIndex == 0,
                isCompact: isCompactNav,
              ),
              _buildNavItem(
                outlineIcon: Icons.trending_up_outlined,
                filledIcon: Icons.trending_up,
                label: _marketLabel,
                isSelected: widget.currentIndex == 1,
                isCompact: isCompactNav,
              ),
              _buildNavItem(
                outlineIcon: Icons.list_alt_outlined,
                filledIcon: Icons.list_alt,
                label: _stocksLabel,
                isSelected: widget.currentIndex == 2,
                isCompact: isCompactNav,
              ),
              if (!widget.hideOurAppsTab)
                _buildNavItem(
                  outlineIcon: Icons.apps_outlined,
                  filledIcon: Icons.apps,
                  label: _ourAppsLabel,
                  isSelected: widget.currentIndex == 3,
                  isCompact: isCompactNav,
                ),
              _buildNavItem(
                outlineIcon: Icons.info_outline,
                filledIcon: Icons.info,
                label: _aboutLabel,
                isSelected: widget.hideOurAppsTab
                    ? widget.currentIndex == 3 || widget.currentIndex == 4
                    : widget.currentIndex == 4 || widget.currentIndex == 5,
                isCompact: isCompactNav,
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _mapScreenIndexToBarIndex(int screenIndex) {
    if (widget.hideOurAppsTab) {
      if (screenIndex <= 2) return screenIndex;
      return 3;
    }

    if (screenIndex <= 3) return screenIndex;
    return 4;
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData outlineIcon,
    required IconData filledIcon,
    required String label,
    required bool isSelected,
    required bool isCompact,
  }) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: AppAnimations.buttonAnimation,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 6 : 10,
          vertical: isCompact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGold.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: AnimatedSwitcher(
          duration: AppAnimations.buttonAnimation,
          child: Icon(
            isSelected ? filledIcon : outlineIcon,
            key: ValueKey('${label}_${isSelected ? 'filled' : 'outline'}'),
            size: isCompact ? 20 : 22,
          ),
        ),
      ),
      label: label,
    );
  }

}
