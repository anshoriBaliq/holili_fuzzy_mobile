import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/sensor_reading.dart';

class ApiService {
  static const String baseUrl =
      'http://172.20.10.7/holili_mobile_fuzzy_gradle_fixed/php';
  static const String getDataUrl = '$baseUrl/Get_data.php';
  static const String historyUrl = '$baseUrl/get_history.php';

  Future<List<SensorReading>> getSensorReadings() async {
    try {
      final url = Uri.parse(getDataUrl).replace(
        queryParameters: {'limit': '15'},
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load sensor readings '
          '(Status: ${response.statusCode})',
        );
      }

      final decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded is Map<String, dynamic>
          ? (decoded['data'] ?? []) as List<dynamic>
          : decoded as List<dynamic>;

      return data
          .map((item) => SensorReading.fromJson(item as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw Exception('No Internet Connection');
    } on TimeoutException {
      throw Exception('Request Timeout');
    } on FormatException catch (error) {
      throw Exception('Invalid JSON Format: $error');
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<DailySensorData> getTodayData() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return getDataByDate(today);
  }

  Future<List<HistoryLog>> getSensorHistory() async {
    try {
      final response = await http.get(Uri.parse(historyUrl)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load history (${response.statusCode})',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (decoded['data'] ?? []) as List<dynamic>;

      return data
          .map((item) => HistoryLog.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  Future<DailySensorData> getDataByDate(String date) async {
    try {
      final url = Uri.parse(getDataUrl).replace(
        queryParameters: {'date': date},
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load data by date '
          '(Status: ${response.statusCode})',
        );
      }

      final decoded = jsonDecode(response.body);
      final jsonMap = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{
              'message': 'Success',
              'data': decoded,
            };

      return DailySensorData.fromJson(jsonMap);
    } on SocketException {
      throw Exception('No Internet Connection');
    } on TimeoutException {
      throw Exception('Request Timeout');
    } catch (error) {
      throw Exception('Error: $error');
    }
  }
}
