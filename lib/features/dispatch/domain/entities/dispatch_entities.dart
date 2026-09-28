import 'package:equatable/equatable.dart';

import '../../../../core/domain/enums.dart';
import '../../../inventory/domain/entities/inventory_entities.dart';

class DispatchLine extends Equatable {
  const DispatchLine({
    required this.material,
    required this.requestedQty,
    required this.availableQty,
    this.confirmedQty,
    this.reason,
  });

  final Material material;
  final double requestedQty;
  final double availableQty;
  final double? confirmedQty;
  final String? reason;

  double get difference {
    final actual = confirmedQty ?? requestedQty;
    return requestedQty - actual;
  }

  bool get hasShortage => difference > 0;

  DispatchLine copyWith({
    double? confirmedQty,
    String? reason,
    double? availableQty,
  }) {
    return DispatchLine(
      material: material,
      requestedQty: requestedQty,
      availableQty: availableQty ?? this.availableQty,
      confirmedQty: confirmedQty ?? this.confirmedQty,
      reason: reason ?? this.reason,
    );
  }

  @override
  List<Object?> get props => [
    material,
    requestedQty,
    availableQty,
    confirmedQty,
    reason,
  ];
}

class DispatchRequest extends Equatable {
  const DispatchRequest({
    required this.id,
    required this.requestCode,
    required this.projectId,
    required this.projectName,
    required this.storeId,
    required this.storeName,
    required this.requestedBy,
    required this.requestedAt,
    required this.status,
    required this.lines,
    this.dispatchCode,
    this.remarks,
    this.localId,
    this.syncStatus = SyncStatus.synced,
    this.photos = const [],
  });

  final String id;
  final String requestCode;
  final int projectId;
  final String projectName;
  final int storeId;
  final String storeName;
  final String requestedBy;
  final DateTime requestedAt;
  final DispatchStatus status;
  final List<DispatchLine> lines;
  final String? dispatchCode;
  final String? remarks;
  final String? localId;
  final SyncStatus syncStatus;
  final List<AttachedPhoto> photos;

  int get materialCount => lines.length;

  DispatchRequest copyWith({
    DispatchStatus? status,
    List<DispatchLine>? lines,
    String? remarks,
    String? dispatchCode,
    SyncStatus? syncStatus,
    List<AttachedPhoto>? photos,
    String? localId,
  }) {
    return DispatchRequest(
      id: id,
      requestCode: requestCode,
      projectId: projectId,
      projectName: projectName,
      storeId: storeId,
      storeName: storeName,
      requestedBy: requestedBy,
      requestedAt: requestedAt,
      status: status ?? this.status,
      lines: lines ?? this.lines,
      dispatchCode: dispatchCode ?? this.dispatchCode,
      remarks: remarks ?? this.remarks,
      localId: localId ?? this.localId,
      syncStatus: syncStatus ?? this.syncStatus,
      photos: photos ?? this.photos,
    );
  }

  @override
  List<Object?> get props => [
    id,
    requestCode,
    projectId,
    projectName,
    storeId,
    storeName,
    requestedBy,
    requestedAt,
    status,
    lines,
    dispatchCode,
    remarks,
    localId,
    syncStatus,
    photos,
  ];
}

class AttachedPhoto extends Equatable {
  const AttachedPhoto({
    required this.id,
    required this.localPath,
    required this.kind,
    required this.syncStatus,
    this.remoteUrl,
  });

  final String id;
  final String localPath;
  final PhotoKind kind;
  final SyncStatus syncStatus;
  final String? remoteUrl;

  AttachedPhoto copyWith({SyncStatus? syncStatus, String? remoteUrl}) {
    return AttachedPhoto(
      id: id,
      localPath: localPath,
      kind: kind,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteUrl: remoteUrl ?? this.remoteUrl,
    );
  }

  @override
  List<Object?> get props => [id, localPath, kind, syncStatus, remoteUrl];
}

class DispatchDraft extends Equatable {
  const DispatchDraft({
    required this.request,
    required this.lines,
    this.remarks = '',
    this.photos = const [],
  });

  final DispatchRequest request;
  final List<DispatchLine> lines;
  final String remarks;
  final List<AttachedPhoto> photos;

  @override
  List<Object?> get props => [request, lines, remarks, photos];
}
