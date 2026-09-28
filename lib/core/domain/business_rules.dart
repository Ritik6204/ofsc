class QuantityCheck {
  const QuantityCheck({
    required this.isValid,
    required this.message,
    this.difference = 0,
  });

  final bool isValid;
  final String message;
  final double difference;
}

class BusinessRules {
  static QuantityCheck canDispatch({
    required double requested,
    required double available,
    required double actual,
  }) {
    if (actual <= 0) {
      return const QuantityCheck(
        isValid: false,
        message: 'Dispatch quantity must be greater than 0.',
      );
    }
    if (actual > requested) {
      return QuantityCheck(
        isValid: false,
        message:
            'You cannot dispatch more than the authorized quantity of $requested.',
        difference: actual - requested,
      );
    }
    if (actual > available) {
      return QuantityCheck(
        isValid: false,
        message: 'Available stock is $available. Reduce the dispatch quantity.',
        difference: actual - available,
      );
    }
    return QuantityCheck(
      isValid: true,
      message: actual < requested
          ? 'Shortage of ${requested - actual}. A reason is required.'
          : 'Quantity is within the authorized limit.',
      difference: requested - actual,
    );
  }

  static QuantityCheck canReceive({
    required double dispatched,
    required double received,
  }) {
    if (received < 0) {
      return const QuantityCheck(
        isValid: false,
        message: 'Received quantity cannot be negative.',
      );
    }
    if (received > dispatched) {
      return QuantityCheck(
        isValid: false,
        message:
            'Received quantity cannot exceed the dispatched quantity of $dispatched.',
        difference: received - dispatched,
      );
    }
    return QuantityCheck(
      isValid: true,
      message: received < dispatched
          ? 'Discrepancy of ${dispatched - received}. A reason is required.'
          : 'Received quantity matches the dispatch.',
      difference: dispatched - received,
    );
  }

  static QuantityCheck canConsume({
    required double available,
    required double used,
  }) {
    if (used <= 0) {
      return const QuantityCheck(
        isValid: false,
        message: 'Used quantity must be greater than 0.',
      );
    }
    if (used > available) {
      return const QuantityCheck(
        isValid: false,
        message: 'You cannot consume more than the available site quantity.',
      );
    }
    return QuantityCheck(
      isValid: true,
      message: 'Remaining quantity will be ${available - used}.',
      difference: available - used,
    );
  }

  static double suggestedRequirement({
    required double currentStock,
    required double requiredQty,
  }) {
    final gap = requiredQty - currentStock;
    return gap < 0 ? 0 : gap;
  }

  static bool requiresShortageReason({
    required double requested,
    required double actual,
  }) {
    return actual < requested;
  }
}
