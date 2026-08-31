import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../utils/storage_path.dart';

enum AppThemeMode { light, dark, system }

/// How a phase-end alert is delivered.
enum AlertMode {
  /// A full-screen alarm that pops over the lock screen, rings a custom sound
  /// and offers Stop / Snooze actions.
  alarm,

  /// A quiet notification-only alert (no loud ringing sound). It still posts
  /// at the exact phase-end time, but without the intrusive pop-out ringer.
  notification,
}

class SettingsProvider extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.system;
  bool _backgroundAlarms = true;
  AlertMode _alertMode = AlertMode.alarm;

  AppThemeMode get themeMode => _themeMode;

  /// Whether native background alarms fire when a phase ends while the app
  /// is minimized. Defaults to on.
  bool get backgroundAlarms => _backgroundAlarms;

  /// How phase-end alerts are delivered. Defaults to a full alarm.
  AlertMode get alertMode => _alertMode;

  void setThemeMode(AppThemeMode mode) {
    _themeMode = mode;
    _saveSettings();
    notifyListeners();
  }

  void setBackgroundAlarms(bool enabled) {
    _backgroundAlarms = enabled;
    _saveSettings();
    notifyListeners();
  }

  void setAlertMode(AlertMode mode) {
    _alertMode = mode;
    _saveSettings();
    notifyListeners();
  }

  Future<void> loadSettings() async {
    try {
      final file = await _file;
      if (!await file.exists()) return;
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      _themeMode = AppThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => AppThemeMode.system,
      );
      _backgroundAlarms = json['backgroundAlarms'] as bool? ?? true;
      _alertMode = AlertMode.values.firstWhere(
        (e) => e.name == json['alertMode'],
        orElse: () => AlertMode.alarm,
      );
      notifyListeners();
    } catch (e) {
      // Use defaults
    }
  }

  Future<File> get _file async {
    final directory = await StoragePath.directory();
    return File('${directory.path}/settings.json');
  }

  Future<void> _saveSettings() async {
    final file = await _file;
    final json = {
      'themeMode': _themeMode.name,
      'backgroundAlarms': _backgroundAlarms,
      'alertMode': _alertMode.name,
    };
    await file.writeAsString(jsonEncode(json));
  }
}
