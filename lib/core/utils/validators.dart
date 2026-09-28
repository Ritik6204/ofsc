class Validators {
  static String? requiredField(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static double? parseQuantity(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value.trim());
  }

  static String? quantity(
    String? value, {
    required double max,
    required String unit,
    bool allowZero = false,
  }) {
    final parsed = parseQuantity(value);
    if (parsed == null) return 'Enter a valid quantity';
    if (!allowZero && parsed <= 0) return 'Quantity must be greater than 0';
    if (parsed > max) {
      return 'You cannot use more than ${max.toStringAsFixed(parsed.truncateToDouble() == parsed ? 0 : 2)} $unit';
    }
    return null;
  }
}
