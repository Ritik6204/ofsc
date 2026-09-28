import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../bloc/inventory_bloc.dart';

class MaterialDetailPage extends StatelessWidget {
  const MaterialDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Material Details')),
      body: BlocBuilder<MaterialDetailCubit, MaterialDetailState>(
        builder: (context, state) {
          if (state.loading) {
            return const SkeletonList();
          }
          final item = state.item;
          if (item == null) {
            return const EmptyView(
              title: 'Material not found',
              message: 'This item is not available in the assigned scope.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                item.material.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text('SKU: ${item.material.sku}'),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Category: ${item.material.category}'),
                      Text('Unit: ${item.material.unit}'),
                      Text(
                        'Available: ${Formatters.qtyUnit(item.available, item.material.unit)}',
                      ),
                      Text(
                        'Reserved: ${Formatters.qtyUnit(item.reserved, item.material.unit)}',
                      ),
                      Text(
                        'Total: ${Formatters.qtyUnit(item.total, item.material.unit)}',
                      ),
                      Text(
                        'Minimum stock: ${Formatters.qtyUnit(item.material.minimumStock, item.material.unit)}',
                      ),
                      const SizedBox(height: 8),
                      StatusBadge(
                        label: item.status.label,
                        color: item.isLowStock
                            ? AppColors.danger
                            : AppColors.success,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SectionHeader('Recent movements'),
              const SizedBox(height: 12),
              ...state.movements.map((movement) {
                final prefix = movement.isInbound ? '+' : '';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '$prefix${Formatters.qtyUnit(movement.quantity.abs(), movement.unit)}',
                    style: TextStyle(
                      color: movement.isInbound
                          ? AppColors.success
                          : AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(movement.title),
                  trailing: Text(Formatters.relative(movement.createdAt)),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
