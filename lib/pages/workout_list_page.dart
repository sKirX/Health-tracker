// lib/pages/workout_list_page.dart
import 'package:flutter/material.dart';
import 'workout_detail_page.dart';

class WorkoutListPage extends StatelessWidget {
  final String title;
  final String category;

  const WorkoutListPage({
    super.key,
    required this.title,
    required this.category,
  });

  List<Map<String, dynamic>> getCourses() {
    if (category == 'indoor') {
      return [
        {
          'title': 'HIIT 10 นาที',
          'duration': '10 นาที',
          'details': [
            'กระโดดตบ 30 วินาที',
            'พัก 10 วินาที',
            'ลันจ์ 30 วินาที',
            'พัก 10 วินาที',
            'แพลงก์ 30 วินาที',
          ],
        },
        {
          'title': 'ยืดกล้ามเนื้อพื้นฐาน',
          'duration': '8 นาที',
          'details': [
            'ยืดคอ 30 วินาที',
            'ยืดไหล่ 30 วินาที',
            'ยืดหลัง 40 วินาที',
            'ยืดขา 40 วินาที',
          ],
        },
      ];
    }
    return [
      {
        'title': 'วิ่งเบา 1 กม. สำหรับมือใหม่',
        'duration': 'ประมาณ 12-15 นาที',
        'details': [
          'วอร์มอัพ 2 นาที',
          'วิ่งเบา 1 กม.',
          'คูลดาวน์ 2 นาที',
        ],
      },
      {
        'title': 'วิ่ง 3 กม. เพิ่มความทนทาน',
        'duration': '20-30 นาที',
        'details': [
          'วอร์มอัพ 3 นาที',
          'วิ่งช้า 1 กม.',
          'วิ่งปานกลาง 1 กม.',
          'วิ่งเร็ว 1 กม.',
          'คูลดาวน์ 3 นาที',
        ],
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final courses = getCourses();
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: courses.length,
        itemBuilder: (context, i) {
          final c = courses[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(c['title'],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              subtitle: Text('ระยะเวลา: ${c['duration']}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutDetailPage(
                    title: c['title'],
                    duration: c['duration'],
                    category: category,           // ← ส่ง category ต่อ
                    details: List<String>.from(c['details']),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}