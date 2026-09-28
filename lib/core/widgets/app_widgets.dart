import 'package:flutter/material.dart';

import '../../features/sync/domain/entities/sync_entities.dart';
import '../domain/enums.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key, required this.snapshot});

  final SyncSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (snapshot.status) {
      ConnectivityStatus.offline => (
        AppColors.offline,
        snapshot.pendingCount > 0
            ? 'Offline · ${snapshot.pendingCount} pending changes'
            : 'Offline',
      ),
      ConnectivityStatus.syncing => (AppColors.syncing, 'Syncing...'),
      ConnectivityStatus.synced => (AppColors.success, 'All data synced'),
      ConnectivityStatus.online => (
        snapshot.pendingCount > 0 ? AppColors.warning : AppColors.success,
        snapshot.pendingCount > 0
            ? '${snapshot.pendingCount} pending changes'
            : 'Online',
      ),
    };
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          if (snapshot.lastSyncedAt != null)
            Text(
              'Last synced: ${Formatters.lastSynced(snapshot.lastSyncedAt)}',
              style: TextStyle(color: color, fontSize: 11),
            ),
        ],
      ),
    );
  }
}

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.accent = AppColors.primary,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  factory StatusBadge.sync(SyncStatus status) {
    return StatusBadge(
      label: status.label,
      color: switch (status) {
        SyncStatus.synced => AppColors.success,
        SyncStatus.syncing => AppColors.syncing,
        SyncStatus.pending => AppColors.warning,
        SyncStatus.failed => AppColors.danger,
        SyncStatus.conflict => AppColors.offline,
      },
    );
  }

  factory StatusBadge.dispatch(DispatchStatus status) {
    return StatusBadge(
      label: status.label,
      color: switch (status) {
        DispatchStatus.pendingDispatch => AppColors.warning,
        DispatchStatus.verifying => AppColors.info,
        DispatchStatus.dispatched => AppColors.info,
        DispatchStatus.inTransit => AppColors.accent,
        DispatchStatus.partiallyReceived => AppColors.warning,
        DispatchStatus.received => AppColors.success,
        DispatchStatus.discrepancy => AppColors.danger,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.muted),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Container(
        height: 96,
        decoration: BoxDecoration(
          color: const Color(0xFFE6EBEE),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class PhotoStatusTile extends StatelessWidget {
  const PhotoStatusTile({super.key, required this.label, required this.status});

  final String label;
  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final text = switch (status) {
      SyncStatus.pending => 'Saved locally · Waiting for sync',
      SyncStatus.syncing => 'Uploading',
      SyncStatus.synced => 'Uploaded',
      SyncStatus.failed => 'Upload failed',
      SyncStatus.conflict => 'Needs review',
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.photo_camera_outlined),
      title: Text(label),
      subtitle: Text(text),
      trailing: StatusBadge.sync(status),
    );
  }
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
