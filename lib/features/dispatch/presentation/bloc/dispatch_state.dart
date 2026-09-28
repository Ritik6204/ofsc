part of 'dispatch_bloc.dart';

enum DispatchListStatus { initial, loading, loaded, empty, error }

class DispatchState extends Equatable {
  const DispatchState({
    required this.status,
    this.items = const [],
    this.errorMessage,
  });

  const DispatchState.initial() : this(status: DispatchListStatus.initial);

  final DispatchListStatus status;
  final List<DispatchRequest> items;
  final String? errorMessage;

  DispatchState copyWith({
    DispatchListStatus? status,
    List<DispatchRequest>? items,
    String? errorMessage,
  }) {
    return DispatchState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}

enum DispatchPhase { initial, loading, ready, creating, pendingSync, failed }

class DispatchWorkflowState extends Equatable {
  const DispatchWorkflowState({
    this.phase = DispatchPhase.initial,
    this.request,
    this.lines = const [],
    this.photos = const [],
    this.remarks = '',
    this.errorMessage,
  });

  final DispatchPhase phase;
  final DispatchRequest? request;
  final List<DispatchLine> lines;
  final List<AttachedPhoto> photos;
  final String remarks;
  final String? errorMessage;

  DispatchWorkflowState copyWith({
    DispatchPhase? phase,
    DispatchRequest? request,
    List<DispatchLine>? lines,
    List<AttachedPhoto>? photos,
    String? remarks,
    String? errorMessage,
  }) {
    return DispatchWorkflowState(
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
