import 'package:flutter/material.dart';
import 'package:green/history_screen.dart';
import 'package:intl/intl.dart';
import 'package:green/services/api_service.dart';
import 'models/sensor_reading.dart';

class ListViewContainer extends StatefulWidget {
  const ListViewContainer({super.key});

  @override
  _ListViewContainerState createState() => _ListViewContainerState();
}

class _ListViewContainerState extends State<ListViewContainer> {
  final ApiService _apiService = ApiService();

  late Future<List<HistoryLog>> _futureData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

Future<void> _loadData() async {
  setState(() => _isLoading = true);

  try {
    _futureData = _apiService.getSensorHistory();
    await _futureData;
  } catch (e) {
    print("Error load data: $e");
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: Icon(Icons.calendar_today, size: 16),
            label: Text('Lihat History Lengkap'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoryScreen()),
              );
            },
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child:FutureBuilder<List<HistoryLog>>(
              future: _futureData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildErrorWidget(snapshot.error.toString());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyWidget();
                }

                return _buildList(snapshot.data!);
              },
            ),
          ),
        ),
      ],
    );
  }

  // =========================
  // GROUP BY DATE


Widget _buildList(List<HistoryLog> data) {
  return ListView.builder(
    padding: const EdgeInsets.only(bottom: 10),
    itemCount: data.length,
    itemBuilder: (context, index) {
      final item = data[index];

      return Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // =======================
              // TANGGAL
              // =======================
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(item.date),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // =======================
              // JAM
              // =======================
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 18,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${item.timeStart} - ${item.timeEnd}",
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),

              const Divider(height: 25),

              Row(
                children: [

                  Expanded(
                    child: _buildItem(
                      Icons.thermostat,
                      Colors.red,
                      "${item.avgTemperature}",
                      "°C",
                      "Suhu",
                    ),
                  ),

                  Expanded(
                    child: _buildItem(
                      Icons.science,
                      Colors.orange,
                      "${item.avgPpm.toInt()}",
                      "ppm",
                      "TDS",
                    ),
                  ),

                  Expanded(
                    child: _buildItem(
                      Icons.water_drop,
                      Colors.blue,
                      "${item.avgWaterLevel}",
                      "%",
                      "Water",
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildItem(
  IconData icon,
  Color color,
  String value,
  String unit,
  String title,
) {
  return Column(
    children: [
      Icon(
        icon,
        color: color,
        size: 32,
      ),
      const SizedBox(height: 8),
      Text(
        "$value $unit",
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        title,
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 13,
        ),
      ),
    ],
  );
}

  Widget _info(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text("$label: ",
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  void _showDetail(
    BuildContext context,
    String date,
    List<SensorReading> readings,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Detail ${_formatDate(date)}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Divider(),

            Expanded(
              child: ListView.builder(
                itemCount: readings.length,
                itemBuilder: (_, i) {
                  final r = readings[i];

                  return ListTile(
                    title: Text(
                      DateFormat('HH:mm').format(r.createdAt),
                    ),
                    subtitle: Text(
                      "T: ${r.temperatur}°C | TDS: ${r.tds} | pH: ${r.ph}",
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(child: Text("Error: $error"));
  }

  Widget _buildEmptyWidget() {
    return Center(child: Text("Tidak ada data"));
  }

  String _formatDate(String date) {
    final d = DateTime.parse(date);
    return DateFormat('dd/MM/yyyy').format(d);
  }
}