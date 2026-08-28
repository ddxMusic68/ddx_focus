import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../utils/storage_path.dart';

enum AppThemeMode { light, dark, system }

class SettingsProvider extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.system;

  AppThemeMode get themeMode => _themeMode;

  void setThemeMode(AppThemeMode mode) {
    _themeMode = mode;
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
    final json = {'themeMode': _themeMode.name};
    await file.writeAsString(jsonEncode(json));
  }
}
