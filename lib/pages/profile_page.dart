import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../main.dart';

// ═══════════════════════════════════════════════════════════════
//  ProfilePage  –  Login / Register / Profile with BMI
// ═══════════════════════════════════════════════════════════════
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  // ── Auth controllers ─────────────────────────────────────────
  final _usernameCtrl        = TextEditingController();
  final _emailCtrl           = TextEditingController();
  final _passwordCtrl        = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isLoginMode    = true;
  bool _loading        = false;
  bool _obscure        = true;
  bool _obscureConfirm = true;

  User? _currentUser;
  UserProgress? _progress;
  StreamSubscription<AuthState>? _authSub;

  // ── Profile body data ────────────────────────────────────────
  double _height = 170;
  double _weight = 70;
  bool   _savingBody = false;

  // ── BMI computed ─────────────────────────────────────────────
  double get _bmi => _weight / ((_height / 100) * (_height / 100));
  String get _bmiLabel {
    if (_bmi < 18.5) return "Underweight";
    if (_bmi < 25)   return "You're Healthy";
    if (_bmi < 30)   return "Overweight";
    return "Obese";
  }
  Color get _bmiColor {
    if (_bmi < 18.5) return Colors.blue;
    if (_bmi < 25)   return Colors.green;
    if (_bmi < 30)   return Colors.orange;
    return Colors.red;
  }

  // ── Badge definitions ─────────────────────────────────────────
  List<Map<String, dynamic>> get _badges => [
    {"icon": Icons.local_fire_department, "color": Colors.orange,    "unlocked": (_progress?.streak ?? 0) >= 3},
    {"icon": Icons.bar_chart,             "color": Colors.indigo,    "unlocked": (_progress?.xp ?? 0) > 0},
    {"icon": Icons.person,                "color": Colors.teal,      "unlocked": true},
    {"icon": Icons.home,                  "color": Colors.brown,     "unlocked": (_progress?.xp ?? 0) >= 50},
    {"icon": Icons.star,                  "color": Colors.amber,     "unlocked": (_progress?.level ?? 1) >= 2},
    {"icon": Icons.fitness_center,        "color": Colors.purple,    "unlocked": (_progress?.xp ?? 0) >= 100},
    {"icon": Icons.local_fire_department, "color": Colors.deepOrange,"unlocked": (_progress?.streak ?? 0) >= 7},
    {"icon": Icons.local_fire_department, "color": Colors.red,       "unlocked": (_progress?.streak ?? 0) >= 14},
  ];

  // ════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ════════════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    if (SupabaseService.instance.isReady) {
      _currentUser = SupabaseService.instance.client.auth.currentUser;
      _authSub = SupabaseService.instance.client.auth.onAuthStateChange.listen((e) {
        if (!mounted) return;
        setState(() => _currentUser = e.session?.user);
        _loadAll();
      });
    }
    _loadAll();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (_currentUser == null) { setState(() => _progress = null); return; }
    setState(() => _loading = true);
    try {
      final p = await SupabaseService.instance.loadUserProgress();
      final body = await _loadBodyData();
      if (mounted) {
        setState(() {
          _progress = p;
          if (body != null) {
            _height = (body['height'] as num?)?.toDouble() ?? 170;
            _weight = (body['weight'] as num?)?.toDouble() ?? 70;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Load body data from supabase user_profiles table ─────────
  Future<Map<String, dynamic>?> _loadBodyData() async {
    if (!SupabaseService.instance.isReady) return null;
    final uid = _currentUser?.id;
    if (uid == null) return null;
    try {
      final res = await SupabaseService.instance.client
          .from('user_profiles')
          .select('height, weight')
          .eq('user_id', uid)
          .maybeSingle();
      return res;
    } catch (e) {
      debugPrint('loadBodyData error: $e');
      return null;
    }
  }

  // ── Save height + weight to supabase ─────────────────────────
  Future<void> _saveBodyData() async {
    if (!SupabaseService.instance.isReady) { _snack("ไม่ได้เชื่อมต่อ Supabase", Colors.orange); return; }
    final uid = _currentUser?.id;
    if (uid == null) return;
    setState(() => _savingBody = true);
    try {
      await SupabaseService.instance.client.from('user_profiles').upsert({
        'user_id': uid,
        'height': _height.round(),
        'weight': _weight.round(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
      _snack("✅ บันทึกข้อมูลร่างกายแล้ว", Colors.green);
    } catch (e) {
      _snack("❌ บันทึกไม่สำเร็จ: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _savingBody = false);
    }
  }

  // ════════════════════════════════════════════════════════════
  //  AUTH
  // ════════════════════════════════════════════════════════════
  Future<void> _submitAuth() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirm = _confirmPasswordCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _snack("⚠️ กรุณากรอกข้อมูลให้ครบ", Colors.orange); return;
    }
    if (password.length < 6) {
      _snack("⚠️ รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร", Colors.orange); return;
    }
    if (!_isLoginMode && password != confirm) {
      _snack("⚠️ รหัสผ่านไม่ตรงกัน", Colors.orange); return;
    }

    // แก้ไข lint warning: ถอดปีกกาป้องคลุมตัวแปรเดี่ยวออก
    final safeUsername = username.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '').toLowerCase();
    final fakeEmail = "$safeUsername@app.healthtracker.com";

    setState(() => _loading = true);
    try {
      if (_isLoginMode) {
        // แก้ไขคอมไพล์เออร์เรอร์: เปลี่ยน authEmail -> fakeEmail
        await SupabaseService.instance.client.auth.signInWithPassword(
          email: fakeEmail, password: password,
        );
        _snack("🎉 เข้าสู่ระบบสำเร็จ!", Colors.green);
      } else {
        // เช็คว่า username ซ้ำหรือยัง
        final existing = await SupabaseService.instance.client
            .from('user_profiles')
            .select('username')
            .eq('username', username)
            .maybeSingle();
        if (existing != null) {
          _snack("⚠️ ชื่อผู้ใช้นี้ถูกใช้แล้ว กรุณาเลือกชื่ออื่น", Colors.orange);
          setState(() => _loading = false);
          return;
        }

        final res = await SupabaseService.instance.client.auth.signUp(
          email: fakeEmail,
          password: password,
          data: {'username': username}, 
        );

        final uid = res.user?.id;
        if (uid != null) {
          await SupabaseService.instance.client.from('user_profiles').upsert({
            'user_id': uid,
            'username': username,
            'email': fakeEmail, // แก้ไขคอมไพล์เออร์เรอร์: เปลี่ยน email -> fakeEmail
            'height': 170,
            'weight': 70,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id');
          _snack("✅ สมัครสำเร็จ! กรุณาเข้าสู่ระบบ", Colors.green);
          setState(() {
            _isLoginMode = true;
            _usernameCtrl.clear();
            _emailCtrl.clear();
            _passwordCtrl.clear();
            _confirmPasswordCtrl.clear();
          });
        } else {
          _snack("⚠️ สมัครสำเร็จแล้ว กรุณาเข้าสู่ระบบ", Colors.teal);
          setState(() => _isLoginMode = true);
        }
      }
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') || msg.contains('already exists')) {
        _snack("⚠️ ชื่อผู้ใช้นี้มีบัญชีอยู่แล้ว กรุณาเข้าสู่ระบบ", Colors.orange);
      } else if (msg.contains('invalid') || msg.contains('password')) {
        _snack("⚠️ username หรือ password ไม่ถูกต้อง", Colors.orange);
      } else {
        _snack("❌ ${e.message}", Colors.red);
      }
    } catch (e) {
      _snack("❌ เกิดข้อผิดพลาด: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _loading = true);
    try {
      await SupabaseService.instance.client.auth.signOut();
      _snack("🚪 ออกจากระบบแล้ว", Colors.teal);
    } catch (e) {
      _snack("❌ $e", Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_loading && _currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _currentUser == null ? _buildAuthScreen() : _buildProfileScreen();
  }

  // ──────────────────────────────────────────────────────────────
  //  AUTH SCREEN
  // ──────────────────────────────────────────────────────────────
  Widget _buildAuthScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildWaveHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLoginMode ? "Login here" : "Create Account",
                      style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold,
                        color: Color(0xFF2C4BE2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isLoginMode
                          ? "ยินดีต้อนรับกลับ! ใส่ชื่อผู้ใช้และรหัสผ่าน"
                          : "สร้างบัญชีเพื่อบันทึกข้อมูลบนคลาวด์",
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                    const SizedBox(height: 28),

                    // Username
                    _field(
                      ctrl: _usernameCtrl,
                      hint: "Username",
                      icon: Icons.person_outline,
                      obscure: false,
                    ),
                    const SizedBox(height: 14),

                    // Email (register only)
                    if (!_isLoginMode) ...[
                      const SizedBox(height: 14),
                      _field(
                        ctrl: _emailCtrl,
                        hint: "Email",
                        icon: Icons.email_outlined,
                        obscure: false,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],

                    // Password
                    const SizedBox(height: 14),
                    _field(
                      ctrl: _passwordCtrl,
                      hint: "Password",
                      icon: Icons.lock_outline,
                      obscure: _obscure,
                      suffix: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[400], size: 20),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),

                    // Register-only: Confirm Password
                    if (!_isLoginMode) ...[
                      const SizedBox(height: 14),
                      _field(
                        ctrl: _confirmPasswordCtrl,
                        hint: "Confirm Password",
                        icon: Icons.lock_outline,
                        obscure: _obscureConfirm,
                        suffix: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[400], size: 20,
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submitAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C4BE2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                        ),
                        child: _loading
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Text(
                                _isLoginMode ? "Sign in" : "Sign up",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isLoginMode = !_isLoginMode;
                          _usernameCtrl.clear();
                          _emailCtrl.clear();
                          _passwordCtrl.clear();
                          _confirmPasswordCtrl.clear();
                        }),
                        child: Text(
                          _isLoginMode ? "Create new account" : "I already have an account",
                          style: const TextStyle(
                            color: Color(0xFF2C4BE2), fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaveHeader() {
    return Stack(children: [
      ClipPath(
        clipper: _WaveClipper(),
        child: Container(height: 180, color: const Color(0xFF2C4BE2)),
      ),
      Positioned(
        bottom: 0, left: 0, right: 0,
        child: ClipPath(
          clipper: _WaveClipper2(),
          child: Container(height: 160, color: const Color(0xFF2C4BE2).withValues(alpha: 0.3)),
        ),
      ),
    ]);
  }

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    required bool obscure,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
          suffixIcon: suffix,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  PROFILE SCREEN
  // ──────────────────────────────────────────────────────────────
  Widget _buildProfileScreen() {
    final email   = _currentUser?.email ?? "";
    final username = email.contains("@healthapp.local")
        ? email.split("@").first
        : email.split("@").first;
    final initial = username.isNotEmpty ? username[0].toUpperCase() : "U";
    final lvl     = _progress?.level ?? 1;
    final xpPct   = ((_progress?.xp ?? 0) % 100) / 100.0;
    final streak  = _progress?.streak ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text("โปรไฟล์",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFFF4F6FB),
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _loading ? null : _signOut,
            icon: const Icon(Icons.logout, size: 16, color: Colors.redAccent),
            label: const Text("ออก",
                style: TextStyle(color: Colors.redAccent, fontSize: 13)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Profile header ──────────────────────────────────
          Row(children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFF2C4BE2),
              child: Text(initial,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Mr.$username",
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              Text("Level $lvl",
                  style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: xpPct, minHeight: 7,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF2C4BE2)),
                ),
              ),
            ])),
            const SizedBox(width: 12),
            Column(children: [
              Text("$streak วัน",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Icon(Icons.local_fire_department, color: Colors.orange, size: 22),
            ]),
          ]),

          const SizedBox(height: 22),

          // ── Badges ──────────────────────────────────────────
          const Text("Badge ที่ได้รับ",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10, crossAxisSpacing: 10,
            children: _badges.map((b) {
              final unlocked = b["unlocked"] as bool;
              return Container(
                decoration: BoxDecoration(
                  color: unlocked ? Colors.white : Colors.grey[100],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: unlocked
                        ? (b["color"] as Color).withValues(alpha: 0.3)
                        : Colors.grey[300]!,
                    width: 1.5,
                  ),
                  boxShadow: unlocked
                      ? [BoxShadow(color: (b["color"] as Color).withValues(alpha: 0.12),
                          blurRadius: 6)]
                      : [],
                ),
                child: Icon(b["icon"] as IconData, size: 26,
                    color: unlocked ? (b["color"] as Color) : Colors.grey[300]),
              );
            }).toList(),
          ),

          const SizedBox(height: 22),

          // ── BMI Card ─────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            padding: const EdgeInsets.all(18),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Height slider
                _buildSlider(
                  label: "Height",
                  value: _height,
                  min: 100, max: 220,
                  displayText: "${_height.round()} cm",
                  chipColor: const Color(0xFFFFE0A3),
                  onChanged: (v) => setState(() => _height = v),
                ),
                const SizedBox(height: 12),

                // Weight slider
                _buildSlider(
                  label: "Weight",
                  value: _weight,
                  min: 30, max: 180,
                  displayText: "${_weight.round()} kg",
                  chipColor: const Color(0xFFB3F0D9),
                  onChanged: (v) => setState(() => _weight = v),
                ),

                const SizedBox(height: 16),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: _savingBody ? null : _saveBodyData,
                    icon: _savingBody
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded, size: 16),
                    label: const Text("บันทึกส่วนสูง / น้ำหนัก",
                        style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C4BE2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // BMI label
                const Text("BMI Calculator",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),

                // BMI result dark card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("Body Mass Index (BMI)",
                        style: TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 6),
                    Row(children: [
                      Text(_bmi.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white,
                              fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _bmiColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_bmiLabel,
                            style: const TextStyle(color: Colors.white,
                                fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(height: 8,
                        child: Row(children: [
                          Expanded(child: Container(color: Colors.blue)),
                          Expanded(child: Container(color: Colors.green)),
                          Expanded(child: Container(color: Colors.orange)),
                          Expanded(child: Container(color: Colors.red)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("15",  style: TextStyle(color: Colors.white54, fontSize: 9)),
                        Text("18.5",style: TextStyle(color: Colors.white54, fontSize: 9)),
                        Text("25",  style: TextStyle(color: Colors.white54, fontSize: 9)),
                        Text("30",  style: TextStyle(color: Colors.white54, fontSize: 9)),
                        Text("40+", style: TextStyle(color: Colors.white54, fontSize: 9)),
                      ],
                    ),
                  ]),
                ),
              ])),

              const SizedBox(width: 16),
              // Body illustration
              SizedBox(width: 76, height: 220,
                  child: CustomPaint(painter: _BodyPainter())),
            ]),
          ),

          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String displayText,
    required Color chipColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: chipColor, borderRadius: BorderRadius.circular(8)),
          child: Text(displayText,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const Spacer(),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ]),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          trackHeight: 4,
          activeTrackColor: const Color(0xFF2C4BE2),
          inactiveTrackColor: Colors.grey[200],
          thumbColor: Colors.white,
          overlayColor: const Color(0xFF2C4BE2).withValues(alpha: 0.15),
        ),
        child: Slider(value: value, min: min, max: max, onChanged: onChanged),
      ),
    ]);
  }
}

// ── Wave clippers ────────────────────────────────────────────────
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final p = Path();
    p.lineTo(0, s.height - 40);
    p.quadraticBezierTo(s.width * .25, s.height, s.width * .5, s.height - 20);
    p.quadraticBezierTo(s.width * .75, s.height - 40, s.width, s.height - 10);
    p.lineTo(s.width, 0);
    p.close();
    return p;
  }
  @override bool shouldReclip(_) => false;
}

class _WaveClipper2 extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final p = Path();
    p.moveTo(0, s.height * .4);
    p.quadraticBezierTo(s.width * .3, 0, s.width * .6, s.height * .3);
    p.quadraticBezierTo(s.width * .85, s.height * .55, s.width, s.height * .2);
    p.lineTo(s.width, s.height);
    p.lineTo(0, s.height);
    p.close();
    return p;
  }
  @override bool shouldReclip(_) => false;
}

// ── Body silhouette CustomPainter ────────────────────────────────
class _BodyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final skin  = Paint()..color = const Color(0xFFE8D5C0)..style = PaintingStyle.fill;
    final shirt = Paint()..color = const Color(0xFFD6E4F7)..style = PaintingStyle.fill;
    final shoe  = Paint()..color = const Color(0xFF222222)..style = PaintingStyle.fill;
    final cx = size.width / 2;

    // Head
    canvas.drawCircle(Offset(cx, 16), 14, skin);
    // Neck
    canvas.drawRect(Rect.fromLTWH(cx - 5, 28, 10, 10), skin);
    // Torso
    _draw(canvas, skin, [Offset(cx-18,38),Offset(cx+18,38),Offset(cx+14,110),Offset(cx-14,110)]);
    // Arms
    _draw(canvas, skin, [Offset(cx-18,40),Offset(cx-30,42),Offset(cx-26,90),Offset(cx-16,88)]);
    _draw(canvas, skin, [Offset(cx+18,40),Offset(cx+30,42),Offset(cx+26,90),Offset(cx+16,88)]);
    // Legs
    _draw(canvas, skin, [Offset(cx-14,110),Offset(cx-2,110),Offset(cx-4,180),Offset(cx-16,178)]);
    _draw(canvas, skin, [Offset(cx+14,110),Offset(cx+2,110),Offset(cx+4,180),Offset(cx+16,178)]);
    // Shirt overlay
    _draw(canvas, shirt, [Offset(cx-18,38),Offset(cx+18,38),Offset(cx+13,85),Offset(cx-13,85)]);
    // Shoes
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx-18,176,16,8), const Radius.circular(4)), shoe);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx+2,176,16,8),  const Radius.circular(4)), shoe);
  }

  void _draw(Canvas c, Paint p, List<Offset> pts) {
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    path.close();
    c.drawPath(path, p);
  }

  @override bool shouldRepaint(_) => false;
}