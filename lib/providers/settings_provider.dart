import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../utils/storage_path.dart';

enum AppThemeMode { light, dark, system }

class SettingsProvider extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.system;
  bool _backgroundAlarms = true;

  AppThemeMode get themeMode => _themeMode;

  /// Whether native background alarms fire when a phase ends while the app
  /// is minimized. Defaults to on.
  bool get backgroundAlarms => _backgroundAlarms;

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
    };
    await file.writeAsString(jsonEncode(json));
  }
}
