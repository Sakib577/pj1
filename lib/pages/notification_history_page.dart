import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../state/finance_app_state.dart';

class NotificationHistoryPage extends StatelessWidget {
  const NotificationHistoryPage({super.key});
  @override
  Widget build(BuildContext context) {
    final items = FinanceAppScope.of(context).notifications;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: items.isEmpty
          ? const Center(child: Text('No notifications yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (_, index) {
                final item = items[index];
                return ListTile(
                  leading: Icon(
                    _iconFor(item),
                    color: _colorFor(item),
                  ),
                  title: Text(item.title),
                  subtitle: Text(
                    '${item.body}\n${_timeLabel(item.createdAt)}',
                  ),
                );
              },
            ),
    );
  }

  IconData _iconFor(AppNotification item) {
    if (item.title == 'Budget overspent') {
      return Icons.warning_amber_rounded;
    }
    if (item.title == 'Budget at risk') {
      return Icons.trending_down_rounded;
    }
    return Icons.notifications_outlined;
  }

  Color _colorFor(AppNotification item) {
    if (item.title == 'Budget overspent') return const Color(0xFFDC2626);
    return const Color(0xFFF59E0B);
  }

  String _timeLabel(DateTime date) {
    final month = _months[date.month - 1];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$month ${date.day}, $hour:$minute $period';
  }

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}
