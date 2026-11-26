import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// API de gravação de voz do chat (mobile/desktop).
class ChatVoice {
  static final _recorder = AudioRecorder();

  static Future<bool> hasPermission() => _recorder.hasPermission();

  static Future<String?> start() async {
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    return path;
  }

  static Future<String?> stop() => _recorder.stop();

  static Future<List<int>?> readBytes(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }
}
