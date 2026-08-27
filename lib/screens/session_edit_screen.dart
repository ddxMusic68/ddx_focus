import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/session_model.dart';
import '../providers/tags_provider.dart';

/// Full-screen form to edit an existing [PomodoroSession] in place.
///
/// Every field is editable: the focus plan, rest plan, tags, rating, review
/// recap, and even the started time and the two measured (focus/rest)
/// durations. Pops with the edited session, or with null when the user
/// backs out without saving.
class SessionEditScreen extends StatefulWidget {
  const SessionEditScreen({super.key, required this.session});

  /// The session being edited; unchanged fields are preserved.
  final PomodoroSession session;

  @override
  State<SessionEditScreen> createState() => _SessionEditScreenState();
}

class _SessionEditScreenState extends State<SessionEditScreen> {
  late final TextEditingController _focusPlanController = TextEditingController(
    text: widget.session.focusPlan,
  );
  late final TextEditingController _restPlanController = TextEditingController(
    text: widget.session.restPlan,
  );
  late final TextEditingController _reviewDoneController =
      TextEditingController(text: widget.session.focusAccomplished ?? '');
  late final TextEditingController _reviewReasonController =
      TextEditingController(text: widget.session.focusReason ?? '');
  late final TextEditingController _startedAtController = TextEditingController(
    text: _formatDateTime(widget.session.startedAt),
  );
  late final TextEditingController _focusMinutesController =
      TextEditingController(
        text: widget.session.focusElapsed.inMinutes.toString(),
      );
  late final TextEditingController _restMinutesController =
      TextEditingController(
        text: widget.session.restElapsed.inMinutes.toString(),
      );

  late DateTime _startedAt = widget.session.startedAt;
  late int _rating = widget.session.focusRating ?? 0;
  late final Set<String> _selectedTags = {...widget.session.tags};

  @override
  void dispose() {
    _focusPlanController.dispose();
    _restPlanController.dispose();
    _reviewDoneController.dispose();
    _reviewReasonController.dispose();
    _startedAtController.dispose();
    _focusMinutesController.dispose();
    _restMinutesController.dispose();
    super.dispose();
  }

  static String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  Future<void> _pickStartedAt() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _startedAt,
      firstDate: DateTime(now.year - 5),
      lastDate: now.add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startedAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _startedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _startedAtController.text = _formatDateTime(_startedAt);
    });
  }

  Duration _parseMinutes(TextEditingController controller) {
    final minutes = int.tryParse(controller.text.trim());
    return Duration(minutes: minutes == null || minutes < 0 ? 0 : minutes);
  }

  void _save() {
    Navigator.of(context).pop(
      widget.session.copyWith(
        tags: _selectedTags.toList(),
        focusPlan: _focusPlanController.text.trim(),
        restPlan: _restPlanController.text.trim(),
        startedAt: _startedAt,
        focusElapsed: _parseMinutes(_focusMinutesController),
        restElapsed: _parseMinutes(_restMinutesController),
        focusRating: _rating == 0 ? null : _rating,
        focusAccomplished: _reviewDoneController.text.trim().isEmpty
            ? null
            : _reviewDoneController.text.trim(),
        focusReason: _reviewReasonController.text.trim().isEmpty
            ? null
            : _reviewReasonController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit session')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TagsEditor(
                    selected: _selectedTags,
                    onChanged: (tags) => setState(
                      () => _selectedTags
                        ..clear()
                        ..addAll(tags),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _focusMinutesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Focus (min)',
                            prefixIcon: Icon(Icons.timer),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _restMinutesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Rest (min)',
                            prefixIcon: Icon(Icons.timer_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: _pickStartedAt,
                        icon: const Icon(Icons.edit_calendar),
                        tooltip: 'Edit started time',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Started:  ${_startedAtController.text}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _focusPlanController,
                    decoration: const InputDecoration(
                      labelText: 'Focus plan',
                      prefixIcon: Icon(Icons.center_focus_strong),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _restPlanController,
                    decoration: const InputDecoration(
                      labelText: 'Rest plan',
                      prefixIcon: Icon(Icons.self_improvement),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reviewDoneController,
                    decoration: const InputDecoration(
                      labelText: 'What did you accomplish?',
                      prefixIcon: Icon(Icons.task_alt),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'How focused were you?',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 1; i <= 5; i++)
                        IconButton(
                          onPressed: () => setState(() => _rating = i),
                          icon: Icon(
                            i <= _rating ? Icons.star : Icons.star_border,
                            color: theme.colorScheme.primary,
                            size: 36,
                          ),
                          tooltip: '$i star${i > 1 ? 's' : ''}',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reviewReasonController,
                    decoration: const InputDecoration(
                      labelText: 'Why this focus rating?',
                      prefixIcon: Icon(Icons.psychology_alt),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Save changes'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Multi-select tag editor backed by the app's [TagsProvider].
class _TagsEditor extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const _TagsEditor({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<TagsProvider>(
      builder: (context, tagsProvider, child) {
        final tags = tagsProvider.tags;
        if (tags.isEmpty) {
          return Text(
            'No tags yet — create them on the timer screen.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in tags)
              FilterChip(
                label: Text(tag),
                selected: selected.contains(tag),
                onSelected: (value) {
                  final next = {...selected};
                  if (value) {
                    next.add(tag);
                  } else {
                    next.remove(tag);
                  }
                  onChanged(next);
                },
              ),
          ],
        );
      },
    );
  }
}
