import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../operations/domain/repositories/operations_repository.dart';
import '../../domain/entities/app_notification.dart';

class NotificationBloc extends Cubit<NotificationState> {
  NotificationBloc(this._repository) : super(const NotificationState());

  final OperationsRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final items = await _repository.getNotifications();
    emit(state.copyWith(loading: false, items: items));
  }

  Future<void> markRead(String id) async {
    await _repository.markNotificationRead(id);
    await load();
  }
}

class NotificationState extends Equatable {
  const NotificationState({this.loading = false, this.items = const []});

  final bool loading;
  final List<AppNotification> items;

  int get unreadCount => items.where((item) => !item.isRead).length;

  NotificationState copyWith({
    bool? loading,
    List<AppNotification>? items,
  }) {
    return NotificationState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [loading, items];
}
