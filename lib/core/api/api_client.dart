import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static Future<Map<String, dynamic>> get(String url) async {
    try {
      print('🔄 GET: $url');

      final response = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('انتهت مهلة الاتصال بالخادم'),
          );

      print('📡 Status: ${response.statusCode}');

      // نحاول نفك JSON حتى لو statusCode != 200 عشان نطلع msg
      Map<String, dynamic>? decoded;
      try {
        final dynamic tmp = json.decode(response.body);
        if (tmp is Map<String, dynamic>) decoded = tmp;
      } catch (_) {
        decoded = null;
      }

      if (response.statusCode != 200) {
        final msg = decoded?['msg']?.toString();
        throw Exception(msg ?? 'HTTP Error: ${response.statusCode}');
      }

      if (decoded == null) {
        throw Exception('صيغة رد غير متوقعة من السيرفر');
      }

      final status = decoded['status'];
      if (status == false) {
        final msg = decoded['msg']?.toString() ?? 'فشل الطلب';
        throw Exception(msg);
      }

      return decoded;
    } catch (e) {
      print('❌ ApiClient error: $e');
      rethrow;
    }
  }
}
