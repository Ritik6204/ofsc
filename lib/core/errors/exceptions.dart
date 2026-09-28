class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code, this.details});

  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic>? details;

  @override
  String toString() => message;
}

class CacheException implements Exception {
  const CacheException([this.message = 'Local storage error']);

  final String message;

  @override
  String toString() => message;
}

class SyncConflictException implements Exception {
  const SyncConflictException({
    required this.message,
    this.serverQuantity,
    this.requestedQuantity,
    this.entityId,
  });

  final String message;
  final double? serverQuantity;
  final double? requestedQuantity;
  final String? entityId;

  @override
  String toString() => message;
}

class ValidationException implements Exception {
  const ValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
