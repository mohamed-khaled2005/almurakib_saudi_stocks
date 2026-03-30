import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/constants.dart';
import '../data/country_options.dart';
import '../providers/app_manager_provider.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({
    super.key,
    this.mandatory = true,
  });

  final bool mandatory;

  static Future<bool> ensureCompleted(
    BuildContext context, {
    bool mandatory = true,
  }) async {
    final manager = context.read<AppManagerProvider>();
    if (!manager.requiresProfileCompletion) {
      return true;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ProfileCompletionScreen(mandatory: mandatory),
      ),
    );

    if (!context.mounted) {
      return result == true;
    }

    return result == true ||
        !context.read<AppManagerProvider>().requiresProfileCompletion;
  }

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedCountryCode;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppManagerProvider>().user;
    _selectedCountryCode =
        _resolveCountryCode(user?.countryCode, user?.countryName);
    _phoneController.text = (user?.phoneNumber ?? '').trim();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
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

  String? _validatePhone(String? value) {
    final input = (value ?? '').trim();
    if (input.isEmpty) {
      return 'أدخل رقم الهاتف.';
    }

    final normalized = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(normalized)) {
      return 'أدخل رقم هاتف صحيح.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final country = _selectedCountry();
    if (country == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر الدولة أولًا.')),
      );
      return;
    }

    final manager = context.read<AppManagerProvider>();
    final ok = await manager.updateProfile(
      countryCode: country.code,
      countryName: country.name,
      phoneNumber: _phoneController.text.trim(),
    );

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            manager.errorMessage ?? 'تعذر حفظ بيانات الحساب.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pop(true);
  }

  Future<void> _logout() async {
    await context.read<AppManagerProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.border),
    );

    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: AppColors.primaryGold, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(
          color: AppColors.primaryGold,
          width: 1.2,
        ),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.error, width: 1.2),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.error, width: 1.3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<AppManagerProvider>();

    return PopScope(
      canPop: !widget.mandatory,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.scaffold,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGold
                                      .withValues(alpha: 0.10),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified_user_outlined,
                                  color: AppColors.primaryGold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'استكمال بيانات الحساب',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'أدخل الدولة ورقم الهاتف لتفعيل الحساب بشكل كامل.',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                        height: 1.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCountryCode,
                            isExpanded: true,
                            decoration: _fieldDecoration(
                              label: 'الدولة',
                              icon: Icons.public_rounded,
                            ),
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
                            onChanged: manager.isBusy
                                ? null
                                : (value) {
                                    setState(
                                        () => _selectedCountryCode = value);
                                  },
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'اختر الدولة.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: _fieldDecoration(
                              label: 'رقم الهاتف',
                              icon: Icons.phone_android_rounded,
                            ),
                            validator: _validatePhone,
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: manager.isBusy ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGold,
                                foregroundColor: Colors.white,
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
                                      'حفظ والمتابعة',
                                      style: TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                            ),
                          ),
                          if (widget.mandatory) ...<Widget>[
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: manager.isBusy ? null : _logout,
                              icon: const Icon(Icons.logout_rounded, size: 18),
                              label: const Text(
                                'تسجيل الخروج',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
