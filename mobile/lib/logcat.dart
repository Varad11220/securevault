import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> with SingleTickerProviderStateMixin {
  List<dynamic> logs = [];
  bool isLoading = true;
  String errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _fetchLogs();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final response = await http.get(
        Uri.parse('https://securevault-743s.onrender.com/api/auth/logs'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            logs = data['logs'] ?? [];
            isLoading = false;
          });
          _animationController.forward();
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Failed to fetch logs';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error connecting to server: $e';
        isLoading = false;
      });
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final DateTime dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dt);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return timestamp;
    }
  }

  String _formatFullDate(String timestamp) {
    try {
      final DateTime dt = DateTime.parse(timestamp);
      return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF334155).withOpacity(0.5),
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFFF1F5F9)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Login Logs',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF1F5F9),
                            ),
                          ),
                          Text(
                            '${logs.length} ${logs.length == 1 ? 'entry' : 'entries'}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Refresh Button
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF334155).withOpacity(0.5),
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.refresh, color: Color(0xFF06B6D4)),
                        onPressed: _fetchLogs,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1E40AF), Color(0xFF06B6D4)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF06B6D4).withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.history,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // const SizedBox(
                            //   width: 40,
                            //   height: 40,
                            //   child: CircularProgressIndicator(
                            //     strokeWidth: 3,
                            //     valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF06B6D4)),
                            //   ),
                            // ),
                            // const SizedBox(height: 16),
                            const Text(
                              'Loading login history...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      )
                    : errorMessage.isNotEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFEF4444).withOpacity(0.1),
                                      border: Border.all(
                                        color: const Color(0xFFEF4444).withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    errorMessage,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: _fetchLogs,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E40AF),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : logs.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF334155).withOpacity(0.3),
                                      ),
                                      child: const Icon(
                                        Icons.inbox_outlined,
                                        size: 48,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    const Text(
                                      'No login logs yet',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFF1F5F9),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Your login history will appear here',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : FadeTransition(
                                opacity: _fadeAnimation,
                                child: RefreshIndicator(
                                  onRefresh: _fetchLogs,
                                  color: const Color(0xFF06B6D4),
                                  backgroundColor: const Color(0xFF1E293B),
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    itemCount: logs.length,
                                    itemBuilder: (context, index) {
                                      final log = logs[index];
                                      final timestamp = log['timestamp'] ?? '';
                                      final ipAddress = log['ip_address'] ?? 'Unknown';
                                      final userAgent = log['user_agent'] ?? 'Unknown device';
                                      final isSuccessful = log['success'] ?? true;

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E293B).withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFF334155).withOpacity(0.5),
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Status Icon
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: isSuccessful
                                                    ? const Color(0xFF10B981).withOpacity(0.1)
                                                    : const Color(0xFFEF4444).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: isSuccessful
                                                      ? const Color(0xFF10B981).withOpacity(0.3)
                                                      : const Color(0xFFEF4444).withOpacity(0.3),
                                                ),
                                              ),
                                              child: Icon(
                                                isSuccessful
                                                    ? Icons.check_circle_outline
                                                    : Icons.error_outline,
                                                color: isSuccessful
                                                    ? const Color(0xFF10B981)
                                                    : const Color(0xFFEF4444),
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 16),

                                            // Log Details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        isSuccessful
                                                            ? 'Successful Login'
                                                            : 'Failed Login',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                          color: Color(0xFFF1F5F9),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFF0F172A)
                                                              .withOpacity(0.5),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          _formatTimestamp(timestamp),
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color: Color(0xFF94A3B8),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.access_time,
                                                        size: 14,
                                                        color: Color(0xFF94A3B8),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        _formatFullDate(timestamp),
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          color: Color(0xFF94A3B8),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.location_on_outlined,
                                                        size: 14,
                                                        color: Color(0xFF94A3B8),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          ipAddress,
                                                          style: const TextStyle(
                                                            fontSize: 13,
                                                            color: Color(0xFF94A3B8),
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.devices_outlined,
                                                        size: 14,
                                                        color: Color(0xFF94A3B8),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          userAgent,
                                                          style: const TextStyle(
                                                            fontSize: 13,
                                                            color: Color(0xFF94A3B8),
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                          softWrap: true,
                                                          maxLines: 1,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
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