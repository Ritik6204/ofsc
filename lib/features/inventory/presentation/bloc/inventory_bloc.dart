import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../authentication/domain/entities/user_session.dart';
import '../../domain/entities/inventory_entities.dart';
import '../../domain/repositories/inventory_repository.dart';

part 'inventory_state.dart';

class InventoryBloc extends Cubit<InventoryState> {
  InventoryBloc({
    required this.user,
    required InventoryRepository repository,
    this.scopeType,
  }) : _repository = repository,
       super(const InventoryState.initial());

  final UserProfile user;
  final InventoryRepository _repository;
  final String? scopeType;

  Future<void> load() async {
    emit(state.copyWith(status: InventoryStatus.loading));
    try {
      final type = scopeType ?? (user.isStoreManager ? 'store' : 'site');
      final scopeId = type == 'store'
          ? user.store!.id
          : user.primaryProject!.id;
      final items = await _repository.getInventory(
        scopeType: type,
        scopeId: scopeId,
      );
      emit(
        state.copyWith(
          status: items.isEmpty ? InventoryStatus.empty : InventoryStatus.loaded,
          items: items,
          categories: {
            'All',
            ...items.map((item) => item.material.category),
          }.toList(),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: InventoryStatus.error,
          errorMessage: humanizeError(error),
        ),
      );
    }
  }

  void search(String query) {
    emit(state.copyWith(query: query));
  }

  void filter(InventoryFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  void category(String category) {
    emit(state.copyWith(category: category));
  }
}

class MaterialDetailCubit extends Cubit<MaterialDetailState> {
  MaterialDetailCubit({
    required this.user,
    required InventoryRepository repository,
    required this.materialId,
  }) : _repository = repository,
       super(const MaterialDetailState());

  final UserProfile user;
  final InventoryRepository _repository;
  final int materialId;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final type = user.isStoreManager ? 'store' : 'site';
    final scopeId = user.isStoreManager
        ? user.store!.id
        : user.primaryProject!.id;
    final item = await _repository.getItem(
      scopeType: type,
      scopeId: scopeId,
      materialId: materialId,
    );
    final movements = await _repository.getMovements(materialId);
    emit(MaterialDetailState(item: item, movements: movements, loading: false));
  }
}

class MaterialDetailState extends Equatable {
  const MaterialDetailState({
    this.item,
    this.movements = const [],
    this.loading = true,
  });

  final InventoryItem? item;
  final List<StockMovement> movements;
  final bool loading;

  MaterialDetailState copyWith({
    InventoryItem? item,
    List<StockMovement>? movements,
    bool? loading,
  }) {
    return MaterialDetailState(
      item: item ?? this.item,
      movements: movements ?? this.movements,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [item, movements, loading];
}
