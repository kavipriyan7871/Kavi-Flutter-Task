import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class RecorderUtil {
  FlutterSoundRecorder? _recorder;
  bool _isInit = false;
  String? _filePath;

  /// MUST be called in initState()
  Future<void> init() async {
    if (_isInit) return;

    // Only microphone permission required
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      throw Exception("Microphone permission not granted");
    }

    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();

    _isInit = true;
  }

  /// Start Recording
  Future<void> start() async {
    if (!_isInit) await init();

    final temp = await getTemporaryDirectory();
    _filePath =
        "${temp.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac";

    await _recorder!.startRecorder(
      toFile: _filePath,
      codec: Codec.aacADTS,
    );
  }

  /// Stop Recording
  Future<File?> stop() async {
    if (!_isInit) return null;

    await _recorder!.stopRecorder();

    if (_filePath == null) return null;

    final f = File(_filePath!);
    return f.existsSync() ? f : null;
  }

  /// Cleanup
  void dispose() {
    if (_isInit) {
      _recorder!.closeRecorder();
      _isInit = false;
    }
  }
}
