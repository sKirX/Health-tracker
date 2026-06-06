// lib/pages/workout_history_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

class WorkoutHistoryPage extends StatefulWidget {
  const WorkoutHistoryPage({super.key});

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  List<WorkoutSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final sessions = await SupabaseService.instance.loadWorkoutSessions();
    if (mounted) setState(() { _sessions = sessions; _loading = false; });
  }

  String _fmtDuration(int s) {
    if (s < 60) return '$s วิ';
    final m = s ~/ 60;
    final rem = s % 60;
    return rem > 0 ? '$m นาที $rem วิ' : '$m นาที';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการออกกำลังกาย'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🏋️', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('ยังไม่มีประวัติการออกกำลังกาย\nเริ่มคอร์สแรกได้เลย!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _sessions.length,
                  itemBuilder: (ctx, i) {
                    final s = _sessions[i];
                    final dateStr = DateFormat('d MMM yyyy, HH:mm', 'th')
                        .format(s.completedAt.toLocal());
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            s.category == 'indoor' ? '🏠' : '🏃',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        title: Text(s.workoutTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(dateStr,
                            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_fmtDuration(s.durationSeconds),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('+${s.xpEarned} XP',
                                style: const TextStyle(
                                    color: Colors.teal,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}