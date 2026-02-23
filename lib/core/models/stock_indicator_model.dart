import '../utils/server_time_utils.dart';

class StockIndicatorModel {
  final Map<String, IndicatorValue> indicators;
  final String overallSummary;
  final int totalBuy;
  final int totalSell;
  final int totalNeutral;
  final DateTime? serverTimeUtc;

  StockIndicatorModel({
    required this.indicators,
    required this.overallSummary,
    required this.totalBuy,
    required this.totalSell,
    required this.totalNeutral,
    this.serverTimeUtc,
  });

  factory StockIndicatorModel.fromJson(Map<String, dynamic> json) {
    final resp = json['response'];
    final info = json['info'] is Map
        ? Map<String, dynamic>.from(json['info'])
        : <String, dynamic>{};
    final serverTimeUtc = ServerTimeUtils.parseToUtc(info['server_time']);

    // =========================
    // ✅ Format A: response is List<Map> (generic list response)
    // =========================
    if (resp is List && resp.isNotEmpty && resp.first is Map) {
      final first = Map<String, dynamic>.from(resp.first);

      final signalMap = first['signal'] is Map
          ? Map<String, dynamic>.from(first['signal'])
          : <String, dynamic>{};

      final overall = (signalMap['summary'] ?? 'Neutral').toString();

      final parsed = <String, IndicatorValue>{};
      int buy = 0, sell = 0, neutral = 0;

      void addSignalCount(String s) {
        final v = s.toLowerCase().trim();
        if (v.contains('buy')) {
          buy++;
        } else if (v.contains('sell')) {
          sell++;
        } else {
          neutral++;
        }
      }

      String normKey(String k) {
        final kk = k.toLowerCase();
        const map = {
          'rsi': 'RSI14',
          'stoch': 'STOCH9_6',
          'stochrsi': 'STOCHRSI14',
          'macd': 'MACD12_26',
          'williamsr': 'WilliamsR',
          'cci': 'CCI14',
          'atr': 'ATR14',
          'uo': 'UltimateOscillator',
          'roc': 'ROC',
          'bullbearpower': 'BullBearPower',
          'adx': 'ADX14',
          'psar': 'ParabolicSAR',
        };
        return map[kk] ?? k;
      }

      void extract(dynamic group) {
        if (group is! Map) return;
        final g = Map<String, dynamic>.from(group);
        for (final entry in g.entries) {
          final v = entry.value;
          if (v is Map) {
            final m = Map<String, dynamic>.from(v);
            if (m.containsKey('v') && m.containsKey('s')) {
              final key = normKey(entry.key.toString());
              final val = _parseDouble(m['v']);
              final sig = m['s']?.toString() ?? 'Neutral';
              parsed[key] = IndicatorValue(value: val, signal: sig);
              addSignalCount(sig);
            }
          }
        }
      }

      extract(first['oscillators']);
      extract(first['moving_averages']);

      return StockIndicatorModel(
        indicators: parsed,
        overallSummary: overall,
        totalBuy: buy,
        totalSell: sell,
        totalNeutral: neutral,
        serverTimeUtc: serverTimeUtc,
      );
    }

    // =========================
    // ✅ Format B: response is Map (expected)
    // response: { indicators:{...}, count:{...}, overall:{summary:...} }
    // =========================
    final response =
        resp is Map ? Map<String, dynamic>.from(resp) : <String, dynamic>{};

    final indicatorsData = response['indicators'] is Map
        ? Map<String, dynamic>.from(response['indicators'])
        : <String, dynamic>{};

    final count = response['count'] is Map
        ? Map<String, dynamic>.from(response['count'])
        : <String, dynamic>{};

    String overall = 'Neutral';
    final overallObj = response['overall'];
    if (overallObj is Map) {
      overall = (overallObj['summary'] ?? overallObj['signal'] ?? 'Neutral')
          .toString();
    } else if (overallObj is String) {
      overall = overallObj;
    }

    final parsedIndicators = <String, IndicatorValue>{};

    indicatorsData.forEach((key, value) {
      if (value is Map) {
        final m = Map<String, dynamic>.from(value);
        if (m.containsKey('v') && m.containsKey('s')) {
          parsedIndicators[key.toString()] = IndicatorValue(
            value: _parseDouble(m['v']),
            signal: m['s']?.toString() ?? 'Neutral',
          );
        }
      }
    });

    return StockIndicatorModel(
      indicators: parsedIndicators,
      overallSummary: overall,
      totalBuy: _parseInt(count['Total_Buy']),
      totalSell: _parseInt(count['Total_Sell']),
      totalNeutral: _parseInt(count['Total_Neutral']),
      serverTimeUtc: serverTimeUtc,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }
}

class IndicatorValue {
  final double value;
  final String signal;

  IndicatorValue({required this.value, required this.signal});

  String get arabicSignal {
    switch (signal.toLowerCase()) {
      case 'buy':
      case 'strong buy':
        return 'شراء';
      case 'sell':
      case 'strong sell':
        return 'بيع';
      default:
        return 'محايد';
    }
  }
}
