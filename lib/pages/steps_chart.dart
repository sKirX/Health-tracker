// lib/pages/steps_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StepsChart extends StatelessWidget {
  final List<int> steps; // length 7 = last 7 days
  const StepsChart({required this.steps, super.key});

  @override
  Widget build(BuildContext context) {
    final spots = List.generate(steps.length, (i) => FlSpot(i.toDouble(), steps[i].toDouble()));
    final maxY = (steps.reduce((a,b) => a>b? a:b) * 1.2).clamp(1000, double.infinity);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (steps.length - 1).toDouble(),
              minY: 0,
              maxY: maxY.toDouble(),
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    // show Mon..Sun or 1..7
                    final idx = value.toInt();
                    final labels = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(labels[idx % labels.length], style: const TextStyle(fontSize: 10)),
                    );
                  },
                )),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  dotData: FlDotData(show: true),
                  barWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
