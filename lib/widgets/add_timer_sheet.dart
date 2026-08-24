import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/timer_model.dart';
import '../providers/timer_provider.dart';

/// Modal bottom sheet for creating a new [PomodoroTimer].
///
/// Shows a name field plus focus/rest minute fields (defaulting to the
/// classic 25/5 split) with basic validation.
class AddTimerSheet extends StatefulWidget {
  const AddTimerSheet({super.key});

  @override
  State<AddTimerSheet> createState() => _AddTimerSheetState();
}

class _AddTimerSheetState extends State<AddTimerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _focusController = TextEditingController(text: '25');
  final _restController = TextEditingController(text: '5');

  @override
  void dispose() {
    _nameController.dispose();
    _focusController.dispose();
    _restController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final timer = PomodoroTimer(
      name: _nameController.text.trim(),
      focusTime: Duration(minutes: int.parse(_focusController.text)),
      restTime: Duration(minutes: int.parse(_restController.text)),
    );
    context.read<TimersProvider>().addTimer(timer);
    Navigator.of(context).pop();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a name';
    }
    return null;
  }

  String? _validateMinutes(String? value) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null || parsed <= 0) {
      return 'Must be a positive number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        24,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New Timer', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: _validateName,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _focusController,
                    decoration: const InputDecoration(
                      labelText: 'Focus (min)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: _validateMinutes,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _restController,
                    decoration: const InputDecoration(
                      labelText: 'Rest (min)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: _validateMinutes,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: const Text('Add Timer'),
            ),
          ],
        ),
      ),
    );
  }
}
