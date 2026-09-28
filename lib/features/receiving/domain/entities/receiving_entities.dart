import 'package:equatable/equatable.dart';

import '../../../../core/domain/enums.dart';
import '../../../dispatch/domain/entities/dispatch_entities.dart';
import '../../../inventory/domain/entities/inventory_entities.dart';

class ReceivingLine extends Equatable {
  const ReceivingLine({
    required this.material,
    required this.dispatchedQty,
    required this.status,
    this.receivedQty,
    this.reason,
  });

  final Material material;
  final double dispatchedQty;
  final ReceivingStatus status;
  final double? receivedQty;
  final String? reason;

  double get actualReceived => receivedQty ?? 0;
  double get difference => dispatchedQty - actualReceived;
  bool get hasDiscrepancy =>
      status != ReceivingStatus.received || difference > 0;

  ReceivingLine copyWith({
    ReceivingStatus? status,
    double? receivedQty,
    String? reason,
  }) {
    return ReceivingLine(
      material: material,
      dispatchedQty: dispatchedQty,
      status: status ?? this.status,
      receivedQty: receivedQty ?? this.receivedQty,
      reason: reason ?? this.reason,
    );
  }

  @override
  List<Object?> get props => [
    material,
    dispatchedQty,
    status,
    receivedQty,
    reason,
  ];
}

class ReceivingDraft extends Equatable {
  const ReceivingDraft({
    required this.request,
    required this.lines,
    this.remarks = '',
    this.photos = const [],
  });

  final DispatchRequest request;
  final List<ReceivingLine> lines;
  final String remarks;
  final List<AttachedPhoto> photos;

  @override
  List<Object?> get props => [request, lines, remarks, photos];
}
