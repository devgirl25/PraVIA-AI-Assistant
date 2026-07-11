import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/controllers/assistant_providers.dart';
import '../core/models/chat_message_model.dart';
import 'chat_history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _statusLabel(AssistantStatus status) {
    switch (status) {
      case AssistantStatus.listening:
        return 'Listening...';
      case AssistantStatus.thinking:
        return 'Thinking...';
      case AssistantStatus.executing:
        return 'Executing...';
      case AssistantStatus.idle:
        return 'Tap to speak';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(assistantStatusProvider);
    final chatHistory = ref.watch(chatHistoryProvider);
    final assistantController = ref.watch(assistantControllerProvider);
    final lastMessage = chatHistory.isNotEmpty ? chatHistory.last : null;

    final isBusy = status != AssistantStatus.idle;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'PraVIA',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white70),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChatHistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            _AiAvatar(active: isBusy),
            const SizedBox(height: 24),
            Text(
              _statusLabel(status),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            if (lastMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  lastMessage.role == ChatRole.user
                      ? '"${lastMessage.text}"'
                      : lastMessage.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: lastMessage.role == ChatRole.user
                        ? Colors.cyanAccent
                        : Colors.white,
                    fontSize: 15,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const Spacer(flex: 3),
            GestureDetector(
              onTap: isBusy
                  ? null
                  : () => assistantController.handleVoiceCommand(),
              child: _MicButton(active: isBusy),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _AiAvatar extends StatelessWidget {
  final bool active;
  const _AiAvatar({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: active
              ? [Colors.cyanAccent.withOpacity(0.6), Colors.transparent]
              : [Colors.blueGrey.withOpacity(0.3), Colors.transparent],
        ),
        boxShadow: [
          if (active)
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.4),
              blurRadius: 40,
              spreadRadius: 10,
            ),
        ],
      ),
      child: Icon(
        Icons.blur_on,
        size: 72,
        color: active ? Colors.cyanAccent : Colors.white38,
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final bool active;
  const _MicButton({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? Colors.cyanAccent.withOpacity(0.15) : Colors.white10,
        border: Border.all(
          color: active ? Colors.cyanAccent : Colors.white24,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.mic,
        size: 36,
        color: active ? Colors.cyanAccent : Colors.white70,
      ),
    );
  }
}
