// lib/services/zegocloud_token_server.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ZegoTokenClient {
  final String baseUrl;

  const ZegoTokenClient({this.baseUrl = AppConfig.tokenServerBaseUrl});

  /// Fetch Zego token from your Node.js backend
  Future<String> getTokenForUser(String uid) async {
    final uri = Uri.parse("$baseUrl/zego/token");

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"uid": uid}),
      );

      if (response.statusCode != 200) {
        throw Exception(
          "❌ Server error: ${response.statusCode}\n${response.body}",
        );
      }

      final data = jsonDecode(response.body);

      // Validate response
      if (!data.containsKey("signature")) {
        throw Exception("❌ Token is missing in backend response");
      }

      // Return ONLY Zego token
      return data["signature"].toString();
    } catch (e) {
      throw Exception("❌ Failed to fetch token: $e");
    }
  }
}
