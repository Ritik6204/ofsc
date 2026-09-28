import 'package:flutter_test/flutter_test.dart';
import 'package:ofsc/core/domain/business_rules.dart';

void main() {
  group('BusinessRules.canDispatch', () {
    test('rejects more than requested', () {
      final result = BusinessRules.canDispatch(
        requested: 50,
        available: 75,
        actual: 60,
      );
      expect(result.isValid, isFalse);
    });

    test('rejects more than available', () {
      final result = BusinessRules.canDispatch(
        requested: 50,
        available: 40,
        actual: 50,
      );
      expect(result.isValid, isFalse);
    });

    test('allows authorized quantity and calculates shortage', () {
      final result = BusinessRules.canDispatch(
        requested: 50,
        available: 75,
        actual: 45,
      );
      expect(result.isValid, isTrue);
      expect(result.difference, 5);
      expect(BusinessRules.requiresShortageReason(requested: 50, actual: 45), isTrue);
    });
  });

  group('BusinessRules.canReceive', () {
    test('rejects received greater than dispatched', () {
      final result = BusinessRules.canReceive(dispatched: 50, received: 55);
      expect(result.isValid, isFalse);
    });

    test('calculates receiving discrepancy', () {
      final result = BusinessRules.canReceive(dispatched: 50, received: 47);
      expect(result.isValid, isTrue);
      expect(result.difference, 3);
    });
  });

  group('BusinessRules.canConsume', () {
    test('prevents used greater than available', () {
      final result = BusinessRules.canConsume(available: 42, used: 50);
      expect(result.isValid, isFalse);
      expect(
        result.message,
        'You cannot consume more than the available site quantity.',
      );
    });

    test('allows valid consumption', () {
      final result = BusinessRules.canConsume(available: 42, used: 8);
      expect(result.isValid, isTrue);
      expect(result.difference, 34);
    });
  });

  test('suggested requirement is stock gap', () {
    expect(
      BusinessRules.suggestedRequirement(currentStock: 20, requiredQty: 60),
      40,
    );
  });
}
