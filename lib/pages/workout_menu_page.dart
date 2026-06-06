// lib/pages/workout_menu_page.dart
import 'package:flutter/material.dart';
import 'workout_list_page.dart';
import 'workout_history_page.dart';

class WorkoutMenuPage extends StatelessWidget {
  const WorkoutMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ออกกำลังกาย'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'ประวัติ',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WorkoutHistoryPage()),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text('เลือกประเภทการออกกำลังกาย',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            ),
            _MenuCard(
              icon: Icons.fitness_center,
              label: 'ออกกำลังกายในร่ม',
              subtitle: 'HIIT · ยืดกล้ามเนื้อ',
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WorkoutListPage(
                    title: 'ออกกำลังกายในร่ม',
                    category: 'indoor',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _MenuCard(
              icon: Icons.directions_run,
              label: 'คอร์สวิ่ง',
              subtitle: '1 กม. · 3 กม.',
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WorkoutListPage(
                    title: 'คอร์สวิ่ง',
                    category: 'running',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}