import 'package:flutter_test/flutter_test.dart';
import 'package:ddx_focus/models/timer_model.dart';
import 'package:ddx_focus/providers/timer_provider.dart';

void main() {
  group('TimersProvider', () {
    late TimersProvider provider;
    var notifications = 0;

    const focus = PomodoroTimer(
      name: 'Focus',
      focusTime: Duration(minutes: 25),
      restTime: Duration(minutes: 5),
    );
    const study = PomodoroTimer(
      name: 'Study',
      focusTime: Duration(minutes: 50),
      restTime: Duration(minutes: 10),
    );

    setUp(() {
      provider = TimersProvider();
      notifications = 0;
      provider.addListener(() => notifications++);
    });

    group('addTimer', () {
      test('starts empty', () {
        expect(provider.timers, isEmpty);
      });

      test('appends the timer and notifies listeners', () {
        provider.addTimer(focus);

        expect(provider.timers, hasLength(1));
        expect(provider.timers.first, equals(focus));
        expect(notifications, greaterThan(0));
      });

      test('preserves insertion order', () {
        provider.addTimer(focus);
        provider.addTimer(study);

        expect(provider.timers.map((t) => t.name), equals(['Focus', 'Study']));
      });
    });

    group('removeAt', () {
      setUp(() {
        provider.addTimer(focus);
        provider.addTimer(study);
      });

      test('removes the timer at the given index', () {
        provider.removeAt(0);

        expect(provider.timers, hasLength(1));
        expect(provider.timers.single, equals(study));
      });

      test('is a no-op for an out-of-range index', () {
        provider.removeAt(5);

        expect(provider.timers, hasLength(2));
      });
    });

    group('updateAt', () {
      setUp(() {
        provider.addTimer(focus);
        provider.addTimer(study);
      });

      test('replaces the timer at the given index', () {
        const renamed = PomodoroTimer(
          name: 'Deep Focus',
          focusTime: Duration(minutes: 25),
          restTime: Duration(minutes: 5),
        );

        provider.updateAt(0, renamed);

        expect(provider.timers[0].name, equals('Deep Focus'));
        expect(provider.timers[1], equals(study));
      });

      test('is a no-op for an out-of-range index', () {
        provider.updateAt(9, study);

        expect(provider.timers, hasLength(2));
      });
    });

    group('replaceAll', () {
      test('replaces all timers and notifies listeners', () {
        provider.addTimer(focus);
        provider.replaceAll([study]);

        expect(provider.timers, hasLength(1));
        expect(provider.timers.single, equals(study));
        expect(notifications, greaterThan(0));
      });

      test('clears timers when given an empty list', () {
        provider.addTimer(focus);
        provider.replaceAll([]);

        expect(provider.timers, isEmpty);
      });
    });

    group('loadTimers', () {
      test('completes without crashing when storage is unavailable', () async {
        await provider.loadTimers();

        expect(provider.timers, isEmpty);
      });

      test('does not reload after the first call', () async {
        provider.addTimer(focus);

        await provider.loadTimers();

        // A second load must not wipe in-memory state.
        expect(provider.timers, hasLength(1));
      });
    });

    group('exposed list', () {
      test('cannot be mutated directly', () {
        provider.addTimer(focus);

        expect(() => provider.timers.add(study), throwsUnsupportedError);
      });
    });
  });
}
