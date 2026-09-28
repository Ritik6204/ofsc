import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ofsc/core/constants/app_constants.dart';
import 'package:ofsc/core/domain/enums.dart';
import 'package:ofsc/features/inventory/presentation/bloc/inventory_bloc.dart';

import '../../helpers/test_harness.dart';

void main() {
  late TestHarness harness;

  setUp(() async {
    harness = TestHarness();
    await harness.setUp();
    await harness.auth.login(
      username: AppConstants.demoStoreUsername,
      password: AppConstants.demoStorePassword,
    );
  });

  tearDown(() async {
    await harness.tearDown();
  });

  blocTest<InventoryBloc, InventoryState>(
    'loads store inventory and supports search/filter',
    build: () {
      return InventoryBloc(
        user: harness.backend.storeUser,
        repository: harness.inventory,
      );
    },
    act: (bloc) async {
      await bloc.load();
      bloc.search('CEM-001');
      bloc.filter(InventoryFilter.lowStock);
    },
    expect: () => [
      isA<InventoryState>().having(
        (s) => s.status,
        'status',
        InventoryStatus.loading,
      ),
      isA<InventoryState>().having(
        (s) => s.status,
        'status',
        InventoryStatus.loaded,
      ),
      isA<InventoryState>().having((s) => s.query, 'query', 'CEM-001'),
      isA<InventoryState>().having(
        (s) => s.filter,
        'filter',
        InventoryFilter.lowStock,
      ),
    ],
  );
}
