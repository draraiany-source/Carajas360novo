/// Voz ausente (plataformas sem Web Speech e sem os plugins).
class TiaVoice {
  bool listening = false;
  bool speaking = false;
  bool audioEnabled = true;
  String? limitation =
      'Reconhecimento de fala e voz não estão disponíveis nesta plataforma.';

  bool get canListen => false;
  bool get canSpeak => false;

  Future<bool> startListening(void Function(String text, bool isFinal) onText) async =>
      false;

  Future<void> stopListening() async {}

  Future<void> speak(String text) async {}

  Future<void> stopSpeaking() async {}

  void setAudioEnabled(bool value) => audioEnabled = value;

  void dispose() {}
}
