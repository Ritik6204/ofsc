enum SyncStatus {
  pending,
  syncing,
  synced,
  failed,
  conflict;

  String get label => switch (this) {
    SyncStatus.pending => 'Pending',
    SyncStatus.syncing => 'Syncing',
    SyncStatus.synced => 'Synced',
    SyncStatus.failed => 'Failed',
    SyncStatus.conflict => 'Conflict',
  };
}

enum DispatchStatus {
  pendingDispatch,
  verifying,
  dispatched,
  inTransit,
  partiallyReceived,
  received,
  discrepancy;

  String get label => switch (this) {
    DispatchStatus.pendingDispatch => 'Pending Dispatch',
    DispatchStatus.verifying => 'Verifying',
    DispatchStatus.dispatched => 'Dispatched',
    DispatchStatus.inTransit => 'In Transit',
    DispatchStatus.partiallyReceived => 'Partially Received',
    DispatchStatus.received => 'Received',
    DispatchStatus.discrepancy => 'Discrepancy',
  };
}

enum ReceivingStatus {
  received,
  partiallyReceived,
  notReceived;

  String get label => switch (this) {
    ReceivingStatus.received => 'Received',
    ReceivingStatus.partiallyReceived => 'Partially Received',
    ReceivingStatus.notReceived => 'Not Received',
  };
}

enum StockStatus {
  normal,
  low,
  reserved;

  String get label => switch (this) {
    StockStatus.normal => 'Normal',
    StockStatus.low => 'Low Stock',
    StockStatus.reserved => 'Reserved',
  };
}

enum RequirementPriority { low, medium, high, urgent }

enum RequirementStatus { draft, pendingAdmin, approved, rejected }

enum PhotoKind {
  material,
  loadedMaterial,
  dispatchProof,
  deliveredMaterial,
  deliveryVehicle,
  materialQuantity,
  siteEvidence,
}

enum SyncEntityType {
  dispatchConfirmation,
  dispatchPhoto,
  receivingConfirmation,
  receivingPhoto,
  consumption,
  requirement,
}

enum InventoryFilter { all, available, reserved, lowStock }

enum ConnectivityStatus { online, offline, syncing, synced }
