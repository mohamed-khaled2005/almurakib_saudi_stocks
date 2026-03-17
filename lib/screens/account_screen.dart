import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/models/stock_model.dart';
import '../core/services/favorites_service.dart';
import '../core/services/stock_service.dart';
import '../core/services/translation_service.dart';
import '../core/utils/constants.dart';
import '../core/utils/responsive.dart';
import '../core/utils/server_time_utils.dart';
import '../providers/app_manager_provider.dart';
import '../widgets/app_section_header.dart';
import '../widgets/last_update_banner.dart';
import 'about_screen.dart';
import 'all_stocks_screen.dart';
import 'auth_screen.dart';
import 'contact_screen.dart';
import 'market_today_screen.dart';
import 'our_apps_screen.dart';
import 'stock_detail_screen.dart';

const Color _headerSurfaceTop = Color(0xFFF9FFF8);
const Color _headerSurfaceBottom = Color(0xFFE8F6E8);
const Color _headerCard = Color(0xFFFFFFFF);

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  static const String _almurakibWebsiteUrl = 'https://almurakib.com/';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final GlobalKey _refreshHintKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _refreshing = false;
  List<StockModel>? _quickSearchStocksCache;
  bool get _showOurAppsTab => defaultTargetPlatform != TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _warmQuickSearchCache();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppManagerProvider>().trackPageView('account');
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _openAuth() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => const AuthScreen()),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الدخول بنجاح.')),
      );
    }
  }

  Future<void> _saveProfile(AppManagerProvider manager) async {
    final user = manager.user;
    final canChangePassword = user?.hasPassword == true;

    final ok = await manager.updateProfile(
      fullName: _nameController.text.trim(),
      currentPassword:
          canChangePassword && _currentPasswordController.text.trim().isNotEmpty
              ? _currentPasswordController.text.trim()
              : null,
      newPassword:
          canChangePassword && _newPasswordController.text.trim().isNotEmpty
              ? _newPasswordController.text.trim()
              : null,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'تم تحديث الحساب.'
              : (manager.errorMessage ?? 'فشل تحديث الحساب.'),
        ),
      ),
    );

    if (ok) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
    }
  }

  Future<void> _logoutAndRequireAuth(AppManagerProvider manager) async {
    await manager.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const AuthScreen(
          redirectToHomeOnSuccess: true,
        ),
      ),
      (_) => false,
    );
  }

  Future<List<StockModel>> _loadQuickSearchUniverse({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _quickSearchStocksCache != null) {
      return _quickSearchStocksCache!;
    }

    final stocks = await StockService.getStocksList(perPage: 500, page: 1);
    _quickSearchStocksCache = stocks;
    return stocks;
  }

  Future<void> _warmQuickSearchCache() async {
    try {
      await _loadQuickSearchUniverse();
      if (mounted) {
        setState(() {});
      }
    } catch (_) {}
  }

  DateTime? _headerLastUpdateUtc() {
    final stocks = _quickSearchStocksCache;
    if (stocks == null || stocks.isEmpty) return null;
    return ServerTimeUtils.pickLatest(stocks.map((stock) => stock.lastUpdateUtc));
  }

  Future<void> _onRefresh() async {
    if (_refreshing) return;

    setState(() => _refreshing = true);
    try {
      await TranslationService.getTranslations(forceRefresh: true);
      await _loadQuickSearchUniverse(forceRefresh: true);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'تم تحديث البيانات بنجاح',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'تعذر تحديث البيانات حاليا',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  Future<void> _onQuickSearch() async {
    final selectedStock = await showModalBottomSheet<StockModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickSearchBottomSheet(
        loadStocks: _loadQuickSearchUniverse,
      ),
    );

    if (!mounted || selectedStock == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StockDetailScreen(stock: selectedStock),
      ),
    );
  }

  Future<void> _confirmDelete(AppManagerProvider manager) async {
    final user = manager.user;
    if (user == null) return;

    String? password;
    bool shouldDelete = false;

    if (user.hasPassword) {
      final passController = TextEditingController();
      final dialogResult = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: AppColors.cardDark,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: AppColors.error.withValues(alpha: 0.25),
              ),
            ),
            title: Text(
              'تأكيد حذف الحساب',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سيتم حذف الحساب نهائيا. أدخل كلمة المرور للتأكيد.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passController,
                  obscureText: true,
                  decoration: _inputDecoration().copyWith(
                    labelText: 'كلمة المرور',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('تأكيد الحذف'),
              ),
            ],
          );
        },
      );
      if (!mounted) {
        passController.dispose();
        return;
      }
      shouldDelete = dialogResult == true;
      password = passController.text.trim();
      passController.dispose();

      if (shouldDelete && password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أدخل كلمة المرور أولا.')),
        );
        return;
      }
    } else {
      final dialogResult = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: AppColors.cardDark,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: AppColors.error.withValues(alpha: 0.25),
              ),
            ),
            title: Text(
              'تأكيد حذف الحساب',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            content: Text(
              'سيتم حذف حسابك نهائيا. هل تريد المتابعة؟',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('تأكيد الحذف'),
              ),
            ],
          );
        },
      );
      if (!mounted) return;
      shouldDelete = dialogResult == true;
    }

    if (!shouldDelete) return;

    final ok = await manager.deleteAccount(password: password);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'تم حذف الحساب.' : (manager.errorMessage ?? 'فشل حذف الحساب.'),
        ),
      ),
    );
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _onLogoTap() async {
    final shouldOpen = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text(
                'فتح موقع المراقب',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: const Text(
                'هل تريد زيارة موقع المراقب الآن؟',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text(
                    'زيارة الموقع',
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldOpen || !mounted) return;

    final ok = await launchUrl(
      Uri.parse(_almurakibWebsiteUrl),
      mode: LaunchMode.externalApplication,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الموقع حاليا')),
      );
    }
  }

  void _openRightMenu() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Drawer _buildSideDrawer(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth > 380 ? 320.0 : screenWidth * 0.86;

    return Drawer(
      width: drawerWidth,
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildSideNavigationPanel(closeOnSelect: true),
    );
  }

  Widget _buildSideNavigationPanel({required bool closeOnSelect}) {
    final items = _navigationItems();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF8FCF8),
            Color(0xFFEEF8EE),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 22,
            spreadRadius: 1.2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(10, 16, 10, 18),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            final isSelected = item.index == _AccountMenuIndex.account;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: AnimatedContainer(
                duration: AppAnimations.buttonAnimation,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            AppColors.primaryGold.withValues(alpha: 0.16),
                            AppColors.primaryGold.withValues(alpha: 0.06),
                          ],
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryGold.withValues(alpha: 0.34)
                        : AppColors.border,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _navigateToMenuItem(
                      item.index,
                      closeDrawer: closeOnSelect,
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsetsDirectional.fromSTEB(12, 6, 10, 6),
                      leading: Icon(
                        item.icon,
                        size: 22,
                        color: isSelected
                            ? AppColors.primaryGold
                            : AppColors.textSecondary,
                      ),
                      title: Text(
                        item.title,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<_AccountSideNavItem> _navigationItems() {
    return <_AccountSideNavItem>[
      const _AccountSideNavItem(
        index: _AccountMenuIndex.home,
        title: 'الصفحة الرئيسية',
        icon: Icons.home_outlined,
      ),
      const _AccountSideNavItem(
        index: _AccountMenuIndex.marketToday,
        title: 'السوق اليوم',
        icon: Icons.trending_up_outlined,
      ),
      const _AccountSideNavItem(
        index: _AccountMenuIndex.allStocks,
        title: 'جميع الأسهم',
        icon: Icons.list_alt_outlined,
      ),
      if (_showOurAppsTab)
        const _AccountSideNavItem(
          index: _AccountMenuIndex.ourApps,
          title: 'تطبيقاتنا',
          icon: Icons.apps_outlined,
        ),
      const _AccountSideNavItem(
        index: _AccountMenuIndex.about,
        title: 'عن التطبيق',
        icon: Icons.info_outline_rounded,
      ),
      const _AccountSideNavItem(
        index: _AccountMenuIndex.contact,
        title: 'الاتصال بنا',
        icon: Icons.contact_page_outlined,
      ),
      const _AccountSideNavItem(
        index: _AccountMenuIndex.account,
        title: 'حسابي',
        icon: Icons.person_outline_rounded,
      ),
    ];
  }

  void _navigateToMenuItem(int index, {required bool closeDrawer}) {
    if (closeDrawer && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    switch (index) {
      case _AccountMenuIndex.home:
        _goHome();
        return;
      case _AccountMenuIndex.marketToday:
        _replaceWith(const MarketTodayScreen());
        return;
      case _AccountMenuIndex.allStocks:
        _replaceWith(const AllStocksScreen());
        return;
      case _AccountMenuIndex.ourApps:
        if (_showOurAppsTab) {
          _replaceWith(const OurAppsScreen());
        }
        return;
      case _AccountMenuIndex.about:
        _replaceWith(const AboutScreen());
        return;
      case _AccountMenuIndex.contact:
        _replaceWith(const ContactScreen());
        return;
      case _AccountMenuIndex.account:
        return;
    }
  }

  void _replaceWith(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  PreferredSizeWidget _buildHeader({required bool isAuthenticated}) {
    final showMenuButton = !Responsive.isDesktop(context);

    return AppBar(
      backgroundColor: _headerCard,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: false,
      toolbarHeight: 72,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_headerSurfaceTop, _headerSurfaceBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border(
            bottom: BorderSide(color: AppColors.border),
          ),
        ),
      ),
      titleSpacing: 12,
      title: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              GestureDetector(
                onTap: _onLogoTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 236),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const Spacer(),
              _AccountHeaderButton(
                tooltip: 'الرئيسية',
                onTap: _goHome,
                icon: Icons.home_outlined,
              ),
              const SizedBox(width: 10),
              _AccountHeaderButton(
                tooltip: isAuthenticated ? 'حسابي' : 'تسجيل الدخول',
                onTap: () {},
                icon: isAuthenticated
                    ? Icons.person_outline_rounded
                    : Icons.account_circle_outlined,
              ),
              if (showMenuButton) ...[
                const SizedBox(width: 10),
                _AccountHeaderButton(
                  tooltip: 'القائمة',
                  onTap: _openRightMenu,
                  icon: Icons.menu_rounded,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopUtilityBar() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_headerSurfaceBottom, _headerSurfaceTop],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: LastUpdateBanner(
                updateUtc: _headerLastUpdateUtc(),
                loading: _refreshing || _quickSearchStocksCache == null,
              ),
            ),
            const SizedBox(width: 8),
            _AccountUtilityButton(
              onTap: _onQuickSearch,
              icon: Icons.search_rounded,
            ),
            const SizedBox(width: 8),
            KeyedSubtree(
              key: _refreshHintKey,
              child: _AccountUtilityButton(
                onTap: _refreshing ? null : _onRefresh,
                child: _refreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryGold,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: AppColors.primaryGold,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      hintText: '...',
      hintStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontFamily: 'Tajawal',
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primaryGold),
      ),
    );
  }

  Widget _labeledInputField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: _inputDecoration(),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryGold),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteChip(String symbol) {
    return InputChip(
      avatar: const Icon(
        Icons.show_chart_rounded,
        size: 16,
        color: AppColors.primaryGold,
      ),
      label: Text(
        symbol,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      backgroundColor: AppColors.background,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onDeleted: () => FavoritesService.removeFavorite(symbol),
      deleteIcon: const Icon(Icons.close_rounded, size: 16),
      deleteIconColor: AppColors.textSecondary,
    );
  }

  Widget _buildFavoritesCard({
    required AppManagerProvider manager,
    required List<String> favorites,
    required bool showDeleteAccount,
  }) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'الأسهم المفضلة (${favorites.length})',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          if (favorites.isEmpty)
            Text(
              'لا توجد أسهم محفوظة حاليا.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else ...[
            Text(
              'اضغط على × لإزالة أي سهم من قائمتك.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: favorites.map(_buildFavoriteChip).toList(),
            ),
          ],
          if (!manager.isAuthenticated) ...[
            const SizedBox(height: 10),
            Text(
              'سجل الدخول لمزامنة قائمتك بين أجهزتك.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (showDeleteAccount) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: manager.isBusy ? null : () => _confirmDelete(manager),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade300,
                side: BorderSide(color: Colors.red.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('حذف الحساب'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuestBody({
    required AppManagerProvider manager,
    required EdgeInsets pagePadding,
    required List<String> favorites,
  }) {
    return SingleChildScrollView(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          const AppSectionHeader(title: 'حسابي'),
          const SizedBox(height: 16),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryGold.withValues(alpha: 0.16),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.primaryGold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'سجل الدخول لحفظ قائمتك المفضلة ومزامنة إعداداتك بين الأجهزة.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _openAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'تسجيل الدخول / إنشاء حساب',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildFavoritesCard(
            manager: manager,
            favorites: favorites,
            showDeleteAccount: false,
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticatedBody({
    required AppManagerProvider manager,
    required EdgeInsets pagePadding,
    required List<String> favorites,
  }) {
    final user = manager.user!;
    final fullName = user.fullName ?? '';
    if (_nameController.text != fullName) {
      _nameController.text = fullName;
    }

    return SingleChildScrollView(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          const AppSectionHeader(title: 'حسابي'),
          const SizedBox(height: 16),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryGold.withValues(alpha: 0.16),
                      ),
                      child: const Icon(
                        Icons.account_circle_rounded,
                        color: AppColors.primaryGold,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        user.email,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      icon: Icons.verified_user_outlined,
                      text: 'النوع: ${user.authProvider}',
                    ),
                    _buildInfoChip(
                      icon: Icons.info_outline_rounded,
                      text: 'الحالة: ${user.status}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'تعديل البيانات',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                _labeledInputField(
                  controller: _nameController,
                  label: 'الاسم',
                ),
                if (user.hasPassword) ...[
                  const SizedBox(height: 10),
                  _labeledInputField(
                    controller: _currentPasswordController,
                    label: 'كلمة المرور الحالية',
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  _labeledInputField(
                    controller: _newPasswordController,
                    label: 'كلمة المرور الجديدة',
                    obscureText: true,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed:
                              manager.isBusy ? null : () => _saveProfile(manager),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGold,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'حفظ التعديلات',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: manager.isBusy
                              ? null
                              : () => _logoutAndRequireAuth(manager),
                          style: OutlinedButton.styleFrom(
                            backgroundColor:
                                AppColors.cardLight.withValues(alpha: 0.40),
                            foregroundColor:
                                AppColors.error.withValues(alpha: 0.92),
                            side: BorderSide(
                              color: AppColors.error.withValues(alpha: 0.42),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text(
                            'تسجيل الخروج',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildFavoritesCard(
            manager: manager,
            favorites: favorites,
            showDeleteAccount: true,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<AppManagerProvider>();
    final pagePadding = Responsive.responsivePadding(context);
    final favorites = List<String>.from(manager.preferences.watchedSymbols)
      ..sort();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.scaffold,
      drawer: _buildSideDrawer(context),
      drawerEnableOpenDragGesture: false,
      appBar: _buildHeader(isAuthenticated: manager.isAuthenticated),
      body: Column(
        children: [
          _buildTopUtilityBar(),
          Expanded(
            child: manager.user == null
                ? _buildGuestBody(
                    manager: manager,
                    pagePadding: pagePadding,
                    favorites: favorites,
                  )
                : _buildAuthenticatedBody(
                    manager: manager,
                    pagePadding: pagePadding,
                    favorites: favorites,
                  ),
          ),
        ],
      ),
    );
  }
}

class _AccountHeaderButton extends StatelessWidget {
  const _AccountHeaderButton({
    required this.tooltip,
    required this.onTap,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: _headerCard,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryGold,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountUtilityButton extends StatelessWidget {
  const _AccountUtilityButton({
    this.onTap,
    this.icon,
    this.child,
  }) : assert(icon != null || child != null);

  final Future<void> Function()? onTap;
  final IconData? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _headerCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Center(
            child: child ??
                Icon(
                  icon,
                  color: AppColors.primaryGold,
                  size: 20,
                ),
          ),
        ),
      ),
    );
  }
}

class _QuickSearchBottomSheet extends StatefulWidget {
  const _QuickSearchBottomSheet({
    required this.loadStocks,
  });

  final Future<List<StockModel>> Function({bool forceRefresh}) loadStocks;

  @override
  State<_QuickSearchBottomSheet> createState() =>
      _QuickSearchBottomSheetState();
}

class _QuickSearchBottomSheetState extends State<_QuickSearchBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Map<String, String> _searchIndexCache = <String, String>{};

  List<StockModel> _stocks = const <StockModel>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStocks();
    _controller.addListener(_onQueryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _dismissKeyboardIfTappedOutside(PointerDownEvent event) {
    if (!_focusNode.hasFocus) return;

    final ctx = _focusNode.context;
    if (ctx != null) {
      final render = ctx.findRenderObject();
      if (render is RenderBox && render.hasSize) {
        final local = render.globalToLocal(event.position);
        if (render.size.contains(local)) return;
      }
    }

    _focusNode.unfocus();
  }

  Future<void> _loadStocks({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final stocks = await widget.loadStocks(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _stocks = stocks;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذر تحميل الأسهم حاليا';
        _loading = false;
      });
    }
  }

  String _normalize(String input) {
    var s = input.toLowerCase();

    s = s.replaceAll(
      RegExp(r'[\u200E\u200F\u202A-\u202E\u2066-\u2069]'),
      '',
    );

    s = s.replaceAll(
      RegExp(r'[^a-z0-9\u0621-\u064A\u0660-\u0669\u06F0-\u06F9]+'),
      ' ',
    );

    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _searchIndexFor(StockModel stock) {
    final key = stock.symbol.isNotEmpty ? stock.symbol : stock.id;
    return _searchIndexCache.putIfAbsent(key, () {
      final raw =
          '${stock.displayName} ${stock.name} ${stock.symbol} ${stock.id}';
      return _normalize(raw);
    });
  }

  bool _matches(StockModel stock, String normalizedQuery) {
    if (normalizedQuery.isEmpty) return true;

    final idx = _searchIndexFor(stock);
    if (idx.contains(normalizedQuery)) return true;

    final compactIdx = idx.replaceAll(' ', '');
    final compactQ = normalizedQuery.replaceAll(' ', '');
    if (compactQ.isNotEmpty && compactIdx.contains(compactQ)) return true;

    final tokens = normalizedQuery.split(' ').where((t) => t.isNotEmpty);
    return tokens.every((t) => idx.contains(t));
  }

  List<StockModel> _results() {
    final normalizedQuery = _normalize(_controller.text.trim());

    if (normalizedQuery.isEmpty) {
      return _stocks.take(40).toList();
    }

    return _stocks.where((s) => _matches(s, normalizedQuery)).take(60).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasText = _controller.text.trim().isNotEmpty;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _dismissKeyboardIfTappedOutside,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SafeArea(
          top: false,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.78,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'بحث سريع عن سهم',
                          style: AppTextStyles.headingSmall.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F9),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: Colors.black.withValues(alpha: 0.06)),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.search,
                      onTapOutside: (_) => _focusNode.unfocus(),
                      onSubmitted: (_) => _focusNode.unfocus(),
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: 'ابحث بالاسم أو الرمز أو الرقم...',
                        hintStyle: TextStyle(
                          fontFamily: 'Tajawal',
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: hasText
                            ? IconButton(
                                onPressed: _controller.clear,
                                icon: const Icon(Icons.clear_rounded, size: 18),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_loading)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    )
                  else if (_error != null)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              size: 34,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: AppTextStyles.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => _loadStocks(forceRefresh: true),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    _QuickSearchResults(
                      stocks: _results(),
                      onSelect: (stock) => Navigator.pop(context, stock),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickSearchResults extends StatelessWidget {
  const _QuickSearchResults({
    required this.stocks,
    required this.onSelect,
  });

  final List<StockModel> stocks;
  final ValueChanged<StockModel> onSelect;

  @override
  Widget build(BuildContext context) {
    if (stocks.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'لا توجد نتائج مطابقة',
            style: TextStyle(
              fontFamily: 'Tajawal',
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: stocks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final stock = stocks[i];
          final isGain = stock.changePercent >= 0;
          final sign = isGain ? '+' : '';
          final color = isGain ? AppColors.gain : AppColors.loss;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelect(stock),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFD),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.black.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stock.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${stock.symbol} • ${stock.id}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          stock.price.toStringAsFixed(2),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$sign${stock.changePercent.toStringAsFixed(2)}%',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

abstract final class _AccountMenuIndex {
  static const int home = 0;
  static const int marketToday = 1;
  static const int allStocks = 2;
  static const int ourApps = 3;
  static const int about = 4;
  static const int contact = 5;
  static const int account = 6;
}

class _AccountSideNavItem {
  const _AccountSideNavItem({
    required this.index,
    required this.title,
    required this.icon,
  });

  final int index;
  final String title;
  final IconData icon;
}
