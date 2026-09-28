import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.isRead,
    this.entityType,
    this.entityId,
    this.route,
  });

  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final bool isRead;
  final String? entityType;
  final String? entityId;
  final String? route;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      description: description,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      entityType: entityType,
      entityId: entityId,
      route: route,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    createdAt,
    isRead,
    entityType,
    entityId,
    route,
  ];
}
