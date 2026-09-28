enum UserRole {
  storeManager,
  siteSupervisor;

  static UserRole fromApi(String value) {
    switch (value) {
      case 'store_manager':
        return UserRole.storeManager;
      case 'site_supervisor':
        return UserRole.siteSupervisor;
      default:
        throw ArgumentError('Unsupported role: $value');
    }
  }

  String get apiValue => switch (this) {
    UserRole.storeManager => 'store_manager',
    UserRole.siteSupervisor => 'site_supervisor',
  };

  String get label => switch (this) {
    UserRole.storeManager => 'Store Manager',
    UserRole.siteSupervisor => 'Site Supervisor',
  };
}

enum AppPermission {
  viewStoreInventory,
  processDispatch,
  captureDispatchPhoto,
  viewSiteInventory,
  receiveMaterials,
  recordConsumption,
  createRequirement,
  viewNotifications,
  viewProfile,
  viewSyncStatus,
}

class RolePermissions {
  static const storeManager = {
    AppPermission.viewStoreInventory,
    AppPermission.processDispatch,
    AppPermission.captureDispatchPhoto,
    AppPermission.viewNotifications,
    AppPermission.viewProfile,
    AppPermission.viewSyncStatus,
  };

  static const siteSupervisor = {
    AppPermission.viewSiteInventory,
    AppPermission.receiveMaterials,
    AppPermission.recordConsumption,
    AppPermission.createRequirement,
    AppPermission.viewNotifications,
    AppPermission.viewProfile,
    AppPermission.viewSyncStatus,
  };

  static Set<AppPermission> forRole(UserRole role) {
    return switch (role) {
      UserRole.storeManager => storeManager,
      UserRole.siteSupervisor => siteSupervisor,
    };
  }

  static bool can(UserRole role, AppPermission permission) {
    return forRole(role).contains(permission);
  }
}
