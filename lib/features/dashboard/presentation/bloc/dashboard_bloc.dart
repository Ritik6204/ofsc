import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../authentication/domain/entities/user_session.dart';
import '../../../dispatch/domain/entities/dispatch_entities.dart';
import '../../../inventory/domain/entities/inventory_entities.dart';
import '../../../inventory/domain/repositories/inventory_repository.dart';
import '../../../operations/domain/repositories/operations_repository.dart';

part 'dashboard_state.dart';

class DashboardBloc extends Cubit<DashboardState> {
  DashboardBloc({
    required this.user,
    required InventoryRepository inventoryRepository,
    required OperationsRepository operationsRepository,
  }) : _inventoryRepository = inventoryRepository,
       _operationsRepository = operationsRepository,
       super(const DashboardState.initial());

  final UserProfile user;
  final InventoryRepository _inventoryRepository;
  final OperationsRepository _operationsRepository;

  Future<void> load({bool refreshing = false}) async {
    if (!refreshing) {
      emit(state.copyWith(status: DashboardStatus.loading));
    }
    try {
      final scopeType = user.isStoreManager ? 'store' : 'site';
      final scopeId = user.isStoreManager
          ? user.store!.id
          : user.primaryProject!.id;
      final inventory = await _inventoryRepository.getInventory(
        scopeType: scopeType,
        scopeId: scopeId,
      );
      final dispatches = await _operationsRepository.getDispatches();
      final activities = await _inventoryRepository.getActivities();
      final lastSynced = await _operationsRepository.lastSyncedAt();
      emit(
        DashboardState(
          status: inventory.isEmpty
              ? DashboardStatus.empty
              : DashboardStatus.loaded,
          inventory: inventory,
          dispatches: dispatches,
          activities: activities,
          lastSyncedAt: lastSynced,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: DashboardStatus.error,
          errorMessage: humanizeError(error),
        ),
      );
    }
  }
}
