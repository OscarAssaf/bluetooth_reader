import 'package:flutter_test/flutter_test.dart';
import 'package:bluetooth_reader/rssi_utils.dart';

void main() {
  group('RssiUtils.toBarFraction', () {
    test('minRssi maps to 0.0', () {
      expect(RssiUtils.toBarFraction(-100), 0.0);
    });

    test('maxRssi maps to 1.0', () {
      expect(RssiUtils.toBarFraction(-30), 1.0);
    });

    test('midpoint maps to 0.5', () {
      expect(RssiUtils.toBarFraction(-65), closeTo(0.5, 0.001));
    });

    test('values stronger than maxRssi are clamped to 1.0', () {
      expect(RssiUtils.toBarFraction(-10), 1.0);
    });

    test('values weaker than minRssi are clamped to 0.0', () {
      expect(RssiUtils.toBarFraction(-120), 0.0);
    });

    test('respects custom min/max bounds', () {
      expect(
        RssiUtils.toBarFraction(-50, minRssi: -90, maxRssi: -40),
        closeTo(0.8, 0.001),
      );
    });
  });
}
