import 'package:flutter/material.dart';

import '../models/timer_model.dart';
import '../screens/timer_page.dart';
import '../utils/constants.dart';

/// Home screen card that displays a [PomodoroTimer] configuration.
///
/// Tapping the card opens the full-screen runner. Deletion is delegated to
/// the parent via [onDelete]; this widget stays provider-free.
class TimerCard extends StatelessWidget {
  final PomodoroTimer timer;
  final VoidCallback onDelete;

  const TimerCard({super.key, required this.timer, required this.onDelete});

  String _format(Duration d) {
    final minutes = d.inMinutes;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final rest = minutes % 60;
      return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.timer_outlined, color: AppColors.mintDark),
        title: Text(timer.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          'Focus ${_format(timer.focusTime)} · Rest ${_format(timer.restTime)}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline),
                title: Text('Delete'),
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TimerPage(timer: timer)),
          );
        },
      ),
    );
  }
}
