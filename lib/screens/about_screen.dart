import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _websiteUrl = 'https://ddxmusic68.github.io/ddxwebsite/';

  static const _atomicHabitsUrl = 'https://jamesclear.com/atomic-habits';

  // Replace this text with why you made the app.
  static const _storyPlaceholder =
      'Hey my name is Jackson I made this app to help me focus using pomodoro technique and help me stay consistent with it. I hope you enjoy it!';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          const Icon(Icons.event_repeat, size: 64, color: AppColors.mintDark),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'ddx routine',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Why I made this app', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            _storyPlaceholder,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          _LinkTile(title: 'Visit the website', url: _websiteUrl),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final String title;
  final String url;

  const _LinkTile({required this.title, required this.url});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.link, color: AppColors.mintDark),
      title: Text(title),
      subtitle: Text(
        url.replaceFirst('https://', ''),
        style: theme.textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () => _open(context, url),
    );
  }

  Future<void> _open(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      messenger.showSnackBar(SnackBar(content: Text('Could not open $title')));
    }
  }
}
