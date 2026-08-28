import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:ddx_focus/models/session_model.dart';
import 'package:ddx_focus/models/timer_model.dart';
import 'package:ddx_focus/providers/sessions_provider.dart';
import 'package:ddx_focus/providers/tags_provider.dart';
import 'package:ddx_focus/providers/timer_provider.dart';
import 'package:ddx_focus/services/data_export_import.dart';

void main() {
  group('buildExportJson', () {
    test('includes version, sessions, timers and tags', () {
      final sessions = SessionsProvider()
        ..record(
          PomodoroSession(
            tags: const ['work'],
            focusPlan: 'plan',
            restPlan: 'rest',
            startedAt: DateTime(2024, 5, 1),
            focusElapsed: const Duration(minutes: 25),
            restElapsed: const Duration(minutes: 5),
            focusRating: 4,
            focusAccomplished: 'done',
            focusReason: 'good',
          ),
        );
      final timers = TimersProvider()
        ..addTimer(
          const PomodoroTimer(
            name: 'Short',
            focusTime: Duration(minutes: 15),
            restTime: Duration(minutes: 3),
          ),
        );
      final tags = TagsProvider()..replaceAll(['work', 'study']);

      final decoded =
          jsonDecode(buildExportJson(sessions, timers, tags))
              as Map<String, dynamic>;

      expect(decoded['version'], kExportVersion);
      expect(decoded['sessions'], isA<List>());
      expect((decoded['sessions'] as List).length, 1);
      expect(decoded['timers'], isA<List>());
      expect((decoded['timers'] as List).length, 1);
      expect(decoded['tags'], ['work', 'study']);
    });
  });

  group('parseImportJson', () {
    test('returns null for invalid JSON', () {
      expect(parseImportJson('not json'), isNull);
    });

    test('returns null when the version is unsupported', () {
      final content = jsonEncode({
        'version': 99,
        'sessions': [],
        'timers': [],
        'tags': [],
      });
      expect(parseImportJson(content), isNull);
    });

    test('returns null when the top level is not an object', () {
      expect(parseImportJson('[1,2]'), isNull);
    });

    test('accepts empty or missing categories', () {
      final content = jsonEncode({'version': kExportVersion});
      final data = parseImportJson(content);
      expect(data, isNotNull);
      expect(data!.sessions, isEmpty);
      expect(data.timers, isEmpty);
      expect(data.tags, isEmpty);
    });

    test('round-trips sessions, timers and tags', () {
      final session = PomodoroSession(
        tags: const ['work'],
        focusPlan: 'plan',
        restPlan: 'rest',
        startedAt: DateTime(2024, 5, 1, 10, 30),
        focusElapsed: const Duration(minutes: 25),
        restElapsed: const Duration(minutes: 5),
        focusRating: 4,
        focusAccomplished: 'done',
        focusReason: 'good',
      );
      final timer = const PomodoroTimer(
        name: 'Short',
        focusTime: Duration(minutes: 15),
        restTime: Duration(minutes: 3),
      );

      final sessions = SessionsProvider()..record(session);
      final timers = TimersProvider()..addTimer(timer);
      final tags = TagsProvider()..replaceAll(['work', 'study']);

      final exported = buildExportJson(sessions, timers, tags);
      final data = parseImportJson(exported);

      expect(data, isNotNull);
      expect(data!.sessions, [session]);
      expect(data.timers, [timer]);
      expect(data.tags, ['work', 'study']);
    });

    test('restores legacy merged focusReview via fromJson', () {
      final legacySession = {
        'tags': ['x'],
        'focusPlan': 'p',
        'restPlan': 'r',
        'startedAt': '2024-01-01T00:00:00.000',
        'focusSeconds': 1500,
        'restSeconds': 300,
        'focusRating': 5,
        'focusReview': 'did the thing\nWhy: it went well',
      };
      final content = jsonEncode({
        'version': kExportVersion,
        'sessions': [legacySession],
        'timers': [],
        'tags': [],
      });

      final data = parseImportJson(content);
      expect(data, isNotNull);
      expect(data!.sessions.single.focusAccomplished, 'did the thing');
      expect(data.sessions.single.focusReason, 'it went well');
    });
  });
}
