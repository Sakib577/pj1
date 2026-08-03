import 'package:flutter/material.dart';
import '../state/finance_app_state.dart';

class NotificationHistoryPage extends StatelessWidget {
  const NotificationHistoryPage({super.key});
  @override
  Widget build(BuildContext context) {
    final items = FinanceAppScope.of(context).notifications.take(10).toList();
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
                  leading: const Icon(
                    Icons.notifications_outlined,
                    color: Color(0xFFF59E0B),
                  ),
                  title: Text(item.title),
                  subtitle: Text(item.body),
                );
              },
            ),
    );
  }
}
