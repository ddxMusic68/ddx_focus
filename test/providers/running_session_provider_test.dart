import 'package:flutter_test/flutter_test.dart';

import 'package:ddx_focus/models/running_session.dart';
import 'package:ddx_focus/providers/running_session_provider.dart';

void main() {
  const session = RunningSession(
    timerName: 'Deep Work',
    focusTime: Duration(minutes: 25),
    restTime: Duration(minutes: 5),
    phase: RunningPhase.focus,
    running: true,
    phaseEndAt: null,
    remaining: Duration.zero,
    focusElapsedAtEnd: Duration.zero,
    restElapsedAtEnd: Duration.zero,
    focusOverflowAnnounced: false,
    tags: ['work'],
    focusPlan: 'Report',
    restPlan: 'Walk',
    startedAt: null,
  );

  group('RunningSessionProvider', () {
    late RunningSessionProvider provider;
    var notifications = 0;

    setUp(() {
      provider = RunningSessionProvider();
      notifications = 0;
      provider.addListener(() => notifications++);
    });

    test('starts with no running session', () {
      expect(provider.session, isNull);
      expect(provider.hasActive, isFalse);
    });

    test('setSession stores the session and notifies listeners', () {
      provider.setSession(session);

      expect(provider.session, equals(session));
      expect(provider.hasActive, isTrue);
      expect(notifications, greaterThan(0));
    });

    test('setSession(null) clears the session and notifies listeners', () {
      provider.setSession(session);
      notifications = 0;

      provider.setSession(null);

      expect(provider.session, isNull);
      expect(provider.hasActive, isFalse);
      expect(notifications, greaterThan(0));
    });

    test(
      'load completes without crashing when storage is unavailable',
      () async {
        await provider.load();

        expect(provider.session, isNull);
      },
    );

    test('does not reload after the first call', () async {
      provider.setSession(session);

      await provider.load();

      // A second load must not wipe in-memory state.
      expect(provider.session, equals(session));
    });
  });
}
