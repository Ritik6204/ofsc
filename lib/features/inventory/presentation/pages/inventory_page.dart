import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../bloc/inventory_bloc.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key, this.title = 'Store Inventory'});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isSite = title == 'Site Inventory';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (isSite)
            IconButton(
              onPressed: () => context.push('/consumption/history'),
              icon: const Icon(Icons.history),
            ),
        ],
      ),
      floatingActionButton: isSite
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/consumption/new'),
              icon: const Icon(Icons.remove_circle_outline),
              label: const Text('Record usage'),
            )
          : null,
      body: BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search material name or SKU',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: context.read<InventoryBloc>().search,
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final filter in InventoryFilter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter.name),
                        selected: state.filter == filter,
                        onSelected: (_) =>
                            context.read<InventoryBloc>().filter(filter),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: switch (state.status) {
                InventoryStatus.loading || InventoryStatus.initial =>
                  const SkeletonList(),
                InventoryStatus.error => ErrorView(
                  message: state.errorMessage ?? 'Unable to load inventory.',
                  onRetry: () => context.read<InventoryBloc>().load(),
                ),
                InventoryStatus.empty => const EmptyView(
                  title: 'No inventory yet',
                  message: 'Synchronized stock will appear here.',
                ),
                InventoryStatus.loaded =>
                  state.visible.isEmpty
                      ? const EmptyView(
                          title: 'No matching materials',
                          message: 'Try another search or filter.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.visible.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = state.visible[index];
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  item.material.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('SKU: ${item.material.sku}'),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Available  ${Formatters.qtyUnit(item.available, item.material.unit)}',
                                      ),
                                      Text(
                                        'Reserved   ${Formatters.qtyUnit(item.reserved, item.material.unit)}',
                                      ),
                                      Text(
                                        'Total      ${Formatters.qtyUnit(item.total, item.material.unit)}',
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                        ),
                                      ),
                                      if (item.isLowStock) ...[
                                        const SizedBox(height: 8),
                                        const StatusBadge(
                                          label: 'Low Stock',
                                          color: AppColors.danger,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                onTap: () =>
                                    context.push('/inventory/${item.material.id}'),
                              ),
                            );
                          },
                        ),
              },
            ),
          ],
        );
      },
    ),
    );
  }
}
