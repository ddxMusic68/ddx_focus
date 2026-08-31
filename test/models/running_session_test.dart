import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:ddx_focus/models/running_session.dart';

RunningSession _sample({
  bool running = true,
  DateTime? phaseEndAt,
  bool focusOverflowAnnounced = false,
}) {
  return RunningSession(
    timerName: 'Deep Work',
    focusTime: const Duration(minutes: 25),
    restTime: const Duration(minutes: 5),
    phase: RunningPhase.focus,
    running: running,
    phaseEndAt: phaseEndAt,
    remaining: running ? Duration.zero : const Duration(minutes: 10),
    focusElapsedAtEnd: const Duration(minutes: 25),
    restElapsedAtEnd: Duration.zero,
    focusOverflowAnnounced: focusOverflowAnnounced,
    tags: const ['work', 'study'],
    focusPlan: 'Finish report',
    restPlan: 'Stretch',
    startedAt: DateTime(2024, 1, 1, 12),
  );
}

void main() {
  group('RunningSession', () {
    test('toJson maps fields correctly', () {
      final endAt = DateTime(2024, 1, 1, 12, 25);
      final json = _sample(phaseEndAt: endAt).toJson();

      expect(json['timerName'], 'Deep Work');
      expect(json['focusSeconds'], 1500);
      expect(json['restSeconds'], 300);
      expect(json['phase'], 'focus');
      expect(json['running'], true);
      expect(json['phaseEndAt'], endAt.toIso8601String());
      expect(json['remainingSeconds'], 0);
      expect(json['focusElapsedAtEndSeconds'], 1500);
      expect(json['restElapsedAtEndSeconds'], 0);
      expect(json['focusOverflowAnnounced'], false);
      expect(json['tags'], ['work', 'study']);
      expect(json['focusPlan'], 'Finish report');
      expect(json['restPlan'], 'Stretch');
      expect(json['startedAt'], DateTime(2024, 1, 1, 12).toIso8601String());
    });

    test('fromJson restores the original values', () {
      final endAt = DateTime(2024, 1, 1, 12, 25);
      final restored = RunningSession.fromJson(
        _sample(phaseEndAt: endAt).toJson(),
      );

      expect(restored, equals(_sample(phaseEndAt: endAt)));
    });

    test('round-trips through JSON text without loss', () {
      final original = _sample(
        phaseEndAt: DateTime(2024, 1, 1, 12, 30),
        focusOverflowAnnounced: true,
      );

      final restored = RunningSession.fromJson(
        (jsonDecode(jsonEncode(original.toJson())) as Map)
            .cast<String, dynamic>(),
      );

      expect(restored, equals(original));
    });

    test('defaults null/missing timestamps and fields', () {
      final restored = RunningSession.fromJson({
        'timerName': 'Deep Work',
        'focusSeconds': 1500,
        'restSeconds': 300,
      });

      expect(restored.timerName, 'Deep Work');
      expect(restored.phase, RunningPhase.focus);
      expect(restored.phaseEndAt, isNull);
      expect(restored.startedAt, isNull);
      expect(restored.tags, isEmpty);
      expect(restored.focusPlan, '');
      expect(restored.running, true);
    });

    test('equality distinguishes a rest phase from focus', () {
      final focus = _sample();
      final rest = RunningSession(
        timerName: focus.timerName,
        focusTime: focus.focusTime,
        restTime: focus.restTime,
        phase: RunningPhase.rest,
        running: focus.running,
        phaseEndAt: focus.phaseEndAt,
        remaining: focus.remaining,
        focusElapsedAtEnd: focus.focusElapsedAtEnd,
        restElapsedAtEnd: focus.restElapsedAtEnd,
        focusOverflowAnnounced: focus.focusOverflowAnnounced,
        tags: focus.tags,
        focusPlan: focus.focusPlan,
        restPlan: focus.restPlan,
        startedAt: focus.startedAt,
      );

      expect(rest, isNot(equals(focus)));
    });
  });
}
