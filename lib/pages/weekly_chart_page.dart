import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../main.dart'; // ใช้ model HealthRecord

class WeeklyChartPage extends StatelessWidget {
  final List<HealthRecord> records;

  const WeeklyChartPage({super.key, required this.records});

  // ---------------------------
  // ดึงข้อมูล 7 วันล่าสุด (Steps)
  // ---------------------------
  List<double> getLast7Steps() {
    final today = DateTime.now();
    List<double> data = [];

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateStr =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      final rec = records.firstWhere(
        (e) => e.date == dateStr,
        orElse: () => HealthRecord(
          date: dateStr,
          steps: 0,
          sleep: 0,
          weight: 0,
          systolic: 0,
          diastolic: 0,
          water: 0,
        ),
      );

      data.add(rec.steps);
    }
    return data;
  }

  // ---------------------------
  // ดึงข้อมูลน้ำดื่ม 7 วันล่าสุด
  // ---------------------------
  List<double> getLast7Water() {
    final today = DateTime.now();
    List<double> data = [];

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateStr =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      final rec = records.firstWhere(
        (e) => e.date == dateStr,
        orElse: () => HealthRecord(
          date: dateStr,
          steps: 0,
          sleep: 0,
          weight: 0,
          systolic: 0,
          diastolic: 0,
          water: 0,
          
        ),
      );

      data.add(rec.water);
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final steps = getLast7Steps();
    final water = getLast7Water();

    final maxY = ([
          ...steps,
          ...water
        ].reduce((a, b) => a > b ? a : b) *
        1.4)
        .clamp(10, double.infinity);

    return Scaffold(
      appBar: AppBar(title: const Text("กราฟสรุป 7 วัน")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // LEGEND
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.circle, color: Colors.teal, size: 12),
                    SizedBox(width: 5),
                    Text("ก้าวเดิน"),
                    SizedBox(width: 15),
                    Icon(Icons.circle, color: Colors.blue, size: 12),
                    SizedBox(width: 5),
                    Text("น้ำดื่ม (แก้ว)"),
                  ],
                ),
                const SizedBox(height: 15),

                // LINE CHART
                Expanded(
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY.toDouble(),

                      gridData: FlGridData(show: true),
                      borderData: FlBorderData(show: true),

                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final days = ["จ", "อ", "พ", "พฤ", "ศ", "ส", "อา"];
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  days[value.toInt() % 7],
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      lineBarsData: [
                        // เส้น Steps
                        LineChartBarData(
                          isCurved: true,
                          barWidth: 3,
                          color: Colors.teal,
                          dotData: FlDotData(show: true),
                          spots: List.generate(
                            7,
                            (i) => FlSpot(i.toDouble(), steps[i]),
                          ),
                        ),

                        // เส้นน้ำดื่ม
                        LineChartBarData(
                          isCurved: true,
                          barWidth: 3,
                          color: Colors.blue,
                          dotData: FlDotData(show: true),
                          spots: List.generate(
                            7,
                            (i) => FlSpot(i.toDouble(), water[i]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
