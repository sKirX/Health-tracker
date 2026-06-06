// lib/pages/workout_detail_page.dart
import 'package:flutter/material.dart';
import 'workout_timer_page.dart';

class WorkoutDetailPage extends StatefulWidget {
  final String title;
  final String duration;
  final String category;      // ← ใหม่: ส่ง category มาด้วย
  final List<String> details;

  const WorkoutDetailPage({
    super.key,
    required this.title,
    required this.duration,
    required this.category,
    required this.details,
  });

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  int parseSuggestedSeconds() {
    final t = widget.title;
    if (t.contains('10 นาที')) return 600;
    if (t.contains('8 นาที'))  return 480;
    if (t.contains('1 กม.'))   return 720;
    if (t.contains('3 กม.'))   return 1200;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ระยะเวลาโดยประมาณ: ${widget.duration}',
                style: const TextStyle(fontSize: 16, color: Colors.teal)),
            const SizedBox(height: 20),
            const Text('ขั้นตอนการออกกำลังกาย:',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: widget.details.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.withValues(alpha: 0.12),
                    child: Text('${i + 1}',
                        style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(widget.details[i]),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkoutTimerPage(
                        title: widget.title,
                        category: widget.category,      // ← ส่ง category
                        suggestedSeconds: parseSuggestedSeconds(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('เริ่มออกกำลังกาย',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}