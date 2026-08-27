import 'package:flutter/material.dart';

/// Data captured by [SessionReviewScreen] when the user saves a round.
class SessionReviewResult {
  const SessionReviewResult({
    required this.doneText,
    required this.focusRating,
    this.reason,
  });

  /// What the user says they got done during the focus phase.
  final String doneText;

  /// Self-reported focus quality, from 1 to 5 stars.
  final int focusRating;

  /// Optional explanation for the rating; null when left blank.
  final String? reason;
}

/// Full-screen form shown after a completed focus + rest round.
///
/// Asks what the user got done, how focused they were (1-5 stars), and an
/// optional reason for the rating. Pops with a [SessionReviewResult], or
/// with null when the user backs out without saving.
class SessionReviewScreen extends StatefulWidget {
  const SessionReviewScreen({super.key});

  @override
  State<SessionReviewScreen> createState() => _SessionReviewScreenState();
}

class _SessionReviewScreenState extends State<SessionReviewScreen> {
  final _doneController = TextEditingController();
  final _reasonController = TextEditingController();
  int _rating = 0;

  @override
  void dispose() {
    _doneController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _save() {
    final reason = _reasonController.text.trim();
    Navigator.of(context).pop(
      SessionReviewResult(
        doneText: _doneController.text.trim(),
        focusRating: _rating,
        reason: reason.isEmpty ? null : reason,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Focus round complete')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _doneController,
                    decoration: const InputDecoration(
                      labelText: 'What did you get done?',
                      prefixIcon: Icon(Icons.task_alt),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
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
                  TextField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Why? (optional)',
                      prefixIcon: Icon(Icons.psychology_alt),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _rating == 0 ? null : _save,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Save round'),
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
