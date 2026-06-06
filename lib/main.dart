import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/supabase_service.dart';

// Pages
import 'pages/workout_menu_page.dart';
import 'pages/multi_chart_page.dart';
import 'pages/profile_page.dart';

// ── Supabase Configuration ──────────────────────────────────
// ใส่ URL และ Anon Key ของโปรเจกต์ Supabase ของคุณที่นี่
const String supabaseUrl = 'https://hhsdwhhahljqlrolmbje.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhoc2R3aGhhaGxqcWxyb2xtYmplIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA2OTI4ODgsImV4cCI6MjA5NjI2ODg4OH0.awb1P8ApOsh0InbkGksdyZmr9jqxSKEVSPoiNQA0jyE';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th', null);

  // เริ่มต้นการใช้งาน Supabase (หากไม่มี credentials จะเข้าโหมด offline fallback อัตโนมัติ)
  await SupabaseService.instance.initialize(
    url: supabaseUrl,
     anonKey: anonKey,
  );

  runApp(const HealthApp());
}

// -----------------------------------------------------------
// APP ROOT
// -----------------------------------------------------------
class HealthApp extends StatelessWidget {
  const HealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "AI Health Tracker",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
      ),
      home: const MainNavigationPage(),
    );
  }
}

// -----------------------------------------------------------
// MAIN BOTTOM NAVIGATION PAGE
// -----------------------------------------------------------
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int currentIndex = 0;

  final GlobalKey<DashboardPageState> dashboardKey =
      GlobalKey<DashboardPageState>();

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(key: dashboardKey),
      const WorkoutMenuPage(),
      MultiChartPage(
        records: dashboardKey.currentState?.records ?? [],
      ),
      const ProfilePage(),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        height: 74,
        backgroundColor: Colors.white,
        indicatorColor: Colors.teal.withValues(alpha: 0.15),
        onDestinationSelected: (index) {
          setState(() => currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: "หน้าแรก",
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: "ออกกำลังกาย",
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: "กราฟ",
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: "โปรไฟล์",
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------
// DATA MODELS
// -----------------------------------------------------------
class HealthRecord {
  final String date;
  final double steps;
  final double sleep;
  final double weight;
  final double systolic;
  final double diastolic;
  final double water;

  HealthRecord({
    required this.date,
    required this.steps,
    required this.sleep,
    required this.weight,
    required this.systolic,
    required this.diastolic,
    required this.water,
  });

  Map<String, dynamic> toMap() => {
        "date": date,
        "steps": steps,
        "sleep": sleep,
        "weight": weight,
        "systolic": systolic,
        "diastolic": diastolic,
        "water": water,
      };

  factory HealthRecord.fromMap(Map<String, dynamic> map) {
    return HealthRecord(
      date: map["date"],
      steps: (map["steps"] as num).toDouble(),
      sleep: (map["sleep"] as num).toDouble(),
      weight: (map["weight"] as num).toDouble(),
      systolic: (map["systolic"] as num?)?.toDouble() ?? 0,
      diastolic: (map["diastolic"] as num?)?.toDouble() ?? 0,
      water: (map["water"] as num?)?.toDouble() ?? 0,
    );
  }
}

class UserProgress {
  int streak;
  int maxStreak;
  int xp;
  String lastCheckIn;

  int get level => (xp ~/ 100) + 1;
  int get xpToNext => 100 - (xp % 100);

  UserProgress({
    required this.streak,
    required this.maxStreak,
    required this.xp,
    required this.lastCheckIn,
  });

  Map<String, dynamic> toMap() => {
        "streak": streak,
        "max_streak": maxStreak,
        "xp": xp,
        "last_check_in": lastCheckIn,
      };

  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      streak: map["streak"] ?? 0,
      maxStreak: map["max_streak"] ?? 0,
      xp: map["xp"] ?? 0,
      lastCheckIn: map["last_check_in"] ?? "",
    );
  }
}

// -----------------------------------------------------------
// DASHBOARD PAGE
// -----------------------------------------------------------
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  // ── Records & progress ──────────────────────────────────
  List<HealthRecord> records = [];
  UserProgress progress = UserProgress(
      streak: 0, maxStreak: 0, xp: 0, lastCheckIn: "");
  bool loading = true;

  // ── Text Controllers สำหรับการ์ดสุขภาพวันนี้ ──────────────
  final _stepsCtrl = TextEditingController();
  final _sleepCtrl = TextEditingController();
  final _waterCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  // ── Pedometer State ──────────────────────────────────────
  int _steps = 0;
  int _stepsOnStart = 0;
  String _pedometerStatus = 'stopped';
  String _pedometerError = '';
  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;
  
  // ตัวแปรเช็คว่าผู้ใช้กำลังพิมพ์ช่องก้าวเดินอยู่หรือไม่ เพื่อไม่ให้เซนเซอร์ไปกวนจังหวะพิมพ์
  bool _isStepFieldFocused = false;

  @override
  void initState() {
    super.initState();
    loadProgress();
    _initRecordsAndControllers();
    _requestPermissionAndStart();
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    _statusSub?.cancel();
    _stepsCtrl.dispose();
    _sleepCtrl.dispose();
    _waterCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  // ── ดึงข้อมูลเก่ามาแสดงในฟิลด์ ถ้าไม่มีให้ใส่ค่า 0 ไว้ก่อน ─────────────────
  Future<void> _initRecordsAndControllers() async {
    await loadRecords();
    final todayRec = getTodayRecord();
    if (todayRec != null) {
      _stepsCtrl.text = todayRec.steps.toInt().toString();
      _sleepCtrl.text = todayRec.sleep > 0 ? todayRec.sleep.toString() : "";
      _waterCtrl.text = todayRec.water > 0 ? todayRec.water.toInt().toString() : "";
      _weightCtrl.text = todayRec.weight > 0 ? todayRec.weight.toString() : "";
    } else {
      _stepsCtrl.text = _steps.toString();
    }
  }

  // ── ตั้งค่าขอสิทธิ์ระบบและเริ่มใช้งานเซนเซอร์จับก้าวเดิน ────────────────────
  Future<void> _requestPermissionAndStart() async {
    final status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      _startListening();
    } else {
      if (mounted) {
        setState(() => _pedometerError = 'ไม่ได้รับสิทธิ์เซนเซอร์ก้าวเดิน');
      }
    }
  }

  void _startListening() {
    _stepSub = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepCountError,
    );
    _statusSub = Pedometer.pedestrianStatusStream.listen(
      _onPedestrianStatus,
      onError: _onStatusError,
    );
  }

  // 🚶‍♂️ ฟังก์ชันอัปเดตตัวเลขก้าวเดินบน TextField อัตโนมัติเมื่อเกิดการเดินจริง
  void _onStepCount(StepCount event) {
    if (!mounted) return;
    setState(() {
      if (_stepsOnStart == 0) _stepsOnStart = event.steps;
      _steps = event.steps - _stepsOnStart;
      
      final todayRec = getTodayRecord();
      // ระบบจะเพิ่มก้าวให้อัตโนมัติก็ต่อเมื่อ: วันนี้ยังไม่ได้กดเซฟบันทึก และ ผู้ใช้ไม่ได้กำลังจิ้มพิมพ์ช่องนี้ค้างไว้
      if (todayRec == null && !_isStepFieldFocused) {
        _stepsCtrl.value = TextEditingValue(
          text: _steps.toString(),
          selection: TextSelection.collapsed(offset: _steps.toString().length),
        );
      }
    });
  }

  void _onPedestrianStatus(PedestrianStatus event) {
    if (!mounted) return;
    setState(() => _pedometerStatus = event.status);
  }

  void _onStepCountError(Object error) {
    if (!mounted) return;
    setState(() => _pedometerError = error.toString());
  }

  void _onStatusError(Object error) {
    if (!mounted) return;
    setState(() => _pedometerStatus = "unknown");
  }

  // ── Load / Save Data ──────────────────────────────────────
  Future<void> loadRecords() async {
    setState(() => loading = true);
    final loaded = await SupabaseService.instance.loadHealthRecords();
    setState(() {
      records = loaded;
      loading = false;
    });
  }

  Future<void> loadProgress() async {
    final loadedProgress = await SupabaseService.instance.loadUserProgress();
    if (mounted) {
      setState(() => progress = loadedProgress);
    }
  }

  Future<void> _updateProgress() async {
    final today = DateFormat("yyyy-MM-dd").format(DateTime.now());

    if (progress.lastCheckIn.isEmpty) {
      progress = UserProgress(streak: 1, maxStreak: 1, xp: 20, lastCheckIn: today);
    } else {
      final diff = DateTime.now().difference(DateTime.parse(progress.lastCheckIn)).inDays;
      if (diff == 1) {
        progress.streak++;
        progress.xp += 20;
      } else if (diff > 1) {
        progress.streak = 1;
        progress.xp += 20;
      } else {
        progress.xp += 10;
      }
      if (progress.streak > progress.maxStreak) {
        progress.maxStreak = progress.streak;
      }
      progress.lastCheckIn = today;
    }
    await SupabaseService.instance.saveUserProgress(progress);
  }

  Future<void> saveRecord(HealthRecord r) async {
    await SupabaseService.instance.saveHealthRecord(r);
    
    // อัปเดตรายการใน UI
    records.removeWhere((e) => e.date == r.date);
    records.insert(0, r);
    
    await _updateProgress();
    await loadProgress();
    if (mounted) setState(() {});
  }

  // ── บันทึกข้อมูลสุขภาพทั้งหมดของการ์ดวันนี้ ───────────────────────
  void _saveTodayData() {
    final todayStr = DateFormat("yyyy-MM-dd").format(DateTime.now());
    final stepsVal = int.tryParse(_stepsCtrl.text) ?? _steps;

    final r = HealthRecord(
      date: todayStr,
      steps: stepsVal.toDouble(),
      sleep: double.tryParse(_sleepCtrl.text) ?? 0,
      weight: double.tryParse(_weightCtrl.text) ?? 0,
      systolic: 0,
      diastolic: 0,
      water: double.tryParse(_waterCtrl.text) ?? 0,
    );

    saveRecord(r);
    FocusScope.of(context).unfocus(); // ปิดคีย์บอร์ด

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("✅ บันทึกข้อมูลสุขภาพวันนี้สำเร็จ"),
        backgroundColor: Colors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────
  HealthRecord? getTodayRecord() {
    if (records.isEmpty) return null;
    final today = DateFormat("yyyy-MM-dd").format(DateTime.now());
    try {
      return records.firstWhere((e) => e.date == today);
    } catch (_) {
      return null;
    }
  }

  String analyzeToday() {
    final steps = int.tryParse(_stepsCtrl.text) ?? 0;
    final sleep = double.tryParse(_sleepCtrl.text) ?? 0;
    final water = double.tryParse(_waterCtrl.text) ?? 0;

    if (steps == 0 && sleep == 0 && water == 0) {
      return "ก้าวเดินจะเพิ่มขึ้นอัตโนมัติตามเซนเซอร์ หรือปรับแก้ไขค่าของการ์ดด้านล่างแล้วกดบันทึกได้เลย!";
    }

    List<String> msg = [];
    if (steps < 5000 && steps > 0) msg.add("เดินน้อยกว่า 5,000 ก้าว – ควรเดินเพิ่มนะ");
    if (sleep < 6 && sleep > 0) msg.add("นอนน้อยกว่า 6 ชั่วโมง – พักผ่อนให้เพียงพอ");
    if (water < 5 && water > 0) msg.add("ดื่มน้ำน้อยกว่า 5 แก้ว – เติมน้ำเพิ่มหน่อย");
    
    return msg.isEmpty
        ? "เป้าหมายวันนี้ของคุณยอดเยี่ยม สุขภาพดีสุด ๆ ✔"
        : "• ${msg.join("\n• ")}";
  }

  List<String> getBadges() {
    List<String> list = [];
    if (progress.streak >= 3) list.add("🔥 Streak 3 วัน");
    if (progress.streak >= 7) list.add("🔥🔥 Streak 7 วัน");
    if (progress.xp >= 100) list.add("⭐ LV.2 Achiever");
    if (progress.xp >= 500) list.add("🏆 Pro Health Keeper");
    return list;
  }

  // ═══════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final todayRec = getTodayRecord();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAnalysisCard(),
                      
                      // หัวข้อ สุขภาพวันนี้ + วันที่
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                        child: Row(
                          children: [
                            const Text("สุขภาพวันนี้",
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A3C40))),
                            const SizedBox(width: 6),
                            Text(DateFormat("d MMM yyyy", "th").format(DateTime.now()),
                                style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                            const Spacer(),
                            if (todayRec != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text("บันทึกแล้ว ✓",
                                    style: TextStyle(color: Colors.teal, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ),

                      // ตารางฟอร์มกรอกข้อมูลการ์ดสุขภาพวันนี้
                      _buildEditableHealthGrid(),
                      
                      // ปุ่มบันทึกข้อมูลสุขภาพวันนี้
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _saveTodayData,
                            icon: const Icon(Icons.save_rounded, size: 18),
                            label: const Text(
                              "บันทึกข้อมูลสุขภาพวันนี้",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ),

                      // แสดงข้อมูลสถานะย่อยของเซนเซอร์ด้านล่างฟอร์มเพื่อความแม่นยำ
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                        child: Text(
                          "สถานะเซนเซอร์ก้าวเดิน: ${_pedometerStatus == 'walking' ? 'กำลังเดิน 🚶' : 'หยุดนิ่ง 🛑'}",
                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                      ),

                      if (_pedometerError.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text("⚠️ $_pedometerError", style: const TextStyle(color: Colors.red, fontSize: 11)),
                        ),

                      const SizedBox(height: 8),
                      _buildSectionTitle("ความก้าวหน้า"),
                      _buildGamification(),
                      const SizedBox(height: 14),
                      _buildBadges(),
                      const SizedBox(height: 14),
                      _buildSectionTitle("ประวัติบันทึกสุขภาพ"),
                    ],
                  ),
                ),

                // ── ประวัติรายการบันทึกด้านล่าง ──────────────────────
                records.isEmpty
                    ? const SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("📋", style: TextStyle(fontSize: 48)),
                              SizedBox(height: 12),
                              Text(
                                "ยังไม่มีข้อมูลประวัติ\nระบบนับก้าวทำงานแล้ว กดบันทึกข้อมูลเพื่อเริ่มบันทึกประวัติ",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _buildHistoryItem(records[i]),
                          childCount: records.length,
                        ),
                      ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // WIDGETS COMPONENTS
  // ═══════════════════════════════════════════════════════

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 110,
      pinned: true,
      backgroundColor: Colors.teal,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
        title: const Text(
          "AI Health Tracker",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00897B), Color(0xFF00695C)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
            child: Row(
              children: [
                const Text("สวัสดี 👋", style: TextStyle(color: Colors.white70, fontSize: 14)),
                const Spacer(),
                _buildStreakBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A3C40)),
      ),
    );
  }

  Widget _buildAnalysisCard() {
    final analysis = analyzeToday();
    final isGood = analysis.contains("ยอดเยี่ยม") || analysis.contains("สมบูรณ์");
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isGood
              ? [const Color(0xFF43A047), const Color(0xFF1B5E20)]
              : [const Color(0xFF0097A7), const Color(0xFF006064)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isGood ? Colors.green : Colors.teal).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              isGood ? Icons.check_circle_outline : Icons.health_and_safety,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("วิเคราะห์สุขภาพวันนี้",
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 5),
                Text(analysis, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableHealthGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _editableCard(
                  emoji: "🚶",
                  label: "ก้าวเดิน",
                  unit: "ก้าว",
                  color: Colors.green,
                  controller: _stepsCtrl,
                  hintText: "ก้าวจริง: $_steps",
                  isStepsField: true, // กำหนดเงื่อนไขพิเศษให้กับช่องก้าวเดิน
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _editableCard(
                  emoji: "😴",
                  label: "การนอนหลับ",
                  unit: "ชม.",
                  color: Colors.indigo,
                  controller: _sleepCtrl,
                  hintText: "เช่น 7.5",
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _editableCard(
                  emoji: "💧",
                  label: "ดื่มน้ำ",
                  unit: "แก้ว",
                  color: Colors.blue,
                  controller: _waterCtrl,
                  hintText: "เช่น 8",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _editableCard(
                  emoji: "⚖️",
                  label: "น้ำหนัก",
                  unit: "kg",
                  color: Colors.purple,
                  controller: _weightCtrl,
                  hintText: "เช่น 62.5",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _editableCard({
    required String emoji,
    required String label,
    required String unit,
    required Color color,
    required TextEditingController controller,
    required String hintText,
    bool isStepsField = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Focus(
                  onFocusChange: (hasFocus) {
                    if (isStepsField) {
                      // เมื่อผู้ใช้แตะเพื่อพิมพ์ จะหยุดการอัปเดตอัตโนมัติจากเซนเซอร์ชั่วคราว ป้องกันแป้นพิมพ์เด้งหลุด
                      _isStepFieldFocused = hasFocus;
                    }
                  },
                  child: TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                    onChanged: (val) => setState(() {}),
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: color),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400], fontWeight: FontWeight.normal),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(height: 1.5, color: color.withValues(alpha: 0.2)),
        ],
      ),
    );
  }

  Widget _buildGamification() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _infoBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text("⭐", style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text("Level ${progress.level}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (progress.xp % 100) / 100,
                      minHeight: 6,
                      backgroundColor: Colors.teal.withValues(alpha: 0.12),
                      valueColor: const AlwaysStoppedAnimation(Colors.teal),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "อีก ${progress.xpToNext} XP ถึง Level ${progress.level + 1}",
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _infoBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text("🔥", style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    const Text("Streak", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    "${progress.streak} วัน",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                  const SizedBox(height: 2),
                  Text("สูงสุด ${progress.maxStreak} วัน", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadges() {
    final badges = getBadges();
    return _infoBox(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("🏅 Badge ที่ได้รับ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          badges.isEmpty
              ? Text("บันทึกข้อมูลต่อเนื่องเพื่อปลดล็อก Badge!", style: TextStyle(color: Colors.grey[500], fontSize: 13))
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: badges
                      .map((e) => Chip(
                            label: Text(e, style: const TextStyle(fontSize: 12)),
                            backgroundColor: Colors.teal.withValues(alpha: 0.1),
                            side: BorderSide.none,
                          ))
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _infoBox({required Widget child, EdgeInsetsGeometry? margin}) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }

  Widget _buildStreakBadge() {
    if (progress.streak == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("🔥", style: TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text("${progress.streak} วัน", style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(HealthRecord r) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                r.date,
                style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _statChip("🚶", "${NumberFormat("#,###").format(r.steps.toInt())} ก้าว"),
                if (r.sleep > 0) _statChip("😴", "${r.sleep} ชม."),
                if (r.weight > 0) _statChip("⚖️", "${r.weight} kg"),
                if (r.water > 0) _statChip("💧", "${r.water.toInt()} แก้ว"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text("$icon $text", style: const TextStyle(fontSize: 12)),
    );
  }
}