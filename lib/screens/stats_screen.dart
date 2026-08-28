import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/session_model.dart';
import '../providers/sessions_provider.dart';
import '../utils/constants.dart';

/// How far back the statistics window reaches.
enum _Frequency {
  week('Week', Duration(days: 7)),
  month('Month', Duration(days: 30)),
  year('Year', Duration(days: 365));

  const _Frequency(this.label, this.window);

  final String label;
  final Duration window;
}

/// What the pie chart decomposes.
enum _Query {
  focusVsRest('Focus vs rest'),
  tags('Tags');

  const _Query(this.label);

  final String label;
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  _Frequency _frequency = _Frequency.week;
  _Query _query = _Query.focusVsRest;

  /// Fixed palette so slice colors stay stable across rebuilds.
  static const _palette = <Color>[
    AppColors.mintDark,
    Colors.orangeAccent,
    Colors.indigoAccent,
    Colors.pinkAccent,
    Colors.tealAccent,
    Colors.purpleAccent,
    Colors.limeAccent,
    Colors.redAccent,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: Consumer<SessionsProvider>(
        builder: (context, provider, child) {
          final sessions = _inWindow(provider.sessions, _frequency.window);
          if (sessions.isEmpty) {
            return _EmptyState(frequency: _frequency.label);
          }
          return _buildContent(context, sessions);
        },
      ),
    );
  }

  /// Filters [all] to those started within the last [window].
  List<PomodoroSession> _inWindow(List<PomodoroSession> all, Duration window) {
    final cutoff = DateTime.now().subtract(window);
    return all.where((s) => !s.startedAt.isBefore(cutoff)).toList();
  }

  Widget _buildContent(BuildContext context, List<PomodoroSession> sessions) {
    final theme = Theme.of(context);
    final slices = _query == _Query.focusVsRest
        ? _focusVsRestSlices(sessions)
        : _tagSlices(sessions);
    final totalFocus = sessions.fold<Duration>(
      Duration.zero,
      (sum, s) => sum + s.focusElapsed,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<_Frequency>(
                  segments: [
                    for (final f in _Frequency.values)
                      ButtonSegment(value: f, label: Text(f.label)),
                  ],
                  selected: {_frequency},
                  onSelectionChanged: (selection) {
                    setState(() => _frequency = selection.first);
                  },
                ),
                const SizedBox(height: 12),
                SegmentedButton<_Query>(
                  segments: [
                    for (final q in _Query.values)
                      ButtonSegment(value: q, label: Text(q.label)),
                  ],
                  selected: {_query},
                  onSelectionChanged: (selection) {
                    setState(() => _query = selection.first);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  '${sessions.length} session${sessions.length == 1 ? '' : 's'} '
                  'in the last ${_frequency.label.toLowerCase()}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                if (slices.isEmpty)
                  _NoDataCard(
                    message: _query == _Query.focusVsRest
                        ? 'No focus or rest time was recorded in this period.'
                        : 'No tag or untagged focus time was recorded in '
                              'this period.',
                  )
                else ...[
                  Container(
                    height: 320,
                    padding: const EdgeInsets.all(8),
                    child: PieChart(
                      PieChartData(
                        sections: slices,
                        sectionsSpace: 2,
                        centerSpaceRadius: 48,
                        startDegreeOffset: -90,
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {},
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Total focus time: ${_formatDuration(totalFocus)}',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  _Legend(slices: slices),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _focusVsRestSlices(List<PomodoroSession> sessions) {
    var focus = Duration.zero;
    var rest = Duration.zero;
    for (final s in sessions) {
      focus += s.focusElapsed;
      rest += s.restElapsed;
    }
    return [
      if (focus > Duration.zero) _slice('Focus', focus, _palette[0]),
      if (rest > Duration.zero) _slice('Rest', rest, _palette[1]),
    ];
  }

  List<PieChartSectionData> _tagSlices(List<PomodoroSession> sessions) {
    final Map<String, Duration> byTag = {};
    var untagged = Duration.zero;
    for (final s in sessions) {
      if (s.tags.isEmpty) {
        untagged += s.focusElapsed;
      } else {
        for (final tag in s.tags) {
          byTag[tag] = (byTag[tag] ?? Duration.zero) + s.focusElapsed;
        }
      }
    }
    final entries = byTag.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final slices = <PieChartSectionData>[];
    var i = 0;
    for (final entry in entries) {
      if (entry.value > Duration.zero) {
        slices.add(
          _slice(entry.key, entry.value, _palette[i % _palette.length]),
        );
        i++;
      }
    }
    if (untagged > Duration.zero) {
      slices.add(_slice('Untagged', untagged, _palette[i % _palette.length]));
    }
    return slices;
  }

  PieChartSectionData _slice(String title, Duration value, Color color) {
    final minutes = value.inMinutes;
    return PieChartSectionData(
      value: minutes.toDouble(),
      color: color,
      title: title,
      radius: 60,
      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    if (minutes < 60) return '$minutes min';
    return '${d.inHours} hr ${minutes % 60} min';
  }
}

class _Legend extends StatelessWidget {
  final List<PieChartSectionData> slices;

  const _Legend({required this.slices});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        for (final slice in slices)
          if (slice.value > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: slice.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${slice.title} (${slice.value.round()} min)',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String frequency;

  const _EmptyState({required this.frequency});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('No stats yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'No sessions in the last ${frequency.toLowerCase()}. '
              'Complete focus sessions to see your stats here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown in place of the pie chart when there are sessions in the window but
/// no measurable duration to plot (e.g. all recorded times are zero).
class _NoDataCard extends StatelessWidget {
  final String message;

  const _NoDataCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
