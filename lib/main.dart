import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'card_view_above.dart';
import 'card_row.dart';
import 'card_with_textfield_and_buttons.dart';
import 'dart:convert';
import 'models/sensor_reading.dart';
import 'domain/fuzzy_sensor_status.dart';

// import 'package:firebase_core/firebase_core.dart';
import 'history_screen.dart'; // Pastikan file history_screen.dart sudah ada

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}
Future<List<HistoryLog>> fetchHistoryLogs() async {

  final url = Uri.parse(
    "http://172.20.10.7/holili_mobile_fuzzy_gradle_fixed/php/get_history.php",
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {

    final Map<String, dynamic> jsonData =
        jsonDecode(response.body);

    final List data = jsonData['data'];

    return data
        .map(
          (e) => HistoryLog.fromJson(e),
        )
        .toList();

  } else {

    throw Exception(
      "Gagal mengambil data history_logs",
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
  child: Column(
    children: [
      CardViewAbove(),

      const SizedBox(height: 10),

      const CardRow(),

      const SizedBox(height: 10),

      CardWithTextFieldAndButtons(),
            Padding(
  padding: const EdgeInsets.all(8.0),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Text(
          'History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HistoryScreen()),
          );
        },
        child: Text('Lihat Semua'),
      ),
    ],
  ),
),
SizedBox(height: 10),

FutureBuilder<List<HistoryLog>>(
  future: fetchHistoryLogs(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Text("Error: ${snapshot.error}");
    }

    final data = snapshot.data ?? [];

    return ListView.builder(
  shrinkWrap: true,
  physics: NeverScrollableScrollPhysics(),

  itemCount: data.length,

  itemBuilder: (context, index) {

    final item = data[index];
    final temperatureStatus = SensorFuzzyLogic.evaluateTemperature(item.avgTemperature);
    final tdsStatus = SensorFuzzyLogic.evaluateTds(item.avgPpm);
    final phStatus = SensorFuzzyLogic.evaluatePh(item.avgWaterLevel);

    return Card(

      elevation: 4,

      margin: EdgeInsets.symmetric(
        vertical: 6,
        horizontal: 10,
      ),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),

      child: Padding(

        padding: const EdgeInsets.all(14),

        child: Row(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // =========================
            // NOMOR URUT
            // =========================
            Container(

              width: 40,
              height: 40,

              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius:
                    BorderRadius.circular(10),
              ),

              child: Center(
                child: Text(

                  "${index + 1}",

                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            SizedBox(width: 14),

            // =========================
            // DATA HISTORY
            // =========================
            Expanded(

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    "Jam ${item.timeStart} - ${item.timeEnd}",

                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    "🌡 Suhu : ${item.avgTemperature} °C • ${temperatureStatus.condition.label}",
                  ),

                  SizedBox(height: 4),

                  Text(
                    "💧 TDS : ${item.avgPpm} PPM • ${tdsStatus.condition.label}",
                  ),

                  SizedBox(height: 4),

                  Text(
                    "🌊 pH : ${item.avgWaterLevel} • ${phStatus.condition.label}",
                  ),

                  SizedBox(height: 6),

                  Text(
                    item.date,

                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  },
);
  },
),

            // SizedBox(
            //   height: 300,
            //   child: ListViewContainer(),
            // ),
          ],
        ),
      ),
    );
  }
}