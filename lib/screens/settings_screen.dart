import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
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
              _WipTile(
                icon: Icons.upload_file,
                title: 'Export Data',
                subtitle: 'Save data to file',
                feature: 'Export',
              ),
              _WipTile(
                icon: Icons.download,
                title: 'Import Data',
                subtitle: 'Load data from file',
                feature: 'Import',
              ),
              _WipTile(
                icon: Icons.delete_outline,
                title: 'Clear Local Data',
                subtitle: 'Delete all data on this device',
                feature: 'Clear local data',
              ),
              _WipTile(
                icon: Icons.cloud_off,
                title: 'Clear Cloud Data',
                subtitle: 'Delete all synced data',
                feature: 'Clear cloud data',
              ),
              const Divider(),
              const _SectionHeader(title: 'Info'),
              _WipTile(
                icon: Icons.info_outline,
                title: 'Learn more about this app',
                feature: 'About',
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
