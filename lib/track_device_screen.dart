import 'dart:async';
import 'dart:collection';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_device.dart';

/// How many recent readings to keep on screen. 
const int _maxPoints = 40;

class TrackDeviceScreen extends StatefulWidget {
  final String deviceId;
  final String deviceName;

  const TrackDeviceScreen({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  State<TrackDeviceScreen> createState() => _TrackDeviceScreenState();
}

class _TrackDeviceScreenState extends State<TrackDeviceScreen> {
  final Queue<int> _rssiHistory = Queue<int>();
  StreamSubscription<List<ScanResult>>? _scanSub;
  int? _latestRssi;
  DateTime? _lastUpdate;

  @override
  void initState() {
    super.initState();
    // Assumes a scan is already running (started from the list screen).
    // We just listen for results and filter to our one device of interest.
    _scanSub = FlutterBluePlus.scanResults.listen(_onScanResults);
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  void _onScanResults(List<ScanResult> results) {
    for (final result in results) {
      if (result.device.remoteId.str != widget.deviceId) continue;

      setState(() {
        _latestRssi = result.rssi;
        _lastUpdate = DateTime.now();
        _rssiHistory.addLast(result.rssi);
        while (_rssiHistory.length > _maxPoints) {
          _rssiHistory.removeFirst();
        }
      });
    }
  }

  Color _colorForRssi(int rssi) {
    final bucket = BleDevice(
      id: '',
      name: '',
      rssi: rssi,
      lastSeen: DateTime.now(),
    ).strength;
    switch (bucket) {
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
    final points = _rssiHistory.toList();
    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].toDouble()),
    ];
    final currentColor = _latestRssi != null ? _colorForRssi(_latestRssi!) : Colors.grey;

    return Scaffold(
      appBar: AppBar(title: Text(widget.deviceName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _latestRssi != null ? '$_latestRssi dBm' : 'Waiting for a reading…',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: currentColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (_lastUpdate != null)
              Text(
                'Updated ${DateTime.now().difference(_lastUpdate!).inSeconds}s ago',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 24),
            Expanded(
              child: spots.length < 2
                  ? Center(
                      child: Text(
                        'Collecting readings…\n(this device needs to stay in range and keep advertising)',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        minY: -100,
                        maxY: -30,
                        minX: 0,
                        maxX: (_maxPoints - 1).toDouble(),
                        gridData: const FlGridData(show: true, drawVerticalLine: false),
                        borderData: FlBorderData(show: true),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 44,
                              interval: 20,
                              getTitlesWidget: (value, meta) => Text(
                                '${value.toInt()}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                        ),
                        lineTouchData: const LineTouchData(enabled: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: currentColor,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: currentColor.withValues(alpha: 0.15),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              'Walk around — the line moves toward the top (stronger, less '
              'negative) as you get closer, and toward the bottom as you move away.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}