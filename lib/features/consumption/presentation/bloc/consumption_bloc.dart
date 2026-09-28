import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/business_rules.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../authentication/domain/entities/user_session.dart';
import '../../../inventory/domain/entities/inventory_entities.dart';
import '../../../inventory/domain/repositories/inventory_repository.dart';
import '../../../operations/domain/repositories/operations_repository.dart';
import '../../domain/entities/consumption_entities.dart';

class ConsumptionBloc extends Cubit<ConsumptionState> {
  ConsumptionBloc(this._repository) : super(const ConsumptionState());

  final OperationsRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final items = await _repository.getConsumptions();
    emit(state.copyWith(loading: false, items: items));
  }
}

class ConsumptionState extends Equatable {
  const ConsumptionState({this.loading = false, this.items = const []});

  final bool loading;
  final List<ConsumptionEntry> items;

  ConsumptionState copyWith({
    bool? loading,
    List<ConsumptionEntry>? items,
  }) {
    return ConsumptionState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [loading, items];
}

class ConsumptionFormCubit extends Cubit<ConsumptionFormState> {
  ConsumptionFormCubit({
    required this.user,
    required InventoryRepository inventoryRepository,
    required OperationsRepository operationsRepository,
    required IdGenerator ids,
  }) : _inventoryRepository = inventoryRepository,
       _operationsRepository = operationsRepository,
       _ids = ids,
       super(const ConsumptionFormState());

  final UserProfile user;
  final InventoryRepository _inventoryRepository;
  final OperationsRepository _operationsRepository;
  final IdGenerator _ids;

  Future<void> load() async {
    final items = await _inventoryRepository.getInventory(
      scopeType: 'site',
      scopeId: user.primaryProject!.id,
    );
    emit(state.copyWith(inventory: items, material: items.firstOrNull));
  }

  void select(InventoryItem item) => emit(state.copyWith(material: item));

  void setUsed(String value) {
    final used = double.tryParse(value) ?? 0;
    emit(state.copyWith(used: used, usedText: value, errorMessage: null));
  }

  void setTask(String value) => emit(state.copyWith(workTask: value));

  void setRemarks(String value) => emit(state.copyWith(remarks: value));

  Future<bool> submit() async {
    final item = state.material;
    if (item == null) return false;
    final check = BusinessRules.canConsume(
      available: item.available,
      used: state.used,
    );
    if (!check.isValid) {
      emit(state.copyWith(errorMessage: check.message));
      return false;
    }
    if (state.workTask.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Work / Task is required.'));
      return false;
    }
    emit(state.copyWith(saving: true));
    try {
      await _operationsRepository.recordConsumption(
        ConsumptionEntry(
          id: _ids.uuid(),
          material: item.material,
          quantity: state.used,
          projectId: user.primaryProject!.id,
          projectName: user.primaryProject!.name,
          workTask: state.workTask.trim(),
          recordedBy: user.name,
          createdAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
          remarks: state.remarks.trim().isEmpty ? null : state.remarks.trim(),
        ),
      );
      emit(state.copyWith(saving: false, saved: true));
      return true;
    } catch (error) {
      emit(state.copyWith(saving: false, errorMessage: humanizeError(error)));
      return false;
    }
  }
}

class ConsumptionFormState extends Equatable {
  const ConsumptionFormState({
    this.inventory = const [],
    this.material,
    this.used = 0,
    this.usedText = '',
    this.workTask = '',
    this.remarks = '',
    this.saving = false,
    this.saved = false,
    this.errorMessage,
  });

  final List<InventoryItem> inventory;
  final InventoryItem? material;
  final double used;
  final String usedText;
  final String workTask;
  final String remarks;
  final bool saving;
  final bool saved;
  final String? errorMessage;

  double get remaining => (material?.available ?? 0) - used;

  ConsumptionFormState copyWith({
    List<InventoryItem>? inventory,
    InventoryItem? material,
    double? used,
    String? usedText,
    String? workTask,
    String? remarks,
    bool? saving,
    bool? saved,
    String? errorMessage,
  }) {
    return ConsumptionFormState(
      inventory: inventory ?? this.inventory,
      material: material ?? this.material,
      used: used ?? this.used,
      usedText: usedText ?? this.usedText,
      workTask: workTask ?? this.workTask,
      remarks: remarks ?? this.remarks,
      saving: saving ?? this.saving,
      saved: saved ?? this.saved,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    inventory,
    material,
    used,
    usedText,
    workTask,
    remarks,
    saving,
    saved,
    errorMessage,
  ];
}

class RequirementFormCubit extends Cubit<RequirementFormState> {
  RequirementFormCubit({
    required this.user,
    required InventoryRepository inventoryRepository,
    required OperationsRepository operationsRepository,
    required IdGenerator ids,
  }) : _inventoryRepository = inventoryRepository,
       _operationsRepository = operationsRepository,
       _ids = ids,
       super(const RequirementFormState());

  final UserProfile user;
  final InventoryRepository _inventoryRepository;
  final OperationsRepository _operationsRepository;
  final IdGenerator _ids;

  Future<void> load({int? materialId}) async {
    final items = await _inventoryRepository.getInventory(
      scopeType: 'site',
      scopeId: user.primaryProject!.id,
    );
    final selected = materialId == null
        ? items.firstOrNull
        : items.cast<InventoryItem?>().firstWhere(
            (item) => item?.material.id == materialId,
            orElse: () => items.firstOrNull,
          );
    emit(state.copyWith(inventory: items, material: selected));
  }

  void select(InventoryItem item) => emit(state.copyWith(material: item));

  void setQty(String value) {
    emit(state.copyWith(requiredQty: double.tryParse(value) ?? 0));
  }

  void setPriority(RequirementPriority priority) {
    emit(state.copyWith(priority: priority));
  }

  void setDate(DateTime date) => emit(state.copyWith(requiredDate: date));

  void setRemarks(String value) => emit(state.copyWith(remarks: value));

  Future<bool> submit() async {
    final item = state.material;
    if (item == null || state.requiredQty <= 0) {
      emit(state.copyWith(errorMessage: 'Enter a valid required quantity.'));
      return false;
    }
    emit(state.copyWith(saving: true));
    try {
      await _operationsRepository.createRequirement(
        MaterialRequirement(
          id: _ids.uuid(),
          projectId: user.primaryProject!.id,
          projectName: user.primaryProject!.name,
          material: item.material,
          requiredQty: state.requiredQty,
          currentStock: item.available,
          priority: state.priority,
          requiredDate: state.requiredDate ??
              DateTime.now().add(const Duration(days: 3)),
          status: RequirementStatus.pendingAdmin,
          syncStatus: SyncStatus.pending,
          createdAt: DateTime.now(),
          remarks: state.remarks,
        ),
      );
      emit(state.copyWith(saving: false, saved: true));
      return true;
    } catch (error) {
      emit(state.copyWith(saving: false, errorMessage: humanizeError(error)));
      return false;
    }
  }
}

class RequirementFormState extends Equatable {
  const RequirementFormState({
    this.inventory = const [],
    this.material,
    this.requiredQty = 0,
    this.priority = RequirementPriority.medium,
    this.requiredDate,
    this.remarks = '',
    this.saving = false,
    this.saved = false,
    this.errorMessage,
  });

  final List<InventoryItem> inventory;
  final InventoryItem? material;
  final double requiredQty;
  final RequirementPriority priority;
  final DateTime? requiredDate;
  final String remarks;
  final bool saving;
  final bool saved;
  final String? errorMessage;

  double get suggested => BusinessRules.suggestedRequirement(
    currentStock: material?.available ?? 0,
    requiredQty: requiredQty,
  );

  RequirementFormState copyWith({
    List<InventoryItem>? inventory,
    InventoryItem? material,
    double? requiredQty,
    RequirementPriority? priority,
    DateTime? requiredDate,
    String? remarks,
    bool? saving,
    bool? saved,
    String? errorMessage,
  }) {
    return RequirementFormState(
      inventory: inventory ?? this.inventory,
      material: material ?? this.material,
      requiredQty: requiredQty ?? this.requiredQty,
      priority: priority ?? this.priority,
      requiredDate: requiredDate ?? this.requiredDate ?? DateTime.now().add(const Duration(days: 3)),
      remarks: remarks ?? this.remarks,
      saving: saving ?? this.saving,
      saved: saved ?? this.saved,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    inventory,
    material,
    requiredQty,
    priority,
    requiredDate,
    remarks,
    saving,
    saved,
    errorMessage,
  ];
}
