import '../utils/server_time_utils.dart';

class TasiIndexModel {
  final double value;
  final double change;
  final double changePercent;
  final DateTime? updateTimeUtc;

  TasiIndexModel({
    required this.value,
    required this.change,
    required this.changePercent,
    this.updateTimeUtc,
  });

  factory TasiIndexModel.fromJson(Map<String, dynamic> data) {
    final resp = data['response'];
    if (resp is! List || resp.isEmpty) {
      throw Exception('لا توجد بيانات لمؤشر تاسي');
    }

    final first = resp.first as Map<String, dynamic>;
    final active =
        (first['active'] is Map) ? (first['active'] as Map) : const {};
    final info = data['info'] is Map ? (data['info'] as Map) : const {};
    final utc = ServerTimeUtils.pickLatest([
      ServerTimeUtils.parseToUtc(first['update']),
      ServerTimeUtils.parseToUtc(first['updateTime']),
      ServerTimeUtils.parseToUtc(first['tm']),
      ServerTimeUtils.parseToUtc(active['update']),
      ServerTimeUtils.parseToUtc(active['updateTime']),
      ServerTimeUtils.parseToUtc(info['server_time']),
    ]);

    return TasiIndexModel(
      value: _parseDouble(active['c']),
      change: _parseDouble(active['ch']),
      changePercent: _parseDouble(active['chp']),
      updateTimeUtc: utc,
    );
  }

  bool get isGain => change >= 0;

  // ✅ سوق السعودية UTC+3 / الأحد-الخميس / 10:00-15:00
  bool get isOpen {
    final nowRiyadh = DateTime.now().toUtc().add(const Duration(hours: 3));
    final weekday = nowRiyadh.weekday; // 1=Mon ... 7=Sun
    final isBusinessDay =
        weekday >= DateTime.sunday && weekday <= DateTime.thursday;
    if (!isBusinessDay) return false;

    final minutes = nowRiyadh.hour * 60 + nowRiyadh.minute;
    final open = 10 * 60; // 10:00
    final close = 15 * 60; // 15:00
    return minutes >= open && minutes <= close;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
