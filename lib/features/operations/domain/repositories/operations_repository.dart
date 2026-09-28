import '../../../consumption/domain/entities/consumption_entities.dart';
import '../../../dispatch/domain/entities/dispatch_entities.dart';
import '../../../notifications/domain/entities/app_notification.dart';
import '../../../receiving/domain/entities/receiving_entities.dart';
import '../../../sync/domain/entities/sync_entities.dart';

abstract class OperationsRepository {
  Future<List<DispatchRequest>> getDispatches();
  Future<DispatchRequest?> getDispatch(String id);
  Future<DispatchRequest> confirmDispatch(DispatchDraft draft);
  Future<DispatchRequest> confirmReceiving(ReceivingDraft draft);
  Future<List<ConsumptionEntry>> getConsumptions();
  Future<ConsumptionEntry> recordConsumption(ConsumptionEntry entry);
  Future<List<MaterialRequirement>> getRequirements();
  Future<MaterialRequirement> createRequirement(MaterialRequirement requirement);
  Future<List<AppNotification>> getNotifications();
  Future<void> markNotificationRead(String id);
  Future<List<SyncQueueItem>> getQueue();
  Future<DateTime?> lastSyncedAt();
}
