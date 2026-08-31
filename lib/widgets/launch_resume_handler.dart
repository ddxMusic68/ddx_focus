import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/timer_model.dart';
import '../models/running_session.dart';
import '../providers/running_session_provider.dart';
import '../screens/timer_page.dart';

/// Reconstructs the [PomodoroTimer] configuration described by [session].
PomodoroTimer timerFromSession(RunningSession session) {
  return PomodoroTimer(
    name: session.timerName,
    focusTime: session.focusTime,
    restTime: session.restTime,
  );
}

/// Pushes a [TimerPage] restoring [session] onto [context]'s navigator.
void openRestoredSession(BuildContext context, RunningSession session) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          TimerPage(timer: timerFromSession(session), initial: session),
    ),
  );
}

/// Puts an invisible widget on top of the app that, right after launch once
/// the persisted [RunningSessionProvider] has loaded, reopens the in-progress
/// timer so a previous run survives an app exit.
///
/// This handles both a plain cold relaunch and an alarm-notification tap: in
/// each case the running session is still on disk (the phase-end alarm was
/// armed while the timer ran), so restoring it drops the user straight back
/// onto the countdown. It navigates at most once per [session].
class LaunchResumeHandler extends StatefulWidget {
  const LaunchResumeHandler({super.key});

  @override
  State<LaunchResumeHandler> createState() => _LaunchResumeHandlerState();
}

class _LaunchResumeHandlerState extends State<LaunchResumeHandler> {
  Object? _lastRestored;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RunningSessionProvider>();
    if (!provider.loaded) return const SizedBox.shrink();
    final session = provider.session;
    if (session == null) return const SizedBox.shrink();

    // Skip if we already restored this exact snapshot (e.g. after the user
    // backs out of the timer and the provider notifies again).
    if (_lastRestored == session) return const SizedBox.shrink();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _lastRestored == session) return;
      _lastRestored = session;
      openRestoredSession(context, session);
    });

    return const SizedBox.shrink();
  }
}
