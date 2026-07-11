import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/intent_model.dart';
import 'local_intent_parser.dart';

/// Talks to the PraVIA FastAPI backend. Falls back to a local on-device
/// intent parser if the backend is unreachable, so voice commands still
/// work offline (Phase 1 requirement: app should work like a mini
/// Jarvis without depending on network availability for basic actions).
class ApiClient {
  /// Android emulator special-cases 10.0.2.2 to reach the host machine's
  /// localhost. Change this to your LAN IP (e.g. 192.168.1.x) when
  /// testing on a physical device, or your deployed backend URL in prod.
  static const String baseUrl = 'http://10.0.2.2:8000';

  final LocalIntentParser _localParser = LocalIntentParser();

  Future<IntentModel> parseIntent(String text) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/intent'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return IntentModel.fromJson(json);
      }
    } catch (_) {
      // Network/backend unavailable — fall through to local parser.
    }

    return _localParser.parse(text);
  }

  /// Logs a sent SMS to the backend history (best-effort, ignored on failure
  /// since the app also keeps its own local Hive history).
  Future<void> logMessage({required String receiver, required String message}) async {
    try {
      await http
          .post(
            Uri.parse('$baseUrl/api/messages/log'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'receiver': receiver, 'message': message}),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      // Best-effort only.
    }
  }
}
