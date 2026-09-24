import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const _baseUrlKey = 'api_base_url';
  static const _defaultBaseUrl = 'http://10.0.2.2:3000';

  String _baseUrl = _defaultBaseUrl;

  String get baseUrl => _baseUrl;

  Future<void> init() async {
    final preferences = await SharedPreferences.getInstance();
    _baseUrl = preferences.getString(_baseUrlKey) ?? _defaultBaseUrl;
  }

  Future<void> setBaseUrl(String value) async {
    final normalized = value.trim().replaceFirst(RegExp(r'/+$'), '');
    if (Uri.tryParse(normalized)?.hasScheme != true) {
      throw const FormatException('服务器地址必须包含 http:// 或 https://');
    }

    _baseUrl = normalized;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_baseUrlKey, normalized);
  }

  Future<void> heartbeat({
    required String pairingCode,
    required String userId,
    required String userName,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/heartbeat'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'pairingCode': pairingCode,
            'userId': userId,
            'userName': userName,
          }),
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw Exception('heartbeat failed: ${response.statusCode}');
    }
  }

  Future<bool> isCompanionOnline({
    required String pairingCode,
    required String userId,
  }) async {
    final response = await http
        .get(
          Uri.parse(
            '$_baseUrl/api/pairs/${Uri.encodeComponent(pairingCode)}/status'
            '?userId=${Uri.encodeQueryComponent(userId)}',
          ),
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) return false;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['companionOnline'] == true;
  }
}
