enum SensorCondition {
  baik,
  cukup,
  kurang,
}

extension SensorConditionLabel on SensorCondition {
  String get label {
    switch (this) {
      case SensorCondition.baik:
        return 'Baik';
      case SensorCondition.cukup:
        return 'Cukup';
      case SensorCondition.kurang:
        return 'Kurang';
    }
  }
}

class FuzzySensorConfig {
  final String sensorName;
  final String unit;
  final double criticalLow;
  final double acceptableLow;
  final double idealLow;
  final double idealHigh;
  final double acceptableHigh;
  final double criticalHigh;

  const FuzzySensorConfig({
    required this.sensorName,
    required this.unit,
    required this.criticalLow,
    required this.acceptableLow,
    required this.idealLow,
    required this.idealHigh,
    required this.acceptableHigh,
    required this.criticalHigh,
  }) : assert(criticalLow < acceptableLow),
       assert(acceptableLow < idealLow),
       assert(idealLow < idealHigh),
       assert(idealHigh < acceptableHigh),
       assert(acceptableHigh < criticalHigh);
}

class FuzzySensorResult {
  final double value;
  final FuzzySensorConfig config;
  final double baikMembership;
  final double cukupMembership;
  final double kurangMembership;
  final double score;
  final SensorCondition condition;

  const FuzzySensorResult({
    required this.value,
    required this.config,
    required this.baikMembership,
    required this.cukupMembership,
    required this.kurangMembership,
    required this.score,
    required this.condition,
  });

  String get description {
    if (value < config.idealLow) {
      return 'Di bawah rentang ideal';
    }

    if (value > config.idealHigh) {
      return 'Di atas rentang ideal';
    }

    return 'Dalam rentang ideal';
  }
}

class SensorFuzzyLogic {
  SensorFuzzyLogic._();

  // Nilai berikut adalah konfigurasi awal untuk akuaskap air tawar umum.
  // Sesuaikan dengan spesies ikan, jenis tanaman, dan target operasional sistem.
  static const temperatureConfig = FuzzySensorConfig(
    sensorName: 'Suhu',
    unit: '°C',
    criticalLow: 20,
    acceptableLow: 22,
    idealLow: 24,
    idealHigh: 28,
    acceptableHigh: 30,
    criticalHigh: 32,
  );

  static const tdsConfig = FuzzySensorConfig(
    sensorName: 'TDS',
    unit: 'PPM',
    criticalLow: 50,
    acceptableLow: 100,
    idealLow: 150,
    idealHigh: 300,
    acceptableHigh: 400,
    criticalHigh: 500,
  );

  static const phConfig = FuzzySensorConfig(
    sensorName: 'pH',
    unit: '',
    criticalLow: 5,
    acceptableLow: 6,
    idealLow: 6.5,
    idealHigh: 7.5,
    acceptableHigh: 8,
    criticalHigh: 9,
  );

  static FuzzySensorResult evaluateTemperature(double value) {
    return evaluate(value, temperatureConfig);
  }

  static FuzzySensorResult evaluateTds(double value) {
    return evaluate(value, tdsConfig);
  }

  static FuzzySensorResult evaluatePh(double value) {
    return evaluate(value, phConfig);
  }

  static FuzzySensorResult evaluate(
    double value,
    FuzzySensorConfig config,
  ) {
    final baik = _trapezoid(
      value,
      config.acceptableLow,
      config.idealLow,
      config.idealHigh,
      config.acceptableHigh,
    );

    final cukupRendah = _triangle(
      value,
      config.criticalLow,
      config.acceptableLow,
      config.idealLow,
    );

    final cukupTinggi = _triangle(
      value,
      config.idealHigh,
      config.acceptableHigh,
      config.criticalHigh,
    );

    final cukup = cukupRendah > cukupTinggi ? cukupRendah : cukupTinggi;

    final kurangRendah = _leftShoulder(
      value,
      config.criticalLow,
      config.acceptableLow,
    );

    final kurangTinggi = _rightShoulder(
      value,
      config.acceptableHigh,
      config.criticalHigh,
    );

    final kurang = kurangRendah > kurangTinggi ? kurangRendah : kurangTinggi;
    final totalMembership = baik + cukup + kurang;

    // Defuzzifikasi berbobot: Baik=100, Cukup=60, Kurang=20.
    final score = totalMembership == 0
        ? 20.0
        : ((baik * 100) + (cukup * 60) + (kurang * 20)) /
              totalMembership;

    // Ambang 80 dan 40 konsisten dengan titik potong fungsi keanggotaan.
    final condition = score > 80
        ? SensorCondition.baik
        : score >= 40
        ? SensorCondition.cukup
        : SensorCondition.kurang;

    return FuzzySensorResult(
      value: value,
      config: config,
      baikMembership: baik,
      cukupMembership: cukup,
      kurangMembership: kurang,
      score: score.clamp(0, 100).toDouble(),
      condition: condition,
    );
  }

  static double _triangle(
    double value,
    double left,
    double peak,
    double right,
  ) {
    if (value <= left || value >= right) {
      return 0;
    }

    if (value == peak) {
      return 1;
    }

    if (value < peak) {
      return (value - left) / (peak - left);
    }

    return (right - value) / (right - peak);
  }

  static double _trapezoid(
    double value,
    double leftZero,
    double leftOne,
    double rightOne,
    double rightZero,
  ) {
    if (value <= leftZero || value >= rightZero) {
      return 0;
    }

    if (value >= leftOne && value <= rightOne) {
      return 1;
    }

    if (value < leftOne) {
      return (value - leftZero) / (leftOne - leftZero);
    }

    return (rightZero - value) / (rightZero - rightOne);
  }

  static double _leftShoulder(
    double value,
    double fullUntil,
    double zeroAt,
  ) {
    if (value <= fullUntil) {
      return 1;
    }

    if (value >= zeroAt) {
      return 0;
    }

    return (zeroAt - value) / (zeroAt - fullUntil);
  }

  static double _rightShoulder(
    double value,
    double zeroUntil,
    double fullAt,
  ) {
    if (value <= zeroUntil) {
      return 0;
    }

    if (value >= fullAt) {
      return 1;
    }

    return (value - zeroUntil) / (fullAt - zeroUntil);
  }
}
