import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ddx_focus/models/running_session.dart';
import 'package:ddx_focus/providers/running_session_provider.dart';
import 'package:ddx_focus/providers/sessions_provider.dart';
import 'package:ddx_focus/providers/settings_provider.dart';
import 'package:ddx_focus/providers/tags_provider.dart';
import 'package:ddx_focus/screens/timer_page.dart';
import 'package:ddx_focus/widgets/launch_resume_handler.dart';

void main() {
  RunningSession session({DateTime? now}) {
    final base = now ?? DateTime.now();
    return RunningSession(
      timerName: 'Test',
      focusTime: const Duration(seconds: 3),
      restTime: const Duration(seconds: 2),
      phase: RunningPhase.focus,
      running: true,
      phaseEndAt: base.add(const Duration(seconds: 2)),
      remaining: Duration.zero,
      focusElapsedAtEnd: Duration.zero,
      restElapsedAtEnd: Duration.zero,
      focusOverflowAnnounced: false,
      tags: const [],
      focusPlan: '',
      restPlan: '',
      startedAt: base,
    );
  }

  RunningSessionProvider loadedProvider(RunningSession? value) {
    final provider = RunningSessionProvider()..seedForTesting(value);
    return provider;
  }

  Widget host(RunningSessionProvider provider) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TagsProvider>(create: (_) => TagsProvider()),
        ChangeNotifierProvider<SessionsProvider>(
          create: (_) => SessionsProvider(),
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),
        ChangeNotifierProvider<RunningSessionProvider>.value(value: provider),
      ],
      child: const MaterialApp(
        home: Scaffold(body: Center(child: LaunchResumeHandler())),
      ),
    );
  }

  testWidgets('reopens the running timer on launch when a session is active', (
    tester,
  ) async {
    final provider = loadedProvider(session());

    await tester.pumpWidget(host(provider));
    await tester.pump(); // fire the post-frame navigation callback
    await tester.pump(); // build the pushed TimerPage route

    expect(find.byType(TimerPage), findsOneWidget);
    expect(find.text('Running'), findsOneWidget);

    final restored = timerFromSession(session());
    expect(restored.name, 'Test');
    expect(restored.focusTime, const Duration(seconds: 3));
    expect(restored.restTime, const Duration(seconds: 2));
  });

  testWidgets('does not navigate when no session is active', (tester) async {
    final provider = loadedProvider(null);

    await tester.pumpWidget(host(provider));
    await tester.pump();
    await tester.pump();

    expect(find.byType(TimerPage), findsNothing);
  });

  testWidgets('navigates only once per restored snapshot', (tester) async {
    final provider = loadedProvider(session());

    await tester.pumpWidget(host(provider));
    await tester.pump();
    await tester.pump();
    expect(find.byType(TimerPage), findsOneWidget);

    // A later provider notification for the same snapshot must not re-push.
    provider.notifyListeners();
    await tester.pump();
    await tester.pump();
    expect(find.byType(TimerPage), findsOneWidget);
  });
}
