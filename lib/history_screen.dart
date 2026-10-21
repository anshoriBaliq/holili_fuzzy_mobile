import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'domain/fuzzy_sensor_status.dart';
import 'models/sensor_reading.dart';
import 'services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();

  late Future<DailySensorData> _futureData;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  int _jumlahData = 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _isLoading = true;
    _futureData = _apiService.getTodayData();
    _updateCountFromFuture();
  }

  Future<void> _loadTodayData() async {
    final today = DateTime.now();

    setState(() {
      _selectedDate = today;
      _isLoading = true;
      _futureData = _apiService.getTodayData();
    });

    await _updateCountFromFuture();
  }

  Future<void> _loadDataByDate(DateTime date) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

    setState(() {
      _selectedDate = date;
      _isLoading = true;
      _futureData = _apiService.getDataByDate(formattedDate);
    });

    await _updateCountFromFuture();
  }

  Future<void> _updateCountFromFuture() async {
    try {
      final result = await _futureData;

      if (!mounted) {
        return;
      }

      setState(() {
        _jumlahData = result.data.length;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      await _loadDataByDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History Sensor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
            tooltip: 'Pilih Tanggal',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateHeader(),
          if (_isLoading)
            const LinearProgressIndicator()
          else
            const SizedBox(height: 2),
          Expanded(child: _buildDataContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadTodayData,
        tooltip: 'Refresh Data Hari Ini',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Data Sensor:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            '$_jumlahData',
            style: TextStyle(
              fontSize: 19,
              color: Colors.blue[900],
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: () => _selectDate(context),
            child: Text(
              DateFormat('dd MMMM yyyy').format(_selectedDate),
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataContent() {
    return FutureBuilder<DailySensorData>(
      future: _futureData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
          return _buildEmptyWidget();
        }

        return _buildDataList(snapshot.data!);
      },
    );
  }

  Widget _buildDataList(DailySensorData data) {
    return RefreshIndicator(
      onRefresh: () => _loadDataByDate(_selectedDate),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: data.data.length,
        itemBuilder: (context, index) {
          return _buildReadingCard(data.data[index]);
        },
      ),
    );
  }

  Widget _buildReadingCard(SensorReading reading) {
    final temperatureStatus = SensorFuzzyLogic.evaluateTemperature(
      reading.temperatur,
    );
    final tdsStatus = SensorFuzzyLogic.evaluateTds(reading.tds);
    final phStatus = SensorFuzzyLogic.evaluatePh(reading.ph);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Waktu: ${_formatTime(reading.createdAt)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                Text(
                  'ID: ${reading.id ?? '-'}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDataRow(
              Icons.thermostat,
              'Suhu',
              '${reading.temperatur.toStringAsFixed(1)}°C',
              temperatureStatus,
            ),
            _buildDataRow(
              Icons.eco,
              'TDS',
              '${reading.tds.toStringAsFixed(0)} PPM',
              tdsStatus,
            ),
            _buildDataRow(
              Icons.water_drop,
              'pH Air',
              reading.ph.toStringAsFixed(1),
              phStatus,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(
    IconData icon,
    String label,
    String value,
    FuzzySensorResult result,
  ) {
    final color = _statusColor(result.condition);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 58,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '${result.condition.label} ${result.score.toStringAsFixed(0)}',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Gagal memuat data',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadDataByDate(_selectedDate),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada data untuk tanggal ini',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _loadDataByDate(_selectedDate),
            child: const Text('Refresh Data'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm:ss').format(time);
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
