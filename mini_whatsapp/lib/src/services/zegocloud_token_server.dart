import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Handles requesting a Zego token from your Node.js backend.
class ZegoTokenClient {
  final String baseUrl;

  const ZegoTokenClient({
    this.baseUrl = AppConfig.tokenServerBaseUrl,
  });

  /// Requests token from Node:  POST /zego/token { uid }
  Future<String> getTokenForUser(String uid) async {
    final url = Uri.parse("$baseUrl/zego/token");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"uid": uid}),
      );

      if (response.statusCode != 200) {
        throw Exception(
          "Server error: ${response.statusCode}\n${response.body}",
        );
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (!data.containsKey("signature") || data["signature"] == null) {
        throw Exception("Invalid backend response: token missing");
      }

      return data["signature"].toString();
    } catch (e) {
      throw Exception("Zego token fetch failed: $e");
    }
  }
}
