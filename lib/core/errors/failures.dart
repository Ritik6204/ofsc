import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    String message =
        'No internet connection. Your work is saved on this device.',
    String? code,
  ]) : super(message, code: code);
}

class ServerFailure extends Failure {
  const ServerFailure([
    String message = 'The server is unavailable. Please try again shortly.',
    String? code,
  ]) : super(message, code: code);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    String message = 'Your session is no longer valid. Please sign in again.',
    String? code,
  ]) : super(message, code: code);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message, [String? code])
    : super(message, code: code);
}

class InsufficientStockFailure extends Failure {
  const InsufficientStockFailure([
    String message = 'There is not enough stock to complete this transaction.',
    String? code,
  ]) : super(message, code: code);
}

class ConflictFailure extends Failure {
  const ConflictFailure(
    super.message, {
    super.code,
    this.serverQuantity,
    this.requestedQuantity,
  });

  final double? serverQuantity;
  final double? requestedQuantity;

  @override
  List<Object?> get props => [...super.props, serverQuantity, requestedQuantity];
}

class CacheFailure extends Failure {
  const CacheFailure([
    String message = 'We could not read local data on this device.',
    String? code,
  ]) : super(message, code: code);
}

class SyncFailure extends Failure {
  const SyncFailure([
    String message =
        'We could not sync this change right now. It is saved on this device and will retry automatically.',
    String? code,
  ]) : super(message, code: code);
}

class UploadFailure extends Failure {
  const UploadFailure([
    String message = 'Photo upload failed. The transaction is still saved.',
    String? code,
  ]) : super(message, code: code);
}

class PermissionFailure extends Failure {
  const PermissionFailure([
    String message = 'You do not have permission to perform this action.',
    String? code,
  ]) : super(message, code: code);
}

class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure([
    String message = 'Your session has expired. Please sign in again.',
    String? code,
  ]) : super(message, code: code);
}
