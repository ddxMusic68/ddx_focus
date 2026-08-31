import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/sessions_provider.dart';
import '../providers/tags_provider.dart';
import '../providers/timer_provider.dart';
import '../utils/constants.dart';
import 'about_screen.dart';
import 'data_screen.dart';
import 'wip_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              const _SectionHeader(title: 'Appearance'),
              RadioGroup<AppThemeMode>(
                groupValue: settings.themeMode,
                onChanged: (mode) {
                  if (mode != null) settings.setThemeMode(mode);
                },
                child: Column(
                  children: [
                    _ThemeTile(title: 'System', value: AppThemeMode.system),
                    _ThemeTile(title: 'Light', value: AppThemeMode.light),
                    _ThemeTile(title: 'Dark', value: AppThemeMode.dark),
                  ],
                ),
              ),
              const Divider(),
              const _SectionHeader(title: 'Timers'),
              SwitchListTile(
                secondary: const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.mintDark,
                ),
                title: const Text('Background alarms'),
                subtitle: const Text(
                  'Alert when a phase ends while the app is minimized',
                ),
                value: settings.backgroundAlarms,
                onChanged: (enabled) => settings.setBackgroundAlarms(enabled),
              ),
              RadioGroup<AlertMode>(
                groupValue: settings.alertMode,
                onChanged: (mode) {
                  if (mode != null) settings.setAlertMode(mode);
                },
                child: Column(
                  children: [
                    _AlertModeTile(
                      title: 'Alarm',
                      subtitle: 'Full-screen ring with sound',
                      value: AlertMode.alarm,
                    ),
                    _AlertModeTile(
                      title: 'Notification',
                      subtitle: 'Quiet - no sound, just a ring',
                      value: AlertMode.notification,
                    ),
                  ],
                ),
              ),
              const Divider(),
              const _SectionHeader(title: 'Sync'),
              _WipTile(
                icon: Icons.cloud,
                title: 'Connect to Dropbox',
                subtitle: 'Sync data across devices',
                feature: 'Dropbox sync',
              ),
              _WipTile(
                icon: Icons.sync,
                title: 'Sync Now',
                subtitle: 'Push pending changes',
                feature: 'Sync',
              ),
              const Divider(),
              const _SectionHeader(title: 'Data'),
              ListTile(
                leading: const Icon(
                  Icons.upload_file,
                  color: AppColors.mintDark,
                ),
                title: const Text('Export Data'),
                subtitle: const Text('Save data to file'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DataScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.download, color: AppColors.mintDark),
                title: const Text('Import Data'),
                subtitle: const Text('Load data from file'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DataScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.mintDark,
                ),
                title: const Text('Clear Local Data'),
                subtitle: const Text('Delete all data on this device'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _clearLocalData(context),
              ),
              _WipTile(
                icon: Icons.cloud_off,
                title: 'Clear Cloud Data',
                subtitle: 'Delete all synced data',
                feature: 'Clear cloud data',
              ),
              const Divider(),
              const _SectionHeader(title: 'Info'),
              ListTile(
                leading: const Icon(
                  Icons.info_outline,
                  color: AppColors.mintDark,
                ),
                title: const Text('Learn more about this app'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  );
                },
              ),
              const Divider(),
              const _VersionTile(),
            ],
          );
        },
      ),
    );
  }
}

class _WipTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String feature;

  const _WipTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.feature,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.mintDark),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.mintLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'WIP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 18),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WipScreen(feature: feature)),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final String title;
  final AppThemeMode value;

  const _ThemeTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Radio<AppThemeMode>(value: value),
        Text(title),
      ],
    );
  }
}

class _AlertModeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final AlertMode value;

  const _AlertModeTile({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Radio<AlertMode>(value: value),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyLarge),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionTile extends StatelessWidget {
  const _VersionTile();

  static final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _packageInfo,
      builder: (context, snapshot) {
        final String label;
        if (snapshot.connectionState != ConnectionState.done) {
          label = '...';
        } else if (snapshot.hasError) {
          debugPrint('PackageInfo error: ${snapshot.error}');
          label = 'Unknown';
        } else {
          final version = snapshot.data?.version ?? '';
          final buildNumber = snapshot.data?.buildNumber ?? '';
          label = version.isEmpty && buildNumber.isEmpty
              ? 'Unknown'
              : 'v$version+$buildNumber';
        }
        return ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Version'),
          subtitle: Text(label),
        );
      },
    );
  }
}

Future<void> _clearLocalData(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final sessions = context.read<SessionsProvider>();
  final timers = context.read<TimersProvider>();
  final tags = context.read<TagsProvider>();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Clear Local Data'),
      content: const Text(
        'This will delete all sessions, timers and tags on this device. '
        'This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Clear'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  sessions.replaceAll([]);
  timers.replaceAll([]);
  tags.replaceAll([]);
  messenger.showSnackBar(
    const SnackBar(content: Text('All local data has been cleared.')),
  );
}
