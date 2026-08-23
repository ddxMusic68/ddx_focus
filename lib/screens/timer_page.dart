import 'dart:async';

import 'package:flutter/material.dart';

import '../models/timer_model.dart';
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
class TimerPage extends StatefulWidget {
  final PomodoroTimer timer;

  const TimerPage({super.key, required this.timer});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  static const _tickInterval = Duration(seconds: 1);

  _Phase _phase = _Phase.focus;
  late Duration _remaining = widget.timer.focusTime;
  Timer? _ticker;
  bool _focusOverflowAnnounced = false;

  bool get _running => _ticker != null;

  /// True while focus has run past zero and is waiting for the user to
  /// advance to the rest phase.
  bool get _isOvertime =>
      _phase == _Phase.focus && _remaining <= Duration.zero;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    if (_running) return;
    setState(() {
      _ticker = Timer.periodic(_tickInterval, (_) => _tick());
    });
  }

  void _pause() {
    setState(() {
      _ticker?.cancel();
      _ticker = null;
    });
  }

  void _reset() {
    setState(() {
      _ticker?.cancel();
      _ticker = null;
      _phase = _Phase.focus;
      _remaining = widget.timer.focusTime;
      _focusOverflowAnnounced = false;
    });
  }

  void _tick() {
    setState(() {
      _remaining -= _tickInterval;
      if (_phase == _Phase.rest && _remaining <= Duration.zero) {
        _ticker?.cancel();
        _ticker = null;
        _phase = _Phase.focus;
        _remaining = widget.timer.focusTime;
        _focusOverflowAnnounced = false;
        _announce('Rest complete — ready for another round?');
        return;
      }
      if (_phase == _Phase.focus &&
          !_focusOverflowAnnounced &&
          _remaining <= Duration.zero) {
        _focusOverflowAnnounced = true;
        _announce('Focus complete — tap the button to start your rest.');
      }
    });
  }

  /// Leaves focus overtime and starts the rest phase immediately.
  void _advanceToRest() {
    setState(() {
      _ticker?.cancel();
      _focusOverflowAnnounced = false;
      _phase = _Phase.rest;
      _remaining = widget.timer.restTime;
      _ticker = Timer.periodic(_tickInterval, (_) => _tick());
    });
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
    final focusRemaining =
        _phase == _Phase.focus ? _remaining : widget.timer.focusTime;
    final restRemaining =
        _phase == _Phase.rest ? _remaining : widget.timer.restTime;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.timer.name),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                _isOvertime ? 'Overtime' : (_running ? 'Running' : 'Paused'),
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
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _isOvertime
                            ? Icons.skip_next
                            : (_running ? Icons.pause : Icons.play_arrow),
                        key: ValueKey<String>('$_isOvertime$_running'),
                        size: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
        : ((totalSeconds - remaining.inSeconds) / totalSeconds)
            .clamp(0.0, 1.0);

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
