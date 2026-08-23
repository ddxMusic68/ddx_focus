import 'package:flutter/foundation.dart';

/// A user-created pomodoro timer configuration.
///
/// Holds the display [name] plus the lengths of the focus and rest phases.
/// This class only describes *how* a pomodoro cycle runs; the actual
/// countdown lives in `TimerPage`.
@immutable
class PomodoroTimer {
  const PomodoroTimer({
    required this.name,
    required this.focusTime,
    required this.restTime,
  });

  /// Display name shown on the home screen card and timer page.
  final String name;

  /// Length of one focus phase.
  final Duration focusTime;

  /// Length of one rest phase.
  final Duration restTime;

  PomodoroTimer copyWith({
    String? name,
    Duration? focusTime,
    Duration? restTime,
  }) {
    return PomodoroTimer(
      name: name ?? this.name,
      focusTime: focusTime ?? this.focusTime,
      restTime: restTime ?? this.restTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'focusSeconds': focusTime.inSeconds,
      'restSeconds': restTime.inSeconds,
    };
  }

  factory PomodoroTimer.fromJson(Map<String, dynamic> json) {
    return PomodoroTimer(
      name: json['name'] as String,
      focusTime: Duration(seconds: json['focusSeconds'] as int),
      restTime: Duration(seconds: json['restSeconds'] as int),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PomodoroTimer &&
        other.name == name &&
        other.focusTime == focusTime &&
        other.restTime == restTime;
  }

  @override
  int get hashCode => Object.hash(name, focusTime, restTime);
}
