enum SensorType {
  temperature,
  tds,
  ph,
}

extension SensorTypeLabel on SensorType {
  String get label {
    switch (this) {
      case SensorType.temperature:
        return 'Suhu';
      case SensorType.tds:
        return 'TDS';
      case SensorType.ph:
        return 'pH Air';
    }
  }

  String get shortLabel {
    switch (this) {
      case SensorType.temperature:
        return 'Suhu';
      case SensorType.tds:
        return 'TDS';
      case SensorType.ph:
        return 'pH';
    }
  }
}
