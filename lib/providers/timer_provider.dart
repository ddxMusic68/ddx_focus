import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/timer_model.dart';

/// Holds the user's saved [PomodoroTimer] configurations and persists them
/// to a local JSON file.
class TimersProvider extends ChangeNotifier {
  final List<PomodoroTimer> _timers = [];

  /// Unmodifiable view of all saved timers, in insertion order.
  List<PomodoroTimer> get timers => List.unmodifiable(_timers);

  bool _loaded = false;

  /// Adds a new timer configuration and persists the change.
  void addTimer(PomodoroTimer timer) {
    _timers.add(timer);
    notifyListeners();
    unawaited(save());
  }

  /// Removes the timer at [index] and persists the change.
  void removeAt(int index) {
    if (index < 0 || index >= _timers.length) return;
    _timers.removeAt(index);
    notifyListeners();
    unawaited(save());
  }

  /// Replaces the timer at [index] with [timer] and persists the change.
  void updateAt(int index, PomodoroTimer timer) {
    if (index < 0 || index >= _timers.length) return;
    _timers[index] = timer;
    notifyListeners();
    unawaited(save());
  }

  Future<File> get _file async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/timers.json');
  }

  /// Loads timers from disk. Safe to call multiple times; only the first
  /// call has an effect. Falls back to an empty list on any error or when
  /// no save file exists yet.
  Future<void> loadTimers() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final file = await _file;
      if (!await file.exists()) return;
      final content = await file.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      _timers
        ..clear()
        ..addAll(
          list
              .map((e) => PomodoroTimer.fromJson(e as Map<String, dynamic>)),
        );
      notifyListeners();
    } catch (e) {
      // Start with an empty list rather than crashing.
    }
  }

  /// Writes the current timer list to disk.
  Future<void> save() async {
    try {
      final file = await _file;
      final json = _timers.map((t) => t.toJson()).toList();
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      // Persistence failures are non-fatal for this step.
    }
  }
}
