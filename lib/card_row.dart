import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'domain/fuzzy_sensor_status.dart';
import 'domain/sensor_type.dart';
import 'models/sensor_reading.dart';
import 'sensor_quality_page.dart';
import 'services/api_service.dart';

class CardRow extends StatefulWidget {
  const CardRow({super.key});

  @override
  State<CardRow> createState() => _CardRowState();
}

class _CardRowState extends State<CardRow> {
  final ApiService apiService = ApiService();

  List<SensorReading> _readings = [];
  Timer? _timer;
  bool _isFetching = false;

  List<double> suhuHistory = [];
  List<double> ppmHistory = [];
  List<double> phHistory = [];

  @override
  void initState() {
    super.initState();
    fetchData();
    _startPolling();
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => fetchData(),
    );
  }

  Future<void> fetchData() async {
    if (_isFetching) {
      return;
    }

    _isFetching = true;

    try {
      final newReadings = await apiService.getSensorReadings();

      if (!mounted || newReadings.isEmpty) {
        return;
      }

      final recentReadings = newReadings.length > 15
          ? newReadings.sublist(newReadings.length - 15)
          : newReadings;

      setState(() {
        _readings = recentReadings;

        // History dibentuk ulang dari data API agar titik yang sama tidak
        // ditambahkan berulang kali oleh polling setiap tiga detik.
        suhuHistory = recentReadings
            .map((reading) => reading.temperatur)
            .toList();
        ppmHistory = recentReadings.map((reading) => reading.tds).toList();
        phHistory = recentReadings.map((reading) => reading.ph).toList();
      });
    } catch (error) {
      debugPrint('Gagal mengambil data sensor: $error');
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _openQualityPage(SensorType sensor) async {
    // Polling halaman utama dihentikan sementara agar tidak terjadi dua
    // request realtime bersamaan ketika halaman indeks sedang terbuka.
    _timer?.cancel();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SensorQualityPage(
          initialSensor: sensor,
          initialReadings: List<SensorReading>.unmodifiable(_readings),
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await fetchData();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasReading = _readings.isNotEmpty;
    final latestReading = hasReading
        ? _readings.last
        : SensorReading(
            id: null,
            temperatur: 0,
            tds: 0,
            ph: 0,
            createdAt: DateTime.now(),
          );

    final temperatureStatus = SensorFuzzyLogic.evaluateTemperature(
      latestReading.temperatur,
    );
    final tdsStatus = SensorFuzzyLogic.evaluateTds(latestReading.tds);
    final phStatus = SensorFuzzyLogic.evaluatePh(latestReading.ph);

    return Row(
      children: [
        Expanded(
          child: buildCard(
            'assets/suhu.json',
            '${latestReading.temperatur.toStringAsFixed(1)}°C',
            title: 'Suhu',
            data: suhuHistory,
            color: Colors.red,
            status: temperatureStatus,
            sensor: SensorType.temperature,
          ),
        ),
        Expanded(
          child: buildCard(
            'assets/daun.json',
            '${latestReading.tds.toStringAsFixed(0)} PPM',
            title: 'TDS',
            data: ppmHistory,
            color: Colors.green,
            status: tdsStatus,
            sensor: SensorType.tds,
          ),
        ),
        Expanded(
          child: buildCard(
            'assets/air.json',
            latestReading.ph.toStringAsFixed(1),
            title: 'pH Air',
            data: phHistory,
            color: Colors.blue,
            status: phStatus,
            sensor: SensorType.ph,
          ),
        ),
      ],
    );
  }

  Widget buildCard(
    String assetPath,
    String valueText, {
    required String title,
    required List<double> data,
    required Color color,
    required FuzzySensorResult status,
    required SensorType sensor,
  }) {
    final statusColor = _statusColor(status.condition);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.white,
        elevation: 5,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _openQualityPage(sensor),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 13,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Lottie.asset(
                  assetPath,
                  height: 60,
                  width: 60,
                ),
                const SizedBox(height: 6),
                Text(
                  valueText,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    '${status.condition.label} • '
                    '${status.score.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 90,
                  child: LineChart(
                    LineChartData(
                      clipData: FlClipData.all(),
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            data.length,
                            (index) => FlSpot(
                              index.toDouble(),
                              data[index],
                            ),
                          ),
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: color,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            checkToShowDot: (spot, barData) {
                              return barData.spots.isNotEmpty &&
                                  spot == barData.spots.last;
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                color.withValues(alpha: 0.45),
                                color.withValues(alpha: 0.05),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ketuk untuk melihat indeks',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(SensorCondition condition) {
    switch (condition) {
      case SensorCondition.baik:
        return Colors.green.shade700;
      case SensorCondition.cukup:
        return Colors.orange.shade800;
      case SensorCondition.kurang:
        return Colors.red.shade700;
    }
  }
}
