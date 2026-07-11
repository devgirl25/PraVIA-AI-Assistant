import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

/// Wraps device speech-to-text (listening) and text-to-speech (speaking)
/// behind a single simple API for the assistant's home screen.
class SpeechService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isInitialized = false;

  /// Must be called once (e.g. in initState) before [startListening].
  /// Returns true if the device supports speech recognition and the
  /// user granted the RECORD_AUDIO permission.
  Future<bool> initialize() async {
    _isInitialized = await _speechToText.initialize(
      onError: (error) => print('SpeechService error: $error'),
      onStatus: (status) => print('SpeechService status: $status'),
    );

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);

    return _isInitialized;
  }

  bool get isListening => _speechToText.isListening;
  bool get isAvailable => _isInitialized;

  /// Starts listening for a single voice command. [onResult] is called
  /// with the live/final transcribed text; check `result.finalResult`
  /// if you only want to react once the user has stopped speaking.
  Future<void> startListening({
    required Function(String recognizedText, bool isFinal) onResult,
    Duration listenFor = const Duration(seconds: 15),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return;
    }

    await _speechToText.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      listenFor: listenFor,
      pauseFor: pauseFor,
      localeId: 'en_US',
    );
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  /// Speaks [text] aloud via TTS.
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _tts.stop(); // Cancel anything currently being spoken.
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }
}
