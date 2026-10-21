import 'package:flutter/material.dart';
import 'dart:async';

class CardViewAbove extends StatefulWidget {
  const CardViewAbove({super.key});

  @override
  _CardViewAboveState createState() => _CardViewAboveState();
}

class _CardViewAboveState extends State<CardViewAbove> {
  late Timer _timer;
  DateTime _currentDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _currentDateTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Color getIconColor() {
    int hour = _currentDateTime.hour;

    if (hour >= 6 && hour < 12) {
      return Colors.yellow; // Pagi
    } else if (hour >= 12 && hour < 18) {
      return Colors.orange; // Siang
    } else {
      return Colors.indigo; // Malam
    }
  }

  IconData getIconType() {
    int hour = _currentDateTime.hour;

    if (hour >= 6 && hour < 18) {
      return Icons.wb_sunny; // Siang hari
    } else {
      return Icons.nights_stay; // Malam hari
    }
  }

  String getDayName() {
    final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return days[(_currentDateTime.weekday - 1) % 7];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 183, 204, 241).withValues(alpha: 0.7),
              const Color.fromARGB(255, 234, 170, 245).withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Ikon bergeser ke kanan
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Icon(
                getIconType(),
                size: 70,
                color: getIconColor(),
              ),
            ),
            SizedBox(width: 50),

            // Informasi hari, tanggal, dan waktu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    getDayName(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 0, 0, 0),
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${_currentDateTime.day} - ${_currentDateTime.month} - ${_currentDateTime.year}',
                    style: TextStyle(
                      fontSize: 18,
                      color: const Color.fromARGB(179, 0, 0, 0),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '${_currentDateTime.hour}:${_currentDateTime.minute.toString().padLeft(2, '0')}:${_currentDateTime.second.toString().padLeft(2, '0')} ${_currentDateTime.hour >= 12 ? 'PM' : 'AM'}',
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color.fromARGB(179, 0, 0, 0),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
