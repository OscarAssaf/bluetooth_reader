/// helper functions to make RSSI value better 'readable' in the UI for the user
class RssiUtils {
  static double toBarFraction(
    int rssi, {
    int minRssi = -100,
    int maxRssi = -30,
  }) {
    final clamped = rssi.clamp(minRssi, maxRssi);
    return (clamped - minRssi) / (maxRssi - minRssi);
  }
}
