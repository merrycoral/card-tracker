import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/performance_model.dart';

class PerformanceChart extends StatelessWidget {
  final List<PerformanceModel> performances;
  final double targetAmount;
  final Color cardColor;

  const PerformanceChart({
    super.key,
    required this.performances,
    required this.targetAmount,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    if (performances.isEmpty) {
      return const Center(child: Text('실적 데이터가 없습니다.'));
    }

    final spots = performances.asMap().entries.map((e) {
      final rate = targetAmount > 0
          ? (e.value.usedAmount / targetAmount * 100).clamp(0.0, 100.0)
          : 0.0;
      return FlSpot(e.key.toDouble(), rate);
    }).toList();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 110,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.grey[300]!,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 25,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}%',
                style: const TextStyle(fontSize: 10),
              ),
              reservedSize: 36,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= performances.length) return const SizedBox();
                final p = performances[idx];
                return Text(
                  '${p.month}월',
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 20,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 100,
              color: Colors.green,
              strokeWidth: 1.5,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                labelResolver: (_) => '목표',
                style: const TextStyle(fontSize: 10, color: Colors.green),
              ),
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: cardColor,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 4,
                color: spot.y >= 100 ? Colors.green : cardColor,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: cardColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}
