import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ddx_focus/models/session_model.dart';
import 'package:ddx_focus/providers/sessions_provider.dart';
import 'package:ddx_focus/screens/session_edit_screen.dart';

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
    return Consumer<SessionsProvider>(
      builder: (context, sessionsProvider, child) {
        void add() => _addSession(context, sessionsProvider);

        return Scaffold(
          appBar: AppBar(title: const Text('History')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: add,
            icon: const Icon(Icons.add),
            label: const Text('Add session'),
          ),
          body: Builder(
            builder: (bodyContext) {
              // Newest first.
              final all = sessionsProvider.sessions.toList().reversed.toList();
              if (all.isEmpty) {
                return _EmptyState(onAdd: add);
              }

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
                      _SessionCard(
                        session: session,
                        onEdit: () =>
                            _editSession(context, sessionsProvider, session),
                        onDelete: () =>
                            _deleteSession(context, sessionsProvider, session),
                      ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Opens a blank form to create a brand-new session and records it.
  Future<void> _addSession(
    BuildContext context,
    SessionsProvider provider,
  ) async {
    final created = await Navigator.of(context).push<PomodoroSession>(
      MaterialPageRoute(
        builder: (_) => SessionEditScreen(
          session: PomodoroSession(
            tags: const [],
            focusPlan: '',
            restPlan: '',
            startedAt: DateTime.now(),
            focusElapsed: Duration.zero,
            restElapsed: Duration.zero,
          ),
          isNew: true,
        ),
      ),
    );
    if (created != null) {
      provider.record(created);
    }
  }

  Future<void> _editSession(
    BuildContext context,
    SessionsProvider provider,
    PomodoroSession session,
  ) async {
    final updated = await Navigator.of(context).push<PomodoroSession>(
      MaterialPageRoute(builder: (_) => SessionEditScreen(session: session)),
    );
    if (updated != null) {
      provider.update(session, updated);
    }
  }

  Future<void> _deleteSession(
    BuildContext context,
    SessionsProvider provider,
    PomodoroSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete session?'),
        content: const Text('This session will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      provider.delete(session);
    }
  }
}

/// Actions offered by a session card's overflow menu.
enum _MenuAction { edit, delete }

/// One session entry with its tags, plans, review recap, rating and time.
class _SessionCard extends StatelessWidget {
  final PomodoroSession session;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.session,
    required this.onEdit,
    required this.onDelete,
  });

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
                PopupMenuButton<_MenuAction>(
                  onSelected: (action) {
                    switch (action) {
                      case _MenuAction.edit:
                        onEdit();
                      case _MenuAction.delete:
                        onDelete();
                    }
                  },
                  icon: const Icon(Icons.more_vert, size: 20),
                  tooltip: 'Session actions',
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _MenuAction.edit,
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _MenuAction.delete,
                      child: ListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (session.focusPlan.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(session.focusPlan, style: theme.textTheme.bodyMedium),
            ],
            if (session.focusAccomplished != null &&
                session.focusAccomplished!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Did: ${session.focusAccomplished}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (session.focusReason != null &&
                session.focusReason!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Why: ${session.focusReason}',
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
                _TimeLabel(
                  icon: Icons.center_focus_strong,
                  label: 'focus',
                  text: _elapsedLabel(session.focusElapsed),
                ),
                const SizedBox(width: 12),
                _TimeLabel(
                  icon: Icons.self_improvement,
                  label: 'rest',
                  text: _elapsedLabel(session.restElapsed),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A labeled duration readout, e.g. a "focus" chip with its elapsed time.
class _TimeLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;

  const _TimeLabel({
    required this.icon,
    required this.label,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color)),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

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
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add a session'),
          ),
        ],
      ),
    );
  }
}
