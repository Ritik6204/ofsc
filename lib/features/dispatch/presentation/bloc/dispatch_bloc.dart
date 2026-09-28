import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../operations/domain/repositories/operations_repository.dart';
import '../../domain/entities/dispatch_entities.dart';

part 'dispatch_state.dart';

class DispatchBloc extends Cubit<DispatchState> {
  DispatchBloc(this._repository) : super(const DispatchState.initial());

  final OperationsRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: DispatchListStatus.loading));
    try {
      final items = await _repository.getDispatches();
      emit(
        state.copyWith(
          status: items.isEmpty
              ? DispatchListStatus.empty
              : DispatchListStatus.loaded,
          items: items,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: DispatchListStatus.error,
          errorMessage: humanizeError(error),
        ),
      );
    }
  }
}

class DispatchWorkflowCubit extends Cubit<DispatchWorkflowState> {
  DispatchWorkflowCubit({
    required OperationsRepository repository,
    required IdGenerator ids,
    required this.requestId,
  }) : _repository = repository,
       _ids = ids,
       super(const DispatchWorkflowState());

  final OperationsRepository _repository;
  final IdGenerator _ids;
  final String requestId;

  Future<void> load() async {
    emit(state.copyWith(phase: DispatchPhase.loading));
    final request = await _repository.getDispatch(requestId);
    if (request == null) {
      emit(state.copyWith(phase: DispatchPhase.failed, errorMessage: 'Request not found.'));
      return;
    }
    emit(
      state.copyWith(
        phase: DispatchPhase.ready,
        request: request,
        lines: request.lines
            .map((line) => line.copyWith(confirmedQty: line.requestedQty))
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
              line.copyWith(confirmedQty: qty)
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

  void updateRemarks(String remarks) {
    emit(state.copyWith(remarks: remarks));
  }

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
    emit(state.copyWith(phase: DispatchPhase.creating));
    try {
      final saved = await _repository.confirmDispatch(
        DispatchDraft(
          request: state.request!,
          lines: state.lines,
          remarks: state.remarks,
          photos: state.photos,
        ),
      );
      emit(state.copyWith(phase: DispatchPhase.pendingSync, request: saved));
    } catch (error) {
      emit(
        state.copyWith(
          phase: DispatchPhase.failed,
          errorMessage: humanizeError(error),
        ),
      );
    }
  }
}
