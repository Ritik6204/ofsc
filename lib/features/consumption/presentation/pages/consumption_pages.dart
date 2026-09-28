import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../inventory/domain/entities/inventory_entities.dart';
import '../bloc/consumption_bloc.dart';

class ConsumptionHistoryPage extends StatelessWidget {
  const ConsumptionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consumption History')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/consumption/new'),
        icon: const Icon(Icons.add),
        label: const Text('Record usage'),
      ),
      body: BlocBuilder<ConsumptionBloc, ConsumptionState>(
        builder: (context, state) {
          if (state.loading) return const SkeletonList();
          if (state.items.isEmpty) {
            return const EmptyView(
              title: 'No consumption yet',
              message: 'Record material usage from the site.',
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
                    '${item.material.name} · ${Formatters.qtyUnit(item.quantity, item.material.unit)}',
                  ),
                  subtitle: Text(
                    '${item.workTask}\nRecorded by: ${item.recordedBy}\n${Formatters.dateTime(item.createdAt)}',
                  ),
                  isThreeLine: true,
                  trailing: StatusBadge.sync(item.syncStatus),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ConsumptionFormPage extends StatelessWidget {
  const ConsumptionFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Material Usage')),
      body: BlocBuilder<ConsumptionFormCubit, ConsumptionFormState>(
        builder: (context, state) {
          final cubit = context.read<ConsumptionFormCubit>();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<InventoryItem>(
                // ignore: deprecated_member_use
                value: state.material,
                items: state.inventory
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item.material.name),
                      ),
                    )
                    .toList(),
                onChanged: (item) {
                  if (item != null) cubit.select(item);
                },
                decoration: const InputDecoration(labelText: 'Material'),
              ),
              const SizedBox(height: 12),
              Text(
                'Available: ${Formatters.qtyUnit(state.material?.available ?? 0, state.material?.material.unit ?? '')}',
              ),
              const SizedBox(height: 12),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Used'),
                onChanged: cubit.setUsed,
              ),
              const SizedBox(height: 12),
              Text(
                'Remaining: ${Formatters.quantity(state.remaining)} ${state.material?.material.unit ?? ''}',
                style: TextStyle(
                  color: state.remaining < 0
                      ? AppColors.danger
                      : AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Work / Task'),
                onChanged: cubit.setTask,
              ),
              const SizedBox(height: 12),
              TextFormField(
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Remarks'),
                onChanged: cubit.setRemarks,
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  state.errorMessage!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: state.saving
                    ? null
                    : () async {
                        final ok = await cubit.submit();
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Usage saved offline and queued for sync.',
                              ),
                            ),
                          );
                          context.pop();
                        }
                      },
                child: const Text('Submit usage'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class RequirementFormPage extends StatelessWidget {
  const RequirementFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Material Requirement')),
      body: BlocBuilder<RequirementFormCubit, RequirementFormState>(
        builder: (context, state) {
          final cubit = context.read<RequirementFormCubit>();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<InventoryItem>(
                // ignore: deprecated_member_use
                value: state.material,
                items: state.inventory
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item.material.name),
                      ),
                    )
                    .toList(),
                onChanged: (item) {
                  if (item != null) cubit.select(item);
                },
                decoration: const InputDecoration(labelText: 'Material'),
              ),
              const SizedBox(height: 12),
              Text(
                'Current site stock: ${Formatters.qtyUnit(state.material?.available ?? 0, state.material?.material.unit ?? '')}',
              ),
              const SizedBox(height: 12),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Required quantity',
                ),
                onChanged: cubit.setQty,
              ),
              const SizedBox(height: 12),
              Text(
                'Suggested requirement: ${Formatters.quantity(state.suggested)} ${state.material?.material.unit ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RequirementPriority>(
                // ignore: deprecated_member_use
                value: state.priority,
                items: RequirementPriority.values
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) cubit.setPriority(value);
                },
                decoration: const InputDecoration(labelText: 'Priority'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Remarks'),
                onChanged: cubit.setRemarks,
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  state.errorMessage!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: state.saving
                    ? null
                    : () async {
                        final ok = await cubit.submit();
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Requirement submitted. Pending Admin Processing.',
                              ),
                            ),
                          );
                          context.pop();
                        }
                      },
                child: const Text('Submit requirement'),
              ),
            ],
          );
        },
      ),
    );
  }
}
