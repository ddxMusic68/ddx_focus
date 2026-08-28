import 'package:flutter_test/flutter_test.dart';
import 'package:ddx_focus/models/session_model.dart';
import 'package:ddx_focus/providers/sessions_provider.dart';

void main() {
  group('SessionsProvider', () {
    late SessionsProvider provider;
    var notifications = 0;

    PomodoroSession session({String? started = '2024-01-01'}) {
      return PomodoroSession(
        tags: const ['work'],
        focusPlan: '',
        restPlan: '',
        startedAt: DateTime.parse('${started}T10:00:00'),
        focusElapsed: const Duration(minutes: 25),
        restElapsed: const Duration(minutes: 5),
      );
    }

    setUp(() {
      provider = SessionsProvider();
      notifications = 0;
      provider.addListener(() => notifications++);
    });

    group('record', () {
      test('appends a session and notifies listeners', () {
        final s = session();
        provider.record(s);

        expect(provider.sessions, [s]);
        expect(notifications, greaterThan(0));
      });
    });

    group('update', () {
      test('replaces a session matched by identity', () {
        final original = session();
        final updated = original.copyWith(focusPlan: 'changed');
        provider.record(original);

        provider.update(original, updated);

        expect(provider.sessions.single.focusPlan, 'changed');
      });

      test('is a no-op when the original is absent', () {
        final orphan = session(started: '2020-01-01');
        provider.update(orphan, orphan.copyWith(focusPlan: 'x'));

        expect(provider.sessions, isEmpty);
      });
    });

    group('delete', () {
      test('removes a session matched by identity', () {
        final s = session();
        provider.record(s);

        provider.delete(s);

        expect(provider.sessions, isEmpty);
      });
    });

    group('replaceAll', () {
      test('replaces all sessions and notifies listeners', () {
        provider.record(session());
        final imported = [
          session(started: '2024-02-01'),
          session(started: '2024-03-01'),
        ];

        provider.replaceAll(imported);

        expect(provider.sessions, hasLength(2));
        expect(provider.sessions, imported);
        expect(notifications, greaterThan(0));
      });

      test('clears sessions when given an empty list', () {
        provider.record(session());
        provider.replaceAll([]);

        expect(provider.sessions, isEmpty);
      });
    });

    group('exposed list', () {
      test('cannot be mutated directly', () {
        provider.record(session());

        expect(
          () => provider.sessions.add(session(started: '2024-02-01')),
          throwsUnsupportedError,
        );
      });
    });
  });
}
