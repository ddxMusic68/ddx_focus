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

/// Puts an invisible widget on top of the app that, right after a cold launch
/// once the persisted [RunningSessionProvider] has loaded, reopens the
/// in-progress timer so a previous run survives an app exit.
///
/// This handles both a plain cold relaunch and an alarm-notification tap: in
/// each case the running session is still on disk (the phase-end alarm was
/// armed while the timer ran), so restoring it drops the user straight back
/// onto the countdown.
///
/// The handler acts **exactly once, only in the launch window**. Once it has
/// decided (whether or not a session was found), it becomes inert and ignores
/// every later provider notification. This is important because the open
/// `TimerPage` re-persists its snapshot on each user action (tag toggles, plan
/// edits, start/pause) and each save produces a fresh [RunningSession]
/// instance; reacting to all of them would stack duplicate timer screens, and
/// would also shadow a timer the user opened manually later in the same run.
class LaunchResumeHandler extends StatefulWidget {
  const LaunchResumeHandler({super.key});

  @override
  State<LaunchResumeHandler> createState() => _LaunchResumeHandlerState();
}

class _LaunchResumeHandlerState extends State<LaunchResumeHandler> {
  bool _didHandle = false;

  /// Performs the one-time cold-launch restore decision and then disables the
  /// handler permanently, regardless of later provider changes.
  void _maybeRestore() {
    if (!mounted) return;
    final provider = context.read<RunningSessionProvider>();
    // Only act once, and only once the persisted session has been read from
    // disk. If the load hasn't settled yet, it completes shortly and we retry
    // on the next build (the provider notifies when loading finishes).
    if (_didHandle || !provider.loaded) return;

    _didHandle = true;
    if (!mounted) return;
    final session = provider.session;
    if (session == null) return;
    openRestoredSession(context, session);
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild as long as the decision is still pending. The provider notifies
    // when its load completes (refreshing `provider.loaded`), which re-runs
    // this builder and lets the post-frame callback settle the one-shot
    // decision once the persisted session is actually on disk.
    final provider = context.watch<RunningSessionProvider>();
    if (!_didHandle && provider.loaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRestore());
    }
    return const SizedBox.shrink();
  }
}
