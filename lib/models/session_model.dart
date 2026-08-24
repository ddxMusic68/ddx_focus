import 'package:flutter/foundation.dart';

/// A recorded pomodoro focus session.
///
/// Captured when a focus phase completes so it can later be listed in
/// History and aggregated in Stats. Tags and plans are copied by value, so
/// deleting a tag never alters existing sessions.
@immutable
class PomodoroSession {
  const PomodoroSession({
    required this.tag,
    required this.focusPlan,
    required this.restPlan,
    required this.startedAt,
    required this.focusElapsed,
  });

  /// Tag chosen for this session; empty string when none was selected.
  final String tag;

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
    String? tag,
    String? focusPlan,
    String? restPlan,
    DateTime? startedAt,
    Duration? focusElapsed,
  }) {
    return PomodoroSession(
      tag: tag ?? this.tag,
      focusPlan: focusPlan ?? this.focusPlan,
      restPlan: restPlan ?? this.restPlan,
      startedAt: startedAt ?? this.startedAt,
      focusElapsed: focusElapsed ?? this.focusElapsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'focusPlan': focusPlan,
      'restPlan': restPlan,
      'startedAt': startedAt.toIso8601String(),
      'focusSeconds': focusElapsed.inSeconds,
    };
  }

  factory PomodoroSession.fromJson(Map<String, dynamic> json) {
    return PomodoroSession(
      tag: json['tag'] as String? ?? '',
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
        other.tag == tag &&
        other.focusPlan == focusPlan &&
        other.restPlan == restPlan &&
        other.startedAt == startedAt &&
        other.focusElapsed == focusElapsed;
  }

  @override
  int get hashCode =>
      Object.hash(tag, focusPlan, restPlan, startedAt, focusElapsed);
}
