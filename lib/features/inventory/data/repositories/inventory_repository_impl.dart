import '../../../../core/database/local_data_source.dart';
import '../../domain/entities/inventory_entities.dart';
import '../../domain/repositories/inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  InventoryRepositoryImpl(this._local);

  final LocalDataSource _local;

  @override
  Future<List<InventoryItem>> getInventory({
    required String scopeType,
    required int scopeId,
  }) {
    return _local.getInventory(scopeType: scopeType, scopeId: scopeId);
  }

  @override
  Future<InventoryItem?> getItem({
    required String scopeType,
    required int scopeId,
    required int materialId,
  }) async {
    final items = await getInventory(scopeType: scopeType, scopeId: scopeId);
    try {
      return items.firstWhere((item) => item.material.id == materialId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<StockMovement>> getMovements(int materialId) {
    return _local.getMovements(materialId);
  }

  @override
  Future<List<ActivityEvent>> getActivities() => _local.getActivities();

  @override
  Future<List<Material>> getMaterials() => _local.getMaterials();
}
