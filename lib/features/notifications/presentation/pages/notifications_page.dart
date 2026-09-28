import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../bloc/notification_bloc.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        if (state.loading) return const SkeletonList();
        if (state.items.isEmpty) {
          return const EmptyView(
            title: 'No notifications',
            message: 'Operational alerts will appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = state.items[index];
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  '${item.description}\n${Formatters.relative(item.createdAt)}',
                ),
                isThreeLine: true,
                onTap: () async {
                  await context.read<NotificationBloc>().markRead(item.id);
                  if (item.route != null && context.mounted) {
                    context.push(item.route!);
                  }
                },
              ),
            );
          },
        );
      },
    ),
    );
  }
}
