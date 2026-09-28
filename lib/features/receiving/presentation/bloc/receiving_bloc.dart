import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../dispatch/domain/entities/dispatch_entities.dart';
import '../../../operations/domain/repositories/operations_repository.dart';
import '../../domain/entities/receiving_entities.dart';

class ReceivingWorkflowCubit extends Cubit<ReceivingWorkflowState> {
  ReceivingWorkflowCubit({
    required OperationsRepository repository,
    required IdGenerator ids,
    required this.requestId,
  }) : _repository = repository,
       _ids = ids,
       super(const ReceivingWorkflowState());

  final OperationsRepository _repository;
  final IdGenerator _ids;
  final String requestId;

  Future<void> load() async {
    emit(state.copyWith(phase: ReceivingPhase.loading));
    final request = await _repository.getDispatch(requestId);
    if (request == null) {
      emit(
        state.copyWith(
          phase: ReceivingPhase.failed,
          errorMessage: 'Incoming dispatch not found.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        phase: ReceivingPhase.ready,
        request: request,
        lines: request.lines
            .map(
              (line) => ReceivingLine(
                material: line.material,
                dispatchedQty: line.confirmedQty ?? line.requestedQty,
                receivedQty: line.confirmedQty ?? line.requestedQty,
                status: ReceivingStatus.received,
              ),
            )
            .toList(),
      ),
    );
  }

  void updateQuantity(int materialId, double qty) {
    emit(
      state.copyWith(
        lines: [
          for (final line in state.lines)
            if (line.material.id == materialId)
              line.copyWith(
                receivedQty: qty,
                status: qty <= 0
                    ? ReceivingStatus.notReceived
                    : qty < line.dispatchedQty
                    ? ReceivingStatus.partiallyReceived
                    : ReceivingStatus.received,
              )
            else
              line,
        ],
      ),
    );
  }

  void updateStatus(int materialId, ReceivingStatus status) {
    emit(
      state.copyWith(
        lines: [
          for (final line in state.lines)
            if (line.material.id == materialId)
              line.copyWith(
                status: status,
                receivedQty: status == ReceivingStatus.notReceived
                    ? 0
                    : line.receivedQty,
              )
            else
              line,
        ],
      ),
    );
  }

  void updateReason(int materialId, String reason) {
    emit(
      state.copyWith(
        lines: [
          for (final line in state.lines)
            if (line.material.id == materialId)
              line.copyWith(reason: reason)
            else
              line,
        ],
      ),
    );
  }

  void updateRemarks(String remarks) => emit(state.copyWith(remarks: remarks));

  void addPhoto(String path, PhotoKind kind) {
    emit(
      state.copyWith(
        photos: [
          ...state.photos,
          AttachedPhoto(
            id: _ids.photoId(),
            localPath: path,
            kind: kind,
            syncStatus: SyncStatus.pending,
          ),
        ],
      ),
    );
  }

  Future<void> confirm() async {
    if (state.request == null) return;
    emit(state.copyWith(phase: ReceivingPhase.creating));
    try {
      final saved = await _repository.confirmReceiving(
        ReceivingDraft(
          request: state.request!,
          lines: state.lines,
          remarks: state.remarks,
          photos: state.photos,
        ),
      );
      emit(state.copyWith(phase: ReceivingPhase.pendingSync, request: saved));
    } catch (error) {
      emit(
        state.copyWith(
          phase: ReceivingPhase.failed,
          errorMessage: humanizeError(error),
        ),
      );
    }
  }
}

enum ReceivingPhase { initial, loading, ready, creating, pendingSync, failed }

class ReceivingWorkflowState extends Equatable {
  const ReceivingWorkflowState({
    this.phase = ReceivingPhase.initial,
    this.request,
    this.lines = const [],
    this.photos = const [],
    this.remarks = '',
    this.errorMessage,
  });

  final ReceivingPhase phase;
  final DispatchRequest? request;
  final List<ReceivingLine> lines;
  final List<AttachedPhoto> photos;
  final String remarks;
  final String? errorMessage;

  ReceivingWorkflowState copyWith({
    ReceivingPhase? phase,
    DispatchRequest? request,
    List<ReceivingLine>? lines,
    List<AttachedPhoto>? photos,
    String? remarks,
    String? errorMessage,
  }) {
    return ReceivingWorkflowState(
      phase: phase ?? this.phase,
      request: request ?? this.request,
      lines: lines ?? this.lines,
      photos: photos ?? this.photos,
      remarks: remarks ?? this.remarks,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [phase, request, lines, photos, remarks, errorMessage];
}
