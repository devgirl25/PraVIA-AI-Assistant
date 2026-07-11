import '../models/intent_model.dart';

/// On-device fallback intent parser. Mirrors the rule-based logic in
/// `backend/ai/intent_parser.py` so the assistant still works for core
/// commands (open app, call, sms) even with zero connectivity.
///
/// This intentionally covers only Phase 1 intents; expense/trading
/// voice parsing is handled server-side (Phase 2/3) since those need
/// richer NLP than a quick regex fallback justifies.
class LocalIntentParser {
  IntentModel parse(String rawText) {
    final text = rawText.trim().toLowerCase().replaceAll(RegExp(r'[.!?]+$'), '');

    // --- SEND_SMS ---
    final smsMatch = RegExp(
      r'^(?:message|text)\s+([a-z ]+?)\s+(?:saying|that|to say)\s+(.+)$',
    ).firstMatch(text);
    if (smsMatch != null) {
      return IntentModel(
        intent: IntentType.sendSms,
        parameters: {
          'contact': _titleCase(smsMatch.group(1)!.trim()),
          'message': _capitalize(smsMatch.group(2)!.trim()),
        },
      );
    }

    final sendSmsMatch = RegExp(
      r'^send\s+(?:sms|message|text)\s+to\s+([a-z ]+?)\s+(?:saying|that|to say)\s+(.+)$',
    ).firstMatch(text);
    if (sendSmsMatch != null) {
      return IntentModel(
        intent: IntentType.sendSms,
        parameters: {
          'contact': _titleCase(sendSmsMatch.group(1)!.trim()),
          'message': _capitalize(sendSmsMatch.group(2)!.trim()),
        },
      );
    }

    // --- MAKE_CALL ---
    final callMatch = RegExp(r'^(?:call|phone|dial)\s+(.+)$').firstMatch(text);
    if (callMatch != null) {
      return IntentModel(
        intent: IntentType.makeCall,
        parameters: {'contact': _titleCase(callMatch.group(1)!.trim())},
      );
    }

    // --- MUSIC ---
    if (RegExp(r'^(pause|stop)(\s+music)?$').hasMatch(text)) {
      return const IntentModel(intent: IntentType.pauseMusic, parameters: {});
    }
    if (RegExp(r'^(next|skip)(\s+track|\s+song)?$').hasMatch(text)) {
      return const IntentModel(intent: IntentType.nextTrack, parameters: {});
    }
    if (RegExp(r'^(previous|back|last)(\s+track|\s+song)?$').hasMatch(text)) {
      return const IntentModel(intent: IntentType.previousTrack, parameters: {});
    }
    final playMatch = RegExp(r'^play\s+(?:my\s+)?(.+)$').firstMatch(text);
    if (playMatch != null) {
      return IntentModel(
        intent: IntentType.playMusic,
        parameters: {'query': playMatch.group(1)!.trim()},
      );
    }

    // --- OPEN_APP (checked last: broad catch-all "open X") ---
    final openMatch = RegExp(r'^(?:open|launch|start)\s+(.+)$').firstMatch(text);
    if (openMatch != null) {
      return IntentModel(
        intent: IntentType.openApp,
        parameters: {'app': _titleCase(openMatch.group(1)!.trim())},
      );
    }

    return IntentModel(
      intent: IntentType.unknown,
      parameters: {'raw_text': rawText},
      confidence: 0.0,
    );
  }

  String _titleCase(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
