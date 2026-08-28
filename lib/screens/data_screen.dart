import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/sessions_provider.dart';
import '../providers/tags_provider.dart';
import '../providers/timer_provider.dart';
import '../services/data_export_import.dart';
import '../utils/constants.dart';

/// Lets the user export all data to a JSON file of their choosing, or import
/// data back from one. Import replaces the current data.
class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<SessionsProvider>();
    final timers = context.watch<TimersProvider>();
    final tags = context.watch<TagsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Data')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Export your sessions, timers and tags to a JSON file, or '
              'import them back. Importing replaces all current data.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file, color: AppColors.mintDark),
            title: const Text('Export Data'),
            subtitle: Text(
              '${sessions.sessions.length} sessions, '
              '${timers.timers.length} timers, '
              '${tags.tags.length} tags',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _export(context, sessions, timers, tags),
          ),
          ListTile(
            leading: const Icon(Icons.download, color: AppColors.mintDark),
            title: const Text('Import Data'),
            subtitle: const Text('Load data from a JSON file'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _import(context, sessions, timers, tags),
          ),
        ],
      ),
    );
  }

  Future<void> _export(
    BuildContext context,
    SessionsProvider sessions,
    TimersProvider timers,
    TagsProvider tags,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: Text(
          'Export ${sessions.sessions.length} sessions, '
          '${timers.timers.length} timers and ${tags.tags.length} tags to a '
          'JSON file?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Export'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final directory = await FilePicker.getDirectoryPath(
      dialogTitle: 'Choose a location to save the export',
    );
    if (directory == null) return;

    try {
      final json = buildExportJson(sessions, timers, tags);
      final path = '$directory${Platform.pathSeparator}ddx_focus_export.json';
      final file = File(path);
      await file.writeAsString(json);
      messenger.showSnackBar(SnackBar(content: Text('Exported to $path')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _import(
    BuildContext context,
    SessionsProvider sessions,
    TimersProvider timers,
    TagsProvider tags,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Choose a JSON file to import',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;

    final String content;
    try {
      content = await File(path).readAsString();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not read the file: $e')),
      );
      return;
    }

    final data = parseImportJson(content);
    if (data == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Import failed: the file is not a valid export, or its format '
            'is not supported.',
          ),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: Text(
          'Import ${data.sessions.length} sessions, '
          '${data.timers.length} timers and ${data.tags.length} tags?\n\n'
          'This will replace all current data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    sessions.replaceAll(data.sessions);
    timers.replaceAll(data.timers);
    tags.replaceAll(data.tags);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Imported ${data.sessions.length} sessions, '
          '${data.timers.length} timers and ${data.tags.length} tags.',
        ),
      ),
    );
  }
}
