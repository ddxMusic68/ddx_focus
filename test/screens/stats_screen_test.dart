import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ddx_focus/models/session_model.dart';
import 'package:ddx_focus/providers/sessions_provider.dart';
import 'package:ddx_focus/screens/stats_screen.dart';

void main() {
  PomodoroSession session({
    required DateTime startedAt,
    List<String> tags = const [],
    Duration focus = const Duration(minutes: 25),
    Duration rest = const Duration(minutes: 5),
  }) {
    return PomodoroSession(
      tags: tags,
      focusPlan: '',
      restPlan: '',
      startedAt: startedAt,
      focusElapsed: focus,
      restElapsed: rest,
    );
  }

  PomodoroSession seed(WidgetTester tester, SessionsProvider provider) {
    final now = DateTime.now();
    final sessions = <PomodoroSession>[
      session(
        startedAt: now,
        tags: const ['work'],
        focus: const Duration(minutes: 25),
        rest: const Duration(minutes: 5),
      ),
      session(
        startedAt: now.subtract(const Duration(days: 3)),
        tags: const ['study'],
        focus: const Duration(minutes: 50),
        rest: const Duration(minutes: 10),
      ),
      session(
        startedAt: now.subtract(const Duration(days: 40)),
        tags: const [],
        focus: const Duration(minutes: 100),
        rest: const Duration(minutes: 20),
      ),
    ];
    for (final s in sessions) {
      provider.record(s);
    }
    return sessions.first;
  }

  Future<void> pumpStats(WidgetTester tester, SessionsProvider provider) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: StatsScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows empty state when there are no sessions', (tester) async {
    final provider = SessionsProvider();
    await pumpStats(tester, provider);

    expect(find.text('No stats yet'), findsOneWidget);
  });

  testWidgets('defaults to week and shows focus vs rest', (tester) async {
    final provider = SessionsProvider();
    seed(tester, provider);
    await pumpStats(tester, provider);

    // The 40-day-old session is outside the week, so 2 in window.
    expect(find.textContaining('2 sessions'), findsOneWidget);
    // Focus slice text is drawn in the chart title; legend lists labels.
    expect(find.textContaining('Focus ('), findsOneWidget);
    expect(find.textContaining('Rest ('), findsOneWidget);
    // Week + Month + Year segments exist.
    expect(find.text('Week'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('Year'), findsOneWidget);
  });

  testWidgets('switching to year includes the older session', (tester) async {
    final provider = SessionsProvider();
    seed(tester, provider);
    await pumpStats(tester, provider);

    await tester.tap(find.text('Year'));
    await tester.pump();

    expect(find.textContaining('3 sessions'), findsOneWidget);
  });

  testWidgets('tags query shows per-tag and untagged slices', (tester) async {
    final provider = SessionsProvider();
    seed(tester, provider);
    await pumpStats(tester, provider);

    // Include all sessions (the untagged one is 40 days old).
    await tester.tap(find.text('Year'));
    await tester.pump();
    await tester.tap(find.text('Tags'));
    await tester.pump();

    // In the Year window all three sessions are included:
    // work=25, study=50, untagged=100. Legend shows each.
    expect(find.textContaining('work ('), findsOneWidget);
    expect(find.textContaining('study ('), findsOneWidget);
    expect(find.textContaining('Untagged ('), findsOneWidget);
  });

  testWidgets('all-zero sessions show a no-data card, not a blank chart', (
    tester,
  ) async {
    final provider = SessionsProvider();
    provider.record(
      session(
        startedAt: DateTime.now(),
        focus: Duration.zero,
        rest: Duration.zero,
      ),
    );
    await pumpStats(tester, provider);

    expect(
      find.textContaining('No focus or rest time was recorded'),
      findsOneWidget,
    );
    // No legend entries since there are no measurable slices.
    expect(find.textContaining('Focus ('), findsNothing);
  });
}
