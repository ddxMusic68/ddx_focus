import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ddx_focus/services/alarm_service.dart';

class _FakeScheduler implements PhaseAlarmScheduler {
  final List<
    ({
      int id,
      String title,
      String body,
      DateTime fireAt,
      String soundResource,
      bool exact,
      bool fullScreen,
      bool notificationOnly,
    })
  >
  scheduled = [];
  final List<int> cancelled = [];
  bool exactAlarms = true;
  bool throwOnSchedule = false;
  bool throwPlatformOnceOnSchedule = false;
  int _scheduleCalls = 0;

  @override
  Future<bool> canScheduleExactAlarms() async => exactAlarms;

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
    required String soundResource,
    required bool exact,
    required bool fullScreen,
    required bool notificationOnly,
  }) async {
    if (throwOnSchedule) throw Exception('schedule boom');
    _scheduleCalls++;
    if (throwPlatformOnceOnSchedule && _scheduleCalls == 1) {
      throw PlatformException(code: 'ERR_PERMISSION_EXACT_ALARM_DENIED');
    }
    scheduled.add((
      id: id,
      title: title,
      body: body,
      fireAt: fireAt,
      soundResource: soundResource,
      exact: exact,
      fullScreen: fullScreen,
      notificationOnly: notificationOnly,
    ));
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
  }
}

void main() {
  group('AlarmService', () {
    test('schedulePhaseEnd is a no-op before initialize (armed)', () async {
      final fake = _FakeScheduler();
      final service = AlarmService.withScheduler(fake);

      await service.schedulePhaseEnd(
        id: 1,
        fireAt: DateTime(2030, 1, 1, 12),
        phase: AlarmPhase.focus,
        title: 'Focus over',
        body: 'Take a break',
        notificationOnly: false,
      );

      expect(fake.scheduled, isEmpty);
    });

    test(
      'focus phase maps to the focus sound and exact when granted',
      () async {
        final fake = _FakeScheduler()..exactAlarms = true;
        final service = AlarmService.withScheduler(fake, initialized: true);
        final fireAt = DateTime(2030, 1, 1, 12);

        await service.schedulePhaseEnd(
          id: 1,
          fireAt: fireAt,
          phase: AlarmPhase.focus,
          title: 'Focus over',
          body: 'Take a break',
          notificationOnly: false,
        );

        expect(fake.scheduled, hasLength(1));
        final record = fake.scheduled.single;
        expect(record.id, 1);
        expect(record.soundResource, 'focus_alarm');
        expect(record.exact, true);
        expect(record.fireAt, fireAt);
        expect(record.title, 'Focus over');
        expect(record.body, 'Take a break');
      },
    );

    test('rest phase maps to the rest sound', () async {
      final fake = _FakeScheduler()..exactAlarms = true;
      final service = AlarmService.withScheduler(fake, initialized: true);

      await service.schedulePhaseEnd(
        id: 2,
        fireAt: DateTime(2030, 1, 1, 12),
        phase: AlarmPhase.rest,
        title: 'Rest over',
        body: 'Back to focus',
        notificationOnly: false,
      );

      expect(fake.scheduled.single.soundResource, 'rest_alarm');
    });

    test('falls back to an inexact schedule on a PlatformException', () async {
      final fake = _FakeScheduler()
        ..exactAlarms = true
        ..throwPlatformOnceOnSchedule = true;
      final service = AlarmService.withScheduler(fake, initialized: true);

      await service.schedulePhaseEnd(
        id: 1,
        fireAt: DateTime(2030, 1, 1, 12),
        phase: AlarmPhase.focus,
        title: 'Title',
        body: 'Body',
        notificationOnly: false,
      );

      expect(fake.scheduled, hasLength(1));
      expect(fake.scheduled.single.exact, false);
    });

    test('passes fullScreen availability through to the scheduler', () async {
      final fake = _FakeScheduler()..exactAlarms = true;
      final service = AlarmService.withScheduler(fake, initialized: true);

      await service.schedulePhaseEnd(
        id: 1,
        fireAt: DateTime(2030, 1, 1, 12),
        phase: AlarmPhase.focus,
        title: 'Title',
        body: 'Body',
        notificationOnly: false,
      );

      // _fullScreenAvailable defaults false; passed through as-is.
      expect(fake.scheduled.single.fullScreen, false);
    });

    test('passes notificationOnly through to the scheduler', () async {
      final fake = _FakeScheduler()..exactAlarms = true;
      final service = AlarmService.withScheduler(fake, initialized: true);

      await service.schedulePhaseEnd(
        id: 1,
        fireAt: DateTime(2030, 1, 1, 12),
        phase: AlarmPhase.focus,
        title: 'Title',
        body: 'Body',
        notificationOnly: true,
      );

      expect(fake.scheduled.single.notificationOnly, true);
    });

    test('schedule errors are swallowed and do not propagate', () async {
      final fake = _FakeScheduler()..throwOnSchedule = true;
      final service = AlarmService.withScheduler(fake, initialized: true);

      await service.schedulePhaseEnd(
        id: 1,
        fireAt: DateTime(2030, 1, 1, 12),
        phase: AlarmPhase.focus,
        title: 'Title',
        body: 'Body',
        notificationOnly: false,
      );
    });

    test(
      'cancelPhaseAlarm cancels the requested id on the scheduler',
      () async {
        final fake = _FakeScheduler();
        final service = AlarmService.withScheduler(fake, initialized: true);

        await service.cancelPhaseAlarm(7);

        expect(fake.cancelled, [7]);
      },
    );
  });
}
