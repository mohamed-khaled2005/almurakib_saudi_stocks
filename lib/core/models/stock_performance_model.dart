import '../utils/server_time_utils.dart';

class StockPerformanceModel {
  final String ticker;
  final Map<String, dynamic> perf;
  final String? serverTime;
  final DateTime? serverTimeUtc;

  const StockPerformanceModel({
    required this.ticker,
    required this.perf,
    this.serverTime,
    this.serverTimeUtc,
  });

  factory StockPerformanceModel.fromJson(Map<String, dynamic> json) {
    final resp = json['response'];
    if (resp is! List || resp.isEmpty) {
      throw Exception('لا توجد بيانات أداء متاحة');
    }

    final first = resp.first;
    if (first is! Map) throw Exception('صيغة response غير متوقعة');

    final map = Map<String, dynamic>.from(first);
    final t = (map['ticker'] ?? '').toString();

    final perfRaw = map['perf'];
    final perfMap = perfRaw is Map
        ? Map<String, dynamic>.from(perfRaw)
        : <String, dynamic>{};

    final info = json['info'];
    final infoMap =
        info is Map ? Map<String, dynamic>.from(info) : <String, dynamic>{};
    final serverTime = infoMap['server_time']?.toString();
    final serverTimeUtc = ServerTimeUtils.parseToUtc(serverTime);

    return StockPerformanceModel(
      ticker: t,
      perf: perfMap,
      serverTime: serverTime,
      serverTimeUtc: serverTimeUtc,
    );
  }

  double? getNum(String key) {
    final v = perf[key];
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString().trim();
    return double.tryParse(s);
  }
}
