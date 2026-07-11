import '../models/intent_model.dart';
import '../services/app_controller.dart';
import '../services/contact_service.dart';
import '../services/sms_service.dart';
import '../services/api_client.dart';

/// Central place that takes a parsed [IntentModel] and actually performs
/// the corresponding action on the phone, returning a human-readable
/// response string for chat display + TTS playback.
///
/// This is deliberately kept UI-agnostic (no BuildContext, no widgets)
/// so it can be unit-tested and reused across screens.
class IntentExecutor {
  final AppController appController;
  final ContactService contactService;
  final SmsService smsService;
  final ApiClient apiClient;

  IntentExecutor({
    AppController? appController,
    ContactService? contactService,
    SmsService? smsService,
    ApiClient? apiClient,
  })  : appController = appController ?? AppController(),
        contactService = contactService ?? ContactService(),
        smsService = smsService ?? SmsService(),
        apiClient = apiClient ?? ApiClient();

  /// Executes [intent] and returns a response string suitable for both
  /// the chat transcript and text-to-speech.
  Future<String> execute(IntentModel intent) async {
    switch (intent.intent) {
      case IntentType.openApp:
        return _handleOpenApp(intent.parameters);

      case IntentType.makeCall:
        return _handleMakeCall(intent.parameters);

      case IntentType.sendSms:
        return _handleSendSms(intent.parameters);

      case IntentType.playMusic:
      case IntentType.pauseMusic:
      case IntentType.nextTrack:
      case IntentType.previousTrack:
        // Wired up fully in Phase 4 (Music Assistant).
        return "Music control is coming in a later phase!";

      case IntentType.addExpense:
      case IntentType.showExpenses:
        // Wired up fully in Phase 2 (Expense Tracker).
        return "Expense tracking is coming in a later phase!";

      case IntentType.addTrade:
      case IntentType.showTradingStats:
        // Wired up fully in Phase 3 (Trading Journal).
        return "Trading journal is coming in a later phase!";

      case IntentType.unknown:
      default:
        return "Sorry, I didn't understand that command.";
    }
  }

  Future<String> _handleOpenApp(Map<String, dynamic> params) async {
    final appName = params['app'] as String?;
    if (appName == null || appName.isEmpty) {
      return "Which app would you like me to open?";
    }
    final launched = await appController.launchApp(appName);
    return launched ? "Opening $appName..." : "I couldn't find an app called $appName.";
  }

  Future<String> _handleMakeCall(Map<String, dynamic> params) async {
    final contact = params['contact'] as String?;
    if (contact == null || contact.isEmpty) {
      return "Who would you like to call?";
    }
    return contactService.callByName(contact);
  }

  Future<String> _handleSendSms(Map<String, dynamic> params) async {
    final contact = params['contact'] as String?;
    final message = params['message'] as String?;
    if (contact == null || message == null) {
      return "I need both a contact and a message to send an SMS.";
    }
    final result = await smsService.sendToContactByName(
      contactName: contact,
      message: message,
    );
    // Best-effort mirror to backend history (fire-and-forget).
    unawaited(apiClient.logMessage(receiver: contact, message: message));
    return result;
  }
}

/// Small helper so we don't need to import dart:async just for this.
void unawaited(Future<void> future) {}
