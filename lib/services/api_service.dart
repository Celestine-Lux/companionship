import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  Future<void> heartbeat({
    required String pairingCode,
    required String userId,
    required String userName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/heartbeat'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'pairingCode': pairingCode,
        'userId': userId,
        'userName': userName,
      }),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw Exception('heartbeat failed: ${response.statusCode}');
    }
  }

  Future<bool> isCompanionOnline({
    required String pairingCode,
    required String userId,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/pairs/${Uri.encodeComponent(pairingCode)}/status'
        '?userId=${Uri.encodeQueryComponent(userId)}',
      ),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) return false;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['companionOnline'] == true;
  }
}
