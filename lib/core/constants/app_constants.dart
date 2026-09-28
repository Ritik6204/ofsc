class AppConstants {
  static const String appName = 'OFSC Inventory';
  static const String appTagline = 'Field Stock Control';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  static const int maxPhotoWidth = 1600;
  static const int photoQuality = 70;
  static const int maxSyncRetries = 5;
  static const int pageSize = 40;

  static const String demoStoreUsername = 'raj.kumar';
  static const String demoStorePassword = 'Store@123';
  static const String demoSiteUsername = 'amit.sharma';
  static const String demoSitePassword = 'Site@123';
}

class StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String tokenExpiry = 'token_expiry';
  static const String cachedUser = 'cached_user';
  static const String lastSyncedAt = 'last_synced_at';
  static const String demoMode = 'demo_mode';
}

class ApiEndpoints {
  static const String baseUrl = 'https://api.ofsc.local/v1';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/change-password';
  static const String forgotPassword = '/auth/forgot-password';
  static const String bootstrap = '/sync/bootstrap';
  static const String inventory = '/inventory';
  static const String dispatches = '/dispatches';
  static const String confirmDispatch = '/dispatches/confirm';
  static const String receive = '/receiving/confirm';
  static const String consumption = '/consumption';
  static const String requirements = '/requirements';
  static const String notifications = '/notifications';
  static const String uploadPhoto = '/uploads/photos';
  static const String dashboard = '/dashboard';
}
