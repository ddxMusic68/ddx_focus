import 'package:flutter/material.dart';
import '../utils/constants.dart';

class WipScreen extends StatelessWidget {
  final String? feature;

  const WipScreen({super.key, this.feature});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WIP')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: AppColors.mintDark),
            const SizedBox(height: 16),
            Text(
              feature == null ? 'Work in progress' : '$feature is coming soon',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This feature has not been implemented yet.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
