import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/constants.dart';
import '../core/utils/responsive.dart';
import '../data/country_options.dart';
import '../models/managed_app_user.dart';
import '../providers/app_manager_provider.dart';
import '../widgets/tab_page_header.dart';
import 'auth_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  static const Color _accent = AppColors.primaryGold;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  String _syncedName = '';
  String _syncedPhone = '';
  String? _syncedCountryCode;
  String? _selectedCountryCode;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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

  String? _resolveCountryCode(String? code, String? name) {
    final normalizedCode = (code ?? '').trim().toUpperCase();
    if (normalizedCode.isNotEmpty &&
        kCountryOptions.any((country) => country.code == normalizedCode)) {
      return normalizedCode;
    }

    final normalizedName = (name ?? '').trim();
    if (normalizedName.isEmpty) return null;

    for (final country in kCountryOptions) {
      if (country.name == normalizedName) {
        return country.code;
      }
    }

    return null;
  }

  CountryOption? _selectedCountry() {
    final code = (_selectedCountryCode ?? '').trim().toUpperCase();
    if (code.isEmpty) return null;

    for (final country in kCountryOptions) {
      if (country.code == code) {
        return country;
      }
    }

    return null;
  }

  String? _dropdownCountryValue() {
    final code = (_selectedCountryCode ?? '').trim().toUpperCase();
    if (code.isEmpty) return null;

    var matches = 0;
    for (final country in kCountryOptions) {
      if (country.code == code) {
        matches += 1;
        if (matches > 1) return null;
      }
    }

    return matches == 1 ? code : null;
  }

  String _providerLabel(String value) {
    switch (value.toLowerCase()) {
      case 'google':
        return 'Google';
      case 'apple':
        return 'Apple';
      case 'password':
        return 'Email';
      default:
        return value;
    }
  }

  String? _validatePhone(String value) {
    final input = value.trim();
    if (input.isEmpty) {
      return 'أدخل رقم الهاتف.';
    }

    final normalized = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(normalized)) {
      return 'أدخل رقم هاتف صحيح.';
    }

    return null;
  }

  void _setControllerText(TextEditingController controller, String value) {
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _syncFormFromUser(ManagedAppUser user) {
    final name = (user.fullName ?? '').trim();
    final phone = (user.phoneNumber ?? '').trim();
    final countryCode = _resolveCountryCode(user.countryCode, user.countryName);

    if (_nameController.text.trim() == _syncedName) {
      _setControllerText(_nameController, name);
    }
    if (_phoneController.text.trim() == _syncedPhone) {
      _setControllerText(_phoneController, phone);
    }
    if ((_selectedCountryCode ?? '') == (_syncedCountryCode ?? '')) {
      _selectedCountryCode = countryCode;
    }

    _syncedName = name;
    _syncedPhone = phone;
    _syncedCountryCode = countryCode;
  }

  Future<void> _saveProfile(AppManagerProvider manager) async {
    final user = manager.user;
    final country = _selectedCountry();
    final phone = _phoneController.text.trim();
    final phoneError = _validatePhone(phone);
    final canChangePassword = user?.hasPassword == true;

    if (country == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر الدولة أولًا.')),
      );
      return;
    }

    if (phoneError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(phoneError)),
      );
      return;
    }

    final ok = await manager.updateProfile(
      fullName: _nameController.text.trim(),
      countryCode: country.code,
      countryName: country.name,
      phoneNumber: phone,
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
      _syncedName = _nameController.text.trim();
      _syncedPhone = phone;
      _syncedCountryCode = country.code;
    }
  }

  Future<void> _logoutAndRequireAuth(AppManagerProvider manager) async {
    await manager.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const AuthScreen(
          redirectToHomeOnSuccess: true,
        ),
      ),
      (_) => false,
    );
  }

  Future<void> _confirmDelete(AppManagerProvider manager) async {
    final user = manager.user;
    if (user == null) return;

    final passwordController = TextEditingController();
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.18),
                  ),
                ),
                title: Row(
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'تأكيد حذف الحساب',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      user.hasPassword
                          ? 'سيتم حذف الحساب نهائيًا. أدخل كلمة المرور للتأكيد.'
                          : 'سيتم حذف الحساب نهائيًا. هل تريد المتابعة؟',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (user.hasPassword) ...<Widget>[
                      const SizedBox(height: 14),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: _inputDecoration('كلمة المرور'),
                      ),
                    ],
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('حذف الحساب'),
                  ),
                ],
              ),
            );
          },
        ) ??
        false;

    final password = passwordController.text.trim();
    passwordController.dispose();

    if (!mounted || !shouldDelete) return;
    if (user.hasPassword && password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل كلمة المرور أولًا.')),
      );
      return;
    }

    final ok = await manager.deleteAccount(
      password: user.hasPassword ? password : null,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'تم حذف الحساب.' : (manager.errorMessage ?? 'فشل حذف الحساب.'),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _accent.withValues(alpha: 0.08),
            blurRadius: 16,
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: _accent),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accent),
      ),
    );
  }

  Widget _labeledInputField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyLarge.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      decoration: _inputDecoration(label),
    );
  }

  Widget _buildCountryField() {
    final selectedValue = _dropdownCountryValue();

    return DropdownButtonFormField<String>(
      key: ValueKey<String?>(selectedValue),
      initialValue: selectedValue,
      isExpanded: true,
      iconEnabledColor: _accent,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      decoration: _inputDecoration('الدولة'),
      items: kCountryOptions
          .map(
            (country) => DropdownMenuItem<String>(
              value: country.code,
              child: Text(
                '${country.flagEmoji} ${country.name} (${country.dialCode})',
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedCountryCode = value?.trim().toUpperCase();
        });
      },
    );
  }

  Widget _buildActionButtons({
    required AppManagerProvider manager,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically = constraints.maxWidth < 430;

        final saveButton = SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: manager.isBusy ? null : () => _saveProfile(manager),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: manager.isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'حفظ التعديلات',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        );

        final logoutButton = SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed:
                manager.isBusy ? null : () => _logoutAndRequireAuth(manager),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: AppColors.error.withValues(alpha: 0.35),
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
        );

        if (stackVertically) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              saveButton,
              const SizedBox(height: 10),
              logoutButton,
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: saveButton),
            const SizedBox(width: 8),
            Expanded(child: logoutButton),
          ],
        );
      },
    );
  }

  Widget _buildGuestBody({
    required EdgeInsets pagePadding,
  }) {
    return SingleChildScrollView(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _accent.withValues(alpha: 0.12),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'سجل الدخول لإدارة حسابك ومزامنة إعداداتك بين الأجهزة.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _openAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'تسجيل الدخول / إنشاء حساب',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeaderCard(ManagedAppUser user) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.account_circle_rounded,
                  color: AppColors.primaryBlue,
                  size: 32,
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
            children: <Widget>[
              _buildInfoChip(
                icon: Icons.verified_user_outlined,
                text: 'المزوّد: ${_providerLabel(user.authProvider)}',
              ),
              _buildInfoChip(
                icon: Icons.info_outline_rounded,
                text: 'الحالة: ${user.status}',
              ),
              if ((user.countryName ?? '').trim().isNotEmpty)
                _buildInfoChip(
                  icon: Icons.public_rounded,
                  text: user.countryName!,
                ),
              if ((user.phoneNumber ?? '').trim().isNotEmpty)
                _buildInfoChip(
                  icon: Icons.phone_android_rounded,
                  text: user.phoneNumber!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileFormCard({
    required AppManagerProvider manager,
    required ManagedAppUser user,
  }) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'تعديل البيانات',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _labeledInputField(
            controller: _nameController,
            label: 'الاسم',
          ),
          const SizedBox(height: 10),
          _buildCountryField(),
          const SizedBox(height: 10),
          _labeledInputField(
            controller: _phoneController,
            label: 'رقم الهاتف',
            keyboardType: TextInputType.phone,
          ),
          if (user.hasPassword) ...<Widget>[
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
          _buildActionButtons(manager: manager),
        ],
      ),
    );
  }

  Widget _buildAccountActionsCard({
    required AppManagerProvider manager,
  }) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'إدارة الحساب',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يمكنك حذف الحساب نهائيًا إذا رغبت بذلك، وسيتم إزالة بياناتك المرتبطة بالتطبيق.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: manager.isBusy ? null : () => _confirmDelete(manager),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              backgroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              side: BorderSide(
                color: AppColors.error.withValues(alpha: 0.45),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'حذف الحساب',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticatedBody({
    required AppManagerProvider manager,
    required ManagedAppUser user,
    required EdgeInsets pagePadding,
  }) {
    return SingleChildScrollView(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildProfileHeaderCard(user),
          const SizedBox(height: 12),
          _buildProfileFormCard(manager: manager, user: user),
          const SizedBox(height: 12),
          _buildAccountActionsCard(manager: manager),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<AppManagerProvider>();
    final user = manager.user;
    final responsivePadding = Responsive.responsivePadding(context);
    final pagePadding = EdgeInsets.fromLTRB(
      responsivePadding.left,
      16,
      responsivePadding.right,
      20,
    );

    if (user != null) {
      _syncFormFromUser(user);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            const TabPageHeaderBlock(title: 'حسابي'),
            Expanded(
              child: user == null
                  ? _buildGuestBody(pagePadding: pagePadding)
                  : _buildAuthenticatedBody(
                      manager: manager,
                      user: user,
                      pagePadding: pagePadding,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
