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
        scaffoldBackgroundColor: const Color(0xFF0A0E0A), // Deep "Root" Black
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
  bool _isLoading = true;
  String _status = "Scanning...";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) => _fetchData());
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(Uri.parse(Config.esp32Url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _moisture = data['moisture'];
          _status = "Online";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = "Offline - Check Wi-Fi";
        _isLoading = false;
      });
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
              const SizedBox(height: 60),
              
              Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      const Text("SOIL MOISTURE", style: TextStyle(color: Colors.grey, letterSpacing: 2)),
                      const SizedBox(height: 20),
                      Text("$_moisture%", style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w200)),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: _moisture / 100,
                        backgroundColor: Colors.white10,
                        color: Colors.greenAccent,
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