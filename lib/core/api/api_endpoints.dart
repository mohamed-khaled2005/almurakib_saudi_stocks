import 'api_keys.dart';

class ApiEndpoints {
  static String _build(String endpoint, Map<String, String> params) {
    final qp = <String, String>{
      'token': ApiKeys.almurakibToken,
      'endpoint': endpoint,
      ...params,
    };

    return Uri.parse(ApiKeys.almurakibBaseUrl)
        .replace(queryParameters: qp)
        .toString();
  }

  // ✅ Indices Latest (TASI)
  static String indicesLatest({String? id, String? symbol}) {
    final params = <String, String>{};
    if (symbol != null && symbol.isNotEmpty) params['symbol'] = symbol;
    if (id != null && id.isNotEmpty) params['id'] = id;
    return _build('indices_latest', params);
  }

  // ✅ Stocks Latest
  static String latest({
    String? symbol,
    String? country,
    String? exchange,
    String? sector,
    String? sortBy,
    int? page,
    int? perPage,
    bool getProfile = true,
    String type = 'stock',
    String? subType,
  }) {
    final params = <String, String>{
      'get_profile': getProfile ? '1' : '0',
      'type': type,
    };

    if (subType != null && subType.isNotEmpty) {
      params['sub_type'] = subType;
    }

    if (symbol != null && symbol.isNotEmpty) params['symbol'] = symbol;
    if (country != null && country.isNotEmpty) params['country'] = country;
    if (exchange != null && exchange.isNotEmpty) params['exchange'] = exchange;
    if (sector != null && sector.isNotEmpty) params['sector'] = sector;
    if (sortBy != null && sortBy.isNotEmpty) params['sort_by'] = sortBy;
    if (page != null) params['page'] = page.toString();
    if (perPage != null) params['per_page'] = perPage.toString();

    return _build('latest', params);
  }

  // ✅ Stock List
  static String list({required String country, int perPage = 500, int page = 1}) {
    return _build('list', {
      'country': country,
      'per_page': perPage.toString(),
      'page': page.toString(),
    });
  }

  static const Set<String> _validHistoryPeriods = {
    '1m',
    '5m',
    '15m',
    '30m',
    '1h',
    '4h',
    '1d',
    '1w',
    '1month',
    '1',
    '5',
    '15',
    '30',
    '60',
    '240',
    '1440',
    '10080',
  };

  static String _sanitizeHistoryPeriod(String p) {
    final t = p.trim();
    if (t.isEmpty) return '1d';

    if (_validHistoryPeriods.contains(t)) return t;

    final low = t.toLowerCase();
    if (_validHistoryPeriods.contains(low)) return low;

    // تحويلات شائعة
    if (t == '1M' || low == '1mo' || low == '1mon') return '1month';

    // أي قيمة غير صالحة -> يومي
    return '1d';
  }

  // ✅ History
  static String history({
    required String symbol,
    String period = '1d',
    int length = 300,
  }) {
    final safePeriod = _sanitizeHistoryPeriod(period);
    return _build('history', {
      'symbol': symbol,
      'period': safePeriod,
      'length': length.toString(),
    });
  }

  // ✅ Indicators (AlMurakib)
  static String indicators({required String symbol}) {
    return _build('indicators', {'symbol': symbol});
  }

  // ✅ Performance (NEW)
  static String performance({required String symbol}) {
    return _build('performance', {'symbol': symbol});
  }
}
