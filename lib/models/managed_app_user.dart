class ManagedAppUser {
  final int id;
  final String email;
  final String? fullName;
  final String? countryCode;
  final String? countryName;
  final String? phoneNumber;
  final String status;
  final String authProvider;
  final bool hasPassword;
  final String? lastLoginAt;

  const ManagedAppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.countryCode,
    required this.countryName,
    required this.phoneNumber,
    required this.status,
    required this.authProvider,
    required this.hasPassword,
    required this.lastLoginAt,
  });

  factory ManagedAppUser.fromJson(Map<String, dynamic> json) {
    return ManagedAppUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: (json['email'] ?? '').toString(),
      fullName: json['full_name']?.toString(),
      countryCode: json['country_code']?.toString(),
      countryName: json['country_name']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      status: (json['status'] ?? 'active').toString(),
      authProvider: (json['auth_provider'] ?? 'password').toString(),
      hasPassword: json['has_password'] == true,
      lastLoginAt: json['last_login_at']?.toString(),
    );
  }

  bool get hasRequiredProfileData {
    final code = (countryCode ?? '').trim();
    final country = (countryName ?? '').trim();
    return code.isNotEmpty || country.isNotEmpty;
  }
}
