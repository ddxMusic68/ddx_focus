import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ddx_focus/models/timer_model.dart';
import 'package:ddx_focus/providers/sessions_provider.dart';
import 'package:ddx_focus/providers/settings_provider.dart';
import 'package:ddx_focus/providers/tags_provider.dart';
import 'package:ddx_focus/screens/timer_page.dart';
import 'package:ddx_focus/utils/constants.dart';

const _timer = PomodoroTimer(
  name: 'Test',
  focusTime: Duration(seconds: 3),
  restTime: Duration(seconds: 2),
);

/// Controllable wall clock. The countdown is derived from this instead of
/// tick counts, so to advance a pump we must also advance the clock.
DateTime _now = DateTime(2020, 1, 1);

void _resetClock() => _now = DateTime(2020, 1, 1);

/// Advances the fake wall clock and pumps [d] of fake time together.
Future<void> _pumpFor(WidgetTester tester, Duration d) async {
  _now = _now.add(d);
  await tester.pump(d);
}

void main() {
  setUp(_resetClock);

  Future<void> pumpTimerPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TagsProvider>(create: (_) => TagsProvider()),
          ChangeNotifierProvider<SessionsProvider>(
            create: (_) => SessionsProvider(),
          ),
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(),
          ),
        ],
        child: MaterialApp(
          home: TimerPage(timer: _timer, now: () => _now),
        ),
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

      // Run focus to zero (3s): enters overtime and shows the focus-complete
      // SnackBar with its "Silence" action. The extra pump lets the SnackBar
      // (shown via a post-frame callback) actually render.
      await _pumpFor(tester, const Duration(seconds: 3));
      await tester.pump();

      expect(find.text('Silence'), findsOneWidget);
      expect(find.text('Overtime'), findsOneWidget);
      expect(find.text('OVERTIME'), findsOneWidget);

      // A further second lands us at -00:01.
      await _pumpFor(tester, const Duration(seconds: 1));
      expect(find.text('-00:01'), findsOneWidget);
    });

    testWidgets(
      'advancing from overtime activates rest and opens the review screen '
      'when rest ends',
      (tester) async {
        await pumpTimerPage(tester);

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();
        await _pumpFor(tester, const Duration(seconds: 4));

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();

        final context = tester.element(find.byType(TimerPage));
        final theme = Theme.of(context);
        final restColor = tester.widget<Text>(find.text('00:02')).style?.color;
        final focusColor = tester.widget<Text>(find.text('00:03')).style?.color;
        expect(restColor, AppColors.coral);
        expect(focusColor, theme.disabledColor);

        // Rest runs out and the post-round review screen opens instead of
        // resetting right away.
        await _pumpFor(tester, const Duration(seconds: 2));
        await tester.pumpAndSettle();

        expect(find.text('How focused were you?'), findsOneWidget);

        // Backing out still resets the runner to an idle focus phase.
        await tester.pageBack();
        await tester.pumpAndSettle();

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

    testWidgets('several chips can be selected at the same time', (
      tester,
    ) async {
      await pumpTimerPage(tester);

      Future<void> addTag(String name) async {
        await tester.enterText(find.widgetWithText(TextField, 'New tag'), name);
        await tester.tap(find.byTooltip('Add tag'));
        await tester.pump();
      }

      bool isSelected(String name) => tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, name))
          .selected;

      await addTag('work');
      await addTag('study');

      // Both freshly created tags stay selected side by side.
      expect(isSelected('work'), isTrue);
      expect(isSelected('study'), isTrue);

      // Tapping a chip toggles only that chip off.
      await tester.tap(find.text('work'));
      await tester.pump();
      expect(isSelected('work'), isFalse);
      expect(isSelected('study'), isTrue);

      // And tapping it again brings both back.
      await tester.tap(find.text('work'));
      await tester.pump();
      expect(isSelected('work'), isTrue);
      expect(isSelected('study'), isTrue);
    });
  });

  group('session recording', () {
    testWidgets('completing focus and rest records a reviewed session', (
      tester,
    ) async {
      final sessions = SessionsProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TagsProvider>(create: (_) => TagsProvider()),
            ChangeNotifierProvider<SessionsProvider>.value(value: sessions),
            ChangeNotifierProvider<SettingsProvider>(
              create: (_) => SettingsProvider(),
            ),
          ],
          child: MaterialApp(
            home: TimerPage(timer: _timer, now: () => _now),
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'New tag'),
        'deep work',
      );
      await tester.tap(find.byTooltip('Add tag'));
      await tester.enterText(
        find.widgetWithText(TextField, 'New tag'),
        'study',
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

      // The tag chips grow the page; bring the FAB into view first.
      await tester.ensureVisible(find.byType(FloatingActionButton));
      await tester.pump();

      // Run the full round: 3s focus plus 1s of overtime, then rest.
      await tester.tap(find.byType(FloatingActionButton));
      await _pumpFor(tester, const Duration(seconds: 4));

      await tester.ensureVisible(find.byType(FloatingActionButton));
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await _pumpFor(tester, const Duration(seconds: 2));

      // Rest ran out and the review screen opened.
      await tester.pumpAndSettle();
      expect(find.text('What did you get done?'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'What did you get done?'),
        'finished draft',
      );
      await tester.tap(find.byIcon(Icons.star_border).at(3));
      await tester.enterText(
        find.widgetWithText(TextField, 'Why? (optional)'),
        'phone buzzed',
      );

      await tester.tap(find.text('Save round'));
      await tester.pumpAndSettle();

      expect(sessions.sessions, hasLength(1));
      final session = sessions.sessions.single;
      expect(session.tags, unorderedEquals(['deep work', 'study']));
      expect(session.focusPlan, 'write report');
      expect(session.restPlan, 'stretch');
      expect(session.focusRating, 4);
      expect(session.focusAccomplished, 'finished draft');
      expect(session.focusReason, 'phone buzzed');
      // Elapsed covers the planned 3s plus the 1s of overtime before the
      // user advanced to rest.
      expect(session.focusElapsed, const Duration(seconds: 4));

      // The runner reset to an idle focus phase behind the review screen.
      expect(find.text('00:03'), findsOneWidget);
      expect(find.text('Paused'), findsOneWidget);
    });
  });

  group('skipping', () {
    testWidgets('skipping focus jumps to rest and shortens the session', (
      tester,
    ) async {
      final sessions = SessionsProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TagsProvider>(create: (_) => TagsProvider()),
            ChangeNotifierProvider<SessionsProvider>.value(value: sessions),
            ChangeNotifierProvider<SettingsProvider>(
              create: (_) => SettingsProvider(),
            ),
          ],
          child: MaterialApp(
            home: TimerPage(timer: _timer, now: () => _now),
          ),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await _pumpFor(tester, const Duration(seconds: 1));

      await tester.tap(find.byTooltip('Skip focus'));
      await tester.pump();

      final context = tester.element(find.byType(TimerPage));
      final theme = Theme.of(context);
      expect(
        tester.widget<Text>(find.text('00:02')).style?.color,
        AppColors.coral,
      );
      expect(
        tester.widget<Text>(find.text('00:03')).style?.color,
        theme.disabledColor,
      );

      // Let rest finish; the review opens with the shortened elapsed.
      await _pumpFor(tester, const Duration(seconds: 2));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(sessions.sessions, hasLength(1));
      expect(sessions.sessions.single.focusElapsed, const Duration(seconds: 1));
    });

    testWidgets('skipping rest opens the review screen right away', (
      tester,
    ) async {
      final sessions = SessionsProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TagsProvider>(create: (_) => TagsProvider()),
            ChangeNotifierProvider<SessionsProvider>.value(value: sessions),
            ChangeNotifierProvider<SettingsProvider>(
              create: (_) => SettingsProvider(),
            ),
          ],
          child: MaterialApp(
            home: TimerPage(timer: _timer, now: () => _now),
          ),
        ),
      );

      // Reach rest quickly via overtime, then skip it.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await _pumpFor(tester, const Duration(seconds: 4));
      await tester.ensureVisible(find.byType(FloatingActionButton));
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      await tester.tap(find.byTooltip('Skip rest'));
      await tester.pumpAndSettle();

      expect(find.text('How focused were you?'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(sessions.sessions, hasLength(1));
      expect(sessions.sessions.single.focusRating, isNull);
      expect(find.text('Paused'), findsOneWidget);
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
