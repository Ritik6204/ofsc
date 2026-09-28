import 'package:flutter_test/flutter_test.dart';
import 'package:ofsc/core/constants/app_constants.dart';

void main() {
  test('demo credentials are defined for both field roles', () {
    expect(AppConstants.demoStoreUsername, 'raj.kumar');
    expect(AppConstants.demoSiteUsername, 'amit.sharma');
  });
}
