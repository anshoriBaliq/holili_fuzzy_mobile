import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'domain/sensor_type.dart';

class CurveCard extends StatelessWidget {
  final List<double> temperatureScores;
  final List<double> tdsScores;
  final List<double> phScores;
  final SensorType? highlightedSensor;

  const CurveCard({
    super.key,
    required this.temperatureScores,
    required this.tdsScores,
    required this.phScores,
    this.highlightedSensor,
  });

  @override
  Widget build(BuildContext context) {
    final pointCount = math.max(
      temperatureScores.length,
      math.max(tdsScores.length, phScores.length),
    );

    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Indeks Kualitas Sensor Realtime',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              highlightedSensor == null
                  ? 'Skor fuzzy 0–100. Baik > 80, Cukup 40–80, Kurang < 40.'
                  : 'Sensor ${highlightedSensor!.shortLabel} sedang ditonjolkan. '
                        'Baik > 80, Cukup 40–80, Kurang < 40.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              width: double.infinity,
              child: pointCount == 0
                  ? const Center(
                      child: Text('Menunggu data sensor...'),
                    )
                  : LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: 100,
                        minX: 0,
                        maxX: math.max(1, pointCount - 1).toDouble(),
                        clipData: FlClipData.all(),
                        gridData: const FlGridData(
                          show: true,
                          horizontalInterval: 20,
                          drawVerticalLine: false,
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 34,
                              interval: 20,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                        ),
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: 40,
                              color: Colors.red.withValues(alpha: 0.55),
                              strokeWidth: 1,
                              dashArray: [6, 4],
                            ),
                            HorizontalLine(
                              y: 80,
                              color: Colors.green.withValues(alpha: 0.55),
                              strokeWidth: 1,
                              dashArray: [6, 4],
                            ),
                          ],
                        ),
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (spots) {
                              return spots.map((spot) {
                                final sensor = switch (spot.barIndex) {
                                  0 => 'Suhu',
                                  1 => 'TDS',
                                  _ => 'pH',
                                };
                                return LineTooltipItem(
                                  '$sensor: ${spot.y.toStringAsFixed(1)}',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        lineBarsData: [
                          _buildLine(
                            temperatureScores,
                            Colors.red,
                            SensorType.temperature,
                          ),
                          _buildLine(
                            tdsScores,
                            Colors.green,
                            SensorType.tds,
                          ),
                          _buildLine(
                            phScores,
                            Colors.blue,
                            SensorType.ph,
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 20,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                LegendItem(
                  color: Colors.red,
                  text: 'Suhu',
                  isHighlighted:
                      highlightedSensor == null ||
                      highlightedSensor == SensorType.temperature,
                ),
                LegendItem(
                  color: Colors.green,
                  text: 'TDS',
                  isHighlighted:
                      highlightedSensor == null ||
                      highlightedSensor == SensorType.tds,
                ),
                LegendItem(
                  color: Colors.blue,
                  text: 'pH',
                  isHighlighted:
                      highlightedSensor == null ||
                      highlightedSensor == SensorType.ph,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _buildLine(
    List<double> values,
    Color color,
    SensorType sensor,
  ) {
    final isHighlighted =
        highlightedSensor == null || highlightedSensor == sensor;

    return LineChartBarData(
      spots: List.generate(
        values.length,
        (index) => FlSpot(index.toDouble(), values[index]),
      ),
      isCurved: true,
      curveSmoothness: 0.3,
      color: color.withValues(alpha: isHighlighted ? 1 : 0.22),
      barWidth: isHighlighted ? 4 : 2,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: isHighlighted,
        checkToShowDot: (spot, barData) {
          return barData.spots.isNotEmpty && spot == barData.spots.last;
        },
      ),
      belowBarData: BarAreaData(show: false),
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  final bool isHighlighted;

  const LegendItem({
    super.key,
    required this.color,
    required this.text,
    this.isHighlighted = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isHighlighted ? 1 : 0.35,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
