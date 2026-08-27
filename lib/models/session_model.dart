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
    this.focusAccomplished,
    this.focusReason,
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

  /// What the user says they accomplished during the focus phase.
  final String? focusAccomplished;

  /// Why the user rated their focus the way they did; null when skipped.
  final String? focusReason;

  PomodoroSession copyWith({
    List<String>? tags,
    String? focusPlan,
    String? restPlan,
    DateTime? startedAt,
    Duration? focusElapsed,
    Duration? restElapsed,
    int? focusRating,
    String? focusAccomplished,
    String? focusReason,
  }) {
    return PomodoroSession(
      tags: tags ?? this.tags,
      focusPlan: focusPlan ?? this.focusPlan,
      restPlan: restPlan ?? this.restPlan,
      startedAt: startedAt ?? this.startedAt,
      focusElapsed: focusElapsed ?? this.focusElapsed,
      restElapsed: restElapsed ?? this.restElapsed,
      focusRating: focusRating ?? this.focusRating,
      focusAccomplished: focusAccomplished ?? this.focusAccomplished,
      focusReason: focusReason ?? this.focusReason,
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
      'focusAccomplished': focusAccomplished,
      'focusReason': focusReason,
    };
  }

  /// Splits a legacy merged `focusReview` string ("done\nWhy: reason") back
  /// into its two parts. Returns [focusAccomplished] and [focusReason].
  static ({String? done, String? reason}) _splitLegacyReview(String? review) {
    if (review == null || review.isEmpty) return (done: null, reason: null);
    final marker = '\nWhy: ';
    final markerIndex = review.indexOf(marker);
    if (markerIndex < 0) return (done: review, reason: null);
    final reason = review.substring(markerIndex + marker.length).trim();
    final done = review.substring(0, markerIndex).trim();
    return (
      done: done.isEmpty ? null : done,
      reason: reason.isEmpty ? null : reason,
    );
  }

  factory PomodoroSession.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    final legacy = _splitLegacyReview(json['focusReview'] as String?);
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
      // New sessions write the parts directly; older ones wrote a single
      // merged `focusReview` field that we split above.
      focusAccomplished: json['focusAccomplished'] as String? ?? legacy.done,
      focusReason: json['focusReason'] as String? ?? legacy.reason,
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
        other.focusAccomplished == focusAccomplished &&
        other.focusReason == focusReason;
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
    focusAccomplished,
    focusReason,
  ]);
}
