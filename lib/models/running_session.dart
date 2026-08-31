import 'package:flutter/foundation.dart';

/// Which phase of a pomodoro cycle is currently active.
enum RunningPhase { focus, rest }

/// A durable snapshot of an in-progress timer so it can survive app exit.
///
/// The live countdown normally lives entirely inside `TimerPage` (a widget in
/// the navigation stack), so it is destroyed if the process dies. This model
/// captures the wall-clock state needed to reconstruct the runner on relaunch:
/// which phase is active, when it ends, how much of it has elapsed, and the
/// session metadata the user entered.
@immutable
class RunningSession {
  const RunningSession({
    required this.timerName,
    required this.focusTime,
    required this.restTime,
    required this.phase,
    required this.running,
    required this.phaseEndAt,
    required this.remaining,
    required this.focusElapsedAtEnd,
    required this.restElapsedAtEnd,
    required this.focusOverflowAnnounced,
    required this.tags,
    required this.focusPlan,
    required this.restPlan,
    required this.startedAt,
  });

  /// Name of the timer configuration this session was started from.
  final String timerName;

  /// Planned length of the focus phase.
  final Duration focusTime;

  /// Planned length of the rest phase.
  final Duration restTime;

  /// The active phase.
  final RunningPhase phase;

  /// Whether the countdown was live (running) when the snapshot was taken.
  ///
  /// A `false` value means the user had paused, or the phase had already ended
  /// while the app was closed (in which case [phaseEndAt] is in the past and
  /// the runner restores paused at the elapsed time).
  final bool running;

  /// Wall-clock instant the active phase ends. Null when the timer was paused
  /// and [remaining] is the authoritative frozen value.
  final DateTime? phaseEndAt;

  /// Remaining time in the active phase. Authoritative when paused or idle;
  /// while running it is superseded by [phaseEndAt].
  final Duration remaining;

  /// Focus time actually elapsed when the focus phase ended.
  final Duration focusElapsedAtEnd;

  /// Rest time actually elapsed when the rest phase ended.
  final Duration restElapsedAtEnd;

  /// Whether the focus-complete (overtime) announcement has already fired.
  final bool focusOverflowAnnounced;

  /// Tags the user had selected for this session.
  final List<String> tags;

  /// What the user said they would focus on.
  final String focusPlan;

  /// What the user said they would do to rest.
  final String restPlan;

  /// When the focus countdown was started; null before the first start.
  final DateTime? startedAt;

  Map<String, dynamic> toJson() {
    return {
      'timerName': timerName,
      'focusSeconds': focusTime.inSeconds,
      'restSeconds': restTime.inSeconds,
      'phase': phase.name,
      'running': running,
      'phaseEndAt': phaseEndAt?.toIso8601String(),
      'remainingSeconds': remaining.inSeconds,
      'focusElapsedAtEndSeconds': focusElapsedAtEnd.inSeconds,
      'restElapsedAtEndSeconds': restElapsedAtEnd.inSeconds,
      'focusOverflowAnnounced': focusOverflowAnnounced,
      'tags': tags,
      'focusPlan': focusPlan,
      'restPlan': restPlan,
      'startedAt': startedAt?.toIso8601String(),
    };
  }

  factory RunningSession.fromJson(Map<String, dynamic> json) {
    final rawPhaseEndAt = json['phaseEndAt'] as String?;
    final rawStartedAt = json['startedAt'] as String?;
    return RunningSession(
      timerName: json['timerName'] as String,
      focusTime: Duration(seconds: json['focusSeconds'] as int),
      restTime: Duration(seconds: json['restSeconds'] as int),
      phase: RunningPhase.values.firstWhere(
        (e) => e.name == json['phase'],
        orElse: () => RunningPhase.focus,
      ),
      running: json['running'] as bool? ?? true,
      phaseEndAt: rawPhaseEndAt == null
          ? null
          : DateTime.tryParse(rawPhaseEndAt),
      remaining: Duration(seconds: json['remainingSeconds'] as int? ?? 0),
      focusElapsedAtEnd: Duration(
        seconds: json['focusElapsedAtEndSeconds'] as int? ?? 0,
      ),
      restElapsedAtEnd: Duration(
        seconds: json['restElapsedAtEndSeconds'] as int? ?? 0,
      ),
      focusOverflowAnnounced: json['focusOverflowAnnounced'] as bool? ?? false,
      tags: (json['tags'] is List) ? json['tags'].cast<String>() : const [],
      focusPlan: json['focusPlan'] as String? ?? '',
      restPlan: json['restPlan'] as String? ?? '',
      startedAt: rawStartedAt == null ? null : DateTime.tryParse(rawStartedAt),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RunningSession &&
        other.timerName == timerName &&
        other.focusTime == focusTime &&
        other.restTime == restTime &&
        other.phase == phase &&
        other.running == running &&
        other.phaseEndAt == phaseEndAt &&
        other.remaining == remaining &&
        other.focusElapsedAtEnd == focusElapsedAtEnd &&
        other.restElapsedAtEnd == restElapsedAtEnd &&
        other.focusOverflowAnnounced == focusOverflowAnnounced &&
        listEquals(other.tags, tags) &&
        other.focusPlan == focusPlan &&
        other.restPlan == restPlan &&
        other.startedAt == startedAt;
  }

  @override
  int get hashCode => Object.hashAll([
    timerName,
    focusTime,
    restTime,
    phase,
    running,
    phaseEndAt,
    remaining,
    focusElapsedAtEnd,
    restElapsedAtEnd,
    focusOverflowAnnounced,
    tags,
    focusPlan,
    restPlan,
    startedAt,
  ]);
}
