import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'auth_access.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Checks for login token and decides initial page.
  Future<Widget> _getInitialPage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? username = prefs.getString('username');

    // If no token → go to login
    if (token == null || token.isEmpty) {
      return const LoginPage();
    }

    // Token found → go to Auth Access Page
    return AuthAccessPage(username: username ?? 'User');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<Widget>(
        future: _getInitialPage(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return snapshot.data!;
          }

          return const Scaffold(
            body: Center(child: Text('Error loading app')),
          );
        },
      ),
    );
  }
}