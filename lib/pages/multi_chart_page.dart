// lib/pages/multi_chart_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../main.dart'; // import HealthRecord

class MultiChartPage extends StatelessWidget {
  final List<HealthRecord> records;
  const MultiChartPage({super.key, required this.records});

  List<HealthRecord> _last7() {
    final today = DateTime.now();
    List<HealthRecord> out = [];
    for (int i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final s = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      final rec = records.firstWhere((e) => e.date == s, orElse: () => HealthRecord(date: s, steps:0, sleep:0, weight:0, systolic:0, diastolic:0, water:0, ));
      out.add(rec);
    }
    return out;
  }

  Widget _lineChart(List<double> data, String label) {
    final maxValue = data.isEmpty ? 1.0 : (data.reduce((a,b)=>a>b?a:b) * 1.3).clamp(1.0, double.infinity);
    return LineChart(LineChartData(
      minY: 0, maxY: maxValue,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v,meta) {
          final labels = ["จ","อ","พ","พฤ","ศ","ส","อา"];
          return Text(labels[v.toInt()%7]);
        })),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i])),
          isCurved: true,
          barWidth: 3,
          dotData: FlDotData(show: true),
        )
      ],
    ));
  }

  Widget _barChart(List<double> data, String label) {
    final maxValue = data.isEmpty ? 1.0 : (data.reduce((a,b)=>a>b?a:b) * 1.3).clamp(1.0, double.infinity);
    return BarChart(BarChartData(
      maxY: maxValue,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v,meta) {
          final labels = ["จ","อ","พ","พฤ","ศ","ส","อา"];
          return Text(labels[v.toInt()%7]);
        })),
      ),
      barGroups: List.generate(data.length, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: data[i])]))
    ));
  }

  @override
  Widget build(BuildContext context) {
    final last7 = _last7();
    final steps = last7.map((e) => e.steps).toList();
    final water = last7.map((e) => e.water).toList();
    final sleep = last7.map((e) => e.sleep).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("กราฟสุขภาพ"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "ก้าวเดิน"),
              Tab(text: "น้ำ"),
              Tab(text: "การนอน"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: _lineChart(steps, "ก้าวเดิน (ก้าว)"),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _lineChart(water, "น้ำ (แก้ว)"),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _barChart(sleep, "ชั่วโมงนอน"),
            ),
          ],
        ),
      ),
    );
  }
}
