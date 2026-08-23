import 'package:flutter_test/flutter_test.dart';
import 'package:ddx_focus/models/timer_model.dart';

void main() {
  group('PomodoroTimer', () {
    const timer = PomodoroTimer(
      name: 'Deep Work',
      focusTime: Duration(minutes: 25),
      restTime: Duration(minutes: 5),
    );

    group('serialization', () {
      test('toJson maps fields correctly', () {
        expect(timer.toJson(), {
          'name': 'Deep Work',
          'focusSeconds': 1500,
          'restSeconds': 300,
        });
      });

      test('fromJson restores the original values', () {
        final json = {
          'name': 'Study',
          'focusSeconds': 3600,
          'restSeconds': 600,
        };

        final restored = PomodoroTimer.fromJson(json);

        expect(restored.name, equals('Study'));
        expect(restored.focusTime, equals(const Duration(hours: 1)));
        expect(restored.restTime, equals(const Duration(minutes: 10)));
      });

      test('round-trips through JSON without loss', () {
        final restored = PomodoroTimer.fromJson(timer.toJson());
        expect(restored, equals(timer));
      });
    });

    group('equality', () {
      test('timers with identical fields are equal', () {
        const other = PomodoroTimer(
          name: 'Deep Work',
          focusTime: Duration(minutes: 25),
          restTime: Duration(minutes: 5),
        );
        expect(timer, equals(other));
        expect(timer.hashCode, equals(other.hashCode));
      });

      test('timers with different names are not equal', () {
        final other = timer.copyWith(name: 'Other');
        expect(timer, isNot(equals(other)));
      });

      test('timers with different durations are not equal', () {
        final other = timer.copyWith(focusTime: const Duration(minutes: 50));
        expect(timer, isNot(equals(other)));
      });
    });

    group('copyWith', () {
      test('overrides only the provided fields', () {
        final updated = timer.copyWith(
          name: 'Gym',
          restTime: const Duration(minutes: 10),
        );

        expect(updated.name, equals('Gym'));
        expect(updated.focusTime, equals(const Duration(minutes: 25)));
        expect(updated.restTime, equals(const Duration(minutes: 10)));
      });

      test('returns an equal instance when nothing is overridden', () {
        expect(timer.copyWith(), equals(timer));
      });
    });
  });
}
