class StockHistoryCandle {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  StockHistoryCandle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  factory StockHistoryCandle.fromMap(Map<String, dynamic> m) {
    final t = m['t']; // unix seconds
    final sec = (t is int) ? t : int.tryParse(t?.toString() ?? '') ?? 0;
    final time = DateTime.fromMillisecondsSinceEpoch(sec * 1000, isUtc: true).toLocal();

    return StockHistoryCandle(
      time: time,
      open: _d(m['o']),
      high: _d(m['h']),
      low: _d(m['l']),
      close: _d(m['c']),
      volume: _d(m['v']),
    );
  }
}
