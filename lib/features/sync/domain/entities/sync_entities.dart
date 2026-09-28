import 'package:equatable/equatable.dart';

import '../../../../core/domain/enums.dart';

class SyncQueueItem extends Equatable {
  const SyncQueueItem({
    required this.localId,
    required this.entityType,
    required this.payload,
    required this.createdAt,
    required this.retryCount,
    required this.syncStatus,
    this.serverId,
    this.lastAttemptAt,
    this.errorMessage,
    this.idempotencyKey,
  });

  final String localId;
  final SyncEntityType entityType;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final SyncStatus syncStatus;
  final String? serverId;
  final DateTime? lastAttemptAt;
  final String? errorMessage;
  final String? idempotencyKey;

  bool get isPhoto =>
      entityType == SyncEntityType.dispatchPhoto ||
      entityType == SyncEntityType.receivingPhoto;

  SyncQueueItem copyWith({
    SyncStatus? syncStatus,
    int? retryCount,
    DateTime? lastAttemptAt,
    String? errorMessage,
    String? serverId,
  }) {
    return SyncQueueItem(
      localId: localId,
      entityType: entityType,
      payload: payload,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      syncStatus: syncStatus ?? this.syncStatus,
      serverId: serverId ?? this.serverId,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      errorMessage: errorMessage,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  List<Object?> get props => [
    localId,
    entityType,
    payload,
    createdAt,
    retryCount,
    syncStatus,
    serverId,
    lastAttemptAt,
    errorMessage,
    idempotencyKey,
  ];
}

class SyncSnapshot extends Equatable {
  const SyncSnapshot({
    required this.pendingCount,
    required this.failedCount,
    required this.conflictCount,
    required this.status,
    this.lastSyncedAt,
    this.currentMessage,
  });

  final int pendingCount;
  final int failedCount;
  final int conflictCount;
  final ConnectivityStatus status;
  final DateTime? lastSyncedAt;
  final String? currentMessage;

  @override
  List<Object?> get props => [
    pendingCount,
    failedCount,
    conflictCount,
    status,
    lastSyncedAt,
    currentMessage,
  ];
}
