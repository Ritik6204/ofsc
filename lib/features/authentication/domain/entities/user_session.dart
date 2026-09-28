import 'package:equatable/equatable.dart';

import '../../../../core/security/user_role.dart';

class AssignedStore extends Equatable {
  const AssignedStore({
    required this.id,
    required this.name,
    required this.location,
  });

  final int id;
  final String name;
  final String location;

  @override
  List<Object?> get props => [id, name, location];
}

class AssignedProject extends Equatable {
  const AssignedProject({
    required this.id,
    required this.name,
    required this.location,
  });

  final int id;
  final String name;
  final String location;

  @override
  List<Object?> get props => [id, name, location];
}

class UserProfile extends Equatable {
  const UserProfile({
    required this.userId,
    required this.name,
    required this.employeeId,
    required this.role,
    required this.email,
    required this.phone,
    required this.accountStatus,
    this.photoUrl,
    this.store,
    this.projects = const [],
  });

  final int userId;
  final String name;
  final String employeeId;
  final UserRole role;
  final String email;
  final String phone;
  final String accountStatus;
  final String? photoUrl;
  final AssignedStore? store;
  final List<AssignedProject> projects;

  AssignedProject? get primaryProject =>
      projects.isEmpty ? null : projects.first;

  bool get isStoreManager => role == UserRole.storeManager;
  bool get isSiteSupervisor => role == UserRole.siteSupervisor;

  bool canAccessStore(int storeId) => store?.id == storeId;

  bool canAccessProject(int projectId) =>
      projects.any((project) => project.id == projectId);

  bool can(AppPermission permission) => RolePermissions.can(role, permission);

  UserProfile copyWith({
    AssignedStore? store,
    List<AssignedProject>? projects,
  }) {
    return UserProfile(
      userId: userId,
      name: name,
      employeeId: employeeId,
      role: role,
      email: email,
      phone: phone,
      accountStatus: accountStatus,
      photoUrl: photoUrl,
      store: store ?? this.store,
      projects: projects ?? this.projects,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'employee_id': employeeId,
      'role': role.apiValue,
      'email': email,
      'phone': phone,
      'account_status': accountStatus,
      'photo_url': photoUrl,
      'store': store == null
          ? null
          : {
              'id': store!.id,
              'name': store!.name,
              'location': store!.location,
            },
      'projects': projects
          .map(
            (p) => {'id': p.id, 'name': p.name, 'location': p.location},
          )
          .toList(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final store = map['store'] as Map<String, dynamic>?;
    final projects = (map['projects'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return UserProfile(
      userId: map['user_id'] as int,
      name: map['name'] as String,
      employeeId: map['employee_id'] as String,
      role: UserRole.fromApi(map['role'] as String),
      email: map['email'] as String,
      phone: map['phone'] as String,
      accountStatus: map['account_status'] as String? ?? 'active',
      photoUrl: map['photo_url'] as String?,
      store: store == null
          ? null
          : AssignedStore(
              id: store['id'] as int,
              name: store['name'] as String,
              location: store['location'] as String,
            ),
      projects: projects
          .map(
            (p) => AssignedProject(
              id: p['id'] as int,
              name: p['name'] as String,
              location: p['location'] as String,
            ),
          )
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
    userId,
    name,
    employeeId,
    role,
    email,
    phone,
    accountStatus,
    photoUrl,
    store,
    projects,
  ];
}

class AuthTokens extends Equatable {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresAt];
}

class AuthSession extends Equatable {
  const AuthSession({required this.user, required this.tokens});

  final UserProfile user;
  final AuthTokens tokens;

  @override
  List<Object?> get props => [user, tokens];
}
