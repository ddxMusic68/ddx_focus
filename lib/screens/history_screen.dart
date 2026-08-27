import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ddx_focus/models/session_model.dart';
import 'package:ddx_focus/providers/sessions_provider.dart';

/// Shows every completed focus session, newest first, grouped under
/// day headers (Today / Yesterday / date).
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  /// Localized day header for [day]: "Today", "Yesterday", or a date.
  String _dayLabel(BuildContext context, DateTime day) {
    final localizations = MaterialLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return localizations.formatCompactDate(day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Consumer<SessionsProvider>(
        builder: (context, sessionsProvider, child) {
          // Newest first.
          final all = sessionsProvider.sessions.toList().reversed.toList();
          if (all.isEmpty) return const _EmptyState();

          // Group by the local-midnight day the session started on.
          final Map<DateTime, List<PomodoroSession>> byDay = {};
          for (final session in all) {
            final day = DateTime(
              session.startedAt.year,
              session.startedAt.month,
              session.startedAt.day,
            );
            byDay.putIfAbsent(day, () => []).add(session);
          }
          final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final day in days) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    _dayLabel(context, day),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                for (final session in byDay[day]!)
                  _SessionCard(session: session),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// One session entry with its tags, plans, review recap, rating and time.
class _SessionCard extends StatelessWidget {
  final PomodoroSession session;

  const _SessionCard({required this.session});

  String _clockTime(DateTime startedAt) {
    final h = startedAt.hour % 12 == 0 ? 12 : startedAt.hour % 12;
    final m = startedAt.minute.toString().padLeft(2, '0');
    final period = startedAt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String _elapsedLabel(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    if (minutes == 0) return '${seconds}s';
    if (minutes < 60) return '${minutes}m ${seconds}s';
    return '${d.inHours}h ${d.inMinutes % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 0; i < session.tags.length; i++) ...[
                  Chip(
                    label: Text(session.tags[i]),
                    visualDensity: VisualDensity.compact,
                    labelStyle: theme.textTheme.labelSmall,
                    backgroundColor: theme.colorScheme.secondaryContainer,
                  ),
                  if (i < session.tags.length - 1) const SizedBox(width: 6),
                ],
                if (session.tags.isNotEmpty) const Spacer(),
                Text(
                  _clockTime(session.startedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (session.focusPlan.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(session.focusPlan, style: theme.textTheme.bodyMedium),
            ],
            if (session.focusReview != null &&
                session.focusReview!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                session.focusReview!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.self_improvement,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    session.restPlan.isEmpty ? '—' : session.restPlan,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (session.focusRating != null) ...[
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(
                    '${session.focusRating}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  _elapsedLabel(session.focusElapsed),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text('No sessions yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Your completed pomodoro sessions will show up here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
