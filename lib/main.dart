import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ble_device.dart';
import 'rssi_utils.dart';
import 'track_device_screen.dart';

void main() {
  runApp(const BleRadarApp());
}

class BleRadarApp extends StatelessWidget {
  const BleRadarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Radar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ScanScreen(),
    );
  }
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final Map<String, BleDevice> _devices = {}; 
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<bool>? _isScanningSub;
  bool _isScanning = false;
  String? _statusMessage;

  @override
  void dispose() {
    _scanSub?.cancel();
    _isScanningSub?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<bool> _ensurePermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }

  Future<void> _startScan() async {
    setState(() => _statusMessage = null);

    final granted = await _ensurePermissions();
    if (!granted) {
      setState(() {
        _statusMessage =
            'Bluetooth/location permission denied. Enable it in system settings to scan.';
      });
      return;
    }

    final supported = await FlutterBluePlus.isSupported;
    if (!supported) {
      setState(() {
        _statusMessage = 'Bluetooth Low Energy is not supported on this device.';
      });
      return;
    }

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen(_onScanResults);

    _isScanningSub?.cancel();
    _isScanningSub = FlutterBluePlus.isScanning.listen((scanning) {
      if (mounted) setState(() => _isScanning = scanning);
    });

   //  Scan window that constantly checks for connection. BLE devices advertise at very different. Scans for 5 minutes.
    await FlutterBluePlus.startScan(
      timeout: const Duration(minutes: 5),
      androidUsesFineLocation: true,
    );
  }

  Future<void> _stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  void _clearDevices() {
    setState(() => _devices.clear());
  }

  void _onScanResults(List<ScanResult> results) {
    for (final result in results) {
      final name = result.advertisementData.advName.isNotEmpty
          ? result.advertisementData.advName
          : result.device.platformName;

      final device = BleDevice(
        id: result.device.remoteId.str,
        name: name.isNotEmpty ? name : 'Unknown device',
        rssi: result.rssi,
        lastSeen: DateTime.now(),
      );

      setState(() {
        _devices[device.id] = device;
      });
    }
  }

  Color _colorFor(SignalStrength s) { // colors based on the signal strength
    switch (s) {
      case SignalStrength.strong:
        return Colors.green;
      case SignalStrength.medium:
        return Colors.orange;
      case SignalStrength.weak:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceList = _devices.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi)); // strongest first  - showcases it first at the top

    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Radar'),
        actions: [
          IconButton(
            onPressed: _devices.isEmpty ? null : _clearDevices,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear list',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_statusMessage != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.all(12),
              child: Text(
                _statusMessage!,
                style: TextStyle(color: Colors.red.shade900),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _isScanning ? _stopScan : _startScan,
              icon: Icon(_isScanning ? Icons.stop : Icons.search),
              label: Text(_isScanning ? 'Stop scanning' : 'Scan for devices'),
            ),
          ),
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${deviceList.length} device${deviceList.length == 1 ? '' : 's'} found',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: deviceList.isEmpty
                ? Center(
                    child: Text(
                      _isScanning
                          ? 'Scanning…'
                          : 'No devices yet. Tap "Scan for devices" to start.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.builder(
                    itemCount: deviceList.length,
                    itemBuilder: (context, index) {
                      final d = deviceList[index];
                      final color = _colorFor(d.strength);
                      final fraction = RssiUtils.toBarFraction(d.rssi);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TrackDeviceScreen(
                                  deviceId: d.id,
                                  deviceName: d.name,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        d.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${d.rssi} dBm',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: fraction,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(color),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}