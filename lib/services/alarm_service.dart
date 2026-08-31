import 'package:alarm_plus/alarm_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The phase an alarm is scheduled for, which picks the notification sound the
/// device plays while the app is backgrounded.
enum AlarmPhase { focus, rest }

/// Maps an Android raw-resource style sound name to the Flutter asset that
/// `alarm_plus` plays for that phase. `alarm_plus` loads its custom alarm
/// audio from the app's Flutter assets (declared in `pubspec.yaml`), not from
/// Android raw resources.
String _assetFor(String soundResource) {
  return switch (soundResource) {
    'focus_alarm' => 'assets/sounds/FocusAlarm.mp3',
    'rest_alarm' => 'assets/sounds/RestAlarm.mp3',
    _ => 'assets/sounds/FocusAlarm.mp3',
  };
}

/// Thin scheduling seam so [AlarmService] can be tested without the
/// `alarm_plus` native plugin (unavailable in unit tests).
abstract class PhaseAlarmScheduler {
  Future<bool> canScheduleExactAlarms();
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
    required String soundResource,
    required bool exact,
    required bool fullScreen,
    required bool notificationOnly,
  });
  Future<void> cancel(int id);
}

/// Real scheduling implementation backed by `alarm_plus`.
///
/// `alarm_plus` schedules exact alarms through Android's AlarmManager
/// (`setExactAndAllowWhileIdle`), rings them via a foreground service with a
/// wake lock, and posts a high-priority full-screen notification over the lock
/// screen. It ships its own STOP / SNOOZE action buttons and persists alarms
/// so they reschedule after a reboot.
class AlarmPlusScheduler implements PhaseAlarmScheduler {
  /// Builds the Flutter-asset-backed notification settings for one alarm.
  ///
  /// When [notificationOnly] is true the alert is delivered more quietly: the
  /// ringer volume is muted so the custom sound does not play, while vibration
  /// is kept so the device still "rings" (buzzes) at phase-end.
  AlarmNotificationSettings _settings({
    required String title,
    required String body,
    required String soundResource,
    required bool notificationOnly,
  }) {
    return AlarmNotificationSettings(
      title: title,
      body: body,
      soundAsset: _assetFor(soundResource),
      stopButtonText: 'Stop',
      snoozeButtonText: 'Snooze',
      vibrationSettings: VibrationSettings(
        enabled: true,
        preset: notificationOnly
            ? VibrationPreset.medium
            : VibrationPreset.strong,
        continuous: true,
      ),
      volumeSettings: VolumeSettings(
        volume: notificationOnly ? 0.0 : 1.0,
        volumeEnforced: true,
      ),
    );
  }

  @override
  Future<bool> canScheduleExactAlarms() async {
    final status = await AlarmPlus.getPermissionStatus();
    return status.exactAlarmsGranted;
  }

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
    // `exact` is informational: alarm_plus always uses an exact alarm
    // (setExactAndAllowWhileIdle). Exact-alarm permission failures surface as
    // PlatformExceptions, which AlarmService treats as non-fatal. `fullScreen`
    // is also informational here — alarm_plus always attaches a full-screen
    // intent to its ringing notification, and whether it pops out over the
    // lock screen is governed by the USE_FULL_SCREEN_INTENT permission plus
    // the activity's showWhenLocked/turnScreenOn manifest flags.
    await AlarmPlus.schedule(
      id: id.toString(),
      time: fireAt,
      data: {'phase': soundResource, 'notificationOnly': notificationOnly},
      notificationSettings: _settings(
        title: title,
        body: body,
        soundResource: soundResource,
        notificationOnly: notificationOnly,
      ),
    );
  }

  @override
  Future<void> cancel(int id) async {
    await AlarmPlus.cancel(id.toString());
  }
}

/// Schedules native Android phase-end alarms so a pomodoro timer can alert
/// (pop out over the lock screen with sound) even while the app is minimized
/// or backgrounded.
///
/// All operations are best-effort and non-fatal: the scheduler is only armed
/// after [initialize] runs (which happens in `main`, not in widgets or tests),
/// and any platform/plugin errors are swallowed so a scheduling failure never
/// crashes the app or aborts a test.
class AlarmService {
  AlarmService._(PhaseAlarmScheduler scheduler, this._enabled)
    : _scheduler = scheduler;

  /// Shared instance used across the app.
  static final AlarmService instance = AlarmService._(
    AlarmPlusScheduler(),
    true,
  );

  /// Builds an instance backed by [scheduler] for tests.
  ///
  /// [initialized] lets a test set the armed flag without invoking the native
  /// plugin ([initialize] does the real plugin setup). Defaults to `false`, so
  /// the returned service is a no-op unless the caller opts in.
  static AlarmService withScheduler(
    PhaseAlarmScheduler scheduler, {
    bool initialized = false,
  }) {
    final service = AlarmService._(scheduler, true);
    service._initialized = initialized;
    return service;
  }

  final PhaseAlarmScheduler _scheduler;
  final bool _enabled;
  bool _initialized = false;

  /// Whether the app may present alarms as full-screen intents (i.e. pop out
  /// over the lock screen / current app). Only true once the user has granted
  /// the full-screen-intent special access on Android 14+; always true below
  /// that. Discovered in [requestPermissions] and passed along to the
  /// scheduler as informational context.
  bool _fullScreenAvailable = false;

  /// Sets up the `alarm_plus` plugin. Call once from `main` before `runApp`.
  ///
  /// `alarm_plus` schedules in local time, so no timezone database setup is
  /// needed (unlike the previous `flutter_local_notifications` path).
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await AlarmPlus.initialize();
      _initialized = true;
    } catch (e) {
      debugPrint('AlarmService.initialize failed: $e');
    }
  }

  /// Requests the Android notification permission (API 33+), the exact alarm
  /// special access, and the full-screen-intent access (API 34+) so alarms can
  /// pop out over the lock screen.
  ///
  /// On Android, `alarm_plus` deep-links to the relevant system Settings
  /// screens rather than showing an in-app dialog. Best-effort; the user can
  /// deny any.
  Future<void> requestPermissions() async {
    if (!_initialized) return;
    try {
      final status = await AlarmPlus.requestPermissions();
      _fullScreenAvailable = status.fullScreenIntentGranted;
    } catch (e) {
      debugPrint('AlarmService permission request failed: $e');
    }
  }

  /// Schedules a one-shot alarm for [fireAt]. `alarm_plus` always uses an
  /// exact alarm (setExactAndAllowWhileIdle); an exact-alarm access failure
  /// throws and is treated as non-fatal here.
  Future<void> schedulePhaseEnd({
    required int id,
    required DateTime fireAt,
    required AlarmPhase phase,
    required String title,
    required String body,
    required bool notificationOnly,
  }) async {
    if (!_enabled || !_initialized) return;
    try {
      final sound = switch (phase) {
        AlarmPhase.focus => 'focus_alarm',
        AlarmPhase.rest => 'rest_alarm',
      };
      final exact = await _scheduler.canScheduleExactAlarms();
      try {
        await _scheduler.schedule(
          id: id,
          title: title,
          body: body,
          fireAt: fireAt,
          soundResource: sound,
          exact: exact,
          fullScreen: _fullScreenAvailable,
          notificationOnly: notificationOnly,
        );
      } on PlatformException {
        // `alarm_plus` only supports exact alarms, so a denial here is a real
        // blocker, not something an "inexact" fallback can work around. Re-run
        // permission requests (alarm_plus deep-links to the relevant Settings
        // screens) so the user actually gets granted exact-alarm access, then
        // retry once. If it fails again, the error is swallowed as non-fatal.
        await requestPermissions();
        await _scheduler.schedule(
          id: id,
          title: title,
          body: body,
          fireAt: fireAt,
          soundResource: sound,
          exact: false,
          fullScreen: _fullScreenAvailable,
          notificationOnly: notificationOnly,
        );
      } catch (e) {
        debugPrint('AlarmService schedule failed: $e');
        return;
      }
    } catch (e) {
      debugPrint('AlarmService schedulePhaseEnd failed: $e');
    }
  }

  /// Cancels a previously scheduled alarm with [id], if any.
  Future<void> cancelPhaseAlarm(int id) async {
    if (!_enabled || !_initialized) return;
    try {
      await _scheduler.cancel(id);
    } catch (e) {
      debugPrint('AlarmService cancel failed: $e');
    }
  }
}
