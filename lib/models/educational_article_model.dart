import 'dart:convert';

class EducationalArticleSummary {
  final int id;
  final String title;
  final String slug;
  final String excerpt;
  final String? category;
  final String? coverImageUrl;
  final String? publishedAt;
  final int readingMinutes;
  final bool isFeatured;

  const EducationalArticleSummary({
    required this.id,
    required this.title,
    required this.slug,
    required this.excerpt,
    required this.category,
    required this.coverImageUrl,
    required this.publishedAt,
    required this.readingMinutes,
    required this.isFeatured,
  });

  factory EducationalArticleSummary.fromJson(Map<String, dynamic> json) {
    return EducationalArticleSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: _normalizeApiText(json['title']),
      slug: (json['slug'] ?? '').toString(),
      excerpt: _normalizeApiText(json['excerpt']),
      category: _normalizeNullableApiText(_pickCategory(json)),
      coverImageUrl: json['cover_image_url']?.toString(),
      publishedAt: json['published_at']?.toString(),
      readingMinutes: (json['reading_minutes'] as num?)?.toInt() ?? 3,
      isFeatured: json['is_featured'] == true,
    );
  }
}

class EducationalArticleDetail {
  final int id;
  final String title;
  final String slug;
  final String? excerpt;
  final String body;
  final String? category;
  final String? coverImageUrl;
  final String? publishedAt;
  final int readingMinutes;
  final bool isFeatured;

  const EducationalArticleDetail({
    required this.id,
    required this.title,
    required this.slug,
    required this.excerpt,
    required this.body,
    required this.category,
    required this.coverImageUrl,
    required this.publishedAt,
    required this.readingMinutes,
    required this.isFeatured,
  });

  factory EducationalArticleDetail.fromJson(Map<String, dynamic> json) {
    return EducationalArticleDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: _normalizeApiText(json['title']),
      slug: (json['slug'] ?? '').toString(),
      excerpt: _normalizeNullableApiText(json['excerpt']),
      body: _normalizeApiText(json['body']),
      category: _normalizeNullableApiText(_pickCategory(json)),
      coverImageUrl: json['cover_image_url']?.toString(),
      publishedAt: json['published_at']?.toString(),
      readingMinutes: (json['reading_minutes'] as num?)?.toInt() ?? 3,
      isFeatured: json['is_featured'] == true,
    );
  }
}

Object? _pickCategory(Map<String, dynamic> json) {
  for (final key in <String>[
    'category',
    'category_name',
    'section',
    'section_name',
    'topic',
    'topic_name',
  ]) {
    final value = json[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value;
    }
  }
  return null;
}

String _normalizeApiText(Object? raw) {
  final value = (raw ?? '').toString().trim();
  if (value.isEmpty) return '';

  final cp1256Decoded = _decodeUtf8FromCp1256Mojibake(value);
  if (cp1256Decoded != null) return cp1256Decoded;

  final latin1Decoded = _decodeUtf8FromLatin1Mojibake(value);
  if (latin1Decoded != null) return latin1Decoded;

  return value;
}

String? _normalizeNullableApiText(Object? raw) {
  if (raw == null) return null;
  final value = _normalizeApiText(raw);
  return value.isEmpty ? null : value;
}

String? _decodeUtf8FromLatin1Mojibake(String value) {
  if (!_looksLikeLatinMojibake(value)) return null;
  if (value.codeUnits.any((unit) => unit > 0xFF)) return null;

  try {
    final decoded = utf8.decode(value.codeUnits, allowMalformed: false).trim();
    return _isDecodedTextBetter(original: value, decoded: decoded)
        ? decoded
        : null;
  } catch (_) {
    return null;
  }
}

String? _decodeUtf8FromCp1256Mojibake(String value) {
  if (!_looksLikeCp1256Mojibake(value)) return null;
  final bytes = _encodeToCp1256Bytes(value);
  if (bytes == null) return null;

  try {
    final decoded = utf8.decode(bytes, allowMalformed: false).trim();
    return _isDecodedTextBetter(original: value, decoded: decoded)
        ? decoded
        : null;
  } catch (_) {
    return null;
  }
}

List<int>? _encodeToCp1256Bytes(String value) {
  final bytes = <int>[];
  for (final rune in value.runes) {
    final mapped = _cp1256ByteFromRune(rune);
    if (mapped == null) return null;
    bytes.add(mapped);
  }
  return bytes;
}

int? _cp1256ByteFromRune(int rune) {
  if (rune >= 0x00 && rune <= 0x7F) return rune;
  if (rune >= 0xA0 && rune <= 0xFF) return rune;
  return _cp1256ReverseMap[rune];
}

bool _isDecodedTextBetter({
  required String original,
  required String decoded,
}) {
  if (decoded.isEmpty || decoded == original) return false;
  if (!_arabicCharPattern.hasMatch(decoded)) return false;
  if (_looksLikeLatinMojibake(decoded)) return false;
  if (_looksLikeCp1256Mojibake(decoded)) return false;
  return true;
}

bool _looksLikeLatinMojibake(String value) {
  return value.contains('\u00D8') ||
      value.contains('\u00D9') ||
      value.contains('\u00C3') ||
      value.contains('\u00C2') ||
      value.contains('\u00E2');
}

bool _looksLikeCp1256Mojibake(String value) {
  for (final token in _cp1256MojibakeTokens) {
    if (value.contains(token)) return true;
  }
  return _cp1256MojibakePattern.hasMatch(value);
}

final RegExp _arabicCharPattern = RegExp(r'[\u0600-\u06FF]');
final RegExp _cp1256MojibakePattern =
    RegExp(r'[\u0637\u0638][^\u0600-\u06FF\s]');

const List<String> _cp1256MojibakeTokens = <String>[
  '\u0637\u00A7',
  '\u0638\u201E',
  '\u0638\u2026',
  '\u0638\u2020',
  '\u0638\u0679',
  '\u0637\u00B9',
  '\u0637\u00A8',
  '\u0637\u00B1',
  '\u0637\u00AA',
  '\u0637\u00AF',
];

const Map<int, int> _cp1256ReverseMap = <int, int>{
  0x20AC: 0x80,
  0x067E: 0x81,
  0x201A: 0x82,
  0x0192: 0x83,
  0x201E: 0x84,
  0x2026: 0x85,
  0x2020: 0x86,
  0x2021: 0x87,
  0x02C6: 0x88,
  0x2030: 0x89,
  0x0679: 0x8A,
  0x2039: 0x8B,
  0x0152: 0x8C,
  0x0686: 0x8D,
  0x0698: 0x8E,
  0x0688: 0x8F,
  0x06AF: 0x90,
  0x2018: 0x91,
  0x2019: 0x92,
  0x201C: 0x93,
  0x201D: 0x94,
  0x2022: 0x95,
  0x2013: 0x96,
  0x2014: 0x97,
  0x06A9: 0x98,
  0x2122: 0x99,
  0x0691: 0x9A,
  0x203A: 0x9B,
  0x0153: 0x9C,
  0x200C: 0x9D,
  0x200D: 0x9E,
  0x06BA: 0x9F,
  0x060C: 0xA1,
  0x06BE: 0xAA,
  0x061B: 0xBA,
  0x061F: 0xBF,
  0x06C1: 0xC0,
  0x0621: 0xC1,
  0x0622: 0xC2,
  0x0623: 0xC3,
  0x0624: 0xC4,
  0x0625: 0xC5,
  0x0626: 0xC6,
  0x0627: 0xC7,
  0x0628: 0xC8,
  0x0629: 0xC9,
  0x062A: 0xCA,
  0x062B: 0xCB,
  0x062C: 0xCC,
  0x062D: 0xCD,
  0x062E: 0xCE,
  0x062F: 0xCF,
  0x0630: 0xD0,
  0x0631: 0xD1,
  0x0632: 0xD2,
  0x0633: 0xD3,
  0x0634: 0xD4,
  0x0635: 0xD5,
  0x0636: 0xD6,
  0x0637: 0xD8,
  0x0638: 0xD9,
  0x0639: 0xDA,
  0x063A: 0xDB,
  0x0640: 0xDC,
  0x0641: 0xDD,
  0x0642: 0xDE,
  0x0643: 0xDF,
  0x0644: 0xE1,
  0x0645: 0xE3,
  0x0646: 0xE4,
  0x0647: 0xE5,
  0x0648: 0xE6,
  0x0649: 0xEC,
  0x064A: 0xED,
  0x064B: 0xF0,
  0x064C: 0xF1,
  0x064D: 0xF2,
  0x064E: 0xF3,
  0x064F: 0xF5,
  0x0650: 0xF6,
  0x0651: 0xF8,
  0x0652: 0xFA,
  0x200E: 0xFD,
  0x200F: 0xFE,
  0x06D2: 0xFF,
};
