import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../authentication/domain/entities/user_session.dart';
import '../bloc/dashboard_bloc.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => context.read<DashboardBloc>().load(refreshing: true),
          child: switch (state.status) {
            DashboardStatus.loading || DashboardStatus.initial =>
              const SkeletonList(),
            DashboardStatus.error => ErrorView(
              message: state.errorMessage ?? 'Unable to load dashboard.',
              onRetry: () => context.read<DashboardBloc>().load(),
            ),
            _ => user.isStoreManager
                ? _StoreDashboard(user: user, state: state)
                : _SiteDashboard(user: user, state: state),
          },
        );
      },
    ),
    );
  }
}

class _StoreDashboard extends StatelessWidget {
  const _StoreDashboard({required this.user, required this.state});

  final UserProfile user;
  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          '${Formatters.greeting(DateTime.now())}, ${user.name.split(' ').first}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          '${user.store?.name} · ${user.store?.location}',
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            KpiCard(
              label: 'Pending Dispatches',
              value: '${state.pendingDispatches.length}',
              accent: AppColors.accent,
            ),
            KpiCard(
              label: 'Total Stock Items',
              value: Formatters.quantity(state.totalAvailable),
            ),
            KpiCard(
              label: 'Low Stock Items',
              value: '${state.lowStock.length}',
              accent: AppColors.danger,
            ),
            KpiCard(
              label: 'Reserved Stock',
              value: Formatters.quantity(state.totalReserved),
              accent: AppColors.info,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const SectionHeader('Pending Dispatches'),
        const SizedBox(height: 12),
        if (state.pendingDispatches.isEmpty)
          const EmptyView(
            title: 'No pending dispatches',
            message: 'New admin requests will appear here.',
          )
        else
          ...state.pendingDispatches.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.projectName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...item.lines.take(3).map(
                        (line) => Text(
                          '${line.material.name}       ${Formatters.qtyUnit(line.requestedQty, line.material.unit)}',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            '${item.materialCount} Materials',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          const Spacer(),
                          StatusBadge.dispatch(item.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => context.push('/dispatches/${item.id}'),
                        child: const Text('View Request'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        const SectionHeader('Recent Activity'),
        const SizedBox(height: 12),
        ...state.activities.map(
          (event) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(event.title),
            subtitle: Text(Formatters.relative(event.createdAt)),
          ),
        ),
      ],
    );
  }
}

class _SiteDashboard extends StatelessWidget {
  const _SiteDashboard({required this.user, required this.state});

  final UserProfile user;
  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          '${Formatters.greeting(DateTime.now())}, ${user.name.split(' ').first}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          user.primaryProject?.name ?? 'Assigned project',
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            KpiCard(
              label: 'Incoming Materials',
              value: '${state.incoming.length}',
              accent: AppColors.accent,
            ),
            KpiCard(
              label: 'Site Stock Items',
              value: '${state.inventory.length}',
            ),
            KpiCard(
              label: 'Low Stock Items',
              value: '${state.lowStock.length}',
              accent: AppColors.danger,
            ),
            KpiCard(
              label: 'Received Today',
              value: '${state.dispatches.where((d) => d.status.name == 'received').length}',
              accent: AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const SectionHeader('Incoming'),
        const SizedBox(height: 12),
        if (state.incoming.isEmpty)
          const EmptyView(
            title: 'Nothing in transit',
            message: 'Dispatched materials will appear here for receiving.',
          )
        else
          ...state.incoming.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  title: Text(item.storeName),
                  subtitle: Text('${item.materialCount} Materials'),
                  trailing: FilledButton(
                    onPressed: () => context.push('/incoming/${item.id}'),
                    child: const Text('Verify'),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        const SectionHeader('Low Stock'),
        const SizedBox(height: 12),
        ...state.lowStock.map(
          (item) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(item.material.name),
              subtitle: Text(
                '${Formatters.qtyUnit(item.available, item.material.unit)} · Minimum ${Formatters.quantity(item.material.minimumStock)}',
              ),
              trailing: TextButton(
                onPressed: () =>
                    context.push('/requirements/new?materialId=${item.material.id}'),
                child: const Text('Request Material'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
