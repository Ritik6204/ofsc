import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../bloc/dispatch_bloc.dart';

class DispatchListPage extends StatelessWidget {
  const DispatchListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dispatches')),
      body: BlocBuilder<DispatchBloc, DispatchState>(
      builder: (context, state) {
        return switch (state.status) {
          DispatchListStatus.loading || DispatchListStatus.initial =>
            const SkeletonList(),
          DispatchListStatus.error => ErrorView(
            message: state.errorMessage ?? 'Unable to load dispatches.',
            onRetry: () => context.read<DispatchBloc>().load(),
          ),
          DispatchListStatus.empty => const EmptyView(
            title: 'No dispatch requests',
            message: 'Admin requests assigned to your store will appear here.',
          ),
          DispatchListStatus.loaded => RefreshIndicator(
            onRefresh: () => context.read<DispatchBloc>().load(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = state.items[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      item.projectName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${item.requestCode} · ${item.materialCount} materials',
                    ),
                    trailing: StatusBadge.dispatch(item.status),
                    onTap: () => context.push('/dispatches/${item.id}'),
                  ),
                );
              },
            ),
          ),
        };
      },
    ),
    );
  }
}

class DispatchDetailPage extends StatelessWidget {
  const DispatchDetailPage({super.key, this.verify = false});

  final bool verify;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DispatchWorkflowCubit, DispatchWorkflowState>(
      listener: (context, state) {
        if (state.phase == DispatchPhase.pendingSync) {
          context.go('/dispatches/${state.request!.id}/confirm');
        }
        if (state.phase == DispatchPhase.failed && state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        if (state.phase == DispatchPhase.loading || state.request == null) {
          return const Scaffold(body: SkeletonList());
        }
        final request = state.request!;
        return Scaffold(
          appBar: AppBar(
            title: Text(verify ? 'Dispatch Verification' : 'Dispatch Request'),
          ),
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
              const SizedBox(height: 8),
              Text('Request ID: ${request.requestCode}'),
              Text('Requested by: ${request.requestedBy}'),
              Text('Date: ${Formatters.date(request.requestedAt)}'),
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
                          'Requested: ${Formatters.qtyUnit(line.requestedQty, line.material.unit)}',
                        ),
                        if (verify) ...[
                          Text(
                            'Available: ${Formatters.qtyUnit(line.availableQty, line.material.unit)}',
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: '${line.confirmedQty ?? line.requestedQty}',
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Dispatch quantity',
                            ),
                            onChanged: (value) {
                              final qty = double.tryParse(value) ?? 0;
                              context
                                  .read<DispatchWorkflowCubit>()
                                  .updateQuantity(line.material.id, qty);
                            },
                          ),
                          if ((line.confirmedQty ?? line.requestedQty) <
                              line.requestedQty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Difference: ${Formatters.quantity(line.requestedQty - (line.confirmedQty ?? 0))}',
                              style: const TextStyle(color: AppColors.danger),
                            ),
                            TextFormField(
                              initialValue: line.reason ?? '',
                              decoration: const InputDecoration(
                                labelText: 'Reason for shortage',
                              ),
                              onChanged: (value) => context
                                  .read<DispatchWorkflowCubit>()
                                  .updateReason(line.material.id, value),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                );
              }),
              if (verify) ...[
                TextFormField(
                  initialValue: state.remarks,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Dispatch remarks',
                  ),
                  onChanged: context.read<DispatchWorkflowCubit>().updateRemarks,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final file = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 70,
                      maxWidth: 1600,
                    );
                    if (file != null && context.mounted) {
                      context.read<DispatchWorkflowCubit>().addPhoto(
                        file.path,
                        PhotoKind.dispatchProof,
                      );
                    }
                  },
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Capture dispatch photo'),
                ),
                ...state.photos.map(
                  (photo) => PhotoStatusTile(
                    label: photo.kind.name,
                    status: photo.syncStatus,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: state.phase == DispatchPhase.creating
                      ? null
                      : () async {
                          final ok = await confirmAction(
                            context,
                            title: 'Confirm dispatch',
                            message:
                                'This will record the dispatch on this device and sync when internet is available.',
                          );
                          if (ok && context.mounted) {
                            await context
                                .read<DispatchWorkflowCubit>()
                                .confirm();
                          }
                        },
                  child: Text(
                    state.phase == DispatchPhase.creating
                        ? 'Saving...'
                        : 'Continue to confirmation',
                  ),
                ),
              ] else
                FilledButton(
                  onPressed: request.status == DispatchStatus.pendingDispatch
                      ? () => context.push('/dispatches/${request.id}/verify')
                      : null,
                  child: const Text('Verify Materials'),
                ),
            ],
          ),
        );
      },
    );
  }
}

class DispatchConfirmPage extends StatelessWidget {
  const DispatchConfirmPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DispatchWorkflowCubit, DispatchWorkflowState>(
      builder: (context, state) {
        final request = state.request;
        return Scaffold(
          appBar: AppBar(title: const Text('Dispatch recorded')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request?.projectName ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ...state.lines.map(
                  (line) => Text(
                    '${line.material.name}       ${Formatters.qtyUnit(line.confirmedQty ?? 0, line.material.unit)}',
                  ),
                ),
                const SizedBox(height: 12),
                Text('Photos: ${state.photos.length}'),
                const SizedBox(height: 16),
                StatusBadge.sync(request?.syncStatus ?? SyncStatus.pending),
                const SizedBox(height: 12),
                const Text(
                  'Dispatch recorded successfully. If you are offline, this is saved on the device and will sync automatically when internet returns.',
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
