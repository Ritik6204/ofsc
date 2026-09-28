import 'package:equatable/equatable.dart';

import '../../../../core/domain/enums.dart';
import '../../../inventory/domain/entities/inventory_entities.dart';

class ConsumptionEntry extends Equatable {
  const ConsumptionEntry({
    required this.id,
    required this.material,
    required this.quantity,
    required this.projectId,
    required this.projectName,
    required this.workTask,
    required this.recordedBy,
    required this.createdAt,
    required this.syncStatus,
    this.remarks,
    this.clientTransactionId,
  });

  final String id;
  final Material material;
  final double quantity;
  final int projectId;
  final String projectName;
  final String workTask;
  final String recordedBy;
  final DateTime createdAt;
  final SyncStatus syncStatus;
  final String? remarks;
  final String? clientTransactionId;

  @override
  List<Object?> get props => [
    id,
    material,
    quantity,
    projectId,
    projectName,
    workTask,
    recordedBy,
    createdAt,
    syncStatus,
    remarks,
    clientTransactionId,
  ];
}

class MaterialRequirement extends Equatable {
  const MaterialRequirement({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.material,
    required this.requiredQty,
    required this.currentStock,
    required this.priority,
    required this.requiredDate,
    required this.status,
    required this.syncStatus,
    required this.createdAt,
    this.remarks,
    this.clientTransactionId,
  });

  final String id;
  final int projectId;
  final String projectName;
  final Material material;
  final double requiredQty;
  final double currentStock;
  final RequirementPriority priority;
  final DateTime requiredDate;
  final RequirementStatus status;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final String? remarks;
  final String? clientTransactionId;

  double get suggestedQty {
    final gap = requiredQty - currentStock;
    return gap < 0 ? 0 : gap;
  }

  @override
  List<Object?> get props => [
    id,
    projectId,
    projectName,
    material,
    requiredQty,
    currentStock,
    priority,
    requiredDate,
    status,
    syncStatus,
    createdAt,
    remarks,
    clientTransactionId,
  ];
}
