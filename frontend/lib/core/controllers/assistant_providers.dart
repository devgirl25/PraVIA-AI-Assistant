import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message_model.dart';
import '../services/speech_service.dart';
import '../services/api_client.dart';
import 'intent_executor.dart';

enum AssistantStatus { idle, listening, thinking, executing }

/// Singleton-style providers for the core services. Keeping these as
/// simple Provider (not per-widget instances) means state like the
/// speech recognizer session persists correctly across rebuilds.
final speechServiceProvider = Provider<SpeechService>((ref) => SpeechService());
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final intentExecutorProvider = Provider<IntentExecutor>((ref) => IntentExecutor());

/// Current assistant status shown on the home screen
/// ("Listening...", "Thinking...", "Executing...").
final assistantStatusProvider = StateProvider<AssistantStatus>((ref) => AssistantStatus.idle);

/// Full chat/command history for the Chat History screen.
final chatHistoryProvider =
    StateNotifierProvider<ChatHistoryNotifier, List<ChatMessageModel>>(
  (ref) => ChatHistoryNotifier(),
);

class ChatHistoryNotifier extends StateNotifier<List<ChatMessageModel>> {
  ChatHistoryNotifier() : super([]);

  void addUserMessage(String text) {
    state = [...state, ChatMessageModel(text: text, role: ChatRole.user)];
  }

  void addAssistantMessage(String text) {
    state = [...state, ChatMessageModel(text: text, role: ChatRole.assistant)];
  }

  void clear() => state = [];
}

/// Orchestrates the full voice pipeline: listen -> transcribe -> parse
/// intent -> execute -> speak response. This is the single entry point
/// the Home Screen's mic button should call.
class AssistantController {
  final Ref ref;
  AssistantController(this.ref);

  Future<void> handleVoiceCommand() async {
    final speech = ref.read(speechServiceProvider);
    final apiClient = ref.read(apiClientProvider);
    final executor = ref.read(intentExecutorProvider);
    final chat = ref.read(chatHistoryProvider.notifier);
    final statusNotifier = ref.read(assistantStatusProvider.notifier);

    final initialized = speech.isAvailable || await speech.initialize();
    if (!initialized) {
      chat.addAssistantMessage(
        "I need microphone permission to listen for commands.",
      );
      return;
    }

    statusNotifier.state = AssistantStatus.listening;

    String finalText = '';
    await speech.startListening(
      onResult: (recognizedText, isFinal) {
        finalText = recognizedText;
      },
    );

    // Wait for the listen session to end (speech_to_text calls onResult
    // repeatedly; we simply poll `isListening` here for simplicity).
    while (speech.isListening) {
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (finalText.trim().isEmpty) {
      statusNotifier.state = AssistantStatus.idle;
      return;
    }

    chat.addUserMessage(finalText);
    statusNotifier.state = AssistantStatus.thinking;

    final intent = await apiClient.parseIntent(finalText);

    statusNotifier.state = AssistantStatus.executing;
    final response = await executor.execute(intent);

    chat.addAssistantMessage(response);
    await speech.speak(response);

    statusNotifier.state = AssistantStatus.idle;
  }
}

final assistantControllerProvider = Provider<AssistantController>(
  (ref) => AssistantController(ref),
);
