import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

/// Result of a contact lookup, kept intentionally small/serializable
/// since it's what most callers (call/SMS flows) actually need.
class ContactLookupResult {
  final String displayName;
  final String phoneNumber;

  const ContactLookupResult({required this.displayName, required this.phoneNumber});
}

class ContactService {
  /// Requests the READ_CONTACTS permission. Returns true if granted.
  Future<bool> requestContactsPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  /// Requests the CALL_PHONE permission. Returns true if granted.
  Future<bool> requestCallPermission() async {
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  /// Searches the device's contacts for [name] and returns the best
  /// match's display name + primary phone number, or null if not found.
  ///
  /// Matching strategy:
  /// 1. Exact case-insensitive full-name match.
  /// 2. Contains-match (handles "Mom" matching "Mom ❤️" or "Rahul K.").
  Future<ContactLookupResult?> getContactByName(String name) async {
    final hasPermission = await FlutterContacts.requestPermission(readonly: true);
    if (!hasPermission) return null;

    final contacts = await FlutterContacts.getContacts(withProperties: true);
    final normalized = name.trim().toLowerCase();

    // 1. Exact match first.
    for (final c in contacts) {
      if (c.displayName.toLowerCase() == normalized && c.phones.isNotEmpty) {
        return ContactLookupResult(
          displayName: c.displayName,
          phoneNumber: c.phones.first.number,
        );
      }
    }

    // 2. Fuzzy contains-match.
    for (final c in contacts) {
      if (c.displayName.toLowerCase().contains(normalized) && c.phones.isNotEmpty) {
        return ContactLookupResult(
          displayName: c.displayName,
          phoneNumber: c.phones.first.number,
        );
      }
    }

    return null;
  }

  /// Places a phone call to [phoneNumber] using CALL_PHONE (direct call,
  /// no dialer confirmation). Requires CALL_PHONE permission granted.
  ///
  /// Falls back to opening the dialer (ACTION_DIAL, no extra permission
  /// needed) if CALL_PHONE isn't granted, so the user can still tap
  /// "Call" manually.
  Future<void> makeCall(String phoneNumber) async {
    final granted = await requestCallPermission();

    final intent = AndroidIntent(
      action: granted ? 'android.intent.action.CALL' : 'android.intent.action.DIAL',
      data: 'tel:$phoneNumber',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    await intent.launch();
  }

  /// Convenience: look up a contact by name and immediately call them.
  /// Returns a status message suitable for TTS/chat display.
  Future<String> callByName(String name) async {
    final contact = await getContactByName(name);
    if (contact == null) {
      return "I couldn't find a contact named $name.";
    }
    await makeCall(contact.phoneNumber);
    return "Calling ${contact.displayName}...";
  }
}
