import 'package:flutter/material.dart';
import '../main.dart';

class HistoryPage extends StatelessWidget {
  final List<HealthRecord> records;

  const HistoryPage({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ประวัติย้อนหลัง")),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: records.length,
        itemBuilder: (context, i) {
          final r = records[i];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(
                r.date,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "ก้าวเดิน: ${r.steps}\n"
                "นอน: ${r.sleep} ชม.\n"
                "น้ำหนัก: ${r.weight} kg\n",
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
          );
        },
      ),
    );
  }
}
