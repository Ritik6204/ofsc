import 'dart:async';

import '../../features/sync/domain/entities/sync_entities.dart';
import '../constants/app_constants.dart';
import '../database/local_data_source.dart';
import '../domain/enums.dart';
import '../errors/exceptions.dart';
import '../network/network_info.dart';
import '../network/remote_data_source.dart';

class SyncEngine {
  SyncEngine({
    required LocalDataSource local,
    required RemoteDataSource remote,
    required NetworkInfo networkInfo,
  }) : _local = local,
       _remote = remote,
       _networkInfo = networkInfo;

  final LocalDataSource _local;
  final RemoteDataSource _remote;
  final NetworkInfo _networkInfo;
  final _controller = StreamController<SyncSnapshot>.broadcast();
  StreamSubscription<bool>? _connectivitySub;
  bool _running = false;

  Stream<SyncSnapshot> get snapshots => _controller.stream;

  Future<void> start() async {
    await publish();
    _connectivitySub ??= _networkInfo.onStatusChange.listen((online) async {
      await publish();
      if (online) {
        await processQueue();
      }
    });
  }

  Future<void> processQueue() async {
    if (_running) return;
    if (!await _networkInfo.isConnected) {
      await publish(message: 'Waiting for Internet');
      return;
    }
    _running = true;
    try {
      final pending = await _local.getQueue(pendingOnly: true);
      if (pending.isEmpty) {
        await _local.setMetadata(
          'last_synced_at',
          DateTime.now().toIso8601String(),
        );
        await publish(message: 'All data synced');
        return;
      }
      await publish(message: 'Syncing...');
      for (final item in pending) {
        await _processItem(item);
      }
      await _local.setMetadata(
        'last_synced_at',
        DateTime.now().toIso8601String(),
      );
      await publish(message: 'All data synced');
    } finally {
      _running = false;
    }
  }

  Future<void> retry(String localId) async {
    final items = await _local.getQueue();
    final match = items.firstWhere((item) => item.localId == localId);
    await _local.updateQueueItem(
      match.copyWith(syncStatus: SyncStatus.pending, errorMessage: null),
    );
    await processQueue();
  }

  Future<void> _processItem(SyncQueueItem item) async {
    final working = item.copyWith(
      syncStatus: SyncStatus.syncing,
      lastAttemptAt: DateTime.now(),
    );
    await _local.updateQueueItem(working);
    await publish();
    try {
      switch (item.entityType) {
        case SyncEntityType.dispatchConfirmation:
          await _remote.confirmDispatch(item.payload);
          await _markDispatch(item.payload['request_id'] as String, SyncStatus.synced);
        case SyncEntityType.receivingConfirmation:
          await _remote.confirmReceiving(item.payload);
          await _markDispatch(item.payload['request_id'] as String, SyncStatus.synced);
        case SyncEntityType.consumption:
          await _remote.recordConsumption(item.payload);
        case SyncEntityType.requirement:
          await _remote.createRequirement(item.payload);
        case SyncEntityType.dispatchPhoto:
        case SyncEntityType.receivingPhoto:
          await _remote.uploadPhoto(item.payload);
      }
      await _local.updateQueueItem(
        working.copyWith(syncStatus: SyncStatus.synced, errorMessage: null),
      );
    } on SyncConflictException catch (error) {
      await _local.updateQueueItem(
        working.copyWith(
          syncStatus: SyncStatus.conflict,
          retryCount: working.retryCount + 1,
          errorMessage: error.message,
        ),
      );
      if (item.payload['request_id'] != null) {
        await _markDispatch(
          item.payload['request_id'] as String,
          SyncStatus.conflict,
        );
      }
    } catch (error) {
      final retries = working.retryCount + 1;
      await _local.updateQueueItem(
        working.copyWith(
          syncStatus: retries >= AppConstants.maxSyncRetries
              ? SyncStatus.failed
              : SyncStatus.failed,
          retryCount: retries,
          errorMessage: error.toString(),
        ),
      );
    }
    await publish();
  }

  Future<void> _markDispatch(String id, SyncStatus status) async {
    final dispatch = await _local.getDispatch(id);
    if (dispatch == null) return;
    await _local.upsertDispatch(dispatch.copyWith(syncStatus: status));
  }

  Future<SyncSnapshot> publish({String? message}) async {
    final online = await _networkInfo.isConnected;
    final queue = await _local.getQueue();
    final pending = queue
        .where((item) => item.syncStatus != SyncStatus.synced)
        .length;
    final failed = queue
        .where((item) => item.syncStatus == SyncStatus.failed)
        .length;
    final conflicts = queue
        .where((item) => item.syncStatus == SyncStatus.conflict)
        .length;
    final last = await _local.getMetadata('last_synced_at');
    final snapshot = SyncSnapshot(
      pendingCount: pending,
      failedCount: failed,
      conflictCount: conflicts,
      status: !online
          ? ConnectivityStatus.offline
          : _running
          ? ConnectivityStatus.syncing
          : pending == 0
          ? ConnectivityStatus.synced
          : ConnectivityStatus.online,
      lastSyncedAt: last == null ? null : DateTime.tryParse(last),
      currentMessage: message,
    );
    if (!_controller.isClosed) {
      _controller.add(snapshot);
    }
    return snapshot;
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    await _controller.close();
  }
}
