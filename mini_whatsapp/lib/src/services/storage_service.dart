import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';

class StorageService {
  // 🔥 Cloudinary config (hard-coded – no .env needed)
  static const String cloudName = "dhe0pkz7a";
  static const String uploadPreset = "flutter_unsigned";

  final uuid = const Uuid();

  /// Upload audio file to Cloudinary
  Future<String> uploadVoiceFile(File file, String chatId) async {
    try {
      final fileName = "voice_${uuid.v4()}.aac";

      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/video/upload",
      );

      final request = http.MultipartRequest("POST", uri)
        ..fields["upload_preset"] = uploadPreset
        ..fields["folder"] = "mini_whatsapp/$chatId"
        ..files.add(
          await http.MultipartFile.fromPath(
            "file",
            file.path,
            filename: fileName,
          ),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json["secure_url"];
      } else {
        throw Exception("Cloudinary Upload Failed: ${response.body}");
      }
    } catch (e) {
      throw Exception("Upload error: $e");
    }
  }
}
