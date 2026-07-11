import 'package:telephony/telephony.dart';
import 'package:hive/hive.dart';

import 'contact_service.dart';

/// A single sent-message record kept in local history (Hive box "messages").
class MessageHistoryEntry {
  final int id;
  final String receiver;
  final String message;
  final DateTime timestamp;

  MessageHistoryEntry({
    required this.id,
    required this.receiver,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'receiver': receiver,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
      };

  factory MessageHistoryEntry.fromMap(Map<dynamic, dynamic> map) {
    return MessageHistoryEntry(
      id: map['id'] as int,
      receiver: map['receiver'] as String,
      message: map['message'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

class SmsService {
  static const String _historyBoxName = 'message_history';
  final Telephony _telephony = Telephony.instance;
  final ContactService _contactService = ContactService();

  /// Requests SEND_SMS permission. Returns true if granted.
  Future<bool> requestSmsPermission() async {
    final granted = await _telephony.requestSmsPermissions;
    return granted ?? false;
  }

  /// Sends an SMS directly (no default-SMS-app UI shown) to [number]
  /// with [message] body.
  Future<void> sendSMS({required String number, required String message}) async {
    final granted = await requestSmsPermission();
    if (!granted) {
      throw Exception('SEND_SMS permission not granted');
    }
    await _telephony.sendSms(to: number, message: message);
    await _logMessage(receiver: number, message: message);
  }

  /// High-level flow used by the intent executor:
  /// 1. Resolve contact name -> phone number
  /// 2. Send the SMS
  /// 3. Return a status string suitable for TTS/chat display
  Future<String> sendToContactByName({
    required String contactName,
    required String message,
  }) async {
    final contact = await _contactService.getContactByName(contactName);
    if (contact == null) {
      return "I couldn't find a contact named $contactName.";
    }
    await sendSMS(number: contact.phoneNumber, message: message);
    return "Message sent to ${contact.displayName}: \"$message\"";
  }

  /// Persists a sent message into local Hive history so the
  /// "Message History" screen can list it, fields: id, receiver,
  /// message, timestamp.
  Future<void> _logMessage({required String receiver, required String message}) async {
    final box = await Hive.openBox(_historyBoxName);
    final id = (box.get('_nextId', defaultValue: 1) as int);
    final entry = MessageHistoryEntry(
      id: id,
      receiver: receiver,
      message: message,
      timestamp: DateTime.now(),
    );
    await box.put(id, entry.toMap());
    await box.put('_nextId', id + 1);
  }

  /// Returns all logged messages, most recent first.
  Future<List<MessageHistoryEntry>> getMessageHistory() async {
    final box = await Hive.openBox(_historyBoxName);
    final entries = <MessageHistoryEntry>[];
    for (final key in box.keys) {
      if (key == '_nextId') continue;
      final raw = box.get(key);
      if (raw is Map) entries.add(MessageHistoryEntry.fromMap(raw));
    }
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }
}
