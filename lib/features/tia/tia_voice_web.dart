import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Web Speech API no navegador. O áudio não sai do aparelho.
class TiaVoice {
  JSObject? _rec;
  bool listening = false;
  bool speaking = false;
  bool audioEnabled = true;
  String? limitation;

  bool get canListen =>
      globalContext.has('SpeechRecognition') ||
      globalContext.has('webkitSpeechRecognition');

  bool get canSpeak => globalContext.has('speechSynthesis');

  Future<bool> startListening(void Function(String text, bool isFinal) onText) async {
    if (!canListen) {
      limitation = 'Este navegador não expõe reconhecimento de fala.';
      return false;
    }
    final ctor = (globalContext.has('SpeechRecognition')
        ? globalContext['SpeechRecognition']
        : globalContext['webkitSpeechRecognition']) as JSFunction;
    final rec = ctor.callAsConstructor<JSObject>();
    rec['lang'] = 'pt-BR'.toJS;
    rec['interimResults'] = true.toJS;
    rec['continuous'] = false.toJS;
    rec['onresult'] = ((JSObject event) {
      final results = event['results'] as JSObject?;
      if (results == null) return;
      final index = (event['resultIndex'] as JSNumber?)?.toDartInt ?? 0;
      final row = results[index.toString()] as JSObject?;
      if (row == null) return;
      final alt = row['0'] as JSObject?;
      final transcript = (alt?['transcript'] as JSString?)?.toDart ?? '';
      final isFinal = (row['isFinal'] as JSBoolean?)?.toDart ?? false;
      onText(transcript, isFinal);
    }).toJS;
    rec['onerror'] = ((JSObject event) {
      final code = (event['error'] as JSString?)?.toDart ?? 'erro';
      limitation = code == 'not-allowed'
          ? 'Permissão do microfone negada pelo navegador.'
          : 'Falha no microfone ($code).';
      listening = false;
    }).toJS;
    rec['onend'] = (() {
      listening = false;
    }).toJS;
    try {
      rec.callMethod('start'.toJS);
      _rec = rec;
      listening = true;
      limitation = null;
      return true;
    } catch (_) {
      limitation = 'Não foi possível abrir o microfone.';
      return false;
    }
  }

  Future<void> stopListening() async {
    listening = false;
    try {
      _rec?.callMethod('stop'.toJS);
    } catch (_) {}
  }

  Future<void> speak(String text) async {
    if (!audioEnabled || !canSpeak || text.trim().isEmpty) return;
    final synth = globalContext['speechSynthesis'] as JSObject;
    final utteranceCtor = globalContext['SpeechSynthesisUtterance'] as JSFunction;
    final utter = utteranceCtor.callAsConstructor<JSObject>(text.toJS);
    utter['lang'] = 'pt-BR'.toJS;
    utter['rate'] = 1.0.toJS;
    final voices = synth.callMethod<JSObject>('getVoices'.toJS);
    final length = (voices['length'] as JSNumber?)?.toDartInt ?? 0;
    for (var i = 0; i < length; i++) {
      final voice = voices[i.toString()] as JSObject?;
      final lang = (voice?['lang'] as JSString?)?.toDart ?? '';
      final name = (voice?['name'] as JSString?)?.toDart ?? '';
      if (lang.toLowerCase().startsWith('pt') &&
          (name.toLowerCase().contains('female') ||
              name.toLowerCase().contains('femin') ||
              name.toLowerCase().contains('luciana') ||
              name.toLowerCase().contains('francisca'))) {
        utter['voice'] = voice!;
        break;
      }
    }
    utter['onend'] = (() {
      speaking = false;
    }).toJS;
    speaking = true;
    synth.callMethod('cancel'.toJS);
    synth.callMethod('speak'.toJS, utter);
  }

  Future<void> stopSpeaking() async {
    speaking = false;
    if (!canSpeak) return;
    try {
      (globalContext['speechSynthesis'] as JSObject).callMethod('cancel'.toJS);
    } catch (_) {}
  }

  void setAudioEnabled(bool value) {
    audioEnabled = value;
    if (!value) stopSpeaking();
  }

  void dispose() {
    stopListening();
    stopSpeaking();
  }
}
