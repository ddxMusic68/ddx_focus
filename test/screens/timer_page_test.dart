import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ddx_focus/models/timer_model.dart';
import 'package:ddx_focus/providers/sessions_provider.dart';
import 'package:ddx_focus/providers/tags_provider.dart';
import 'package:ddx_focus/screens/timer_page.dart';
import 'package:ddx_focus/utils/constants.dart';

const _timer = PomodoroTimer(
  name: 'Test',
  focusTime: Duration(seconds: 3),
  restTime: Duration(seconds: 2),
);

void main() {
  Future<void> pumpTimerPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TagsProvider>(create: (_) => TagsProvider()),
          ChangeNotifierProvider<SessionsProvider>(
            create: (_) => SessionsProvider(),
          ),
        ],
        child: MaterialApp(home: TimerPage(timer: _timer)),
      ),
    );
  }

  group('layout', () {
    testWidgets('renders both phases and the session metadata fields', (
      tester,
    ) async {
      await pumpTimerPage(tester);

      expect(find.text('FOCUS'), findsOneWidget);
      expect(find.text('REST'), findsOneWidget);
      expect(find.text('00:03'), findsOneWidget);
      expect(find.text('00:02'), findsOneWidget);
      expect(find.text('New tag'), findsOneWidget);
      expect(find.text('What task are you focusing on?'), findsOneWidget);
      expect(find.text('How will you rest?'), findsOneWidget);
    });

    testWidgets('grays out the rest phase while focus is active', (
      tester,
    ) async {
      await pumpTimerPage(tester);

      final context = tester.element(find.byType(TimerPage));
      final theme = Theme.of(context);
      final focusColor = tester.widget<Text>(find.text('00:03')).style?.color;
      final restColor = tester.widget<Text>(find.text('00:02')).style?.color;

      expect(focusColor, theme.colorScheme.primary);
      expect(restColor, theme.disabledColor);
    });
  });

  group('overtime flow', () {
    testWidgets('focus counts negative before the user advances to rest', (
      tester,
    ) async {
      await pumpTimerPage(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // 3s focus + 1 extra tick lands us in overtime.
      await tester.pump(const Duration(seconds: 4));

      expect(find.text('-00:01'), findsOneWidget);
      expect(find.text('Overtime'), findsOneWidget);
      expect(find.text('OVERTIME'), findsOneWidget);
    });

    testWidgets(
      'advancing from overtime activates rest and resets after it ends',
      (tester) async {
        await pumpTimerPage(tester);

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();
        await tester.pump(const Duration(seconds: 4));

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();

        final context = tester.element(find.byType(TimerPage));
        final theme = Theme.of(context);
        final restColor = tester.widget<Text>(find.text('00:02')).style?.color;
        final focusColor = tester.widget<Text>(find.text('00:03')).style?.color;
        expect(restColor, AppColors.coral);
        expect(focusColor, theme.disabledColor);

        // Rest runs out and the cycle resets to an idle focus phase.
        await tester.pump(const Duration(seconds: 2));

        expect(find.text('00:03'), findsOneWidget);
        expect(find.text('Paused'), findsOneWidget);
        final resetFocusColor = tester
            .widget<Text>(find.text('00:03'))
            .style
            ?.color;
        expect(resetFocusColor, theme.colorScheme.primary);
      },
    );
  });

  group('tags', () {
    testWidgets('creating a tag adds a selected chip', (tester) async {
      await pumpTimerPage(tester);

      await tester.enterText(find.widgetWithText(TextField, 'New tag'), 'work');
      await tester.tap(find.byTooltip('Add tag'));
      await tester.pump();

      expect(find.text('work'), findsOneWidget);
      final chip = tester.widget<ChoiceChip>(find.byType(ChoiceChip));
      expect(chip.selected, isTrue);
    });

    testWidgets('long-pressing a chip deletes it and clears selection', (
      tester,
    ) async {
      await pumpTimerPage(tester);

      await tester.enterText(find.widgetWithText(TextField, 'New tag'), 'work');
      await tester.tap(find.byTooltip('Add tag'));
      await tester.pump();

      await tester.longPress(find.text('work'));
      await tester.pump();

      expect(find.text('work'), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
    });
  });

  group('session recording', () {
    testWidgets('completing focus records a session with metadata', (
      tester,
    ) async {
      final sessions = SessionsProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TagsProvider>(create: (_) => TagsProvider()),
            ChangeNotifierProvider<SessionsProvider>.value(value: sessions),
          ],
          child: MaterialApp(home: TimerPage(timer: _timer)),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'New tag'),
        'deep work',
      );
      await tester.tap(find.byTooltip('Add tag'));
      await tester.enterText(
        find.widgetWithText(TextField, 'What task are you focusing on?'),
        'write report',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'How will you rest?'),
        'stretch',
      );
      await tester.pump();

      // The tag chip grows the page; bring the FAB into view first.
      await tester.ensureVisible(find.byType(FloatingActionButton));
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      // 4 ticks: 3s of focus plus 1s of overtime.
      await tester.pump(const Duration(seconds: 4));

      expect(sessions.sessions, hasLength(1));
      final session = sessions.sessions.single;
      expect(session.tag, 'deep work');
      expect(session.focusPlan, 'write report');
      expect(session.restPlan, 'stretch');
      // Recording happens on the zero-crossing tick, so elapsed equals
      // the full planned focus time.
      expect(session.focusElapsed, const Duration(seconds: 3));
    });
  });

  group('session metadata', () {
    testWidgets('typing keeps the timer intact', (tester) async {
      await pumpTimerPage(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'What task are you focusing on?'),
        'write report',
      );
      await tester.pump();

      expect(find.text('write report'), findsOneWidget);
      expect(find.text('00:03'), findsOneWidget);
      expect(find.text('Paused'), findsOneWidget);
    });
  });
}
