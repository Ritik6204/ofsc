part of 'dashboard_bloc.dart';

enum DashboardStatus { initial, loading, loaded, empty, error }

class DashboardState extends Equatable {
  const DashboardState({
    required this.status,
    this.inventory = const [],
    this.dispatches = const [],
    this.activities = const [],
    this.lastSyncedAt,
    this.errorMessage,
  });

  const DashboardState.initial() : this(status: DashboardStatus.initial);

  final DashboardStatus status;
  final List<InventoryItem> inventory;
  final List<DispatchRequest> dispatches;
  final List<ActivityEvent> activities;
  final DateTime? lastSyncedAt;
  final String? errorMessage;

  List<DispatchRequest> get pendingDispatches => dispatches
      .where((item) => item.status == DispatchStatus.pendingDispatch)
      .toList();

  List<DispatchRequest> get incoming => dispatches
      .where(
        (item) =>
            item.status == DispatchStatus.inTransit ||
            item.status == DispatchStatus.dispatched ||
            item.status == DispatchStatus.partiallyReceived,
      )
      .toList();

  List<InventoryItem> get lowStock =>
      inventory.where((item) => item.isLowStock).toList();

  double get totalAvailable =>
      inventory.fold(0, (sum, item) => sum + item.available);

  double get totalReserved =>
      inventory.fold(0, (sum, item) => sum + item.reserved);

  DashboardState copyWith({
    DashboardStatus? status,
    List<InventoryItem>? inventory,
    List<DispatchRequest>? dispatches,
    List<ActivityEvent>? activities,
    DateTime? lastSyncedAt,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      inventory: inventory ?? this.inventory,
      dispatches: dispatches ?? this.dispatches,
      activities: activities ?? this.activities,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    inventory,
    dispatches,
    activities,
    lastSyncedAt,
    errorMessage,
  ];
}
