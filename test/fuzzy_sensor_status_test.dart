import 'package:flutter_test/flutter_test.dart';
import 'package:green/domain/fuzzy_sensor_status.dart';

void main() {
  group('SensorFuzzyLogic temperature', () {
    test('returns Baik inside ideal range', () {
      final result = SensorFuzzyLogic.evaluateTemperature(26);

      expect(result.condition, SensorCondition.baik);
      expect(result.score, 100);
      expect(result.baikMembership, 1);
    });

    test('returns Cukup near acceptable point', () {
      final result = SensorFuzzyLogic.evaluateTemperature(22);

      expect(result.condition, SensorCondition.cukup);
      expect(result.score, 60);
      expect(result.cukupMembership, 1);
    });

    test('returns Kurang outside safe range', () {
      final result = SensorFuzzyLogic.evaluateTemperature(19);

      expect(result.condition, SensorCondition.kurang);
      expect(result.score, 20);
      expect(result.kurangMembership, 1);
    });
  });

  group('SensorFuzzyLogic TDS and pH', () {
    test('evaluates ideal TDS as Baik', () {
      final result = SensorFuzzyLogic.evaluateTds(220);

      expect(result.condition, SensorCondition.baik);
      expect(result.score, 100);
    });

    test('evaluates high pH as Kurang', () {
      final result = SensorFuzzyLogic.evaluatePh(9.2);

      expect(result.condition, SensorCondition.kurang);
      expect(result.score, 20);
    });

    test('keeps score between zero and one hundred', () {
      final values = [-100.0, 5.5, 7, 8.5, 100];

      for (final value in values) {
        final result = SensorFuzzyLogic.evaluatePh(value);
        expect(result.score, inInclusiveRange(0, 100));
      }
    });
  });
}
