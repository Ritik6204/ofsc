import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../dispatch/presentation/bloc/dispatch_bloc.dart';
import '../bloc/receiving_bloc.dart';

class IncomingListPage extends StatelessWidget {
  const IncomingListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Materials'),
        actions: [
          IconButton(
            onPressed: () => context.push('/consumption/history'),
            icon: const Icon(Icons.history),
            tooltip: 'Consumption history',
          ),
        ],
      ),
      body: BlocBuilder<DispatchBloc, DispatchState>(
      builder: (context, state) {
        if (state.status == DispatchListStatus.loading) {
          return const SkeletonList();
        }
        final incoming = state.items
            .where(
              (item) =>
                  item.status != DispatchStatus.pendingDispatch &&
                  item.status != DispatchStatus.verifying,
            )
            .toList();
        if (incoming.isEmpty) {
          return const EmptyView(
            title: 'No incoming materials',
            message: 'Dispatches headed to your site will appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: incoming.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = incoming[index];
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(item.projectName),
                subtitle: Text(
                  'Dispatch #${item.dispatchCode ?? item.requestCode}\nFrom: ${item.storeName}',
                ),
                isThreeLine: true,
                trailing: StatusBadge.dispatch(item.status),
                onTap: () => context.push('/incoming/${item.id}'),
              ),
            );
          },
        );
      },
    ),
    );
  }
}

class ReceivingPage extends StatelessWidget {
  const ReceivingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReceivingWorkflowCubit, ReceivingWorkflowState>(
      listener: (context, state) {
        if (state.phase == ReceivingPhase.pendingSync) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receiving saved. It will sync when internet returns.'),
            ),
          );
          context.go('/home');
        }
        if (state.errorMessage != null && state.phase == ReceivingPhase.failed) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        if (state.request == null) {
          return const Scaffold(body: SkeletonList());
        }
        final request = state.request!;
        return Scaffold(
          appBar: AppBar(title: const Text('Receive Materials')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                request.projectName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text('From: ${request.storeName}'),
              Text('Dispatch #${request.dispatchCode ?? request.requestCode}'),
              const SizedBox(height: 16),
              ...state.lines.map((line) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.material.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Dispatched: ${Formatters.qtyUnit(line.dispatchedQty, line.material.unit)}',
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<ReceivingStatus>(
                          segments: ReceivingStatus.values
                              .map(
                                (status) => ButtonSegment(
                                  value: status,
                                  label: Text(status.label, maxLines: 1),
                                ),
                              )
                              .toList(),
                          selected: {line.status},
                          onSelectionChanged: (value) => context
                              .read<ReceivingWorkflowCubit>()
                              .updateStatus(line.material.id, value.first),
                        ),
                        if (line.status != ReceivingStatus.notReceived)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: TextFormField(
                              initialValue: '${line.receivedQty ?? 0}',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Received quantity',
                              ),
                              onChanged: (value) {
                                context
                                    .read<ReceivingWorkflowCubit>()
                                    .updateQuantity(
                                      line.material.id,
                                      double.tryParse(value) ?? 0,
                                    );
                              },
                            ),
                          ),
                        if (line.hasDiscrepancy) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Difference: ${Formatters.quantity(line.difference)}',
                            style: const TextStyle(color: AppColors.danger),
                          ),
                          TextFormField(
                            initialValue: line.reason ?? '',
                            decoration: const InputDecoration(
                              labelText: 'Reason',
                            ),
                            onChanged: (value) => context
                                .read<ReceivingWorkflowCubit>()
                                .updateReason(line.material.id, value),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              OutlinedButton.icon(
                onPressed: () async {
                  final file = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                    imageQuality: 70,
                    maxWidth: 1600,
                  );
                  if (file != null && context.mounted) {
                    context.read<ReceivingWorkflowCubit>().addPhoto(
                      file.path,
                      PhotoKind.siteEvidence,
                    );
                  }
                },
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Capture receiving photo'),
              ),
              ...state.photos.map(
                (photo) =>
                    PhotoStatusTile(label: photo.kind.name, status: photo.syncStatus),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: state.phase == ReceivingPhase.creating
                    ? null
                    : () async {
                        final ok = await confirmAction(
                          context,
                          title: 'Confirm receiving',
                          message:
                              'Site stock will update on this device immediately.',
                        );
                        if (ok && context.mounted) {
                          await context.read<ReceivingWorkflowCubit>().confirm();
                        }
                      },
                child: const Text('Mark as received'),
              ),
            ],
          ),
        );
      },
    );
  }
}
