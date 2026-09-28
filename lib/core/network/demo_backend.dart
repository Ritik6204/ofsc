import '../../features/authentication/domain/entities/user_session.dart';
import '../../features/consumption/domain/entities/consumption_entities.dart';
import '../../features/dispatch/domain/entities/dispatch_entities.dart';
import '../../features/inventory/domain/entities/inventory_entities.dart';
import '../../features/notifications/domain/entities/app_notification.dart';
import '../../core/domain/enums.dart';
import '../../core/errors/exceptions.dart';
import '../../core/security/user_role.dart';
import '../constants/app_constants.dart';

class DemoBackend {
  DemoBackend({DateTime Function()? now}) : _now = now ?? DateTime.now {
    reset();
  }

  final DateTime Function() _now;
  final Set<String> _processedKeys = {};
  final Map<String, AuthTokens> _tokens = {};

  late List<Material> materials;
  late UserProfile storeUser;
  late UserProfile siteUser;
  late List<InventoryItem> storeInventory;
  late List<InventoryItem> siteInventory;
  late List<DispatchRequest> dispatches;
  late List<StockMovement> movements;
  late List<ActivityEvent> activities;
  late List<ConsumptionEntry> consumptions;
  late List<MaterialRequirement> requirements;
  late List<AppNotification> storeNotifications;
  late List<AppNotification> siteNotifications;

  void reset() {
    _processedKeys.clear();
    _tokens.clear();
    materials = [
      const Material(
        id: 1,
        name: 'Cement',
        sku: 'CEM-001',
        category: 'Civil',
        unit: 'Bags',
        minimumStock: 80,
      ),
      const Material(
        id: 2,
        name: 'Steel Rod 12mm',
        sku: 'STL-012',
        category: 'Steel',
        unit: 'KG',
        minimumStock: 200,
      ),
      const Material(
        id: 3,
        name: 'Steel Rod 16mm',
        sku: 'STL-016',
        category: 'Steel',
        unit: 'KG',
        minimumStock: 150,
      ),
      const Material(
        id: 4,
        name: 'Bricks',
        sku: 'BRK-001',
        category: 'Civil',
        unit: 'PCS',
        minimumStock: 2000,
      ),
      const Material(
        id: 5,
        name: 'Sand',
        sku: 'SND-001',
        category: 'Civil',
        unit: 'CFT',
        minimumStock: 200,
      ),
      const Material(
        id: 6,
        name: 'Electrical Cable',
        sku: 'ELC-001',
        category: 'Electrical',
        unit: 'MTR',
        minimumStock: 100,
      ),
      const Material(
        id: 7,
        name: 'PVC Pipe',
        sku: 'PVC-001',
        category: 'Plumbing',
        unit: 'MTR',
        minimumStock: 80,
      ),
      const Material(
        id: 8,
        name: 'Paint',
        sku: 'PNT-001',
        category: 'Finishing',
        unit: 'Ltr',
        minimumStock: 40,
      ),
    ];

    storeUser = const UserProfile(
      userId: 101,
      name: 'Raj Kumar',
      employeeId: 'EMP-101',
      role: UserRole.storeManager,
      email: 'raj.kumar@ofsc.example',
      phone: '+91 98111 22001',
      accountStatus: 'Active',
      store: AssignedStore(
        id: 5,
        name: 'Noida Store',
        location: 'Sector 63, Noida',
      ),
    );

    siteUser = const UserProfile(
      userId: 205,
      name: 'Amit Sharma',
      employeeId: 'EMP-205',
      role: UserRole.siteSupervisor,
      email: 'amit.sharma@ofsc.example',
      phone: '+91 98222 44005',
      accountStatus: 'Active',
      projects: [
        AssignedProject(
          id: 10,
          name: 'ABC Residential Tower',
          location: 'Noida Extension',
        ),
        AssignedProject(
          id: 12,
          name: 'XYZ Business Park',
          location: 'Greater Noida',
        ),
      ],
    );

    storeInventory = [
      _storeItem(1, 500, 100, 600),
      _storeItem(2, 820, 300, 1120),
      _storeItem(3, 410, 90, 500),
      _storeItem(4, 8500, 1000, 9500),
      _storeItem(5, 180, 40, 220),
      _storeItem(6, 260, 20, 280),
      _storeItem(7, 140, 10, 150),
      _storeItem(8, 36, 4, 40),
    ];

    siteInventory = [
      _siteItem(1, 42, 0, 42),
      _siteItem(2, 280, 0, 280),
      _siteItem(3, 120, 0, 120),
      _siteItem(4, 650, 0, 650),
      _siteItem(5, 90, 0, 90),
      _siteItem(6, 45, 0, 45),
      _siteItem(7, 60, 0, 60),
      _siteItem(8, 18, 0, 18),
    ];

    final now = _now();
    dispatches = [
      DispatchRequest(
        id: 'REQ-1025',
        requestCode: 'REQ-1025',
        projectId: 10,
        projectName: 'ABC Residential Tower',
        storeId: 5,
        storeName: 'Noida Store',
        requestedBy: 'Admin User',
        requestedAt: DateTime(now.year, now.month, now.day),
        status: DispatchStatus.pendingDispatch,
        lines: [
          DispatchLine(material: materials[0], requestedQty: 50, availableQty: 500),
          DispatchLine(material: materials[1], requestedQty: 300, availableQty: 820),
          DispatchLine(material: materials[3], requestedQty: 1000, availableQty: 8500),
        ],
      ),
      DispatchRequest(
        id: 'REQ-1021',
        requestCode: 'REQ-1021',
        projectId: 12,
        projectName: 'XYZ Business Park',
        storeId: 5,
        storeName: 'Noida Store',
        requestedBy: 'Admin User',
        requestedAt: now.subtract(const Duration(days: 1)),
        status: DispatchStatus.pendingDispatch,
        lines: [
          DispatchLine(material: materials[4], requestedQty: 80, availableQty: 180),
          DispatchLine(material: materials[7], requestedQty: 12, availableQty: 36),
        ],
      ),
      DispatchRequest(
        id: 'DSP-1045',
        requestCode: 'REQ-1018',
        dispatchCode: 'DSP-1045',
        projectId: 10,
        projectName: 'ABC Residential Tower',
        storeId: 5,
        storeName: 'Noida Store',
        requestedBy: 'Admin User',
        requestedAt: now.subtract(const Duration(hours: 8)),
        status: DispatchStatus.inTransit,
        remarks: 'Loaded on vehicle DL-01-AB-4421',
        lines: [
          DispatchLine(
            material: materials[0],
            requestedQty: 50,
            availableQty: 500,
            confirmedQty: 50,
          ),
          DispatchLine(
            material: materials[1],
            requestedQty: 300,
            availableQty: 820,
            confirmedQty: 300,
          ),
          DispatchLine(
            material: materials[3],
            requestedQty: 1000,
            availableQty: 8500,
            confirmedQty: 1000,
          ),
        ],
      ),
      DispatchRequest(
        id: 'DSP-1038',
        requestCode: 'REQ-1012',
        dispatchCode: 'DSP-1038',
        projectId: 10,
        projectName: 'ABC Residential Tower',
        storeId: 5,
        storeName: 'Noida Store',
        requestedBy: 'Admin User',
        requestedAt: now.subtract(const Duration(days: 2)),
        status: DispatchStatus.received,
        lines: [
          DispatchLine(
            material: materials[2],
            requestedQty: 80,
            availableQty: 410,
            confirmedQty: 80,
          ),
        ],
      ),
    ];

    movements = [
      StockMovement(
        id: 'MOV-1',
        materialId: 1,
        quantity: 500,
        unit: 'Bags',
        title: 'Stock Received',
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      StockMovement(
        id: 'MOV-2',
        materialId: 1,
        quantity: -50,
        unit: 'Bags',
        title: 'Dispatched to ABC Project',
        createdAt: now.subtract(const Duration(hours: 8)),
        reference: 'DSP-1045',
      ),
      StockMovement(
        id: 'MOV-3',
        materialId: 2,
        quantity: -20,
        unit: 'KG',
        title: 'Dispatched to XYZ Project',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    activities = [
      ActivityEvent(
        id: 'ACT-1',
        title: '50 Cement Bags dispatched',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      ActivityEvent(
        id: 'ACT-2',
        title: '100 KG Steel received into store',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    consumptions = [
      ConsumptionEntry(
        id: 'CON-1001',
        material: materials[0],
        quantity: 8,
        projectId: 10,
        projectName: 'ABC Residential Tower',
        workTask: 'Foundation Work',
        recordedBy: 'Amit Sharma',
        createdAt: DateTime(now.year, now.month, now.day, 9, 15),
        syncStatus: SyncStatus.synced,
        remarks: 'Concrete work completed',
        clientTransactionId: 'SS-20260926-000010',
      ),
    ];

    requirements = [];

    storeNotifications = [
      AppNotification(
        id: 'N-SM-1',
        title: 'New dispatch request',
        description: 'REQ-1025 for ABC Residential Tower is waiting.',
        createdAt: now.subtract(const Duration(minutes: 40)),
        isRead: false,
        entityType: 'dispatch',
        entityId: 'REQ-1025',
        route: '/dispatches/REQ-1025',
      ),
      AppNotification(
        id: 'N-SM-2',
        title: 'Low stock',
        description: 'Paint is below the minimum stock level.',
        createdAt: now.subtract(const Duration(hours: 5)),
        isRead: false,
        entityType: 'inventory',
        entityId: '8',
        route: '/inventory/8',
      ),
    ];

    siteNotifications = [
      AppNotification(
        id: 'N-SS-1',
        title: 'Material arriving',
        description: 'DSP-1045 is in transit to ABC Residential Tower.',
        createdAt: now.subtract(const Duration(hours: 3)),
        isRead: false,
        entityType: 'dispatch',
        entityId: 'DSP-1045',
        route: '/incoming/DSP-1045',
      ),
      AppNotification(
        id: 'N-SS-2',
        title: 'Low site stock',
        description: 'Cement is below the site minimum.',
        createdAt: now.subtract(const Duration(hours: 6)),
        isRead: false,
        entityType: 'site_stock',
        entityId: '1',
        route: '/site-stock',
      ),
    ];
  }

  AuthSession login(String username, String password) {
    final normalized = username.trim().toLowerCase();
    UserProfile? user;
    if ((normalized == AppConstants.demoStoreUsername ||
            normalized == 'emp-101') &&
        password == AppConstants.demoStorePassword) {
      user = storeUser;
    } else if ((normalized == AppConstants.demoSiteUsername ||
            normalized == 'emp-205') &&
        password == AppConstants.demoSitePassword) {
      user = siteUser;
    }
    if (user == null) {
      throw const ApiException(
        'Employee ID or password is incorrect.',
        statusCode: 401,
        code: 'invalid_credentials',
      );
    }
    final tokens = AuthTokens(
      accessToken: 'demo-access-${user.userId}-${_now().millisecondsSinceEpoch}',
      refreshToken: 'demo-refresh-${user.userId}',
      expiresAt: _now().add(const Duration(hours: 12)),
    );
    _tokens[tokens.accessToken] = tokens;
    return AuthSession(user: user, tokens: tokens);
  }

  UserProfile me(String token) => _userForToken(token);

  Map<String, dynamic> bootstrap(String token) {
    final user = _userForToken(token);
    return {
      'user': user,
      'materials': materials,
      'inventory': user.isStoreManager ? storeInventory : siteInventory,
      'dispatches': user.isStoreManager
          ? dispatches.where((d) => d.storeId == user.store!.id).toList()
          : dispatches
                .where((d) => user.canAccessProject(d.projectId))
                .toList(),
      'movements': movements,
      'activities': activities,
      'consumptions': user.isSiteSupervisor ? consumptions : <ConsumptionEntry>[],
      'requirements': user.isSiteSupervisor
          ? requirements
          : <MaterialRequirement>[],
      'notifications': user.isStoreManager
          ? storeNotifications
          : siteNotifications,
    };
  }

  Map<String, dynamic> confirmDispatch(Map<String, dynamic> payload) {
    final key = payload['client_transaction_id'] as String;
    if (_processedKeys.contains(key)) {
      return {'duplicate': false, 'replayed': true, 'id': payload['request_id']};
    }

    final request = dispatches.firstWhere((d) => d.id == payload['request_id']);
    final lines = (payload['lines'] as List).cast<Map<String, dynamic>>();
    for (final line in lines) {
      final materialId = line['material_id'] as int;
      final qty = (line['confirmed_qty'] as num).toDouble();
      final stock = storeInventory.firstWhere(
        (item) => item.material.id == materialId,
      );
      if (qty > stock.available) {
        throw SyncConflictException(
          message:
              'Current server stock: ${stock.available}. Requested dispatch: $qty. Please review this transaction.',
          serverQuantity: stock.available,
          requestedQuantity: qty,
          entityId: request.id,
        );
      }
    }

    for (final line in lines) {
      final materialId = line['material_id'] as int;
      final qty = (line['confirmed_qty'] as num).toDouble();
      _adjustStore(materialId, -qty);
    }

    final updatedLines = request.lines.map((line) {
      final match = lines.firstWhere(
        (item) => item['material_id'] == line.material.id,
      );
      return line.copyWith(
        confirmedQty: (match['confirmed_qty'] as num).toDouble(),
        reason: match['reason'] as String?,
      );
    }).toList();

    final updated = request.copyWith(
      status: DispatchStatus.inTransit,
      remarks: payload['remarks'] as String?,
      dispatchCode: 'DSP-${request.requestCode.split('-').last}',
      lines: updatedLines,
      syncStatus: SyncStatus.synced,
    );
    _replaceDispatch(updated);
    activities.insert(
      0,
      ActivityEvent(
        id: 'ACT-${_now().millisecondsSinceEpoch}',
        title: '${updated.lines.first.material.name} dispatched',
        createdAt: _now(),
      ),
    );
    _processedKeys.add(key);
    return {'duplicate': false, 'replayed': false, 'id': updated.id};
  }

  Map<String, dynamic> confirmReceiving(Map<String, dynamic> payload) {
    final key = payload['client_transaction_id'] as String;
    if (_processedKeys.contains(key)) {
      return {'duplicate': false, 'replayed': true, 'id': payload['request_id']};
    }
    final request = dispatches.firstWhere((d) => d.id == payload['request_id']);
    final lines = (payload['lines'] as List).cast<Map<String, dynamic>>();
    var hasPartial = false;
    var hasMissing = false;
    for (final line in lines) {
      final materialId = line['material_id'] as int;
      final received = (line['received_qty'] as num).toDouble();
      final status = ReceivingStatus.values.byName(line['status'] as String);
      if (status == ReceivingStatus.partiallyReceived) hasPartial = true;
      if (status == ReceivingStatus.notReceived) hasMissing = true;
      _adjustSite(materialId, received);
    }
    final status = hasMissing || hasPartial
        ? (hasMissing ? DispatchStatus.discrepancy : DispatchStatus.partiallyReceived)
        : DispatchStatus.received;
    _replaceDispatch(request.copyWith(status: status, syncStatus: SyncStatus.synced));
    _processedKeys.add(key);
    return {'duplicate': false, 'replayed': false, 'id': request.id};
  }

  Map<String, dynamic> recordConsumption(Map<String, dynamic> payload) {
    final key = payload['client_transaction_id'] as String;
    if (_processedKeys.contains(key)) {
      return {'duplicate': false, 'replayed': true, 'id': key};
    }
    final materialId = payload['material_id'] as int;
    final qty = (payload['quantity'] as num).toDouble();
    final stock = siteInventory.firstWhere((item) => item.material.id == materialId);
    if (qty > stock.available) {
      throw SyncConflictException(
        message:
            'Current server stock: ${stock.available}. Requested consumption: $qty. Please review this transaction.',
        serverQuantity: stock.available,
        requestedQuantity: qty,
        entityId: key,
      );
    }
    _adjustSite(materialId, -qty);
    _processedKeys.add(key);
    return {'duplicate': false, 'replayed': false, 'id': key};
  }

  Map<String, dynamic> createRequirement(Map<String, dynamic> payload) {
    final key = payload['client_transaction_id'] as String;
    if (_processedKeys.contains(key)) {
      return {'duplicate': false, 'replayed': true, 'id': key};
    }
    _processedKeys.add(key);
    return {'duplicate': false, 'replayed': false, 'id': key};
  }

  Map<String, dynamic> uploadPhoto(Map<String, dynamic> payload) {
    final key = payload['client_transaction_id'] as String? ?? payload['photo_id'];
    if (_processedKeys.contains(key)) {
      return {'duplicate': false, 'replayed': true, 'url': 'demo://$key'};
    }
    _processedKeys.add(key as String);
    return {'duplicate': false, 'replayed': false, 'url': 'demo://$key'};
  }

  void reduceStoreStock(int materialId, double qty) {
    _adjustStore(materialId, -qty);
  }

  bool wasProcessed(String key) => _processedKeys.contains(key);

  UserProfile _userForToken(String token) {
    if (token.contains('101')) return storeUser;
    if (token.contains('205')) return siteUser;
    throw const ApiException(
      'Your session is no longer valid. Please sign in again.',
      statusCode: 401,
    );
  }

  InventoryItem _storeItem(int id, double available, double reserved, double total) {
    return InventoryItem(
      material: materials[id - 1],
      available: available,
      reserved: reserved,
      total: total,
      scopeId: 5,
      scopeType: 'store',
    );
  }

  InventoryItem _siteItem(int id, double available, double reserved, double total) {
    return InventoryItem(
      material: materials[id - 1],
      available: available,
      reserved: reserved,
      total: total,
      scopeId: 10,
      scopeType: 'site',
    );
  }

  void _adjustStore(int materialId, double delta) {
    storeInventory = storeInventory.map((item) {
      if (item.material.id != materialId) return item;
      final available = item.available + delta;
      return item.copyWith(available: available, total: available + item.reserved);
    }).toList();
  }

  void _adjustSite(int materialId, double delta) {
    siteInventory = siteInventory.map((item) {
      if (item.material.id != materialId) return item;
      final available = item.available + delta;
      return item.copyWith(available: available, total: available + item.reserved);
    }).toList();
  }

  void _replaceDispatch(DispatchRequest updated) {
    dispatches = [
      for (final item in dispatches)
        if (item.id == updated.id) updated else item,
    ];
  }
}
