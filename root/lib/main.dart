import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'config.dart';

// ─────────────────────────────────────────────────────────────
//  Design tokens — monochromatic dark, accent-sparing
// ─────────────────────────────────────────────────────────────
class RC {
  static const bg       = Color(0xFF131313);
  static const surface  = Color(0xFF1A1A1A);
  static const navBg    = Color(0xFF161616);
  static const navPill  = Color(0xFF242424);
  static const border   = Color(0xFF252525);
  static const borderLo = Color(0xFF1D1D1D);
  static const green    = Color(0xFF52D470);
  static const amber    = Color(0xFFE8A820);
  static const red      = Color(0xFFCF5050);
  static const orange   = Color(0xFFC87E28);
  static const textHi   = Color(0xFFD8D8D8);
  static const textMid  = Color(0xFF525252);
  static const textLo   = Color(0xFF323232);
}

// ─────────────────────────────────────────────────────────────
//  App root
// ─────────────────────────────────────────────────────────────
void main() => runApp(const RootApp());

class RootApp extends StatelessWidget {
  const RootApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: RC.bg,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      home: const MainShell(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Shell — tab manager
// ─────────────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RC.bg,
      body: IndexedStack(
        index: _tab,
        children: const [DevicePage(), ProfilePage()],
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: RC.navBg,
        border: Border(top: BorderSide(color: RC.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 10, 32, 8),
          child: Row(
            children: [
              _navItem(0, Icons.hub_outlined,           Icons.hub,           'Device'),
              _navItem(1, Icons.local_florist_outlined, Icons.local_florist, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, IconData activeIcon, String label) {
    final sel = _tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = idx),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? RC.navPill : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(sel ? activeIcon : icon, size: 21,
                   color: sel ? RC.textHi : RC.textMid),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: sel ? RC.textHi : RC.textMid,
                  fontWeight: sel ? FontWeight.w500 : FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Device page
// ─────────────────────────────────────────────────────────────
class DevicePage extends StatefulWidget {
  const DevicePage({super.key});
  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> with TickerProviderStateMixin {
  int    _moisture = 0;
  int    _light    = 0;
  int    _battery  = 0; // Battery state added
  bool   _online   = false;
  bool   _loading  = true;
  Timer? _timer;

  late AnimationController _moistCtrl;
  late AnimationController _lightCtrl;
  late Animation<double>   _moistAnim;
  late Animation<double>   _lightAnim;
  double _prevMoist = 0;
  double _prevLight = 0;

  @override
  void initState() {
    super.initState();
    _moistCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _lightCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _moistAnim = const AlwaysStoppedAnimation(0);
    _lightAnim = const AlwaysStoppedAnimation(0);
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchData());
  }

  Future<void> _fetchData() async {
    try {
      final res = await http.get(Uri.parse(Config.esp32Url))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data  = json.decode(res.body);
        final moist = (data['moisture'] as num).toDouble();
        final light = (data['light']    as num).toDouble();
        final batt  = (data['battery'] as num?)?.toInt() ?? 0; // Safely parse battery
        final lProg = (light / 5000).clamp(0.0, 1.0);

        _moistAnim = Tween<double>(begin: _prevMoist / 100, end: moist / 100)
            .animate(CurvedAnimation(parent: _moistCtrl, curve: Curves.easeOutCubic));
        _lightAnim = Tween<double>(begin: _prevLight, end: lProg)
            .animate(CurvedAnimation(parent: _lightCtrl, curve: Curves.easeOutCubic));

        _moistCtrl.forward(from: 0);
        _lightCtrl.forward(from: 0);
        _prevMoist = moist;
        _prevLight = lProg;

        setState(() {
          _moisture = moist.toInt();
          _light    = light.toInt();
          _battery  = batt;
          _online   = true;
          _loading  = false;
        });
      }
    } catch (_) {
      setState(() { _online = false; _loading = false; });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _moistCtrl.dispose();
    _lightCtrl.dispose();
    super.dispose();
  }

  Color _moistColor() {
    if (_moisture < 25) return RC.red;
    if (_moisture < 40) return RC.orange;
    return RC.green;
  }

  String _moistLabel() {
    if (_moisture < 25) return "critically dry";
    if (_moisture < 40) return "getting dry";
    if (_moisture < 70) return "healthy";
    if (_moisture < 85) return "moist";
    return "overwatered";
  }

  String _lightLabel() {
    if (_light <= 1000)   return "Dark";
    if (_light <= 5000)   return "Low light";
    if (_light <= 10000)  return "Medium light";
    if (_light <= 250000) return "Bright indirect";
    return "Direct sunlight";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RC.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          color: RC.green,
          backgroundColor: RC.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    _buildTopBar(),
                    const Spacer(),
                    _buildCirclesArea(),
                    const Spacer(),
                    _buildReadouts(),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final dotColor = _loading ? RC.textLo : (_online ? RC.green : RC.red);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Root',
            style: TextStyle(
              fontSize: 23,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w300,
              color: RC.textHi,
              letterSpacing: 0.5,
            ),
          ),
          Row(
            children: [
              // --- Battery UI added here ---
              if (_online && !_loading) ...[
                Icon(
                  Icons.battery_4_bar, 
                  size: 14, 
                  color: _battery < 20 ? RC.red : RC.textMid
                ),
                const SizedBox(width: 4),
                Text(
                  '$_battery%',
                  style: TextStyle(
                    fontSize: 11, 
                    color: _battery < 20 ? RC.red : RC.textMid, 
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                _loading ? 'scanning' : (_online ? 'online' : 'offline'),
                style: const TextStyle(
                  fontSize: 11, color: RC.textMid, letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCirclesArea() {
    return AnimatedBuilder(
      animation: Listenable.merge([_moistAnim, _lightAnim]),
      builder: (_, __) => SizedBox(
        width: 300, height: 300,
        child: CustomPaint(
          painter: ConcentricGaugePainter(
            moistProgress: _moistAnim.value,
            lightProgress: _lightAnim.value,
            moistColor:    _moistColor(),
            online:        _online,
            loading:       _loading,
          ),
          child: Center(child: _centerContent()),
        ),
      ),
    );
  }

  Widget _centerContent() {
    if (_loading) {
      return const Text(
        'Connecting…',
        style: TextStyle(fontSize: 13, color: RC.textMid, letterSpacing: 0.5),
      );
    }
    if (!_online) {
      return const Text(
        'No sensor found, pull\ndown to refresh',
        style: TextStyle(
          fontSize: 13, color: RC.textMid, height: 1.8, letterSpacing: 0.2,
        ),
        textAlign: TextAlign.center,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$_moisture',
          style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w200,
            color: _moistColor(),
            height: 1.0,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '% moisture',
          style: TextStyle(
            fontSize: 10, color: RC.textMid, letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _moistLabel(),
          style: TextStyle(
            fontSize: 11,
            color: _moistColor().withOpacity(0.55),
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildReadouts() {
    if (!_online || _loading) return const SizedBox.shrink();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wb_sunny_outlined, size: 13, color: RC.textMid),
            const SizedBox(width: 8),
            Text(
              _light >= 1000
                  ? '${(_light / 1000).toStringAsFixed(1)}k lux'
                  : '$_light lux',
              style: const TextStyle(fontSize: 13, color: RC.textMid, letterSpacing: 0.3),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(width: 1, height: 10, color: RC.border),
            ),
            Text(
              _lightLabel(),
              style: const TextStyle(fontSize: 13, color: RC.textMid),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 44),
          child: Container(height: 0.5, color: RC.border),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _metaChip('XIAO C3'),
            const SizedBox(width: 28),
            _metaChip('RISC-V'),
            const SizedBox(width: 28),
            _metaChip('2 s poll'),
          ],
        ),
      ],
    );
  }

  Widget _metaChip(String label) => Text(
    label,
    style: const TextStyle(fontSize: 10, color: RC.textLo, letterSpacing: 1.0),
  );
}

// ─────────────────────────────────────────────────────────────
//  Concentric gauge painter
//  · outer ring  → ambient light arc (amber, 1px)
//  · middle ring → moisture arc (colored, glow halo + end dot)
//  · inner ring  → decorative border only
// ─────────────────────────────────────────────────────────────
class ConcentricGaugePainter extends CustomPainter {
  final double moistProgress;
  final double lightProgress;
  final Color  moistColor;
  final bool   online;
  final bool   loading;

  ConcentricGaugePainter({
    required this.moistProgress,
    required this.lightProgress,
    required this.moistColor,
    required this.online,
    required this.loading,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c      = Offset(size.width / 2, size.height / 2);
    final outerR = size.width * 0.47;
    final midR   = size.width * 0.33;
    final innerR = size.width * 0.20;

    final track = Paint()
      ..color      = RC.border
      ..style      = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.drawCircle(c, outerR, track);
    canvas.drawCircle(c, midR,   track);
    canvas.drawCircle(c, innerR, track);

    if (!online || loading) return;

    const startAngle = -math.pi / 2;

    // Moisture arc — middle ring
    if (moistProgress > 0.005) {
      final sweep = 2 * math.pi * moistProgress;
      // Glow
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: midR),
        startAngle, sweep, false,
        Paint()
          ..color       = moistColor.withOpacity(0.10)
          ..style       = PaintingStyle.stroke
          ..strokeWidth = 16
          ..strokeCap   = StrokeCap.round
          ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      // Arc
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: midR),
        startAngle, sweep, false,
        Paint()
          ..color       = moistColor
          ..style       = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap   = StrokeCap.round,
      );
      // End dot
      final endAngle = startAngle + sweep;
      final dx = c.dx + midR * math.cos(endAngle);
      final dy = c.dy + midR * math.sin(endAngle);
      canvas.drawCircle(Offset(dx, dy), 3, Paint()..color = moistColor);
    }

    // Light arc — outer ring
    if (lightProgress > 0.005) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: outerR),
        startAngle,
        2 * math.pi * lightProgress,
        false,
        Paint()
          ..color       = RC.amber.withOpacity(0.40)
          ..style       = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..strokeCap   = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(ConcentricGaugePainter old) =>
    old.moistProgress != moistProgress ||
    old.lightProgress != lightProgress ||
    old.moistColor    != moistColor    ||
    old.online        != online;
}

// ─────────────────────────────────────────────────────────────
//  Profile page
// ─────────────────────────────────────────────────────────────
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RC.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 23,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w300,
                      color: RC.textHi,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Icon(Icons.edit_outlined, size: 18, color: RC.textMid),
                ],
              ),
              const SizedBox(height: 44),

              // Avatar
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: RC.surface,
                        border: Border.all(color: RC.border, width: 0.5),
                      ),
                      child: const Icon(Icons.local_florist_outlined, size: 34, color: RC.textMid),
                    ),
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: RC.navPill,
                          border: Border.all(color: RC.border, width: 0.5),
                        ),
                        child: const Icon(Icons.camera_alt_outlined, size: 13, color: RC.textMid),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Name
              const Center(
                child: Text(
                  'My Plant',
                  style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w300,
                    color: RC.textHi, letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              const Center(
                child: Text(
                  'Unknown species',
                  style: TextStyle(fontSize: 12, color: RC.textMid, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 36),

              // Stats
              const Row(
                children: [
                  _StatCard(label: 'AVG MOISTURE', value: '—', unit: '%'),
                  SizedBox(width: 10),
                  _StatCard(label: 'LIGHT LEVEL',  value: '—', unit: 'lux'),
                  SizedBox(width: 10),
                  _StatCard(label: 'DAYS TRACKED', value: '—', unit: 'days'),
                ],
              ),
              const SizedBox(height: 32),
              _divider(),
              const SizedBox(height: 28),

              // Care schedule
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'CARE SCHEDULE',
                    style: TextStyle(
                      fontSize: 9, letterSpacing: 2.2,
                      color: RC.textMid, fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text('Set up', style: TextStyle(fontSize: 11, color: RC.textMid)),
                ],
              ),
              const SizedBox(height: 18),
              const _CareRow(icon: Icons.water_drop_outlined, label: 'Watering',    value: 'Not configured'),
              const SizedBox(height: 14),
              const _CareRow(icon: Icons.wb_sunny_outlined,   label: 'Light',       value: 'Not configured'),
              const SizedBox(height: 14),
              const _CareRow(icon: Icons.thermostat_outlined, label: 'Temperature', value: 'Not configured'),
              const SizedBox(height: 32),
              _divider(),
              const SizedBox(height: 28),

              // Notes
              const Text(
                'NOTES',
                style: TextStyle(
                  fontSize: 9, letterSpacing: 2.2,
                  color: RC.textMid, fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: RC.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: RC.border, width: 0.5),
                ),
                child: const Text(
                  'Add notes about your plant…',
                  style: TextStyle(fontSize: 13, color: RC.textLo, height: 1.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _divider() => Container(height: 0.5, color: RC.border);
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _StatCard({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: BoxDecoration(
          color: RC.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: RC.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
              style: const TextStyle(
                fontSize: 7, letterSpacing: 1.5,
                color: RC.textMid, fontWeight: FontWeight.w600,
              )),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value,
                  style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w200,
                    color: RC.textHi, height: 1.0,
                  )),
                const SizedBox(width: 3),
                Text(unit, style: const TextStyle(fontSize: 9, color: RC.textMid)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CareRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _CareRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: RC.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: RC.border, width: 0.5),
          ),
          child: Icon(icon, size: 16, color: RC.textMid),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w400, color: RC.textHi,
                )),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 11, color: RC.textMid)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, size: 16, color: RC.textLo),
      ],
    );
  }
}