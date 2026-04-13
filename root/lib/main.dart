import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'config.dart';

class RC {
  static const bg          = Color(0xFF080C08);
  static const surface     = Color(0xFF0E140E);
  static const surfaceHi   = Color(0xFF141E14);
  static const border      = Color(0xFF1A2A1A);
  static const green       = Color(0xFF3DDC6B);
  static const greenDim    = Color(0xFF112A1A);
  static const amber       = Color(0xFFFBBF24);
  static const amberDim    = Color(0xFF2E2008);
  static const textPrimary = Color(0xFFDEEEDE);
  static const textSub     = Color(0xFF4E6E4E);
  static const textMuted   = Color(0xFF283828);
  static const red         = Color(0xFFFF5252);
  static const orange      = Color(0xFFFF9800);
}

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
      home: const Dashboard(),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  int    _moisture = 0;
  int    _light    = 0;
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
    _moistCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _lightCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
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
        final data   = json.decode(res.body);
        final moist  = (data['moisture'] as num).toDouble();
        final light  = (data['light']    as num).toDouble();
        final lProg  = (light / 5000).clamp(0.0, 1.0);

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
    if (_moisture < 25) return "Critically dry";
    if (_moisture < 40) return "Getting dry";
    if (_moisture < 70) return "Healthy";
    if (_moisture < 85) return "Moist";
    return "Overwatered";
  }

  String _lightLabel() {
    if (_light <= 1000)  return "Dark";
    if (_light <= 5000) return "Low Light";
    if (_light <= 10000) return "Medium Light";
    if (_light <= 250000) return "Bright Indirect Light";
    return "Direct Sunlight";
  }

  String _insightTitle() {
    if (_loading)          return "Connecting…";
    if (!_online)          return "Sensor unreachable";
    if (_moisture < 25)    return "Water your plant soon";
    if (_moisture > 85)    return "May be overwatered";
    if (_light < 200)      return "Very low light";
    return "Plant is doing well";
  }

  String _insightBody() {
    if (_loading)  return "Reaching ${Config.esp32Url}";
    if (!_online)  return "Check that the XIAO C3 is powered and connected to WiFi.";
    if (_moisture < 25) return "Moisture at $_moisture% — soil is very dry. Water soon.";
    if (_moisture > 85) return "Moisture at $_moisture% — let the soil dry out before next watering.";
    if (_light < 200)   return "Only $_light lux detected. Move the plant to a brighter spot.";
    return "Moisture $_moisture% · ${_lightLabel()} light. No action needed right now.";
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(time),
              const SizedBox(height: 28),
              AnimatedBuilder(
                animation: _moistAnim,
                builder: (_, __) => SensorCard(
                  label:    "SOIL MOISTURE",
                  value:    "$_moisture",
                  unit:     "%",
                  subLabel: _moistLabel(),
                  progress: _moistAnim.value,
                  color:    _moistColor(),
                  icon:     Icons.water_drop_outlined,
                  detail:   "Capacitive · Pin A0",
                ),
              ),
              const SizedBox(height: 14),
              AnimatedBuilder(
                animation: _lightAnim,
                builder: (_, __) => SensorCard(
                  label:    "LIGHT INTENSITY",
                  value:    _light >= 1000
                                ? "${(_light / 1000).toStringAsFixed(1)}k"
                                : "$_light",
                  unit:     "lux",
                  subLabel: _lightLabel(),
                  progress: _lightAnim.value,
                  color:    RC.amber,
                  icon:     Icons.wb_sunny_outlined,
                  detail:   "BH1750 · I²C 0x23",
                  badge:    _light > 0 ? "$_light lx" : null,
                  badgeColor: RC.amber,
                ),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: InfoTile(label: "Device",   value: "XIAO C3",  sub: "RISC-V")),
                const SizedBox(width: 10),
                Expanded(child: InfoTile(label: "Refresh",  value: "5s",       sub: "Auto-poll")),
                const SizedBox(width: 10),
                Expanded(child: InfoTile(label: "Updated",  value: time,       sub: "Local")),
              ]),
              const SizedBox(height: 14),
              _buildInsight(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text(
                "ROOT",
                style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w700,
                  letterSpacing: 5, color: RC.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: RC.greenDim, borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "v1.0",
                  style: TextStyle(fontSize: 10, color: RC.green, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
            const SizedBox(height: 3),
            const Text(
              "Plant monitoring",
              style: TextStyle(fontSize: 13, color: RC.textSub, letterSpacing: 0.2),
            ),
          ],
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: _loading
                ? RC.surfaceHi
                : (_online ? RC.greenDim : const Color(0xFF3D1414)),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _loading
                  ? RC.border
                  : (_online ? const Color(0xFF1F5C35) : const Color(0xFF5D2020)),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: _loading
                      ? RC.textSub
                      : (_online ? RC.green : RC.red),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                _loading ? "Scanning" : (_online ? "Online" : "Offline"),
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500,
                  color: _loading
                      ? RC.textSub
                      : (_online ? RC.green : RC.red),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsight() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: RC.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RC.border, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: RC.greenDim,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.eco_outlined, size: 17, color: RC.green),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _insightTitle(),
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: RC.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _insightBody(),
                  style: const TextStyle(fontSize: 12, color: RC.textSub, height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SensorCard extends StatelessWidget {
  final String  label;
  final String  value;
  final String  unit;
  final String  subLabel;
  final double  progress;
  final Color   color;
  final IconData icon;
  final String  detail;
  final String? badge;
  final Color?  badgeColor;

  const SensorCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.subLabel,
    required this.progress,
    required this.color,
    required this.icon,
    required this.detail,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RC.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: RC.border, width: 0.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 98, height: 98,
            child: CustomPaint(
              painter: ArcGaugePainter(progress: progress, color: color),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: color.withOpacity(0.65)),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 21, fontWeight: FontWeight.w600,
                        color: color, height: 1.1,
                      ),
                    ),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 10, color: color.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9, letterSpacing: 1.5,
                    color: RC.textSub, fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  subLabel,
                  style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w300,
                    color: RC.textPrimary, height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: RC.border,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      detail,
                      style: const TextStyle(fontSize: 10, color: RC.textSub),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (badgeColor ?? color).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            fontSize: 9,
                            color: (badgeColor ?? color).withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ArcGaugePainter extends CustomPainter {
  final double progress;
  final Color  color;
  const ArcGaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c      = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;
    const start  = math.pi * 0.75;
    const sweep  = math.pi * 1.5;
    final rect   = Rect.fromCircle(center: c, radius: radius);

    canvas.drawArc(
      rect, start, sweep, false,
      Paint()
        ..color      = RC.border
        ..style      = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap  = StrokeCap.round,
    );

    if (progress > 0.01) {
      canvas.drawArc(
        rect, start, sweep * progress.clamp(0.0, 1.0), false,
        Paint()
          ..color      = color
          ..style      = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap  = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(ArcGaugePainter old) =>
      old.progress != progress || old.color != color;
}

class InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  const InfoTile({super.key, required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: RC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RC.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, letterSpacing: 1.2, color: RC.textSub)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: RC.textPrimary)),
          Text(sub,   style: const TextStyle(fontSize: 10, color: RC.textSub)),
        ],
      ),
    );
  }
}