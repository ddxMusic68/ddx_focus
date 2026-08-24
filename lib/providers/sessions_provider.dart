import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/session_model.dart';

/// Holds recorded [PomodoroSession]s and persists them to a local JSON
/// file. This is the data source for the future History and Stats screens.
class SessionsProvider extends ChangeNotifier {
  final List<PomodoroSession> _sessions = [];

  /// Unmodifiable view of all sessions, oldest first.
  List<PomodoroSession> get sessions => List.unmodifiable(_sessions);

  bool _loaded = false;

  /// Records a completed focus session and persists the change.
  void record(PomodoroSession session) {
    _sessions.add(session);
    notifyListeners();
    unawaited(save());
  }

  Future<File> get _file async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/sessions.json');
  }

  /// Loads sessions from disk. Safe to call multiple times; only the first
  /// call has an effect. Falls back to an empty list on any error or when
  /// no save file exists yet.
  Future<void> loadSessions() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final file = await _file;
      if (!await file.exists()) return;
      final content = await file.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      _sessions
        ..clear()
        ..addAll(
          list.map((e) => PomodoroSession.fromJson(e as Map<String, dynamic>)),
        );
      notifyListeners();
    } catch (e) {
      // Start with an empty list rather than crashing.
    }
  }

  /// Writes the current session list to disk.
  Future<void> save() async {
    try {
      final file = await _file;
      final json = _sessions.map((s) => s.toJson()).toList();
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      // Persistence failures are non-fatal for this step.
    }
  }
}
