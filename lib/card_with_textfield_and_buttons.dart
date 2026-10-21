import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CardWithTextFieldAndButtons extends StatefulWidget {
  const CardWithTextFieldAndButtons({super.key});

  @override
  State<CardWithTextFieldAndButtons> createState() =>
      _CardWithTextFieldAndButtonsState();
}

class _CardWithTextFieldAndButtonsState
    extends State<CardWithTextFieldAndButtons> {
  final TextEditingController _tdsController = TextEditingController();

  final TextEditingController _phController = TextEditingController();

  final String esp32Ip = "192.168.1.8";

  bool isOn = false;

  // =================================================
  // CONTROL ON OFF ESP32
  // =================================================

  void controlSystem(String action) async {
    final url = Uri.parse("http://$esp32Ip/$action");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        _showSnackBar(
          "Berhasil",
          response.body,
          Colors.green,
        );
      } else {
        _showSnackBar(
          "Gagal",
          response.body,
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar(
        "Error",
        e.toString(),
        Colors.red,
      );
    }
  }

  // =================================================
  // KIRIM TARGET TDS / PH
  // =================================================

  void sendTargetSensor() async {
    String tds = _tdsController.text.trim();

    String ph = _phController.text.trim();

    if (tds.isEmpty && ph.isEmpty) {
      _showSnackBar(
        "Peringatan",
        "Isi minimal TDS atau PH",
        Colors.red,
      );

      return;
    }

    Map<String, String> parameter = {};

    if (tds.isNotEmpty) {
      parameter['tds'] = tds;
    }

    if (ph.isNotEmpty) {
      parameter['ph'] = ph;
    }

    final uri = Uri.parse("http://$esp32Ip/set-target").replace(
      queryParameters: parameter,
    );

    try {
      final response = await http.get(uri);

      print(uri);

      print(response.body);

      if (response.statusCode == 200) {
        _showSnackBar(
          "Berhasil",
          response.body,
          Colors.green,
        );
      } else {
        _showSnackBar(
          "Gagal",
          response.body,
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar(
        "Error",
        e.toString(),
        Colors.red,
      );
    }
  }

  // =================================================
  // SNACK DIALOG
  // =================================================

  void _showSnackBar(String title, String message, Color color) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                color == Colors.green ? Icons.check_circle : Icons.error,
                size: 60,
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Tutup"),
              )
            ],
          ),
        ),
      ),
    );
  }

  // =================================================
  // KONFIRMASI
  // =================================================

  void _showCustomDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Konfirmasi"),
          content: const Text("Kirim nilai yang sudah diisi?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                sendTargetSensor();
              },
              child: const Text("Kirim"),
            )
          ],
        );
      },
    );
  }

  // =================================================
  // UI
  // =================================================

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Target Parameter Aquascape",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _tdsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Target TDS (ppm)",
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _phController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Target PH",
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(
                      isOn ? "Turn Off" : "Turn On",
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isOn = !isOn;
                        });

                        controlSystem(isOn ? "turn-on" : "turn-off");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOn ? Colors.green : Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOn ? Icons.power : Icons.power_off,
                            size: 25,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            isOn ? "ON" : "OFF",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                ElevatedButton(
                  onPressed: _showCustomDialog,
                  child: const Text("Kirim ke ESP32"),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tdsController.dispose();

    _phController.dispose();

    super.dispose();
  }
}
