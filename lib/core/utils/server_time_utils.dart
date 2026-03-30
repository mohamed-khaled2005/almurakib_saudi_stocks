class ServerTimeUtils {
  static DateTime? parseToUtc(dynamic raw) {
    if (raw == null) return null;

    if (raw is DateTime) {
      return raw.isUtc ? raw : raw.toUtc();
    }

    if (raw is num) {
      final n = raw.toInt();
      if (n >= 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(n, isUtc: true).toUtc();
      }
      if (n >= 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(n * 1000, isUtc: true)
            .toUtc();
      }
      return null;
    }

    final s = raw.toString().trim();
    if (s.isEmpty) return null;

    final asInt = int.tryParse(s);
    if (asInt != null) {
      return parseToUtc(asInt);
    }

    final normalized =
        (s.contains(' ') && !s.contains('T')) ? s.replaceFirst(' ', 'T') : s;

    final hasZone = RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(normalized);
    final fixed = hasZone ? normalized : '${normalized}Z';

    final dt = DateTime.tryParse(fixed);
    if (dt == null) return null;
    return dt.toUtc();
  }

  static DateTime? pickLatest(Iterable<DateTime?> values) {
    DateTime? best;
    for (final v in values) {
      if (v == null) continue;
      final utc = v.isUtc ? v : v.toUtc();
      if (best == null || utc.isAfter(best)) best = utc;
    }
    return best;
  }

  static String formatLocalDateTime(DateTime utc) {
    final local = utc.isUtc ? utc.toLocal() : utc.toLocal();
    return '${local.year}/${_two(local.month)}/${_two(local.day)} '
        '${_two(local.hour)}:${_two(local.minute)}';
  }

  static String gmtOffsetLabel(DateTime dt) {
    final local = dt.toLocal();
    final off = local.timeZoneOffset;
    final sign = off.isNegative ? '-' : '+';
    final h = off.inHours.abs();
    final m = off.inMinutes.abs() % 60;
    return m == 0 ? 'GMT$sign$h' : 'GMT$sign$h:${_two(m)}';
  }

  static String formatLastUpdate(
    DateTime? utc, {
    bool includeTimeZone = true,
  }) {
    if (utc == null) return '--';
    final local = utc.isUtc ? utc.toLocal() : utc.toLocal();
    final formatted = formatLocalDateTime(utc);
    if (!includeTimeZone) return formatted;
    return '$formatted (${gmtOffsetLabel(local)})';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
