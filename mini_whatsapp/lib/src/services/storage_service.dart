import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';

class StorageService {
  // 🔥 Cloudinary Config
  static const String cloudName = "dhe0pkz7a"; // your cloud name
  static const String uploadPreset = "flutter_unsigned"; // unsigned preset

  final uuid = const Uuid();

  // ---------------------------------------------------------------------------
  // 📌 Upload ANY File (Image / Video)
  // ---------------------------------------------------------------------------
  Future<String> uploadAnyFile(File file, String chatId) async {
    try {
      final fileName = "file_${uuid.v4()}";

      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/auto/upload",
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

      final streamedRes = await request.send();
      final res = await http.Response.fromStream(streamedRes);

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        return json["secure_url"];
      } else {
        throw Exception("Cloudinary Upload Failed: ${res.body}");
      }
    } catch (e) {
      throw Exception("Upload error: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // 🎤 Upload VOICE message only (AAC format)
  // ---------------------------------------------------------------------------
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

      final streamedRes = await request.send();
      final res = await http.Response.fromStream(streamedRes);

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        return json["secure_url"];
      } else {
        throw Exception("Cloudinary Upload Failed: ${res.body}");
      }
    } catch (e) {
      throw Exception("Voice Upload Error: $e");
    }
  }
}
