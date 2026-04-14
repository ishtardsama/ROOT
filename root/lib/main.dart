import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'config.dart';

// ─────────────────────────────────────────────────────────────
//  Design tokens
// ─────────────────────────────────────────────────────────────
class RC {
  static const bg          = Color(0xFF040804);
  static const surface     = Color(0xFF090E09);
  static const surfaceHi   = Color(0xFF0E160E);
  static const border      = Color(0xFF152015);
  static const borderHi    = Color(0xFF1C2C1C);
  // Greens
  static const green       = Color(0xFF48E077);
  static const greenDim    = Color(0xFF091A10);
  static const greenGlow   = Color(0xFF48E077);
  // Ambers
  static const amber       = Color(0xFFF5BC28);
  static const amberDim    = Color(0xFF1C1507);
  static const amberGlow   = Color(0xFFF5BC28);
  // Text
  static const textPrimary = Color(0xFFCEEAD2);
  static const textSub     = Color(0xFF355035);
  static const textMuted   = Color(0xFF1A261A);
  // Status
  static const red         = Color(0xFFFF5353);
  static const orange      = Color(0xFFFF9A00);
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

// ─────────────────────────────────────────────────────────────
//  Dashboard
// ─────────────────────────────────────────────────────────────
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
  late AnimationController _pulseCtrl;
  late Animation<double>   _moistAnim;
  late Animation<double>   _lightAnim;
  late Animation<double>   _pulseAnim;
  double _prevMoist = 0;
  double _prevLight = 0;

  @override
  void initState() {
    super.initState();
    _moistCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _lightCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _moistAnim = const AlwaysStoppedAnimation(0);
    _lightAnim = const AlwaysStoppedAnimation(0);
    _pulseAnim = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

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
    _pulseCtrl.dispose();
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
    if (_light <= 1000)   return "Dark";
    if (_light <= 5000)   return "Low Light";
    if (_light <= 10000)  return "Medium Light";
    if (_light <= 250000) return "Bright Indirect";
    return "Direct Sunlight";
  }

  String _insightTitle() {
    if (_loading)       return "Connecting…";
    if (!_online)       return "Sensor unreachable";
    if (_moisture < 25) return "Water your plant soon";
    if (_moisture > 85) return "May be overwatered";
    if (_light < 200)   return "Very low light";
    return "Plant is doing well";
  }

  String _insightBody() {
    if (_loading)       return "Reaching ${Config.esp32Url}";
    if (!_online)       return "Check that the XIAO C3 is powered and connected to WiFi.";
    if (_moisture < 25) return "Moisture at $_moisture% — soil is very dry. Water soon.";
    if (_moisture > 85) return "Moisture at $_moisture% — let the soil dry out before next watering.";
    if (_light < 200)   return "Only $_light lux detected. Move the plant to a brighter spot.";
    return "Moisture $_moisture% · ${_lightLabel()} light. No action needed right now.";
  }

  @override
  Widget build(BuildContext context) {
    final now  = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      body: Stack(
        children: [
          // Subtle top radial glow
          Positioned(
            top: -80, left: -60,
            child: Container(
              width: 320, height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [RC.greenDim.withOpacity(0.6), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(time),
                  const SizedBox(height: 30),
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
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
                  _buildInfoRow(time),
                  const SizedBox(height: 12),
                  _buildInsight(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────
  Widget _buildHeader(String time) {
    final dotColor = _loading ? RC.textSub : (_online ? RC.green : RC.red);
    final pillBg   = _loading
        ? RC.surfaceHi
        : (_online ? RC.greenDim : const Color(0xFF2A0A0A));
    final pillBorder = _loading
        ? RC.border
        : (_online ? const Color(0xFF1A4A28) : const Color(0xFF4A1A1A));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "ROOT",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 6,
                    color: RC.textPrimary,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: RC.greenDim,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: RC.border, width: 0.5),
                  ),
                  child: Text(
                    "v1.0",
                    style: TextStyle(
                      fontSize: 9,
                      color: RC.green.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "plant monitoring",
              style: TextStyle(
                fontSize: 12,
                color: RC.textSub,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        // Status pill with animated pulse dot
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: pillBorder, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_online && !_loading)
                      Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dotColor.withOpacity(_pulseAnim.value * 0.25),
                        ),
                      ),
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _loading ? "Scanning" : (_online ? "Online" : "Offline"),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: dotColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Info row ─────────────────────────────────────────────
  Widget _buildInfoRow(String time) {
    return Row(children: [
      Expanded(child: InfoTile(label: "DEVICE",  value: "XIAO C3", sub: "RISC-V")),
      const SizedBox(width: 10),
      Expanded(child: InfoTile(label: "REFRESH", value: "5s",      sub: "Auto-poll")),
      const SizedBox(width: 10),
      Expanded(child: InfoTile(label: "UPDATED", value: time,      sub: "Local")),
    ]);
  }

  // ── Insight card ─────────────────────────────────────────
  Widget _buildInsight() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RC.border, width: 0.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            RC.greenDim.withOpacity(0.6),
            RC.surface,
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar
              Container(
                width: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      RC.green.withOpacity(0.9),
                      RC.green.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: RC.greenDim,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: RC.border, width: 0.5),
                        ),
                        child: const Icon(Icons.eco_outlined, size: 16, color: RC.green),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _insightTitle(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: RC.textPrimary,
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _insightBody(),
                              style: TextStyle(
                                fontSize: 12,
                                color: RC.textSub,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
//  SensorCard
// ─────────────────────────────────────────────────────────────
class SensorCard extends StatelessWidget {
  final String   label;
  final String   value;
  final String   unit;
  final String   subLabel;
  final double   progress;
  final Color    color;
  final IconData icon;
  final String   detail;
  final String?  badge;
  final Color?   badgeColor;

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
      decoration: BoxDecoration(
        color: RC.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: RC.border, width: 0.5),
        // Colored glow shadow
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.07),
            blurRadius: 28,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 8,
            spreadRadius: -2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Top gradient strip
            Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.0),
                    color.withOpacity(0.7),
                    color.withOpacity(0.0),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Row(
                children: [
                  // Gauge
                  SizedBox(
                    width: 104, height: 104,
                    child: CustomPaint(
                      painter: ArcGaugePainter(progress: progress, color: color),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 13, color: color.withOpacity(0.5)),
                            const SizedBox(height: 3),
                            Text(
                              value,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: color,
                                height: 1.0,
                                fontFamily: 'monospace',
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              unit,
                              style: TextStyle(
                                fontSize: 9,
                                color: color.withOpacity(0.4),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 8,
                            letterSpacing: 2,
                            color: RC.textSub,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subLabel,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                            color: RC.textPrimary,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Stack(
                            children: [
                              Container(height: 3, color: RC.border),
                              FractionallySizedBox(
                                widthFactor: progress.clamp(0.0, 1.0),
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    gradient: LinearGradient(
                                      colors: [
                                        color.withOpacity(0.5),
                                        color,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              detail,
                              style: const TextStyle(
                                fontSize: 10,
                                color: RC.textSub,
                              ),
                            ),
                            if (badge != null) ...[
                              const SizedBox(width: 7),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (badgeColor ?? color).withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: (badgeColor ?? color).withOpacity(0.18),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  badge!,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: (badgeColor ?? color).withOpacity(0.85),
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'monospace',
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
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Arc gauge painter — with glow halo + end dot
// ─────────────────────────────────────────────────────────────
class ArcGaugePainter extends CustomPainter {
  final double progress;
  final Color  color;
  const ArcGaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c      = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.41;
    const start  = math.pi * 0.75;
    const sweep  = math.pi * 1.5;
    final rect   = Rect.fromCircle(center: c, radius: radius);
    final p      = progress.clamp(0.0, 1.0);

    // Track
    canvas.drawArc(
      rect, start, sweep, false,
      Paint()
        ..color      = RC.border
        ..style      = PaintingStyle.stroke
        ..strokeWidth = 5.5
        ..strokeCap  = StrokeCap.round,
    );

    if (p > 0.01) {
      // Glow halo layer
      canvas.drawArc(
        rect, start, sweep * p, false,
        Paint()
          ..color       = color.withOpacity(0.18)
          ..style       = PaintingStyle.stroke
          ..strokeWidth = 13
          ..strokeCap   = StrokeCap.round
          ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // Main arc
      canvas.drawArc(
        rect, start, sweep * p, false,
        Paint()
          ..color      = color
          ..style      = PaintingStyle.stroke
          ..strokeWidth = 5.5
          ..strokeCap  = StrokeCap.round,
      );

      // End dot glow
      final endAngle = start + sweep * p;
      final dotX = c.dx + radius * math.cos(endAngle);
      final dotY = c.dy + radius * math.sin(endAngle);
      canvas.drawCircle(
        Offset(dotX, dotY), 7,
        Paint()
          ..color      = color.withOpacity(0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // End dot solid
      canvas.drawCircle(
        Offset(dotX, dotY), 3.5,
        Paint()..color = color,
      );
      canvas.drawCircle(
        Offset(dotX, dotY), 3.5,
        Paint()
          ..color  = Colors.white.withOpacity(0.3)
          ..style  = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(ArcGaugePainter old) =>
      old.progress != progress || old.color != color;
}

// ─────────────────────────────────────────────────────────────
//  InfoTile
// ─────────────────────────────────────────────────────────────
class InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  const InfoTile({super.key, required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
      decoration: BoxDecoration(
        color: RC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RC.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 7,
              letterSpacing: 1.8,
              color: RC.textSub,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: RC.textPrimary,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 1),
          Text(
            sub,
            style: const TextStyle(fontSize: 9, color: RC.textSub),
          ),
        ],
      ),
    );
  }
}