/// A scanned BLE device and its most recent signal reading.
class BleDevice {
  final String id; 
  final String name;
  final int rssi; // signal strength in measured in dBm
  final DateTime lastSeen;

  BleDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.lastSeen,
  });

  ///  Simple signal quality measurement threshold with only 3 values for now.

  SignalStrength get strength {
    if (rssi >= -60) return SignalStrength.strong;
    if (rssi >= -80) return SignalStrength.medium;
    return SignalStrength.weak;
  }
}

enum SignalStrength { strong, medium, weak }