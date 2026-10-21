import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import 'curve_card.dart';
import 'domain/fuzzy_sensor_status.dart';
import 'domain/sensor_type.dart';
import 'models/sensor_reading.dart';
import 'services/api_service.dart';

class SensorQualityPage extends StatefulWidget {
  final SensorType initialSensor;
  final List<SensorReading> initialReadings;

  const SensorQualityPage({
    super.key,
    required this.initialSensor,
    this.initialReadings = const [],
  });

  @override
  State<SensorQualityPage> createState() => _SensorQualityPageState();
}

class _SensorQualityPageState extends State<SensorQualityPage> {
  final ApiService _apiService = ApiService();

  late SensorType _selectedSensor;
  late List<SensorReading> _readings;
  Timer? _timer;
  bool _isFetching = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedSensor = widget.initialSensor;
    _readings = List<SensorReading>.of(widget.initialReadings);
    _fetchData();
    _startPolling();
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _fetchData(),
    );
  }

  Future<void> _fetchData() async {
    if (_isFetching) {
      return;
    }

    _isFetching = true;

    try {
      final data = await _apiService.getSensorReadings();
      if (!mounted || data.isEmpty) {
        return;
      }

      final recentReadings = data.length > 15
          ? data.sublist(data.length - 15)
          : data;

      setState(() {
        _readings = recentReadings;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      _isFetching = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text('Indeks Kualitas Sensor Realtime'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          child: _readings.isEmpty
              ? _buildEmptyState()
              : _buildContent(_readings.last),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.72,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMessage == null)
                const CircularProgressIndicator()
              else
                Icon(
                  Icons.cloud_off_rounded,
                  size: 58,
                  color: Colors.grey.shade500,
                ),
              const SizedBox(height: 16),
              Text(
                _errorMessage == null
                    ? 'Mengambil data sensor realtime...'
                    : 'Data sensor belum dapat dimuat.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _fetchData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(SensorReading latestReading) {
    final selectedResult = _evaluate(latestReading, _selectedSensor);
    final selectedValue = _valueText(latestReading, _selectedSensor);

    final temperatureScores = _readings
        .map(
          (reading) => SensorFuzzyLogic.evaluateTemperature(
            reading.temperatur,
          ).score,
        )
        .toList();

    final tdsScores = _readings
        .map((reading) => SensorFuzzyLogic.evaluateTds(reading.tds).score)
        .toList();

    final phScores = _readings
        .map((reading) => SensorFuzzyLogic.evaluatePh(reading.ph).score)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: _buildSensorSelector(),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: _buildSelectedSensorCard(
            latestReading: latestReading,
            result: selectedResult,
            valueText: selectedValue,
          ),
        ),
        CurveCard(
          temperatureScores: temperatureScores,
          tdsScores: tdsScores,
          phScores: phScores,
          highlightedSensor: _selectedSensor,
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
            child: Text(
              'Pembaruan terakhir gagal. Data terakhir yang berhasil diterima '
              'tetap ditampilkan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSensorSelector() {
    return Row(
      children: SensorType.values.map((sensor) {
        final selected = sensor == _selectedSensor;
        final color = _sensorColor(sensor);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: sensor == SensorType.ph ? 0 : 8,
            ),
            child: Material(
              color: selected ? color.withValues(alpha: 0.12) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  setState(() {
                    _selectedSensor = sensor;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? color : Colors.grey.shade300,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _sensorIcon(sensor),
                        color: selected ? color : Colors.grey.shade600,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        sensor.shortLabel,
                        style: TextStyle(
                          color: selected ? color : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectedSensorCard({
    required SensorReading latestReading,
    required FuzzySensorResult result,
    required String valueText,
  }) {
    final sensorColor = _sensorColor(_selectedSensor);
    final statusColor = _statusColor(result.condition);
    final timestamp = DateFormat(
      'dd MMM yyyy, HH:mm:ss',
    ).format(latestReading.createdAt.toLocal());

    return Card(
      elevation: 5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: sensorColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Lottie.asset(_sensorAsset(_selectedSensor)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedSensor.label,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        valueText,
                        style: TextStyle(
                          color: sensorColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${result.condition.label} • '
                          '${result.score.toStringAsFixed(1)} / 100',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                result.description,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildMembershipBar(
              label: 'Baik',
              value: result.baikMembership,
              color: Colors.green.shade700,
            ),
            const SizedBox(height: 10),
            _buildMembershipBar(
              label: 'Cukup',
              value: result.cukupMembership,
              color: Colors.orange.shade800,
            ),
            const SizedBox(height: 10),
            _buildMembershipBar(
              label: 'Kurang',
              value: result.kurangMembership,
              color: Colors.red.shade700,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 15,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Pembaruan data: $timestamp',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipBar({
    required String label,
    required double value,
    required Color color,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 55,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: value.clamp(0, 1).toDouble(),
              minHeight: 9,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            value.toStringAsFixed(2),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  FuzzySensorResult _evaluate(
    SensorReading reading,
    SensorType sensor,
  ) {
    switch (sensor) {
      case SensorType.temperature:
        return SensorFuzzyLogic.evaluateTemperature(reading.temperatur);
      case SensorType.tds:
        return SensorFuzzyLogic.evaluateTds(reading.tds);
      case SensorType.ph:
        return SensorFuzzyLogic.evaluatePh(reading.ph);
    }
  }

  String _valueText(SensorReading reading, SensorType sensor) {
    switch (sensor) {
      case SensorType.temperature:
        return '${reading.temperatur.toStringAsFixed(1)} °C';
      case SensorType.tds:
        return '${reading.tds.toStringAsFixed(0)} PPM';
      case SensorType.ph:
        return reading.ph.toStringAsFixed(1);
    }
  }

  String _sensorAsset(SensorType sensor) {
    switch (sensor) {
      case SensorType.temperature:
        return 'assets/suhu.json';
      case SensorType.tds:
        return 'assets/daun.json';
      case SensorType.ph:
        return 'assets/air.json';
    }
  }

  IconData _sensorIcon(SensorType sensor) {
    switch (sensor) {
      case SensorType.temperature:
        return Icons.thermostat_rounded;
      case SensorType.tds:
        return Icons.eco_rounded;
      case SensorType.ph:
        return Icons.water_drop_rounded;
    }
  }

  Color _sensorColor(SensorType sensor) {
    switch (sensor) {
      case SensorType.temperature:
        return Colors.red.shade600;
      case SensorType.tds:
        return Colors.green.shade700;
      case SensorType.ph:
        return Colors.blue.shade700;
    }
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
