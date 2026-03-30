class CountryOption {
  const CountryOption({
    required this.code,
    required this.name,
    required this.dialCode,
  });

  final String code;
  final String name;
  final String dialCode;

  String get flagEmoji {
    final normalized = code.trim().toUpperCase();
    if (normalized.length != 2) return '';
    final first = normalized.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final second = normalized.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(first) + String.fromCharCode(second);
  }
}

const List<CountryOption> kCountryOptions = <CountryOption>[
  CountryOption(code: 'EG', name: 'مصر', dialCode: '+20'),
  CountryOption(code: 'SA', name: 'السعودية', dialCode: '+966'),
  CountryOption(code: 'AE', name: 'الإمارات العربية المتحدة', dialCode: '+971'),
  CountryOption(code: 'QA', name: 'قطر', dialCode: '+974'),
  CountryOption(code: 'KW', name: 'الكويت', dialCode: '+965'),
  CountryOption(code: 'BH', name: 'البحرين', dialCode: '+973'),
  CountryOption(code: 'OM', name: 'عمان', dialCode: '+968'),
  CountryOption(code: 'JO', name: 'الأردن', dialCode: '+962'),
  CountryOption(code: 'IQ', name: 'العراق', dialCode: '+964'),
  CountryOption(code: 'LB', name: 'لبنان', dialCode: '+961'),
  CountryOption(code: 'SY', name: 'سوريا', dialCode: '+963'),
  CountryOption(code: 'PS', name: 'فلسطين', dialCode: '+970'),
  CountryOption(code: 'YE', name: 'اليمن', dialCode: '+967'),
  CountryOption(code: 'SD', name: 'السودان', dialCode: '+249'),
  CountryOption(code: 'LY', name: 'ليبيا', dialCode: '+218'),
  CountryOption(code: 'TN', name: 'تونس', dialCode: '+216'),
  CountryOption(code: 'DZ', name: 'الجزائر', dialCode: '+213'),
  CountryOption(code: 'MA', name: 'المغرب', dialCode: '+212'),
  CountryOption(code: 'MR', name: 'موريتانيا', dialCode: '+222'),
  CountryOption(code: 'DJ', name: 'جيبوتي', dialCode: '+253'),
  CountryOption(code: 'SO', name: 'الصومال', dialCode: '+252'),
  CountryOption(code: 'KM', name: 'جزر القمر', dialCode: '+269'),
  CountryOption(code: 'TR', name: 'تركيا', dialCode: '+90'),
  CountryOption(code: 'US', name: 'الولايات المتحدة', dialCode: '+1'),
  CountryOption(code: 'CA', name: 'كندا', dialCode: '+1'),
  CountryOption(code: 'GB', name: 'المملكة المتحدة', dialCode: '+44'),
  CountryOption(code: 'DE', name: 'ألمانيا', dialCode: '+49'),
  CountryOption(code: 'FR', name: 'فرنسا', dialCode: '+33'),
  CountryOption(code: 'IT', name: 'إيطاليا', dialCode: '+39'),
  CountryOption(code: 'ES', name: 'إسبانيا', dialCode: '+34'),
  CountryOption(code: 'CH', name: 'سويسرا', dialCode: '+41'),
  CountryOption(code: 'NL', name: 'هولندا', dialCode: '+31'),
  CountryOption(code: 'SE', name: 'السويد', dialCode: '+46'),
  CountryOption(code: 'NO', name: 'النرويج', dialCode: '+47'),
  CountryOption(code: 'RU', name: 'روسيا', dialCode: '+7'),
  CountryOption(code: 'IN', name: 'الهند', dialCode: '+91'),
  CountryOption(code: 'PK', name: 'باكستان', dialCode: '+92'),
  CountryOption(code: 'BD', name: 'بنغلاديش', dialCode: '+880'),
  CountryOption(code: 'CN', name: 'الصين', dialCode: '+86'),
  CountryOption(code: 'JP', name: 'اليابان', dialCode: '+81'),
  CountryOption(code: 'KR', name: 'كوريا الجنوبية', dialCode: '+82'),
  CountryOption(code: 'MY', name: 'ماليزيا', dialCode: '+60'),
  CountryOption(code: 'SG', name: 'سنغافورة', dialCode: '+65'),
  CountryOption(code: 'ID', name: 'إندونيسيا', dialCode: '+62'),
  CountryOption(code: 'AU', name: 'أستراليا', dialCode: '+61'),
  CountryOption(code: 'BR', name: 'البرازيل', dialCode: '+55'),
  CountryOption(code: 'ZA', name: 'جنوب أفريقيا', dialCode: '+27'),
  CountryOption(code: 'NG', name: 'نيجيريا', dialCode: '+234'),
  CountryOption(code: 'MX', name: 'المكسيك', dialCode: '+52'),
];
