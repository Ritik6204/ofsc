import '../../../../core/database/local_data_source.dart';
import '../../../../core/domain/business_rules.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../consumption/domain/entities/consumption_entities.dart';
import '../../../dispatch/domain/entities/dispatch_entities.dart';
import '../../../inventory/domain/entities/inventory_entities.dart';
import '../../../notifications/domain/entities/app_notification.dart';
import '../../../receiving/domain/entities/receiving_entities.dart';
import '../../../sync/domain/entities/sync_entities.dart';
import '../../domain/repositories/operations_repository.dart';

class OperationsRepositoryImpl implements OperationsRepository {
  OperationsRepositoryImpl({
    required LocalDataSource local,
    required IdGenerator ids,
  }) : _local = local,
       _ids = ids;

  final LocalDataSource _local;
  final IdGenerator _ids;

  @override
  Future<List<DispatchRequest>> getDispatches() => _local.getDispatches();

  @override
  Future<DispatchRequest?> getDispatch(String id) => _local.getDispatch(id);

  @override
  Future<DispatchRequest> confirmDispatch(DispatchDraft draft) async {
    for (final line in draft.lines) {
      final actual = line.confirmedQty ?? 0;
      final check = BusinessRules.canDispatch(
        requested: line.requestedQty,
        available: line.availableQty,
        actual: actual,
      );
      if (!check.isValid) {
        throw ValidationException(check.message);
      }
      if (BusinessRules.requiresShortageReason(
            requested: line.requestedQty,
            actual: actual,
          ) &&
          (line.reason == null || line.reason!.trim().isEmpty)) {
        throw const ValidationException(
          'A reason is required when the actual quantity is lower than requested.',
        );
      }
    }

    final user = await _local.getCachedUser();
    final clientId = _ids.clientTransactionId('SM');
    final confirmed = draft.request.copyWith(
      status: DispatchStatus.dispatched,
      lines: draft.lines,
      remarks: draft.remarks,
      photos: draft.photos,
      localId: clientId,
      syncStatus: SyncStatus.pending,
      dispatchCode: draft.request.dispatchCode ?? 'DSP-LOCAL',
    );
    await _local.upsertDispatch(confirmed);

    if (user?.store != null) {
      for (final line in draft.lines) {
        final qty = line.confirmedQty ?? 0;
        final items = await _local.getInventory(
          scopeType: 'store',
          scopeId: user!.store!.id,
        );
        final match = items.firstWhere(
          (item) => item.material.id == line.material.id,
        );
        await _local.upsertInventory(
          match.copyWith(
            available: match.available - qty,
            reserved: (match.reserved - line.requestedQty).clamp(0, match.reserved),
            total: match.total - qty,
          ),
        );
        await _local.insertMovement(
          StockMovement(
            id: _ids.uuid(),
            materialId: line.material.id,
            quantity: -qty,
            unit: line.material.unit,
            title: 'Dispatched to ${draft.request.projectName}',
            createdAt: DateTime.now(),
            reference: clientId,
          ),
        );
      }
    }

    await _local.insertActivity(
      ActivityEvent(
        id: _ids.uuid(),
        title:
            '${draft.lines.first.confirmedQty ?? 0} ${draft.lines.first.material.name} dispatched',
        createdAt: DateTime.now(),
      ),
    );

    await _local.enqueue(
      SyncQueueItem(
        localId: _ids.uuid(),
        entityType: SyncEntityType.dispatchConfirmation,
        payload: {
          'request_id': draft.request.id,
          'client_transaction_id': clientId,
          'remarks': draft.remarks,
          'lines': draft.lines
              .map(
                (line) => {
                  'material_id': line.material.id,
                  'confirmed_qty': line.confirmedQty,
                  'reason': line.reason,
                },
              )
              .toList(),
        },
        createdAt: DateTime.now(),
        retryCount: 0,
        syncStatus: SyncStatus.pending,
        idempotencyKey: clientId,
      ),
    );

    for (final photo in draft.photos) {
      await _local.enqueue(
        SyncQueueItem(
          localId: photo.id,
          entityType: SyncEntityType.dispatchPhoto,
          payload: {
            'photo_id': photo.id,
            'parent_id': draft.request.id,
            'local_path': photo.localPath,
            'kind': photo.kind.name,
            'client_transaction_id': photo.id,
          },
          createdAt: DateTime.now(),
          retryCount: 0,
          syncStatus: SyncStatus.pending,
          idempotencyKey: photo.id,
        ),
      );
    }
    return confirmed;
  }

  @override
  Future<DispatchRequest> confirmReceiving(ReceivingDraft draft) async {
    for (final line in draft.lines) {
      final received = line.receivedQty ?? 0;
      final check = BusinessRules.canReceive(
        dispatched: line.dispatchedQty,
        received: received,
      );
      if (!check.isValid) {
        throw ValidationException(check.message);
      }
      if (line.hasDiscrepancy &&
          (line.reason == null || line.reason!.trim().isEmpty) &&
          line.status != ReceivingStatus.received) {
        throw const ValidationException(
          'A reason is required for partial or missing receipts.',
        );
      }
    }

    final user = await _local.getCachedUser();
    final clientId = _ids.clientTransactionId('SS');
    final hasPartial = draft.lines.any(
      (line) => line.status == ReceivingStatus.partiallyReceived,
    );
    final hasMissing = draft.lines.any(
      (line) => line.status == ReceivingStatus.notReceived,
    );
    final status = hasMissing
        ? DispatchStatus.discrepancy
        : hasPartial
        ? DispatchStatus.partiallyReceived
        : DispatchStatus.received;

    final updated = draft.request.copyWith(
      status: status,
      remarks: draft.remarks,
      photos: draft.photos,
      localId: clientId,
      syncStatus: SyncStatus.pending,
    );
    await _local.upsertDispatch(updated);

    if (user?.primaryProject != null) {
      for (final line in draft.lines) {
        final qty = line.receivedQty ?? 0;
        if (qty <= 0) continue;
        final items = await _local.getInventory(
          scopeType: 'site',
          scopeId: user!.primaryProject!.id,
        );
        final match = items.firstWhere(
          (item) => item.material.id == line.material.id,
        );
        await _local.upsertInventory(
          match.copyWith(
            available: match.available + qty,
            total: match.total + qty,
          ),
        );
      }
    }

    await _local.enqueue(
      SyncQueueItem(
        localId: _ids.uuid(),
        entityType: SyncEntityType.receivingConfirmation,
        payload: {
          'request_id': draft.request.id,
          'client_transaction_id': clientId,
          'remarks': draft.remarks,
          'lines': draft.lines
              .map(
                (line) => {
                  'material_id': line.material.id,
                  'received_qty': line.receivedQty,
                  'status': line.status.name,
                  'reason': line.reason,
                },
              )
              .toList(),
        },
        createdAt: DateTime.now(),
        retryCount: 0,
        syncStatus: SyncStatus.pending,
        idempotencyKey: clientId,
      ),
    );

    for (final photo in draft.photos) {
      await _local.enqueue(
        SyncQueueItem(
          localId: photo.id,
          entityType: SyncEntityType.receivingPhoto,
          payload: {
            'photo_id': photo.id,
            'parent_id': draft.request.id,
            'local_path': photo.localPath,
            'kind': photo.kind.name,
            'client_transaction_id': photo.id,
          },
          createdAt: DateTime.now(),
          retryCount: 0,
          syncStatus: SyncStatus.pending,
          idempotencyKey: photo.id,
        ),
      );
    }
    return updated;
  }

  @override
  Future<List<ConsumptionEntry>> getConsumptions() => _local.getConsumptions();

  @override
  Future<ConsumptionEntry> recordConsumption(ConsumptionEntry entry) async {
    final user = await _local.getCachedUser();
    final projectId = user?.primaryProject?.id ?? entry.projectId;
    final items = await _local.getInventory(scopeType: 'site', scopeId: projectId);
    final stock = items.firstWhere(
      (item) => item.material.id == entry.material.id,
    );
    final check = BusinessRules.canConsume(
      available: stock.available,
      used: entry.quantity,
    );
    if (!check.isValid) {
      throw ValidationException(check.message);
    }

    final clientId = entry.clientTransactionId ?? _ids.clientTransactionId('SS');
    final saved = ConsumptionEntry(
      id: entry.id,
      material: entry.material,
      quantity: entry.quantity,
      projectId: projectId,
      projectName: user?.primaryProject?.name ?? entry.projectName,
      workTask: entry.workTask,
      recordedBy: user?.name ?? entry.recordedBy,
      createdAt: entry.createdAt,
      syncStatus: SyncStatus.pending,
      remarks: entry.remarks,
      clientTransactionId: clientId,
    );
    await _local.upsertConsumption(saved);
    await _local.upsertInventory(
      stock.copyWith(
        available: stock.available - entry.quantity,
        total: stock.total - entry.quantity,
      ),
    );
    await _local.enqueue(
      SyncQueueItem(
        localId: saved.id,
        entityType: SyncEntityType.consumption,
        payload: {
          'id': saved.id,
          'material_id': saved.material.id,
          'quantity': saved.quantity,
          'project_id': saved.projectId,
          'work_task': saved.workTask,
          'remarks': saved.remarks,
          'client_transaction_id': clientId,
        },
        createdAt: DateTime.now(),
        retryCount: 0,
        syncStatus: SyncStatus.pending,
        idempotencyKey: clientId,
      ),
    );
    return saved;
  }

  @override
  Future<List<MaterialRequirement>> getRequirements() =>
      _local.getRequirements();

  @override
  Future<MaterialRequirement> createRequirement(
    MaterialRequirement requirement,
  ) async {
    final clientId =
        requirement.clientTransactionId ?? _ids.clientTransactionId('SS');
    final saved = MaterialRequirement(
      id: requirement.id,
      projectId: requirement.projectId,
      projectName: requirement.projectName,
      material: requirement.material,
      requiredQty: requirement.requiredQty,
      currentStock: requirement.currentStock,
      priority: requirement.priority,
      requiredDate: requirement.requiredDate,
      status: RequirementStatus.pendingAdmin,
      syncStatus: SyncStatus.pending,
      createdAt: requirement.createdAt,
      remarks: requirement.remarks,
      clientTransactionId: clientId,
    );
    await _local.upsertRequirement(saved);
    await _local.enqueue(
      SyncQueueItem(
        localId: saved.id,
        entityType: SyncEntityType.requirement,
        payload: {
          'id': saved.id,
          'material_id': saved.material.id,
          'required_qty': saved.requiredQty,
          'priority': saved.priority.name,
          'required_date': saved.requiredDate.toIso8601String(),
          'remarks': saved.remarks,
          'client_transaction_id': clientId,
        },
        createdAt: DateTime.now(),
        retryCount: 0,
        syncStatus: SyncStatus.pending,
        idempotencyKey: clientId,
      ),
    );
    return saved;
  }

  @override
  Future<List<AppNotification>> getNotifications() =>
      _local.getNotifications();

  @override
  Future<void> markNotificationRead(String id) =>
      _local.markNotificationRead(id);

  @override
  Future<List<SyncQueueItem>> getQueue() => _local.getQueue();

  @override
  Future<DateTime?> lastSyncedAt() async {
    final value = await _local.getMetadata('last_synced_at');
    return value == null ? null : DateTime.tryParse(value);
  }
}
