// lib/pages/workout_timer_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class WorkoutTimerPage extends StatefulWidget {
  final String title;
  final String category;                  // ← ใหม่: ส่งมาจาก WorkoutListPage
  final int suggestedSeconds;

  const WorkoutTimerPage({
    super.key,
    required this.title,
    this.category = '',
    this.suggestedSeconds = 0,
  });

  @override
  State<WorkoutTimerPage> createState() => _WorkoutTimerPageState();
}

class _WorkoutTimerPageState extends State<WorkoutTimerPage> {
  Timer? _timer;
  int _elapsed = 0;     // เวลาที่ใช้จริง (นับขึ้น)
  int _countdown = 0;   // เวลาถอยหลัง (ถ้า suggestedSeconds > 0)
  bool _running = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _countdown = widget.suggestedSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_running) return;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed++;
        if (widget.suggestedSeconds > 0) {
          if (_countdown > 0) {
            _countdown--;
          } else {
            _finishWorkout();
          }
        }
      });
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  // ── บันทึกผลและอัปเดต XP ─────────────────────────────────
  Future<void> _finishWorkout() async {
    _timer?.cancel();
    setState(() { _running = false; _saving = true; });

    // คำนวณ XP: 10 XP ต่อนาที ขั้นต่ำ 5 XP
    final xpGain = ((_elapsed / 60) * 10).round().clamp(5, 9999);

    try {
      // 1. บันทึก workout session ลง Supabase
      await SupabaseService.instance.saveWorkoutSession(
        workoutTitle: widget.title,
        category: widget.category,
        durationSeconds: _elapsed,
        xpEarned: xpGain,
      );

      // 2. อัปเดต XP ใน user_progress
      final progress = await SupabaseService.instance.loadUserProgress();
      progress.xp += xpGain;
      await SupabaseService.instance.saveUserProgress(progress);

    } catch (e) {
      debugPrint('❌ _finishWorkout: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🏆 คอร์สเสร็จแล้ว +$xpGain XP'),
        backgroundColor: Colors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
    Navigator.pop(context, true);
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final displayTime = widget.suggestedSeconds > 0 ? _countdown : _elapsed;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // นาฬิกา
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.teal.withValues(alpha: 0.1),
                border: Border.all(color: Colors.teal, width: 3),
              ),
              alignment: Alignment.center,
              child: Text(
                _fmt(displayTime),
                style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            ),

            const SizedBox(height: 12),
            Text(
              'เวลาที่ใช้จริง: ${_fmt(_elapsed)}',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),

            const SizedBox(height: 36),

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              // ปุ่ม Start / Pause
              ElevatedButton.icon(
                onPressed: _saving ? null : (_running ? _pause : _start),
                icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                label: Text(_running ? 'หยุด' : 'เริ่ม'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(width: 16),

              // ปุ่มจบคอร์ส
              ElevatedButton.icon(
                onPressed: _saving
                    ? null
                    : () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('ยืนยัน'),
                            content: const Text('ต้องการจบคอร์สและบันทึกผลหรือไม่?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: const Text('ยกเลิก')),
                              TextButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  child: const Text('ยืนยัน')),
                            ],
                          ),
                        );
                        if (ok == true) await _finishWorkout();
                      },
                icon: _saving
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.flag_rounded),
                label: const Text('จบคอร์ส'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ]),

            const SizedBox(height: 24),
            Text(
              'เมื่อจบคอร์สระบบจะบันทึกผลและเพิ่ม XP อัตโนมัติ',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}