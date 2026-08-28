import 'dart:convert';

import '../models/session_model.dart';
import '../models/timer_model.dart';
import '../providers/sessions_provider.dart';
import '../providers/tags_provider.dart';
import '../providers/timer_provider.dart';

/// Current schema version of the on-disk export file.
const int kExportVersion = 1;

/// The parsed contents of an import file.
class ImportData {
  final List<PomodoroSession> sessions;
  final List<PomodoroTimer> timers;
  final List<String> tags;

  const ImportData({
    required this.sessions,
    required this.timers,
    required this.tags,
  });
}

/// Builds a versioned JSON document describing all user data.
String buildExportJson(
  SessionsProvider sessions,
  TimersProvider timers,
  TagsProvider tags,
) {
  final envelope = <String, dynamic>{
    'version': kExportVersion,
    'sessions': sessions.sessions.map((s) => s.toJson()).toList(),
    'timers': timers.timers.map((t) => t.toJson()).toList(),
    'tags': tags.tags.toList(),
  };
  return jsonEncode(envelope);
}

/// Parses an export document back into [ImportData].
///
/// Returns null when the content is not valid JSON, the version is
/// unsupported, or the top-level shape is wrong. Missing category keys are
/// treated as empty lists.
ImportData? parseImportJson(String content) {
  final Object? decoded;
  try {
    decoded = jsonDecode(content);
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, dynamic>) return null;
  if (decoded['version'] is! int || decoded['version'] != kExportVersion) {
    return null;
  }
  try {
    final sessions = <PomodoroSession>[];
    final rawSessions = decoded['sessions'];
    if (rawSessions is List) {
      for (final item in rawSessions) {
        if (item is Map<String, dynamic>) {
          sessions.add(PomodoroSession.fromJson(item));
        }
      }
    }

    final timers = <PomodoroTimer>[];
    final rawTimers = decoded['timers'];
    if (rawTimers is List) {
      for (final item in rawTimers) {
        if (item is Map<String, dynamic>) {
          timers.add(PomodoroTimer.fromJson(item));
        }
      }
    }

    final tags = <String>[];
    final rawTags = decoded['tags'];
    if (rawTags is List) {
      for (final item in rawTags) {
        if (item is String) tags.add(item);
      }
    }
    return ImportData(sessions: sessions, timers: timers, tags: tags);
  } catch (_) {
    return null;
  }
}
