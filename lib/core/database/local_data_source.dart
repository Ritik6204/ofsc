import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../features/authentication/domain/entities/user_session.dart';
import '../../features/consumption/domain/entities/consumption_entities.dart';
import '../../features/dispatch/domain/entities/dispatch_entities.dart';
import '../../features/inventory/domain/entities/inventory_entities.dart';
import '../../features/notifications/domain/entities/app_notification.dart';
import '../../features/sync/domain/entities/sync_entities.dart';
import '../domain/enums.dart';
import 'app_database.dart';

class LocalDataSource {
  LocalDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

  Future<void> replaceBootstrap({
    required UserProfile user,
    required List<Material> materials,
    required List<InventoryItem> inventory,
    required List<DispatchRequest> dispatches,
    required List<StockMovement> movements,
    required List<ActivityEvent> activities,
    required List<ConsumptionEntry> consumptions,
    required List<MaterialRequirement> requirements,
    required List<AppNotification> notifications,
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('users');
      await txn.delete('materials');
      await txn.delete('inventory');
      await txn.delete('stock_movements');
      await txn.delete('activities');
      await txn.delete('dispatch_requests');
      await txn.delete('photos');
      await txn.delete('consumptions');
      await txn.delete('requirements');
      await txn.delete('notifications');
      await txn.insert('users', {
        'user_id': user.userId,
        'name': user.name,
        'employee_id': user.employeeId,
        'role': user.role.apiValue,
        'email': user.email,
        'phone': user.phone,
        'account_status': user.accountStatus,
        'photo_url': user.photoUrl,
        'store_json': user.store == null ? null : jsonEncode(user.toMap()['store']),
        'projects_json': jsonEncode(user.toMap()['projects']),
      });
      for (final material in materials) {
        await txn.insert('materials', _materialMap(material));
      }
      for (final item in inventory) {
        await txn.insert('inventory', _inventoryMap(item));
      }
      for (final movement in movements) {
        await txn.insert('stock_movements', {
          'id': movement.id,
          'material_id': movement.materialId,
          'quantity': movement.quantity,
          'unit': movement.unit,
          'title': movement.title,
          'created_at': movement.createdAt.toIso8601String(),
          'reference': movement.reference,
        });
      }
      for (final activity in activities) {
        await txn.insert('activities', {
          'id': activity.id,
          'title': activity.title,
          'created_at': activity.createdAt.toIso8601String(),
        });
      }
      for (final dispatch in dispatches) {
        await _upsertDispatch(txn, dispatch);
      }
      for (final entry in consumptions) {
        await txn.insert('consumptions', _consumptionMap(entry));
      }
      for (final requirement in requirements) {
        await txn.insert('requirements', _requirementMap(requirement));
      }
      for (final notification in notifications) {
        await txn.insert('notifications', _notificationMap(notification));
      }
    });
  }

  Future<UserProfile?> getCachedUser() async {
    final rows = await (await _db).query('users', limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return UserProfile.fromMap({
      'user_id': row['user_id'],
      'name': row['name'],
      'employee_id': row['employee_id'],
      'role': row['role'],
      'email': row['email'],
      'phone': row['phone'],
      'account_status': row['account_status'],
      'photo_url': row['photo_url'],
      'store': row['store_json'] == null
          ? null
          : jsonDecode(row['store_json']! as String),
      'projects': jsonDecode(row['projects_json'] as String? ?? '[]'),
    });
  }

  Future<List<Material>> getMaterials() async {
    final rows = await (await _db).query('materials', orderBy: 'name ASC');
    return rows.map(_materialFrom).toList();
  }

  Future<Material?> getMaterial(int id) async {
    final rows = await (await _db).query(
      'materials',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return _materialFrom(rows.first);
  }

  Future<List<InventoryItem>> getInventory({
    required String scopeType,
    required int scopeId,
  }) async {
    final materials = {for (final m in await getMaterials()) m.id: m};
    final rows = await (await _db).query(
      'inventory',
      where: 'scope_type = ? AND scope_id = ?',
      whereArgs: [scopeType, scopeId],
    );
    return rows
        .where((row) => materials.containsKey(row['material_id']))
        .map((row) {
          return InventoryItem(
            material: materials[row['material_id'] as int]!,
            available: (row['available'] as num).toDouble(),
            reserved: (row['reserved'] as num).toDouble(),
            total: (row['total'] as num).toDouble(),
            scopeId: row['scope_id'] as int,
            scopeType: row['scope_type'] as String,
          );
        })
        .toList();
  }

  Future<void> upsertInventory(InventoryItem item) async {
    await (await _db).insert(
      'inventory',
      _inventoryMap(item),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<StockMovement>> getMovements(int materialId) async {
    final rows = await (await _db).query(
      'stock_movements',
      where: 'material_id = ?',
      whereArgs: [materialId],
      orderBy: 'created_at DESC',
    );
    return rows
        .map(
          (row) => StockMovement(
            id: row['id'] as String,
            materialId: row['material_id'] as int,
            quantity: (row['quantity'] as num).toDouble(),
            unit: row['unit'] as String,
            title: row['title'] as String,
            createdAt: DateTime.parse(row['created_at'] as String),
            reference: row['reference'] as String?,
          ),
        )
        .toList();
  }

  Future<void> insertMovement(StockMovement movement) async {
    await (await _db).insert('stock_movements', {
      'id': movement.id,
      'material_id': movement.materialId,
      'quantity': movement.quantity,
      'unit': movement.unit,
      'title': movement.title,
      'created_at': movement.createdAt.toIso8601String(),
      'reference': movement.reference,
    });
  }

  Future<List<ActivityEvent>> getActivities() async {
    final rows = await (await _db).query(
      'activities',
      orderBy: 'created_at DESC',
      limit: 20,
    );
    return rows
        .map(
          (row) => ActivityEvent(
            id: row['id'] as String,
            title: row['title'] as String,
            createdAt: DateTime.parse(row['created_at'] as String),
          ),
        )
        .toList();
  }

  Future<void> insertActivity(ActivityEvent event) async {
    await (await _db).insert('activities', {
      'id': event.id,
      'title': event.title,
      'created_at': event.createdAt.toIso8601String(),
    });
  }

  Future<List<DispatchRequest>> getDispatches() async {
    final db = await _db;
    final rows = await db.query(
      'dispatch_requests',
      orderBy: 'requested_at DESC',
    );
    final result = <DispatchRequest>[];
    for (final row in rows) {
      result.add(await _dispatchFrom(db, row));
    }
    return result;
  }

  Future<DispatchRequest?> getDispatch(String id) async {
    final db = await _db;
    final rows = await db.query(
      'dispatch_requests',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return _dispatchFrom(db, rows.first);
  }

  Future<void> upsertDispatch(DispatchRequest request) async {
    final db = await _db;
    await db.transaction((txn) async {
      await _upsertDispatch(txn, request);
    });
  }

  Future<void> _upsertDispatch(DatabaseExecutor txn, DispatchRequest request) async {
    await txn.insert('dispatch_requests', {
      'id': request.id,
      'request_code': request.requestCode,
      'project_id': request.projectId,
      'project_name': request.projectName,
      'store_id': request.storeId,
      'store_name': request.storeName,
      'requested_by': request.requestedBy,
      'requested_at': request.requestedAt.toIso8601String(),
      'status': request.status.name,
      'dispatch_code': request.dispatchCode,
      'remarks': request.remarks,
      'local_id': request.localId,
      'sync_status': request.syncStatus.name,
      'lines_json': jsonEncode(
        request.lines
            .map(
              (line) => {
                'material_id': line.material.id,
                'requested_qty': line.requestedQty,
                'available_qty': line.availableQty,
                'confirmed_qty': line.confirmedQty,
                'reason': line.reason,
              },
            )
            .toList(),
      ),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await txn.delete('photos', where: 'parent_id = ?', whereArgs: [request.id]);
    for (final photo in request.photos) {
      await txn.insert('photos', {
        'id': photo.id,
        'parent_id': request.id,
        'local_path': photo.localPath,
        'kind': photo.kind.name,
        'sync_status': photo.syncStatus.name,
        'remote_url': photo.remoteUrl,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<DispatchRequest> _dispatchFrom(
    Database db,
    Map<String, Object?> row,
  ) async {
    final materials = {for (final m in await getMaterials()) m.id: m};
    final lineMaps = (jsonDecode(row['lines_json'] as String) as List)
        .cast<Map<String, dynamic>>();
    final photoRows = await db.query(
      'photos',
      where: 'parent_id = ?',
      whereArgs: [row['id']],
    );
    return DispatchRequest(
      id: row['id'] as String,
      requestCode: row['request_code'] as String,
      projectId: row['project_id'] as int,
      projectName: row['project_name'] as String,
      storeId: row['store_id'] as int,
      storeName: row['store_name'] as String,
      requestedBy: row['requested_by'] as String,
      requestedAt: DateTime.parse(row['requested_at'] as String),
      status: DispatchStatus.values.byName(row['status'] as String),
      dispatchCode: row['dispatch_code'] as String?,
      remarks: row['remarks'] as String?,
      localId: row['local_id'] as String?,
      syncStatus: SyncStatus.values.byName(row['sync_status'] as String),
      lines: lineMaps.map((line) {
        return DispatchLine(
          material: materials[line['material_id'] as int]!,
          requestedQty: (line['requested_qty'] as num).toDouble(),
          availableQty: (line['available_qty'] as num).toDouble(),
          confirmedQty: (line['confirmed_qty'] as num?)?.toDouble(),
          reason: line['reason'] as String?,
        );
      }).toList(),
      photos: photoRows
          .map(
            (photo) => AttachedPhoto(
              id: photo['id'] as String,
              localPath: photo['local_path'] as String,
              kind: PhotoKind.values.byName(photo['kind'] as String),
              syncStatus: SyncStatus.values.byName(photo['sync_status'] as String),
              remoteUrl: photo['remote_url'] as String?,
            ),
          )
          .toList(),
    );
  }

  Future<List<ConsumptionEntry>> getConsumptions() async {
    final materials = {for (final m in await getMaterials()) m.id: m};
    final rows = await (await _db).query(
      'consumptions',
      orderBy: 'created_at DESC',
    );
    return rows.map((row) {
      return ConsumptionEntry(
        id: row['id'] as String,
        material: materials[row['material_id'] as int]!,
        quantity: (row['quantity'] as num).toDouble(),
        projectId: row['project_id'] as int,
        projectName: row['project_name'] as String,
        workTask: row['work_task'] as String,
        recordedBy: row['recorded_by'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
        syncStatus: SyncStatus.values.byName(row['sync_status'] as String),
        remarks: row['remarks'] as String?,
        clientTransactionId: row['client_transaction_id'] as String?,
      );
    }).toList();
  }

  Future<void> upsertConsumption(ConsumptionEntry entry) async {
    await (await _db).insert(
      'consumptions',
      _consumptionMap(entry),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MaterialRequirement>> getRequirements() async {
    final materials = {for (final m in await getMaterials()) m.id: m};
    final rows = await (await _db).query(
      'requirements',
      orderBy: 'created_at DESC',
    );
    return rows.map((row) {
      return MaterialRequirement(
        id: row['id'] as String,
        projectId: row['project_id'] as int,
        projectName: row['project_name'] as String,
        material: materials[row['material_id'] as int]!,
        requiredQty: (row['required_qty'] as num).toDouble(),
        currentStock: (row['current_stock'] as num).toDouble(),
        priority: RequirementPriority.values.byName(row['priority'] as String),
        requiredDate: DateTime.parse(row['required_date'] as String),
        status: RequirementStatus.values.byName(row['status'] as String),
        syncStatus: SyncStatus.values.byName(row['sync_status'] as String),
        createdAt: DateTime.parse(row['created_at'] as String),
        remarks: row['remarks'] as String?,
        clientTransactionId: row['client_transaction_id'] as String?,
      );
    }).toList();
  }

  Future<void> upsertRequirement(MaterialRequirement requirement) async {
    await (await _db).insert(
      'requirements',
      _requirementMap(requirement),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AppNotification>> getNotifications() async {
    final rows = await (await _db).query(
      'notifications',
      orderBy: 'created_at DESC',
    );
    return rows.map(_notificationFrom).toList();
  }

  Future<void> upsertNotification(AppNotification notification) async {
    await (await _db).insert(
      'notifications',
      _notificationMap(notification),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> markNotificationRead(String id) async {
    await (await _db).update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<SyncQueueItem>> getQueue({bool pendingOnly = false}) async {
    final rows = await (await _db).query(
      'sync_queue',
      where: pendingOnly
          ? "sync_status IN ('pending','failed')"
          : null,
      orderBy: 'created_at ASC',
    );
    return rows.map(_queueFrom).toList();
  }

  Future<void> enqueue(SyncQueueItem item) async {
    await (await _db).insert(
      'sync_queue',
      _queueMap(item),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateQueueItem(SyncQueueItem item) async {
    await (await _db).update(
      'sync_queue',
      _queueMap(item),
      where: 'local_id = ?',
      whereArgs: [item.localId],
    );
  }

  Future<void> setMetadata(String key, String value) async {
    await (await _db).insert('sync_metadata', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getMetadata(String key) async {
    final rows = await (await _db).query(
      'sync_metadata',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> clearAll() async {
    final db = await _db;
    await db.transaction((txn) async {
      for (final table in [
        'users',
        'materials',
        'inventory',
        'stock_movements',
        'activities',
        'dispatch_requests',
        'photos',
        'consumptions',
        'requirements',
        'notifications',
        'sync_queue',
        'sync_metadata',
      ]) {
        await txn.delete(table);
      }
    });
  }

  Map<String, Object?> _materialMap(Material material) => {
    'id': material.id,
    'name': material.name,
    'sku': material.sku,
    'category': material.category,
    'unit': material.unit,
    'minimum_stock': material.minimumStock,
  };

  Material _materialFrom(Map<String, Object?> row) => Material(
    id: row['id'] as int,
    name: row['name'] as String,
    sku: row['sku'] as String,
    category: row['category'] as String,
    unit: row['unit'] as String,
    minimumStock: (row['minimum_stock'] as num).toDouble(),
  );

  Map<String, Object?> _inventoryMap(InventoryItem item) => {
    'id': '${item.scopeType}-${item.scopeId}-${item.material.id}',
    'material_id': item.material.id,
    'scope_type': item.scopeType,
    'scope_id': item.scopeId,
    'available': item.available,
    'reserved': item.reserved,
    'total': item.total,
  };

  Map<String, Object?> _consumptionMap(ConsumptionEntry entry) => {
    'id': entry.id,
    'material_id': entry.material.id,
    'quantity': entry.quantity,
    'project_id': entry.projectId,
    'project_name': entry.projectName,
    'work_task': entry.workTask,
    'recorded_by': entry.recordedBy,
    'created_at': entry.createdAt.toIso8601String(),
    'sync_status': entry.syncStatus.name,
    'remarks': entry.remarks,
    'client_transaction_id': entry.clientTransactionId,
  };

  Map<String, Object?> _requirementMap(MaterialRequirement requirement) => {
    'id': requirement.id,
    'project_id': requirement.projectId,
    'project_name': requirement.projectName,
    'material_id': requirement.material.id,
    'required_qty': requirement.requiredQty,
    'current_stock': requirement.currentStock,
    'priority': requirement.priority.name,
    'required_date': requirement.requiredDate.toIso8601String(),
    'status': requirement.status.name,
    'sync_status': requirement.syncStatus.name,
    'created_at': requirement.createdAt.toIso8601String(),
    'remarks': requirement.remarks,
    'client_transaction_id': requirement.clientTransactionId,
  };

  Map<String, Object?> _notificationMap(AppNotification notification) => {
    'id': notification.id,
    'title': notification.title,
    'description': notification.description,
    'created_at': notification.createdAt.toIso8601String(),
    'is_read': notification.isRead ? 1 : 0,
    'entity_type': notification.entityType,
    'entity_id': notification.entityId,
    'route': notification.route,
  };

  AppNotification _notificationFrom(Map<String, Object?> row) => AppNotification(
    id: row['id'] as String,
    title: row['title'] as String,
    description: row['description'] as String,
    createdAt: DateTime.parse(row['created_at'] as String),
    isRead: (row['is_read'] as int) == 1,
    entityType: row['entity_type'] as String?,
    entityId: row['entity_id'] as String?,
    route: row['route'] as String?,
  );

  Map<String, Object?> _queueMap(SyncQueueItem item) => {
    'local_id': item.localId,
    'entity_type': item.entityType.name,
    'payload_json': jsonEncode(item.payload),
    'created_at': item.createdAt.toIso8601String(),
    'retry_count': item.retryCount,
    'sync_status': item.syncStatus.name,
    'server_id': item.serverId,
    'last_attempt_at': item.lastAttemptAt?.toIso8601String(),
    'error_message': item.errorMessage,
    'idempotency_key': item.idempotencyKey,
  };

  SyncQueueItem _queueFrom(Map<String, Object?> row) => SyncQueueItem(
    localId: row['local_id'] as String,
    entityType: SyncEntityType.values.byName(row['entity_type'] as String),
    payload: jsonDecode(row['payload_json'] as String) as Map<String, dynamic>,
    createdAt: DateTime.parse(row['created_at'] as String),
    retryCount: row['retry_count'] as int,
    syncStatus: SyncStatus.values.byName(row['sync_status'] as String),
    serverId: row['server_id'] as String?,
    lastAttemptAt: row['last_attempt_at'] == null
        ? null
        : DateTime.parse(row['last_attempt_at'] as String),
    errorMessage: row['error_message'] as String?,
    idempotencyKey: row['idempotency_key'] as String?,
  );
}
