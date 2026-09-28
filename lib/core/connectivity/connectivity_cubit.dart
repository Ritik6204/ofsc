import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/enums.dart';
import '../network/network_info.dart';
import '../sync/sync_engine.dart';
import '../../features/sync/domain/entities/sync_entities.dart';

class ConnectivityCubit extends Cubit<SyncSnapshot> {
  ConnectivityCubit({
    required NetworkInfo networkInfo,
    required SyncEngine syncEngine,
  }) : _networkInfo = networkInfo,
       _syncEngine = syncEngine,
       super(
         const SyncSnapshot(
           pendingCount: 0,
           failedCount: 0,
           conflictCount: 0,
           status: ConnectivityStatus.online,
         ),
       );

  final NetworkInfo _networkInfo;
  final SyncEngine _syncEngine;
  StreamSubscription<SyncSnapshot>? _sub;

  Future<void> start() async {
    await _syncEngine.start();
    _sub = _syncEngine.snapshots.listen(emit);
    await _syncEngine.publish();
    if (await _networkInfo.isConnected) {
      unawaited(_syncEngine.processQueue());
    }
  }

  Future<void> retryAll() => _syncEngine.processQueue();

  Future<void> retryItem(String localId) => _syncEngine.retry(localId);

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
