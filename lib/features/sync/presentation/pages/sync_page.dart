import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/connectivity_cubit.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../operations/domain/repositories/operations_repository.dart';
import '../../domain/entities/sync_entities.dart';

class SyncPage extends StatelessWidget {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sync Status')),
      body: FutureBuilder<List<SyncQueueItem>>(
        future: context.read<OperationsRepository>().getQueue(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          return BlocBuilder<ConnectivityCubit, SyncSnapshot>(
            builder: (context, status) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ConnectivityBanner(snapshot: status),
                  const SizedBox(height: 16),
                  Text(
                    'Last synced: ${Formatters.lastSynced(status.lastSyncedAt)}',
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () =>
                        context.read<ConnectivityCubit>().retryAll(),
                    child: const Text('Retry pending sync'),
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader('Sync Queue'),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    const Text('There are no queued transactions.')
                  else
                    ...items.map(
                      (item) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(item.entityType.name),
                          subtitle: Text(
                            [
                              item.idempotencyKey ?? item.localId,
                              if (item.errorMessage != null) item.errorMessage!,
                            ].join('\n'),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              StatusBadge.sync(item.syncStatus),
                              if (item.syncStatus.name == 'failed' ||
                                  item.syncStatus.name == 'conflict')
                                TextButton(
                                  onPressed: () => context
                                      .read<ConnectivityCubit>()
                                      .retryItem(item.localId),
                                  child: const Text('Retry'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Photos are uploaded separately from inventory transactions. A failed photo upload will never recreate the original dispatch or consumption.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
