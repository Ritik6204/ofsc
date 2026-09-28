import 'exceptions.dart';
import 'failures.dart';

Failure mapExceptionToFailure(Object error) {
  if (error is Failure) return error;
  if (error is SyncConflictException) {
    return ConflictFailure(
      error.message,
      serverQuantity: error.serverQuantity,
      requestedQuantity: error.requestedQuantity,
    );
  }
  if (error is ValidationException) {
    return ValidationFailure(error.message);
  }
  if (error is CacheException) {
    return CacheFailure(error.message);
  }
  if (error is ApiException) {
    switch (error.statusCode) {
      case 401:
        return const UnauthorizedFailure();
      case 403:
        return const PermissionFailure();
      case 409:
        return ConflictFailure(
          error.message,
          code: error.code,
          serverQuantity: _asDouble(error.details?['server_quantity']),
          requestedQuantity: _asDouble(error.details?['requested_quantity']),
        );
      case 422:
        return ValidationFailure(error.message, error.code);
      default:
        if (error.code == 'insufficient_stock') {
          return InsufficientStockFailure(error.message);
        }
        if (error.statusCode == null) {
          return NetworkFailure(error.message);
        }
        return ServerFailure(error.message);
    }
  }
  return ServerFailure(error.toString());
}

double? _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return null;
}

String humanizeError(Object error) {
  return mapExceptionToFailure(error).message;
}
