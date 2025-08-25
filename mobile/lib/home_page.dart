import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  String username = '';
  int userId = 0;
  String authCode = '';
  bool isLoading = false;

  Timer? _timer;
  Timer? _countdownTimer;
  int secondsLeft = 30;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? 'Guest';
      userId = prefs.getInt('userId') ?? 0;
    });
    _startAuthCodeCycle();
  }

  void _startAuthCodeCycle() {
    // Calculate ms until next 30-second boundary
    final now = DateTime.now();
    final msUntilNext30Sec = (30 - (now.second % 30)) * 1000 - now.millisecond;

    Future.delayed(Duration(milliseconds: msUntilNext30Sec), () {
      _fetchAuthCode();

      // Start the animation and timers
      _animationController.forward(from: 0);
      _startCountdownTimer();

      // Then periodic fetch every 30 seconds aligned to backend
      _timer = Timer.periodic(const Duration(seconds: 30), (_) {
        _fetchAuthCode();
        _animationController.forward(from: 0);
        secondsLeft = 30;
      });
    });
  }

  void _startCountdownTimer() {
    secondsLeft = 30;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft > 0) {
        setState(() {
          secondsLeft--;
        });
      } else {
        secondsLeft = 30; // reset countdown (safe fallback)
      }
    });
  }

  Future<void> _fetchAuthCode() async {
    setState(() => isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final response = await http.get(
        Uri.parse('http://10.195.179.104:3000/api/auth/code'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            authCode = data['code'] ?? '';
          });
        }
      } else {
        // handle error or logout maybe
      }
    } catch (e) {
      // handle error
    }

    setState(() => isLoading = false);
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double size = 150;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('Welcome $username (ID: $userId)', style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 30),

      if (authCode.isEmpty) ...[
        const CircularProgressIndicator(),
        const SizedBox(height: 10),
        const Text(
          'Please wait, your code is being generated...',
          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ] else ...[
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return CircularProgressIndicator(
                    value: 1 - _animationController.value,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation(Colors.deepPurple),
                  );
                },
              ),
            ),
            Text(
              authCode,
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 5),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text('Next code in: $secondsLeft s', style: const TextStyle(fontSize: 16)),
      ],
    ],
  ),
),

    );
  }
}
