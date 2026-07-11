enum ChatRole { user, assistant, system }

class ChatMessageModel {
  final String text;
  final ChatRole role;
  final DateTime timestamp;
  final String? status; // e.g. "Listening...", "Thinking...", "Executing..."

  ChatMessageModel({
    required this.text,
    required this.role,
    DateTime? timestamp,
    this.status,
  }) : timestamp = timestamp ?? DateTime.now();
}
