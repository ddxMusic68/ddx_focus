import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ddx_focus/models/session_model.dart';
import 'package:ddx_focus/models/timer_model.dart';
import 'package:ddx_focus/providers/sessions_provider.dart';
import 'package:ddx_focus/providers/settings_provider.dart';
import 'package:ddx_focus/providers/tags_provider.dart';
import 'package:ddx_focus/providers/timer_provider.dart';
import 'package:ddx_focus/screens/settings_screen.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    SessionsProvider? sessions,
    TimersProvider? timers,
    TagsProvider? tags,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => timers ?? TimersProvider()),
          ChangeNotifierProvider(create: (_) => tags ?? TagsProvider()),
          ChangeNotifierProvider(create: (_) => sessions ?? SessionsProvider()),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
  }

  group('Clear Local Data', () {
    testWidgets('clears sessions, timers and tags after confirmation', (
      tester,
    ) async {
      final sessions = SessionsProvider()
        ..record(
          PomodoroSession(
            tags: const ['work'],
            focusPlan: '',
            restPlan: '',
            startedAt: DateTime(2024, 1, 1),
            focusElapsed: const Duration(minutes: 25),
            restElapsed: const Duration(minutes: 5),
          ),
        );
      final timers = TimersProvider()
        ..addTimer(
          const PomodoroTimer(
            name: 'Focus',
            focusTime: Duration(minutes: 25),
            restTime: Duration(minutes: 5),
          ),
        );
      final tags = TagsProvider()..replaceAll(['work', 'study']);

      await pump(tester, sessions: sessions, timers: timers, tags: tags);

      await tester.scrollUntilVisible(find.text('Clear Local Data'), 200);
      await tester.tap(find.text('Clear Local Data'));
      await tester.pumpAndSettle();

      expect(find.text('Clear Local Data'), findsWidgets);
      await tester.tap(find.text('Clear').last);
      await tester.pumpAndSettle();

      expect(sessions.sessions, isEmpty);
      expect(timers.timers, isEmpty);
      expect(tags.tags, isEmpty);
    });

    testWidgets('cancelling leaves data untouched', (tester) async {
      final timers = TimersProvider()
        ..addTimer(
          const PomodoroTimer(
            name: 'Focus',
            focusTime: Duration(minutes: 25),
            restTime: Duration(minutes: 5),
          ),
        );

      await pump(tester, timers: timers);

      await tester.scrollUntilVisible(find.text('Clear Local Data'), 200);
      await tester.tap(find.text('Clear Local Data'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(timers.timers, hasLength(1));
    });
  });
}
