// sensor_models.dart

class SensorReading {
  final int? id;
  final double temperatur;
  final double tds;
  final double ph;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SensorReading({
    required this.id,
    required this.temperatur,
    required this.tds,
    required this.ph,
    required this.createdAt,
    this.updatedAt,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    try {
      return SensorReading(
        id: int.tryParse(json['id'].toString()),

        temperatur:
            double.tryParse(json['temperatur'].toString()) ?? 0.0,

        tds:
            double.tryParse(json['tds'].toString()) ?? 0.0,

        ph:
            double.tryParse(json['ph'].toString()) ?? 0.0,

        createdAt: DateTime.parse(json['created_at']),

        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
      );
    } catch (e) {
      throw FormatException(
        'Failed to parse SensorReading: $e',
      );
    }
  }
}

// ===============================
// HISTORY LOG (2 JAM / DAILY LOG)
// ===============================

class HistoryLog {
  final int? id;
  final String date;
  final String timeStart;
  final String timeEnd;
  final double avgTemperature;
  final double avgPpm;
  final double avgWaterLevel;

  HistoryLog({
    this.id,
    required this.date,
    required this.timeStart,
    required this.timeEnd,
    required this.avgTemperature,
    required this.avgPpm,
    required this.avgWaterLevel,
  });

  factory HistoryLog.fromJson(Map<String, dynamic> json) {
    try {
      return HistoryLog(
        id: int.tryParse(json['id'].toString()),

        date: json['date'] ?? '',

        timeStart: json['time_start'] ?? '',

        timeEnd: json['time_end'] ?? '',

        avgTemperature:
            double.tryParse(json['avg_temperature'].toString()) ?? 0.0,

        avgPpm:
            double.tryParse(json['avg_ppm'].toString()) ?? 0.0,

        avgWaterLevel:
            double.tryParse(json['avg_water_level'].toString()) ?? 0.0,
      );
    } catch (e) {
      throw FormatException(
        'Failed to parse HistoryLog: $e',
      );
    }
  }
}

// ===============================
// DAILY SENSOR DATA
// ===============================

class DailySensorData {
  final String message;
  final List<SensorReading> data;

  DailySensorData({
    required this.message,
    required this.data,
  });

  factory DailySensorData.fromJson(
    Map<String, dynamic> json,
  ) {
    return DailySensorData(
      message: json['message'] ?? 'No message',

      data: json['data'] != null
          ? (json['data'] as List)
              .map(
                (e) => SensorReading.fromJson(e),
              )
              .toList()
          : [],
    );
  }
}