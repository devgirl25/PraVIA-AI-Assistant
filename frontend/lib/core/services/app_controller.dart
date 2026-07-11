import 'package:device_apps/device_apps.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

/// Handles discovering installed Android apps and launching them by
/// a human-friendly name spoken/typed by the user (e.g. "Instagram").
class AppController {
  /// Cache of installed apps so we don't re-query the package manager
  /// on every single command.
  List<Application>? _cachedApps;

  /// A few common name -> package-name overrides for apps whose display
  /// name doesn't obviously match their package (helps fuzzy matching
  /// succeed on the very first try instead of falling back to search).
  static const Map<String, String> _knownPackages = {
    'instagram': 'com.instagram.android',
    'whatsapp': 'com.whatsapp',
    'youtube': 'com.google.android.youtube',
    'spotify': 'com.spotify.music',
    'camera': 'com.android.camera',
    'gmail': 'com.google.android.gm',
    'chrome': 'com.android.chrome',
    'maps': 'com.google.android.apps.maps',
    'settings': 'com.android.settings',
    'phone': 'com.android.dialer',
    'messages': 'com.google.android.apps.messaging',
    'facebook': 'com.facebook.katana',
    'telegram': 'org.telegram.messenger',
  };

  /// Returns all launchable, non-system apps installed on the device.
  /// Set [includeSystemApps] to true to also list system apps (e.g. Camera,
  /// Settings), which are commonly what users mean by "open camera".
  Future<List<Application>> getInstalledApps({
    bool includeSystemApps = true,
  }) async {
    _cachedApps = await DeviceApps.getInstalledApplications(
      includeSystemApps: includeSystemApps,
      onlyAppsWithLaunchIntent: true,
    );
    // Sort alphabetically for predictable UI listing.
    _cachedApps!.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
    return _cachedApps!;
  }

  /// Attempts to launch an app by its spoken/typed name.
  ///
  /// Resolution order:
  /// 1. Known package-name lookup table (fast path for common apps).
  /// 2. Exact (case-insensitive) match against installed app names.
  /// 3. Fuzzy "contains" match against installed app names.
  ///
  /// Returns true if an app was found and a launch was attempted.
  Future<bool> launchApp(String appName) async {
    final normalized = appName.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    // 1. Known package fast path.
    final knownPackage = _knownPackages[normalized];
    if (knownPackage != null) {
      final isInstalled = await DeviceApps.isAppInstalled(knownPackage);
      if (isInstalled) {
        return DeviceApps.openApp(knownPackage);
      }
    }

    // Make sure we have an app list to search through.
    final apps = _cachedApps ?? await getInstalledApps();

    // 2. Exact match.
    for (final app in apps) {
      if (app.appName.toLowerCase() == normalized) {
        return DeviceApps.openApp(app.packageName);
      }
    }

    // 3. Fuzzy contains-match (either direction, to catch partial names
    //    like "insta" -> "Instagram" or "chrome browser" -> "Chrome").
    for (final app in apps) {
      final name = app.appName.toLowerCase();
      if (name.contains(normalized) || normalized.contains(name)) {
        return DeviceApps.openApp(app.packageName);
      }
    }

    return false; // No match found — caller should surface "app not found".
  }

  /// Fallback launcher using an explicit Android intent, useful for apps
  /// that device_apps can't resolve directly (e.g. deep-linking to the
  /// dialer or a specific activity).
  Future<void> launchViaIntent({
    required String action,
    String? packageName,
    String? data,
  }) async {
    final intent = AndroidIntent(
      action: action,
      package: packageName,
      data: data,
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    await intent.launch();
  }
}
