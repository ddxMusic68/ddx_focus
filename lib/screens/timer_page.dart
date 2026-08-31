import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/session_model.dart';
import '../models/timer_model.dart';
import '../providers/sessions_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/tags_provider.dart';
import '../services/alarm_service.dart';
import 'session_review_screen.dart';
import '../utils/constants.dart';

enum _Phase { focus, rest }

/// Formats a duration as `mm:ss`, prefixing a minus sign for overtime.
String _formatDuration(Duration d) {
  final negative = d.isNegative;
  final abs = negative ? -d : d;
  return '${negative ? '-' : ''}'
      '${abs.inMinutes.toString().padLeft(2, '0')}:'
      '${(abs.inSeconds % 60).toString().padLeft(2, '0')}';
}

/// Full-screen pomodoro runner for a single [PomodoroTimer] configuration.
///
/// Shows both phases at once: the focus timer counts down (into negative
/// overtime once it hits zero) while the rest timer stays grayed out until
/// the user advances. When rest finishes the cycle resets to an idle focus
/// phase. The config is passed by value, so edits or deletes made on the
/// home screen never affect a running session.
///
/// The user can also capture session metadata: pick or create tags,
/// note what they're focusing on, and how they plan to rest. Completing
/// a full focus + rest round opens the review screen and records a
/// [PomodoroSession].
class TimerPage extends StatefulWidget {
  final PomodoroTimer timer;

  /// Returns the current wall-clock time; injected so tests can control the
  /// countdown, which is derived from real time rather than tick counts.
  final DateTime Function() now;

  const TimerPage({super.key, required this.timer, this.now = DateTime.now});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with WidgetsBindingObserver {
  static const _tickInterval = Duration(seconds: 1);

  /// The focus phase gets alarm id 1 and rest phase id 2, so scheduling the
  /// rest alarm never overwrites a pending focus alarm (and vice versa).
  static const _focusAlarmId = 1;
  static const _restAlarmId = 2;

  _Phase _phase = _Phase.focus;

  /// Remaining time for the active phase. Authoritative while paused or idle;
  /// while running it is superseded by [_phaseEndAt] (see [_remainingNow]).
  Duration _remaining = Duration.zero;

  /// Wall-clock instant the active phase ends, set only while running. This
  /// makes the countdown DateTime-derived so elapsed time is correct even if
  /// the app is minimized and the periodic ticker stops.
  DateTime? _phaseEndAt;

  Timer? _ticker;
  bool _focusOverflowAnnounced = false;

  /// Live remaining time. While running this is derived from the wall clock
  /// (`[phaseEndAt] - now`); otherwise it is the stored [_remaining].
  Duration get _remainingNow =>
      _phaseEndAt != null ? _phaseEndAt!.difference(widget.now()) : _remaining;

  /// Focus time actually elapsed when the focus phase ended — planned time
  /// plus overtime, or less when focus was skipped. Folded into the
  /// recorded session's [PomodoroSession.focusElapsed].
  Duration _focusElapsedAtEnd = Duration.zero;

  /// Rest time actually elapsed when the rest phase ended — planned time,
  /// or less when rest was skipped. Folded into the recorded session's
  /// [PomodoroSession.restElapsed].
  Duration _restElapsedAtEnd = Duration.zero;

  /// Session metadata entered by the user on this page.
  ///
  /// Multiple tags can be active at once.
  final Set<String> _selectedTags = {};
  final _newTagController = TextEditingController();
  final _focusPlanController = TextEditingController();
  final _restPlanController = TextEditingController();
  DateTime? _startedAt;

  bool get _running => _ticker != null;

  /// True while focus has run past zero and is waiting for the user to
  /// advance to the rest phase.
  bool get _isOvertime =>
      _phase == _Phase.focus && _remainingNow <= Duration.zero;

  /// Whether native background alarms are armed for the running phase.
  bool get _backgroundAlarmsOn {
    try {
      return context.read<SettingsProvider>().backgroundAlarms;
    } catch (_) {
      // No SettingsProvider in the widget tree (e.g. isolated tests).
      return false;
    }
  }

  /// Whether the user chose a quiet notification-only alert (no loud ringer)
  /// instead of the full-screen alarm.
  bool get _notificationOnlyAlert {
    try {
      return context.read<SettingsProvider>().alertMode ==
          AlertMode.notification;
    } catch (_) {
      // No SettingsProvider in the widget tree (e.g. isolated tests).
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _remaining = widget.timer.focusTime;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _disarmPhaseAlarm();
    _newTagController.dispose();
    _focusPlanController.dispose();
    _restPlanController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // The app is foregrounded again. Re-sync the OS alarm (re-arm it while
      // the active phase is still running so it keeps firing if we minimize
      // again, or disarm once the phase has already ended), then reconcile
      // any phase that ended while minimized. We must NOT unconditionally
      // disarm here, or the OS alarm would never fire for a backgrounded
      // phase-end (the reported "no pop-out / no sound" bug).
      _syncPhaseAlarm();
      _reconcile();
    }
  }

  /// Ensures the OS alarm matches the live countdown state: armed for the
  /// active phase's end time when the phase is still running, otherwise
  /// disarmed (idle/paused/already-ended).
  void _syncPhaseAlarm() {
    final endAt = _phaseEndAt;
    if (_running && endAt != null && widget.now().isBefore(endAt)) {
      _armPhaseAlarm();
    } else {
      _disarmPhaseAlarm();
    }
  }

  void _start() {
    if (_running) return;
    final now = widget.now();
    setState(() {
      _startedAt ??= now;
      _phaseEndAt = now.add(_remaining);
      _ticker = Timer.periodic(_tickInterval, (_) => _tick());
    });
    // Ensure the app has permission to post notifications and schedule exact
    // alarms before arming the background alarm (best-effort on first start).
    unawaited(_ensureAlarmPermissionThenArm());
  }

  /// Requests the Android notification/exact-alarm permissions (no-op once
  /// granted or when background alarms are disabled), then arms the native
  /// alarm for the current phase so it can fire while the app is minimized.
  Future<void> _ensureAlarmPermissionThenArm() async {
    if (!_backgroundAlarmsOn) return;
    await AlarmService.instance.requestPermissions();
    if (!mounted) return;
    _armPhaseAlarm();
  }

  void _pause() {
    setState(() {
      _remaining = _remainingNow;
      _phaseEndAt = null;
      _ticker?.cancel();
      _ticker = null;
    });
    _disarmPhaseAlarm();
  }

  void _reset() {
    setState(() {
      _ticker?.cancel();
      _ticker = null;
      _phase = _Phase.focus;
      _remaining = widget.timer.focusTime;
      _phaseEndAt = null;
      _focusElapsedAtEnd = Duration.zero;
      _restElapsedAtEnd = Duration.zero;
      _focusOverflowAnnounced = false;
    });
    _disarmPhaseAlarm();
  }

  /// Periodic tick while foregrounded: recomputes the countdown from the
  /// wall clock and fires any phase transition whose end time has passed.
  void _tick() => _reconcile();

  /// Recomputes state against the wall clock and handles a phase that has
  /// just ended. Called every tick while foregrounded and again on resume so
  /// time that elapsed while the app was minimized is caught up.
  void _reconcile() {
    final endAt = _phaseEndAt;
    if (endAt == null) {
      setState(() {});
      return;
    }

    if (_phase == _Phase.rest && !widget.now().isBefore(endAt)) {
      _ticker?.cancel();
      _ticker = null;
      _phaseEndAt = null;
      _restElapsedAtEnd = widget.timer.restTime;
      _announce('Rest complete — log your round.');
      unawaited(_completeCycle());
      return;
    }

    if (_phase == _Phase.focus &&
        !_focusOverflowAnnounced &&
        !widget.now().isBefore(endAt)) {
      _focusOverflowAnnounced = true;
      _announce('Focus complete — tap the button to start your rest.');
      _disarmPhaseAlarm();
      return;
    }

    setState(() {});
  }

  /// Opens the review screen for the finished round, records the resulting
  /// [PomodoroSession] (unrated when the review was dismissed), and resets
  /// the runner to an idle focus phase.
  Future<void> _completeCycle() async {
    final result = await Navigator.of(context).push<SessionReviewResult>(
      MaterialPageRoute(builder: (_) => const SessionReviewScreen()),
    );
    if (!mounted) return;
    context.read<SessionsProvider>().record(
      PomodoroSession(
        tags: _selectedTags.toList(),
        focusPlan: _focusPlanController.text.trim(),
        restPlan: _restPlanController.text.trim(),
        startedAt: _startedAt ?? widget.now(),
        focusElapsed: _focusElapsedAtEnd,
        restElapsed: _restElapsedAtEnd,
        focusRating: result?.focusRating,
        focusAccomplished: _cleanText(result?.doneText),
        focusReason: _cleanText(result?.reason),
      ),
    );
    setState(() {
      _phase = _Phase.focus;
      _remaining = widget.timer.focusTime;
      _phaseEndAt = null;
      _focusElapsedAtEnd = Duration.zero;
      _restElapsedAtEnd = Duration.zero;
      _focusOverflowAnnounced = false;
    });
    _disarmPhaseAlarm();
    _announce('Round logged — ready for another one?');
  }

  /// Trims [value] and returns null when it is blank.
  String? _cleanText(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Adds [tag] to the active selection, or removes it when [selected] is
  /// false.
  void _toggleTag(String tag, bool selected) {
    setState(() {
      if (selected) {
        _selectedTags.add(tag);
      } else {
        _selectedTags.remove(tag);
      }
    });
  }

  /// Deletes [tag] from the user's tag list and deselects it when it was
  /// among the active tags. Existing sessions keep their own copy.
  void _deleteTag(String tag) {
    final removed = context.read<TagsProvider>().removeTag(tag);
    if (removed && _selectedTags.contains(tag)) {
      setState(() => _selectedTags.remove(tag));
    }
  }

  /// Leaves focus overtime and starts the rest phase immediately.
  /// Ends the focus phase and starts rest, capturing how long focus
  /// actually ran.
  void _advanceToRest() {
    final now = widget.now();
    setState(() {
      _focusElapsedAtEnd = widget.timer.focusTime - _remainingNow;
      _ticker?.cancel();
      _focusOverflowAnnounced = false;
      _phase = _Phase.rest;
      _remaining = widget.timer.restTime;
      _phaseEndAt = now.add(widget.timer.restTime);
      _ticker = Timer.periodic(_tickInterval, (_) => _tick());
    });
    _armPhaseAlarm();
  }

  /// Jumps past the current phase: focus goes straight to rest; rest goes
  /// straight to the post-round review. Hidden during focus overtime,
  /// where the main button already offers "skip to rest".
  void _skipPhase() {
    if (_isOvertime) return;
    if (_phase == _Phase.rest) {
      setState(() {
        _restElapsedAtEnd = widget.timer.restTime - _remainingNow;
        _ticker?.cancel();
        _ticker = null;
        _phaseEndAt = null;
      });
      _disarmPhaseAlarm();
      unawaited(_completeCycle());
      return;
    }
    _advanceToRest();
  }

  /// Arms the native background alarm for the active phase's end time, so a
  /// phase that finishes while the app is minimized can still alert. No-op
  /// when background alarms are disabled in settings.
  void _armPhaseAlarm() {
    if (!_backgroundAlarmsOn) return;
    final endAt = _phaseEndAt;
    if (endAt == null) return;
    final id = _phase == _Phase.rest ? _restAlarmId : _focusAlarmId;
    unawaited(
      AlarmService.instance.schedulePhaseEnd(
        id: id,
        fireAt: endAt,
        phase: _phase == _Phase.rest ? AlarmPhase.rest : AlarmPhase.focus,
        title: _phase == _Phase.rest ? 'Rest complete' : 'Focus complete',
        body: _phase == _Phase.rest
            ? '${widget.timer.name} — tap to log your round.'
            : '${widget.timer.name} — start your rest.',
        notificationOnly: _notificationOnlyAlert,
      ),
    );
  }

  /// Cancels any pending native background alarm for the active phase.
  void _disarmPhaseAlarm() {
    unawaited(AlarmService.instance.cancelPhaseAlarm(_focusAlarmId));
    unawaited(AlarmService.instance.cancelPhaseAlarm(_restAlarmId));
  }

  void _announce(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focusRemaining = _phase == _Phase.focus
        ? _remainingNow
        : widget.timer.focusTime;
    final restRemaining = _phase == _Phase.rest
        ? _remainingNow
        : widget.timer.restTime;

    return Scaffold(
      appBar: AppBar(title: Text(widget.timer.name)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: viewport.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: 320,
                        child: Column(
                          children: [
                            Consumer<TagsProvider>(
                              builder: (context, tagsProvider, child) {
                                final tags = tagsProvider.tags;
                                return Column(
                                  children: [
                                    if (tags.isNotEmpty)
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 0,
                                        children: [
                                          for (final tag in tags)
                                            GestureDetector(
                                              onLongPress: () =>
                                                  _deleteTag(tag),
                                              child: ChoiceChip(
                                                label: Text(tag),
                                                selected: _selectedTags
                                                    .contains(tag),
                                                onSelected: (selected) =>
                                                    _toggleTag(tag, selected),
                                              ),
                                            ),
                                        ],
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _newTagController,
                                            decoration: const InputDecoration(
                                              labelText: 'New tag',
                                              hintText: 'e.g. work, study',
                                              prefixIcon: Icon(Icons.tag),
                                              border: OutlineInputBorder(),
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            final name = _newTagController.text;
                                            final added = context
                                                .read<TagsProvider>()
                                                .addTag(name);
                                            if (!added) return;
                                            setState(() {
                                              _selectedTags.add(name.trim());
                                              _newTagController.clear();
                                            });
                                          },
                                          icon: const Icon(Icons.add_circle),
                                          tooltip: 'Add tag',
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _focusPlanController,
                              decoration: const InputDecoration(
                                labelText: 'What task are you focusing on?',
                                prefixIcon: Icon(Icons.center_focus_strong),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              textCapitalization: TextCapitalization.sentences,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _restPlanController,
                              decoration: const InputDecoration(
                                labelText: 'How will you rest?',
                                prefixIcon: Icon(Icons.self_improvement),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _PhaseDisplay(
                      label: 'FOCUS',
                      remaining: focusRemaining,
                      total: widget.timer.focusTime,
                      active: _phase == _Phase.focus,
                      color: theme.colorScheme.primary,
                      overtime: _isOvertime,
                    ),
                    const SizedBox(height: 32),
                    _PhaseDisplay(
                      label: 'REST',
                      remaining: restRemaining,
                      total: widget.timer.restTime,
                      active: _phase == _Phase.rest,
                      color: AppColors.coral,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _isOvertime
                          ? 'Overtime'
                          : (_running ? 'Running' : 'Paused'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filledTonal(
                          onPressed: _reset,
                          icon: const Icon(Icons.restart_alt),
                          tooltip: 'Reset',
                        ),
                        const SizedBox(width: 24),
                        FloatingActionButton.large(
                          onPressed: () {
                            if (_isOvertime) {
                              _advanceToRest();
                            } else if (_running) {
                              _pause();
                            } else {
                              _start();
                            }
                          },
                          tooltip: _isOvertime
                              ? 'Skip to rest'
                              : (_running ? 'Pause' : 'Start'),
                          // Plain icon: an AnimatedSwitcher here produced
                          // duplicate-key crashes when states toggled fast.
                          child: Icon(
                            _isOvertime
                                ? Icons.skip_next
                                : (_running ? Icons.pause : Icons.play_arrow),
                            size: 40,
                          ),
                        ),
                        const SizedBox(width: 24),
                        if (!_isOvertime)
                          IconButton.filledTonal(
                            onPressed: _skipPhase,
                            icon: const Icon(Icons.skip_next),
                            tooltip: _phase == _Phase.rest
                                ? 'Skip rest'
                                : 'Skip focus',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One phase row (label + countdown + progress bar).
///
/// When [active] is false the whole display renders in the theme's disabled
/// color so the inactive phase reads as grayed out.
class _PhaseDisplay extends StatelessWidget {
  final String label;
  final Duration remaining;
  final Duration total;
  final bool active;
  final Color color;
  final bool overtime;

  const _PhaseDisplay({
    required this.label,
    required this.remaining,
    required this.total,
    required this.active,
    required this.color,
    this.overtime = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = active ? color : theme.disabledColor;
    final totalSeconds = total.inSeconds;
    final progress = totalSeconds <= 0
        ? 0.0
        : ((totalSeconds - remaining.inSeconds) / totalSeconds).clamp(0.0, 1.0);

    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: accent,
                ),
              ),
              if (overtime) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'OVERTIME',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatDuration(remaining),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              color: accent,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: accent.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(accent),
              semanticsLabel: '$label timer progress',
            ),
          ),
        ],
      ),
    );
  }
}
