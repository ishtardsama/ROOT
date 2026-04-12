import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'config.dart';

void main() => runApp(const RootApp());

class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E0A),
        primaryColor: const Color(0xFF4CAF50),
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

class _DashboardState extends State<Dashboard> {
  int _moisture = 0;
  int _light = 0;
  String _status = "Scanning...";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 5), (t) => _fetchData());
  }

  String _getLightStatus(int lux) {
    if (lux <= 500) return "Dark";
    if (lux <= 5000) return "Low-Light";
    if (lux <= 25000) return "Bright Indirect";
    return "Extremely Bright";
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(Uri.parse(Config.esp32Url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _moisture = data['moisture'];
          _light = data['light'];
          _status = "Online";
        });
      }
    } catch (e) {
      setState(() { _status = "Offline"; });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("ROOT", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4)),
              Text(_status, style: TextStyle(color: _status == "Online" ? Colors.green : Colors.red)),
              const SizedBox(height: 40),
              _buildCard("SOIL MOISTURE", "$_moisture%", _moisture / 100, Colors.greenAccent),
              const SizedBox(height: 20),
              _buildCard(
                "LIGHT LEVEL", 
                _getLightStatus(_light), 
                (_light / 5000).clamp(0.0, 1.0), 
                Colors.amberAccent,
                detail: "$_light lx"
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, String value, double progress, Color color, {String detail = ""}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, letterSpacing: 2, fontSize: 11)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w200)),
          if (detail.isNotEmpty) Text(detail, style: TextStyle(color: color.withOpacity(0.6), fontSize: 14)),
          const SizedBox(height: 20),
          LinearProgressIndicator(value: progress, backgroundColor: Colors.white10, color: color),
        ],
      ),
    );
  }
}