import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/running_session.dart';
import '../utils/storage_path.dart';

/// Persists the single in-progress [RunningSession] across app exits.
///
/// The live countdown lives in `TimerPage`, which is destroyed when the app is
/// closed. This provider keeps a durable copy on disk so that on relaunch the
/// app can reconstruct and reopen the in-progress timer. At most one session
/// is ever running, so this stores a single JSON document (or none).
class RunningSessionProvider extends ChangeNotifier {
  RunningSession? _session;
  bool _loaded = false;

  /// The currently persisted in-progress session, or null when none is
  /// running.
  RunningSession? get session => _session;

  /// Whether a restorable running session exists on disk.
  bool get hasActive => _session != null;

  /// Whether the persisted session has been read from disk at least once.
  bool get loaded => _loaded;

  /// Saves (or, when [session] is null, clears) the in-progress session.
  void setSession(RunningSession? session) {
    _session = session;
    notifyListeners();
    unawaited(save());
  }

  /// Seeds the in-memory state for widget tests without touching disk.
  ///
  /// Marks the provider as [loaded] so launch-time navigation decisions read
  /// straightforwardly, and stores [session] (or clears it when null) without
  /// any persistence side effects. Never used in production.
  @visibleForTesting
  void seedForTesting(RunningSession? session) {
    _session = session;
    _loaded = true;
  }

  Future<File> get _file async {
    final directory = await StoragePath.directory();
    return File('${directory.path}/running_session.json');
  }

  /// Loads the persisted running session from disk. Safe to call multiple
  /// times; only the first call has an effect. Falls back to no session on
  /// any error or when no save file exists yet.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final file = await _file;
      if (!await file.exists()) return;
      final content = await file.readAsString();
      _session = RunningSession.fromJson(
        jsonDecode(content) as Map<String, dynamic>,
      );
      notifyListeners();
    } catch (e) {
      // Start with no in-progress session rather than crashing.
    }
  }

  /// Writes the current session (or removes the save file when null) to disk.
  Future<void> save() async {
    try {
      final file = await _file;
      if (_session == null) {
        if (await file.exists()) await file.delete();
        return;
      }
      await file.writeAsString(jsonEncode(_session!.toJson()));
    } catch (e) {
      // Persistence failures are non-fatal for this step.
    }
  }
}
