import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Voz no aparelho (Android, iOS e desktop com plugin). Sem envio de áudio ao servidor.
class TiaVoice {
  SpeechToText? _stt;
  FlutterTts? _tts;
  bool listening = false;
  bool speaking = false;
  bool audioEnabled = true;
  String? limitation;
  bool _ready = false;

  bool get canListen => limitation == null;
  bool get canSpeak => true;

  Future<bool> startListening(void Function(String text, bool isFinal) onText) async {
    try {
      _stt ??= SpeechToText();
      _ready = await _stt!.initialize(
        onError: (error) => limitation = 'Microfone: ${error.errorMsg}',
        onStatus: (status) {
          listening = status == 'listening';
        },
      );
      if (!_ready) {
        limitation ??= 'Permissão do microfone negada ou reconhecimento indisponível.';
        return false;
      }
      limitation = null;
      listening = true;
      await _stt!.listen(
        listenOptions: SpeechListenOptions(localeId: 'pt_BR'),
        onResult: (result) => onText(result.recognizedWords, result.finalResult),
      );
      return true;
    } catch (e) {
      limitation = 'Reconhecimento de fala indisponível neste aparelho.';
      listening = false;
      return false;
    }
  }

  Future<void> stopListening() async {
    listening = false;
    try {
      await _stt?.stop();
    } catch (_) {}
  }

  Future<void> speak(String text) async {
    if (!audioEnabled || text.trim().isEmpty) return;
    try {
      _tts ??= FlutterTts();
      await _tts!.setLanguage('pt-BR');
      await _tts!.setSpeechRate(0.48);
      await _tts!.setPitch(1.05);
      await _tts!.setVolume(1.0);
      speaking = true;
      await _tts!.speak(text);
    } catch (_) {
      limitation = 'A leitura em voz não está disponível neste aparelho.';
    } finally {
      speaking = false;
    }
  }

  Future<void> stopSpeaking() async {
    speaking = false;
    try {
      await _tts?.stop();
    } catch (_) {}
  }

  void setAudioEnabled(bool value) {
    audioEnabled = value;
    if (!value) {
      stopSpeaking();
    }
  }

  void dispose() {
    stopListening();
    stopSpeaking();
  }
}
