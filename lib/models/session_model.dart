import 'package:flutter/foundation.dart';

/// A recorded pomodoro focus session.
///
/// Captured when a focus phase completes so it can later be listed in
/// History and aggregated in Stats. Tags and plans are copied by value, so
/// deleting a tag never alters existing sessions.
@immutable
class PomodoroSession {
  const PomodoroSession({
    required this.tags,
    required this.focusPlan,
    required this.restPlan,
    required this.startedAt,
    required this.focusElapsed,
  });

  /// Tags chosen for this session; empty list when none was selected.
  final List<String> tags;

  /// What the user said they would focus on.
  final String focusPlan;

  /// What the user said they would do to rest.
  final String restPlan;

  /// When the focus countdown was started.
  final DateTime startedAt;

  /// How long the focus phase actually ran, including any overtime the
  /// user let elapse past zero.
  final Duration focusElapsed;

  PomodoroSession copyWith({
    List<String>? tags,
    String? focusPlan,
    String? restPlan,
    DateTime? startedAt,
    Duration? focusElapsed,
  }) {
    return PomodoroSession(
      tags: tags ?? this.tags,
      focusPlan: focusPlan ?? this.focusPlan,
      restPlan: restPlan ?? this.restPlan,
      startedAt: startedAt ?? this.startedAt,
      focusElapsed: focusElapsed ?? this.focusElapsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tags': tags,
      'focusPlan': focusPlan,
      'restPlan': restPlan,
      'startedAt': startedAt.toIso8601String(),
      'focusSeconds': focusElapsed.inSeconds,
    };
  }

  factory PomodoroSession.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    return PomodoroSession(
      tags: rawTags is List
          ? rawTags.cast<String>()
          // Legacy single-tag sessions written before multi-select.
          : [
              if ((json['tag'] as String? ?? '').isNotEmpty)
                json['tag'] as String,
            ],
      focusPlan: json['focusPlan'] as String? ?? '',
      restPlan: json['restPlan'] as String? ?? '',
      startedAt: DateTime.parse(json['startedAt'] as String),
      focusElapsed: Duration(seconds: json['focusSeconds'] as int),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PomodoroSession &&
        listEquals(other.tags, tags) &&
        other.focusPlan == focusPlan &&
        other.restPlan == restPlan &&
        other.startedAt == startedAt &&
        other.focusElapsed == focusElapsed;
  }

  @override
  int get hashCode =>
      Object.hashAll([tags, focusPlan, restPlan, startedAt, focusElapsed]);
}
