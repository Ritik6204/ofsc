import '../entities/inventory_entities.dart';

abstract class InventoryRepository {
  Future<List<InventoryItem>> getInventory({
    required String scopeType,
    required int scopeId,
  });

  Future<InventoryItem?> getItem({
    required String scopeType,
    required int scopeId,
    required int materialId,
  });

  Future<List<StockMovement>> getMovements(int materialId);

  Future<List<ActivityEvent>> getActivities();

  Future<List<Material>> getMaterials();
}
