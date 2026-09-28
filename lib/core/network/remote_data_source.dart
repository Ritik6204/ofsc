import '../../features/authentication/domain/entities/user_session.dart';
import '../../features/consumption/domain/entities/consumption_entities.dart';
import '../../features/dispatch/domain/entities/dispatch_entities.dart';
import '../../features/inventory/domain/entities/inventory_entities.dart';
import '../../features/notifications/domain/entities/app_notification.dart';
import '../errors/exceptions.dart';
import 'demo_backend.dart';
import 'network_info.dart';

class BootstrapPayload {
  const BootstrapPayload({
    required this.user,
    required this.materials,
    required this.inventory,
    required this.dispatches,
    required this.movements,
    required this.activities,
    required this.consumptions,
    required this.requirements,
    required this.notifications,
  });

  final UserProfile user;
  final List<Material> materials;
  final List<InventoryItem> inventory;
  final List<DispatchRequest> dispatches;
  final List<StockMovement> movements;
  final List<ActivityEvent> activities;
  final List<ConsumptionEntry> consumptions;
  final List<MaterialRequirement> requirements;
  final List<AppNotification> notifications;
}

class RemoteDataSource {
  RemoteDataSource({
    required DemoBackend backend,
    required NetworkInfo networkInfo,
    this.simulateLatency = const Duration(milliseconds: 250),
  }) : _backend = backend,
       _networkInfo = networkInfo;

  final DemoBackend _backend;
  final NetworkInfo _networkInfo;
  final Duration simulateLatency;

  Future<void> _ensureOnline() async {
    if (!await _networkInfo.isConnected) {
      throw const ApiException(
        'No internet connection right now.',
        code: 'offline',
      );
    }
    if (simulateLatency > Duration.zero) {
      await Future<void>.delayed(simulateLatency);
    }
  }

  Future<AuthSession> login(String username, String password) async {
    await _ensureOnline();
    return _backend.login(username, password);
  }

  Future<UserProfile> me(String token) async {
    await _ensureOnline();
    return _backend.me(token);
  }

  Future<BootstrapPayload> bootstrap(String token) async {
    await _ensureOnline();
    final data = _backend.bootstrap(token);
    return BootstrapPayload(
      user: data['user'] as UserProfile,
      materials: data['materials'] as List<Material>,
      inventory: data['inventory'] as List<InventoryItem>,
      dispatches: data['dispatches'] as List<DispatchRequest>,
      movements: data['movements'] as List<StockMovement>,
      activities: data['activities'] as List<ActivityEvent>,
      consumptions: data['consumptions'] as List<ConsumptionEntry>,
      requirements: data['requirements'] as List<MaterialRequirement>,
      notifications: data['notifications'] as List<AppNotification>,
    );
  }

  Future<Map<String, dynamic>> confirmDispatch(
    Map<String, dynamic> payload,
  ) async {
    await _ensureOnline();
    return _backend.confirmDispatch(payload);
  }

  Future<Map<String, dynamic>> confirmReceiving(
    Map<String, dynamic> payload,
  ) async {
    await _ensureOnline();
    return _backend.confirmReceiving(payload);
  }

  Future<Map<String, dynamic>> recordConsumption(
    Map<String, dynamic> payload,
  ) async {
    await _ensureOnline();
    return _backend.recordConsumption(payload);
  }

  Future<Map<String, dynamic>> createRequirement(
    Map<String, dynamic> payload,
  ) async {
    await _ensureOnline();
    return _backend.createRequirement(payload);
  }

  Future<Map<String, dynamic>> uploadPhoto(Map<String, dynamic> payload) async {
    await _ensureOnline();
    return _backend.uploadPhoto(payload);
  }
}
