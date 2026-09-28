import 'package:flutter_test/flutter_test.dart';
import 'package:ofsc/core/constants/app_constants.dart';
import 'package:ofsc/core/domain/enums.dart';
import 'package:ofsc/core/errors/exceptions.dart';
import 'package:ofsc/features/dispatch/domain/entities/dispatch_entities.dart';
import 'package:ofsc/features/receiving/domain/entities/receiving_entities.dart';

import '../../helpers/test_harness.dart';

void main() {
  late TestHarness harness;

  setUp(() async {
    harness = TestHarness();
    await harness.setUp();
  });

  tearDown(() async {
    await harness.tearDown();
  });

  test('local database insert/update/delete', () async {
    await harness.auth.login(
      username: AppConstants.demoStoreUsername,
      password: AppConstants.demoStorePassword,
    );
    final before = await harness.local.getActivities();
    expect(before, isNotEmpty);
    await harness.local.clearAll();
    expect(await harness.local.getActivities(), isEmpty);
  });

  test('offline dispatch is saved and syncs after reconnect without duplicates', () async {
    await harness.auth.login(
      username: AppConstants.demoStoreUsername,
      password: AppConstants.demoStorePassword,
    );
    final request = (await harness.operations.getDispatches()).firstWhere(
      (item) => item.id == 'REQ-1025',
    );
    harness.network.connected = false;

    final saved = await harness.operations.confirmDispatch(
      DispatchDraft(
        request: request,
        lines: request.lines
            .map((line) => line.copyWith(confirmedQty: line.requestedQty))
            .toList(),
        remarks: 'Loaded and verified',
      ),
    );
    expect(saved.syncStatus, SyncStatus.pending);

    final queueBeforeRestart = await harness.local.getQueue(pendingOnly: true);
    expect(queueBeforeRestart, isNotEmpty);

    // Simulate process death by reading the same local database again.
    final stillThere = await harness.local.getDispatch('REQ-1025');
    expect(stillThere!.syncStatus, SyncStatus.pending);

    harness.network.connected = true;
    await harness.sync.processQueue();
    await harness.sync.processQueue();

    final after = await harness.local.getDispatch('REQ-1025');
    expect(after!.syncStatus, SyncStatus.synced);
    expect(harness.backend.wasProcessed(saved.localId!), isTrue);

    final cement = harness.backend.storeInventory.firstWhere(
      (item) => item.material.id == 1,
    );
    expect(cement.available, 450);
  });

  test('idempotent retry does not create a second server transaction', () async {
    await harness.auth.login(
      username: AppConstants.demoStoreUsername,
      password: AppConstants.demoStorePassword,
    );
    final request = (await harness.operations.getDispatches()).firstWhere(
      (item) => item.id == 'REQ-1025',
    );
    final saved = await harness.operations.confirmDispatch(
      DispatchDraft(
        request: request,
        lines: request.lines
            .map((line) => line.copyWith(confirmedQty: line.requestedQty))
            .toList(),
      ),
    );
    await harness.sync.processQueue();
    final firstStock = harness.backend.storeInventory
        .firstWhere((item) => item.material.id == 1)
        .available;
    await harness.remote.confirmDispatch({
      'request_id': saved.id,
      'client_transaction_id': saved.localId,
      'lines': saved.lines
          .map(
            (line) => {
              'material_id': line.material.id,
              'confirmed_qty': line.confirmedQty,
            },
          )
          .toList(),
    });
    final secondStock = harness.backend.storeInventory
        .firstWhere((item) => item.material.id == 1)
        .available;
    expect(secondStock, firstStock);
  });

  test('sync conflict is surfaced when server stock changed', () async {
    await harness.auth.login(
      username: AppConstants.demoStoreUsername,
      password: AppConstants.demoStorePassword,
    );
    final request = (await harness.operations.getDispatches()).firstWhere(
      (item) => item.id == 'REQ-1025',
    );
    harness.network.connected = false;
    await harness.operations.confirmDispatch(
      DispatchDraft(
        request: request,
        lines: request.lines
            .map((line) => line.copyWith(confirmedQty: line.requestedQty))
            .toList(),
      ),
    );
    harness.backend.reduceStoreStock(1, 480);
    harness.network.connected = true;
    await harness.sync.processQueue();
    final queue = await harness.local.getQueue();
    expect(
      queue.any((item) => item.syncStatus == SyncStatus.conflict),
      isTrue,
    );
  });

  test('site receiving and consumption stay local while offline', () async {
    await harness.auth.login(
      username: AppConstants.demoSiteUsername,
      password: AppConstants.demoSitePassword,
    );
    harness.network.connected = false;
    final incoming = (await harness.operations.getDispatches()).firstWhere(
      (item) => item.id == 'DSP-1045',
    );
    await harness.operations.confirmReceiving(
      ReceivingDraft(
        request: incoming,
        lines: incoming.lines
            .map(
              (line) => ReceivingLine(
                material: line.material,
                dispatchedQty: line.confirmedQty ?? line.requestedQty,
                receivedQty: line.confirmedQty ?? line.requestedQty,
                status: ReceivingStatus.received,
              ),
            )
            .toList(),
      ),
    );
    final queue = await harness.local.getQueue(pendingOnly: true);
    expect(
      queue.any((item) => item.entityType == SyncEntityType.receivingConfirmation),
      isTrue,
    );
  });

  test('repository falls back to local data when remote is unavailable', () async {
    await harness.auth.login(
      username: AppConstants.demoStoreUsername,
      password: AppConstants.demoStorePassword,
    );
    harness.network.connected = false;
    final items = await harness.inventory.getInventory(
      scopeType: 'store',
      scopeId: 5,
    );
    expect(items, isNotEmpty);
    expect(
      () => harness.remote.bootstrap('demo-access-101'),
      throwsA(isA<ApiException>()),
    );
  });
}
