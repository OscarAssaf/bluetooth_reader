import 'package:flutter_test/flutter_test.dart';
import 'package:bluetooth_reader/ble_device.dart';

void main() {
  group('BleDevice.strength', () {
    test('rssi >= -60 is strong', () {
      final d = BleDevice(id: '1', name: 'x', rssi: -45, lastSeen: DateTime.now());
      expect(d.strength, SignalStrength.strong);
    });

    test('exactly -60 is strong (boundary is inclusive)', () {
      final d = BleDevice(id: '1', name: 'x', rssi: -60, lastSeen: DateTime.now());
      expect(d.strength, SignalStrength.strong);
    });

    test('-61 to -80 is medium', () {
      final d = BleDevice(id: '1', name: 'x', rssi: -70, lastSeen: DateTime.now());
      expect(d.strength, SignalStrength.medium);
    });

    test('exactly -80 is medium (boundary is inclusive)', () {
      final d = BleDevice(id: '1', name: 'x', rssi: -80, lastSeen: DateTime.now());
      expect(d.strength, SignalStrength.medium);
    });

    test('below -80 is weak', () {
      final d = BleDevice(id: '1', name: 'x', rssi: -95, lastSeen: DateTime.now());
      expect(d.strength, SignalStrength.weak);
    });

    test('very weak signal is still classified as weak, not an error', () {
      final d = BleDevice(id: '1', name: 'x', rssi: -110, lastSeen: DateTime.now());
      expect(d.strength, SignalStrength.weak);
    });
  });
}
