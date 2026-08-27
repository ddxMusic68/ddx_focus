import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:ddx_focus/models/session_model.dart';

DateTime _startedAt() => DateTime(2026, 8, 24, 9);

PomodoroSession _session() => PomodoroSession(
  tags: const ['work', 'study'],
  focusPlan: 'write report',
  restPlan: 'stretch',
  startedAt: _startedAt(),
  focusElapsed: const Duration(minutes: 25, seconds: 30),
  focusRating: 4,
  focusReview: 'finished draft\nWhy: phone buzzed',
);

void main() {
  group('serialization', () {
    test('toJson maps fields correctly', () {
      final json = _session().toJson();

      expect(json['tags'], ['work', 'study']);
      expect(json['focusPlan'], 'write report');
      expect(json['restPlan'], 'stretch');
      expect(json['startedAt'], _startedAt().toIso8601String());
      expect(json['focusSeconds'], 1530);
      expect(json['focusRating'], 4);
      expect(json['focusReview'], 'finished draft\nWhy: phone buzzed');
    });

    test('fromJson restores the original values', () {
      final session = PomodoroSession.fromJson(_session().toJson());

      expect(session, _session());
    });

    test('round-trips through JSON text without loss', () {
      final encoded = jsonEncode(_session().toJson());
      final restored = PomodoroSession.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );

      expect(restored, _session());
    });

    test('fromJson tolerates unrated sessions', () {
      final session = PomodoroSession.fromJson({
        'tags': ['work'],
        'focusPlan': '',
        'restPlan': '',
        'startedAt': _startedAt().toIso8601String(),
        'focusSeconds': 1500,
        'focusRating': null,
        'focusReview': null,
      });

      expect(session.focusRating, isNull);
      expect(session.focusReview, isNull);
      expect(session.focusElapsed, const Duration(minutes: 25));
    });

    test('fromJson falls back to a legacy single tag string', () {
      final session = PomodoroSession.fromJson({
        'tag': 'old-school',
        'focusPlan': '',
        'restPlan': '',
        'startedAt': _startedAt().toIso8601String(),
        'focusSeconds': 1500,
      });

      expect(session.tags, ['old-school']);
    });

    test('fromJson maps a missing or empty legacy tag to no tags', () {
      final session = PomodoroSession.fromJson({
        'tag': '',
        'focusPlan': '',
        'restPlan': '',
        'startedAt': _startedAt().toIso8601String(),
        'focusSeconds': 1500,
      });

      expect(session.tags, isEmpty);
    });
  });

  group('equality', () {
    test('sessions with identical fields are equal', () {
      expect(_session(), _session());
    });

    test('sessions with different tags are not equal', () {
      expect(_session().copyWith(tags: ['work']), isNot(_session()));
    });

    test('sessions with different ratings are not equal', () {
      expect(_session().copyWith(focusRating: 2), isNot(_session()));
    });
  });

  group('copyWith', () {
    test('overrides only the provided fields', () {
      final updated = _session().copyWith(focusRating: 5);

      expect(updated.focusRating, 5);
      expect(updated.tags, ['work', 'study']);
      expect(updated.focusPlan, 'write report');
      expect(updated.restPlan, 'stretch');
      expect(updated.startedAt, _startedAt());
      expect(updated.focusElapsed, const Duration(minutes: 25, seconds: 30));
      expect(updated.focusReview, 'finished draft\nWhy: phone buzzed');
    });

    test('returns an equal instance when nothing is overridden', () {
      expect(_session().copyWith(), _session());
    });
  });
}
