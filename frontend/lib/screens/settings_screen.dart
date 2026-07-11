import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<Permission, PermissionStatus> _statuses = {};

  static const _permissions = [
    Permission.microphone,
    Permission.contacts,
    Permission.phone,
    Permission.sms,
  ];

  @override
  void initState() {
    super.initState();
    _refreshStatuses();
  }

  Future<void> _refreshStatuses() async {
    final statuses = <Permission, PermissionStatus>{};
    for (final p in _permissions) {
      statuses[p] = await p.status;
    }
    setState(() => _statuses = statuses);
  }

  String _label(Permission p) {
    switch (p) {
      case Permission.microphone:
        return 'Microphone (voice commands)';
      case Permission.contacts:
        return 'Contacts (find who to call/text)';
      case Permission.phone:
        return 'Phone (make calls)';
      case Permission.sms:
        return 'SMS (send messages)';
      default:
        return p.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Permissions',
            style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          ..._permissions.map((p) {
            final status = _statuses[p];
            final granted = status?.isGranted ?? false;
            return Card(
              color: Colors.white.withOpacity(0.05),
              child: ListTile(
                title: Text(_label(p), style: const TextStyle(color: Colors.white)),
                trailing: Icon(
                  granted ? Icons.check_circle : Icons.error_outline,
                  color: granted ? Colors.greenAccent : Colors.orangeAccent,
                ),
                onTap: () async {
                  await p.request();
                  _refreshStatuses();
                },
              ),
            );
          }),
          const SizedBox(height: 24),
          const Text(
            'About',
            style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          const Card(
            color: Color(0x11FFFFFF),
            child: ListTile(
              title: Text('PraVIA', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'Phase 1: Voice Assistant + App Control + Calling + SMS',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
