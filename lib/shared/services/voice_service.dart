import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Platform adapter for speech recognition and text to speech.
///
/// Unsupported platforms return false so the chat flow remains usable.
class VoiceService {
  VoiceService({SpeechToText? speech, FlutterTts? tts})
      : _speech = speech ?? SpeechToText(),
        _tts = tts ?? FlutterTts();

  final SpeechToText _speech;
  final FlutterTts _tts;
  bool _initialized = false;

  bool get isListening => _speech.isListening;

  Future<bool> startListening({
    required void Function(String text) onText,
    void Function(bool listening)? onListeningChanged,
  }) async {
    try {
      if (!_initialized) {
        _initialized = await _speech.initialize(
          onStatus: (String status) {
            onListeningChanged?.call(status == SpeechToText.listeningStatus);
          },
          onError: (_) {
            onListeningChanged?.call(false);
          },
        );
      }
      if (!_initialized) {
        return false;
      }
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) =>
            onText(result.recognizedWords),
        partialResults: true,
        listenMode: ListenMode.dictation,
      );
      onListeningChanged?.call(true);
      return true;
    } catch (_) {
      onListeningChanged?.call(false);
      return false;
    }
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {
      // Unsupported platforms are handled as an already-stopped session.
    }
  }

  Future<bool> speak(String text) async {
    final String content = text.trim();
    if (content.isEmpty) {
      return false;
    }
    try {
      await _tts.setLanguage('zh-CN');
      await _tts.speak(content);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Unsupported platforms are handled as an already-stopped session.
    }
  }
}
