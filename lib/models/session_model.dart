import 'package:flutter/foundation.dart';

/// A recorded pomodoro focus session.
///
/// Captured when a full focus + rest round completes (via the review
/// screen) so it can later be listed in History and aggregated in Stats.
/// Tags and plans are copied by value, so deleting a tag never alters
/// existing sessions.
@immutable
class PomodoroSession {
  const PomodoroSession({
    required this.tags,
    required this.focusPlan,
    required this.restPlan,
    required this.startedAt,
    required this.focusElapsed,
    required this.restElapsed,
    this.focusRating,
    this.focusReview,
  });

  /// Tags chosen for this session; empty list when none was selected.
  final List<String> tags;

  /// What the user said they would focus on.
  final String focusPlan;

  /// What the user said they would do to rest.
  final String restPlan;

  /// When the focus countdown was started.
  final DateTime startedAt;

  /// How long the focus phase actually ran — the planned focus time plus
  /// any overtime the user let elapse past zero, or less than planned when
  /// focus was skipped early.
  final Duration focusElapsed;

  /// How long the rest phase actually ran — the planned rest time, or less
  /// when rest was skipped early.
  final Duration restElapsed;

  /// How focused the user felt, from 1 to 5; null when the round wasn't
  /// rated (e.g. the review screen was dismissed).
  final int? focusRating;

  /// Free-form recap written after the round; null when skipped.
  final String? focusReview;

  PomodoroSession copyWith({
    List<String>? tags,
    String? focusPlan,
    String? restPlan,
    DateTime? startedAt,
    Duration? focusElapsed,
    Duration? restElapsed,
    int? focusRating,
    String? focusReview,
  }) {
    return PomodoroSession(
      tags: tags ?? this.tags,
      focusPlan: focusPlan ?? this.focusPlan,
      restPlan: restPlan ?? this.restPlan,
      startedAt: startedAt ?? this.startedAt,
      focusElapsed: focusElapsed ?? this.focusElapsed,
      restElapsed: restElapsed ?? this.restElapsed,
      focusRating: focusRating ?? this.focusRating,
      focusReview: focusReview ?? this.focusReview,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tags': tags,
      'focusPlan': focusPlan,
      'restPlan': restPlan,
      'startedAt': startedAt.toIso8601String(),
      'focusSeconds': focusElapsed.inSeconds,
      'restSeconds': restElapsed.inSeconds,
      'focusRating': focusRating,
      'focusReview': focusReview,
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
      // Older sessions had no rest measurement; default to zero.
      restElapsed: Duration(seconds: json['restSeconds'] as int? ?? 0),
      focusRating: json['focusRating'] as int?,
      focusReview: json['focusReview'] as String?,
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
        other.focusElapsed == focusElapsed &&
        other.restElapsed == restElapsed &&
        other.focusRating == focusRating &&
        other.focusReview == focusReview;
  }

  @override
  int get hashCode => Object.hashAll([
    tags,
    focusPlan,
    restPlan,
    startedAt,
    focusElapsed,
    restElapsed,
    focusRating,
    focusReview,
  ]);
}
