import 'package:equatable/equatable.dart';

import '../../../../core/domain/enums.dart';

class Material extends Equatable {
  const Material({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.unit,
    required this.minimumStock,
  });

  final int id;
  final String name;
  final String sku;
  final String category;
  final String unit;
  final double minimumStock;

  @override
  List<Object?> get props => [id, name, sku, category, unit, minimumStock];
}

class InventoryItem extends Equatable {
  const InventoryItem({
    required this.material,
    required this.available,
    required this.reserved,
    required this.total,
    required this.scopeId,
    required this.scopeType,
  });

  final Material material;
  final double available;
  final double reserved;
  final double total;
  final int scopeId;
  final String scopeType;

  bool get isLowStock => available < material.minimumStock;

  StockStatus get status {
    if (isLowStock) return StockStatus.low;
    if (reserved > 0 && available == 0) return StockStatus.reserved;
    return StockStatus.normal;
  }

  InventoryItem copyWith({double? available, double? reserved, double? total}) {
    return InventoryItem(
      material: material,
      available: available ?? this.available,
      reserved: reserved ?? this.reserved,
      total: total ?? this.total,
      scopeId: scopeId,
      scopeType: scopeType,
    );
  }

  @override
  List<Object?> get props => [
    material,
    available,
    reserved,
    total,
    scopeId,
    scopeType,
  ];
}

class StockMovement extends Equatable {
  const StockMovement({
    required this.id,
    required this.materialId,
    required this.quantity,
    required this.unit,
    required this.title,
    required this.createdAt,
    this.reference,
  });

  final String id;
  final int materialId;
  final double quantity;
  final String unit;
  final String title;
  final DateTime createdAt;
  final String? reference;

  bool get isInbound => quantity > 0;

  @override
  List<Object?> get props => [
    id,
    materialId,
    quantity,
    unit,
    title,
    createdAt,
    reference,
  ];
}

class ActivityEvent extends Equatable {
  const ActivityEvent({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  final String id;
  final String title;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, title, createdAt];
}
