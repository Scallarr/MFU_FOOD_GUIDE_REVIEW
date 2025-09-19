import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/Atlas-model.dart';
import 'package:myapp/Profileinfo.dart';
import 'package:myapp/admin/Admin-Dashboard.dart';
import 'package:myapp/admin/Admin-Home.dart';
import 'package:myapp/admin/Admin-Leaderboard.dart';
import 'package:myapp/admin/Admin-Pending_Thread.dart';
import 'package:myapp/admin/Admin-Thread-Reply.dart';
import 'package:myapp/admin/Admin-myhistoy.dart';
import 'package:myapp/admin/Admin-pendingThreadsReplied.dart';
import 'package:intl/intl.dart';
import 'package:myapp/admin/Admin-profile-info.dart';
import 'package:myapp/admin/Admin_nexus-model.dart';
import 'package:myapp/dashboard.dart';
import 'package:myapp/home.dart';
import 'package:myapp/leaderboard.dart';
import 'package:myapp/login.dart';
import 'package:myapp/thread_reply.dart';
import 'package:myapp/user_history.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThreadsUserPage extends StatefulWidget {
  const ThreadsUserPage({super.key});

  @override
  State<ThreadsUserPage> createState() => _ThreadsAdminPageState();
}

class _ThreadsAdminPageState extends State<ThreadsUserPage> {
  List threads = [];
  int? userId;
  int _selectedIndex = 3;
  final Color _primaryColor = Color(0xFF4285F4);
  final Color _successColor = Color(0xFF34A853);
  final Color _warningColor = Color(0xFFFBBC05);
  final Color _dangerColor = Color(0xFFEA4335);
  final Color _cardColor = Colors.white;
  final Color _textColor = Color(0xFF202124);
  final Color _secondaryTextColor = Color(0xFF5F6368);
  TextEditingController _textController = TextEditingController();
  Map<String, dynamic>? _selectedUser;
  int _pendingRepliedThreadsCount = 0;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool isSending = false;

  String? profileImageUrl;
  int _pendingThreadsCount = 0; // เพิ่มตัวแปรเก็บจำนวน pending threads
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUserID();
    loadUserIdAndFetchProfile();
    fetchPendingThreadsCount();
    fetchPendingRepliedThreadsCount();
  }

  Future<void> fetchPendingThreadsCount() async {
    try {
      final response = await http.get(
        Uri.parse('http://172.22.173.39:8080/threads/pending'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> pendingThreads = json.decode(response.body);
        setState(() {
          _pendingThreadsCount = pendingThreads.length;
        });
      } else {
        print('Failed to fetch pending threads count');
        setState(() {
          _pendingThreadsCount = 0;
        });
      }
    } catch (e) {
      print('Error fetching pending threads count: $e');
      setState(() {
        _pendingThreadsCount = 0;
      });
    }
  }

  Future<void> fetchPendingRepliedThreadsCount() async {
    try {
      final response = await http.get(
        Uri.parse('http://172.22.173.39:8080/threads-replied/pending'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> pendingRepliedThreads = json.decode(response.body);
        setState(() {
          _pendingRepliedThreadsCount = pendingRepliedThreads.length;
        });
      } else {
        print('Failed to fetch pending replied threads count');
        setState(() {
          _pendingRepliedThreadsCount = 0;
        });
      }
    } catch (e) {
      print('Error fetching pending replied threads count: $e');
      setState(() {
        _pendingRepliedThreadsCount = 0;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('user_id');
      print('userId: $userId');
    });
    fetchThreads();
  }

  Future<void> loadUserIdAndFetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getInt('user_id');

    if (storedUserId != null) {
      setState(() {
        userId = storedUserId;
      });

      await fetchProfilePicture(userId!);
    }
  }

  Future<void> fetchProfilePicture(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('http://172.22.173.39:8080/user-profile/$userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          profileImageUrl = data['picture_url'];
          print(profileImageUrl);
        });
      } else {
        print('Failed to load profile picture');
      }
    } catch (e) {
      print('Error fetching profile picture: $e');
    }
  }

  Future<void> _showRejectDialog(Map<String, dynamic> thread) async {
    final reasonController = TextEditingController();
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder(
                  duration: Duration(milliseconds: 300),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _dangerColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 40,
                          color: _dangerColor,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),
                Text(
                  'Confirm Rejection',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Are you sure you want to reject this thread?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: _secondaryTextColor,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: 'Reason (optional)',
                    labelStyle: TextStyle(color: _secondaryTextColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  maxLines: 2,
                  style: TextStyle(color: _textColor),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _banThread(thread, reason: reasonController.text);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _dangerColor,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Reject',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // เพิ่มเมธอดสำหรับเรียก API แบน
  Future<void> _banThread(
    Map<String, dynamic> thread, {
    String reason = '',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final int threadId = int.parse(thread['Thread_ID'].toString());
      final rejectionReason = reason.isEmpty ? 'Inappropriate message' : reason;
      final response = await http.post(
        Uri.parse('http://172.22.173.39:8080/threads/reject'),
        headers: {'Content-Type': 'application/json'},
        // headers: {'Authorization': 'Bearer $token'},
        body: json.encode({
          'threadId': threadId,
          'adminId': userId,
          'reason': rejectionReason,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Thread banned successfully')));
        fetchThreads(); // รีเฟรชรายการ threads
      } else {
        throw Exception('Failed to banned thread');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _fetchCurrentUserInfo(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final uri = Uri.parse('http://172.22.173.39:8080/user/info/$userId');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        setState(() {
          _selectedUser = {
            'User_ID': userId,
            'username': userData['username'] ?? '',
            'email': userData['email'] ?? '',
            'review_total_likes': userData['total_likes'] ?? 0,
            'total_reviews': userData['total_reviews'] ?? 0,
            'coins': userData['coins'] ?? 0,
            'formattedCoins': NumberFormat(
              '#,###',
            ).format(int.tryParse(userData['coins'].toString()) ?? 0),
            'status': userData['status'] ?? '',
            'picture_url': userData['picture_url'] ?? '',
            'role': userData['role'] ?? '',
          };
        });
        print(' Udfdfdfpgfgplfgpfplg $_selectedUser');
      } else {
        print('Failed to fetch user info. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user info: $e');
    }
  }

  Future<void> _showRejectDialog2(Map<String, dynamic> thread) async {
    final reasonController = TextEditingController();
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder(
                  duration: Duration(milliseconds: 300),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _dangerColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 40,
                          color: _dangerColor,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),
                Text(
                  'Confirm Rejection',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Are you sure you want to reject this thread?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: _secondaryTextColor,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: 'Reason (optional)',
                    labelStyle: TextStyle(color: _secondaryTextColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  maxLines: 2,
                  style: TextStyle(color: _textColor),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _banThread2(thread, reason: reasonController.text);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _dangerColor,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Reject',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // เพิ่มเมธอดสำหรับเรียก API แบน
  Future<void> _banThread2(
    Map<String, dynamic> thread, {
    String reason = '',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final int threadId = int.parse(thread['Thread_ID'].toString());
      final rejectionReason = reason.isEmpty ? 'Inappropriate message' : reason;
      final response = await http.post(
        Uri.parse('http://172.22.173.39:8080/threads/AdminManual-check/reject'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'threadId': threadId,
          'adminId': userId,
          'reason': rejectionReason,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Thread banned successfully')));
        fetchThreads(); // รีเฟรชรายการ threads
      } else {
        throw Exception('Failed to ban thread');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> fetchThreads() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (userId == null) return;
    final response = await http.get(
      Uri.parse('http://172.22.173.39:8080/all_threads/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        threads = json.decode(response.body);
        for (var thread in threads) {
          final rawCoins = thread['coins'] ?? 0;

          // แปลงเป็น int เผื่อเป็น string
          final coins = rawCoins is int
              ? rawCoins
              : int.tryParse(rawCoins.toString()) ?? 0;

          // เพิ่ม key ใหม่ formattedCoins
          thread['formattedCoins'] = NumberFormat('#,###').format(coins);
        }
      });
      print('f');
      print(threads);
      fetchPendingThreadsCount();
    } else if (response.statusCode == 401) {
      // Token หมดอายุ
      _showAlert(context, 'Session expired');
      return;
    } else if (response.statusCode == 403) {
      // User ถูกแบน - แสดง alert ตามที่ต้องการ
      _showAlert(context, 'Your account has been banned.');
      return;
    } else {
      throw Exception('Failed to load threads');
    }
  }

  void _showAlert(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // ผู้ใช้ต้องกดปุ่ม OK ก่อนปิด
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 5,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Colors.orangeAccent, Colors.deepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 50,
                color: Colors.white,
              ),
              const SizedBox(height: 15),
              Text(
                'Warning',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> toggleLike(int threadId, bool liked) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final response = await http.post(
      Uri.parse('http://172.22.173.39:8080/like_thread'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'User_ID': userId,
        'Thread_ID': threadId,
        'liked': !liked, // toggle
      }),
    );

    if (response.statusCode == 200) {
      fetchThreads();
    } else {
      throw Exception('Failed to toggle like');
    }
  }

  Future<String?> fetchUserPictureUrl(int? userId) async {
    if (userId == null) return null;

    try {
      final response = await http.get(
        Uri.parse('http://172.22.173.39:8080/user_profile_picture/$userId'),
      );
      setState(() => isSending = true);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final profileImageUrl2 = data['picture_url'];
        return data['picture_url'] as String?;
      }
    } catch (e) {
      print('Error fetching user picture: $e');
    }
    return null;
  }

  Future<void> sendThread() async {
    final message = _textController.text.trim();
    if (message.isEmpty || userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    try {
      setState(() => isSending = true);
      final response = await http.post(
        Uri.parse('http://172.22.173.39:8080/create_thread'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'User_ID': userId, 'message': message}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _textController.clear();
        fetchThreads();

        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
        // สมมติ API ตอบกลับ ai_evaluation ด้วย (ต้อง backend ส่งกลับมาด้วย)
        String aiEval = data['ai_evaluation'] ?? 'Safe';

        if (aiEval == 'Inappropriate') {
          // แสดง Dialog เตือนเนื้อหาไม่เหมาะสม
          await showDialog(
            context: context,
            builder: (context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 10,
                backgroundColor: Colors.white,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(66, 94, 81, 81),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.5),
                              blurRadius: 12,
                              spreadRadius: 1,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 56,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Warning!',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your Threads contains inappropriate content and is pending review.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 6,
                            shadowColor: const Color.fromARGB(
                              255,
                              0,
                              0,
                              0,
                            ).withOpacity(0.6),
                          ),
                          child: const Text(
                            'OK',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          // โชว์ snackbar ว่าส่งโพสต์สำเร็จ
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thread posted successfully'),
              duration: Duration(seconds: 1), // แสดง 1 วิ
            ),
          );
        }
      } else {
        throw Exception('Failed to post thread');
      }
      {
        if (mounted) setState(() => isSending = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String timeAgo(String datetimeString) {
    if (datetimeString.isEmpty) return 'Unknown time';

    try {
      // Post time from server (UTC)
      DateTime postTime = DateTime.parse(datetimeString);

      // Current time (UTC)
      DateTime now = DateTime.now().toUtc();

      Duration diff = now.difference(postTime);

      if (diff.inSeconds < 60) {
        return 'Just now';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} minutes ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} hours ago';
      } else if (diff.inDays < 30) {
        return '${diff.inDays} days ago';
      } else if (diff.inDays < 365) {
        int months = (diff.inDays / 30).floor();
        return '$months months ago';
      } else {
        int years = (diff.inDays / 365).floor();
        return '$years years ago';
      }
    } catch (e) {
      return 'Soon';
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RestaurantListPageUser()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LeaderboardPageUser()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => userChatbotScreen()),
        );
        break;
      // case 3:
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (context) => LeaderboardPage()),
      //   );
      //   break;
    }
  }

  Widget _buildInfoChip(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    final baseColor = color ?? Colors.blue;

    return Container(
      width: 120, // ให้ขนาดเท่ากัน
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            baseColor.withOpacity(0.95),
            const Color.fromARGB(255, 174, 174, 174).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.15),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 3, 3, 3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 22,
              color: const Color.fromARGB(255, 255, 255, 255),
            ),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 255, 255, 255),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color.fromARGB(255, 220, 216, 216),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildUserBanner(String? imageUrl) {
    final placeholder =
        "https://via.placeholder.com/400x200.png?text=No+Image"; // fallback

    return Container(
      width: double.infinity,
      height: 370,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              (imageUrl != null && imageUrl.isNotEmpty)
                  ? imageUrl
                  : placeholder,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey[600],
                      size: 48,
                    ),
                  ),
                );
              },
            ),
            // gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String obfuscateEmail(String email) {
    if (email.endsWith('@lamduan.mfu.ac.th')) {
      final domain = '@lamduan.mfu.ac.th';
      if (email.length > domain.length + 2) {
        final prefix = email.substring(0, 2);
        return '$prefix********$domain';
      }
    } else if (email.endsWith('@mfu.ac.th')) {
      final domain = '@mfu.ac.th';
      return '**********$domain';
    } else {
      final domain = '@gmail.com';
      return '**********$domain';
    }

    return email; // กรณีอื่น ๆ
  }

  @override
  Widget build(BuildContext context) {
    // กรอง threads ตาม search query
    final filteredThreads = threads.where((thread) {
      final message = thread['message'].toString().toLowerCase();
      final fullname = thread['username'].toString().toLowerCase();
      final status = thread['status']?.toString().toLowerCase() ?? '';
      final id = thread['Thread_ID'].toString().toLowerCase();
      return message.contains(_searchQuery) ||
          fullname.contains(_searchQuery) ||
          status.contains(_searchQuery) ||
          id.contains(_searchQuery);
    }).toList();

    return Scaffold(
      body: _selectedUser != null
          ? Container(
              color: Color.fromARGB(
                255,
                116,
                115,
                113,
              ).withOpacity(1), // ความเข้มของดำ
              child: Center(
                child: Text(
                  "",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 127, 45, 45),
                    fontSize: 18,
                  ),
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 244, 242, 238),
                    Color.fromARGB(255, 255, 255, 255),
                    Color(0xFFF7F4EF),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(
                      255,
                      48,
                      47,
                      47,
                    ).withOpacity(0.2),
                    blurRadius: 16,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverAppBar(
                    toolbarHeight: 80,
                    pinned: false,
                    floating: true,
                    snap: true,
                    elevation: 6,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                    ),
                    flexibleSpace: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFCEBFA3),
                            const Color(0xFFCEBFA3),
                          ],
                        ),
                      ),
                    ),
                    title: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Food Threads',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                              color: const Color.fromARGB(255, 35, 34, 34),
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final shouldRefresh = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfilePageUser(),
                                ),
                              );
                              if (shouldRefresh == true) {
                                fetchProfilePicture(userId!);
                                _loadUserID();
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: profileImageUrl == null
                                  ? CircleAvatar(
                                      backgroundColor: Colors.grey[300],
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                      radius: 27,
                                    )
                                  : CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        profileImageUrl!,
                                      ),
                                      radius: 27,
                                      backgroundColor: Colors.grey[300],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(height: 15),
                          Row(
                            children: [
                              // Search TextField
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 1,
                                        offset: const Offset(1, 1),
                                      ),
                                    ],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Search threads ID or urthor Name ... ',
                                      hintStyle: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.black,
                                      ),
                                      prefixIcon: const Icon(Icons.search),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _searchQuery = value.toLowerCase();
                                      });
                                    },
                                  ),
                                ),
                              ),
                              // Three-dot menu button
                              SizedBox(width: 10),
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                ),
                                itemBuilder: (BuildContext context) => [
                                  // PopupMenuItem(
                                  //   value: 'verify_threads',
                                  //   child: Container(
                                  //     padding: EdgeInsets.symmetric(
                                  //       vertical: 8,
                                  //     ),
                                  //     child: Row(
                                  //       children: [
                                  //         Container(
                                  //           width: 32,
                                  //           height: 32,
                                  //           decoration: BoxDecoration(
                                  //             color: Colors.blue.shade50,
                                  //             shape: BoxShape.circle,
                                  //           ),
                                  //           child: Icon(
                                  //             Icons.verified_outlined,
                                  //             size: 18,
                                  //             color: Colors.blue.shade700,
                                  //           ),
                                  //         ),
                                  //         SizedBox(width: 12),
                                  //         Expanded(
                                  //           child: Column(
                                  //             crossAxisAlignment:
                                  //                 CrossAxisAlignment.start,
                                  //             children: [
                                  //               Text(
                                  //                 'Verify Threads',
                                  //                 style: TextStyle(
                                  //                   fontWeight: FontWeight.w500,
                                  //                   fontSize: 14,
                                  //                 ),
                                  //               ),
                                  //               if (_pendingThreadsCount > -1)
                                  //                 Text(
                                  //                   '$_pendingThreadsCount pending',
                                  //                   style: TextStyle(
                                  //                     fontSize: 12,
                                  //                     color:
                                  //                         Colors.grey.shade600,
                                  //                   ),
                                  //                 ),
                                  //             ],
                                  //           ),
                                  //         ),
                                  //         if (_pendingThreadsCount > 0)
                                  //           Container(
                                  //             width: 24,
                                  //             height: 24,
                                  //             decoration: BoxDecoration(
                                  //               color: Color(0xFFFF4757),
                                  //               shape: BoxShape.circle,
                                  //             ),
                                  //             child: Center(
                                  //               child: Text(
                                  //                 '$_pendingThreadsCount',
                                  //                 style: TextStyle(
                                  //                   color: Colors.white,
                                  //                   fontSize: 11,
                                  //                   fontWeight: FontWeight.bold,
                                  //                 ),
                                  //               ),
                                  //             ),
                                  //           ),
                                  //       ],
                                  //     ),
                                  //   ),
                                  // ),
                                  // PopupMenuItem(
                                  //   value: 'verify_threads_replied',
                                  //   child: Container(
                                  //     padding: EdgeInsets.symmetric(
                                  //       vertical: 8,
                                  //     ),
                                  //     child: Row(
                                  //       children: [
                                  //         Container(
                                  //           width: 32,
                                  //           height: 32,
                                  //           decoration: BoxDecoration(
                                  //             color: Colors.green.shade50,
                                  //             shape: BoxShape.circle,
                                  //           ),
                                  //           child: Icon(
                                  //             Icons.reply_all_rounded,
                                  //             size: 18,
                                  //             color: Colors.green.shade700,
                                  //           ),
                                  //         ),
                                  //         SizedBox(width: 12),
                                  //         Expanded(
                                  //           child: Column(
                                  //             crossAxisAlignment:
                                  //                 CrossAxisAlignment.start,
                                  //             children: [
                                  //               Text(
                                  //                 'Verify Threads Replied',
                                  //                 style: TextStyle(
                                  //                   fontWeight: FontWeight.w500,
                                  //                   fontSize: 13.5,
                                  //                 ),
                                  //               ),
                                  //               if (_pendingRepliedThreadsCount >
                                  //                   -1)
                                  //                 Text(
                                  //                   '$_pendingRepliedThreadsCount pending',
                                  //                   style: TextStyle(
                                  //                     fontSize: 12,
                                  //                     color:
                                  //                         Colors.grey.shade600,
                                  //                   ),
                                  //                 ),
                                  //             ],
                                  //           ),
                                  //         ),
                                  //         if (_pendingRepliedThreadsCount > 0)
                                  //           Container(
                                  //             width: 24,
                                  //             height: 24,
                                  //             decoration: BoxDecoration(
                                  //               color: Color(0xFFFF4757),
                                  //               shape: BoxShape.circle,
                                  //             ),
                                  //             child: Center(
                                  //               child: Text(
                                  //                 '$_pendingRepliedThreadsCount',
                                  //                 style: TextStyle(
                                  //                   color: Colors.white,
                                  //                   fontSize: 11,
                                  //                   fontWeight: FontWeight.bold,
                                  //                 ),
                                  //               ),
                                  //             ),
                                  //           ),
                                  //       ],
                                  //     ),
                                  //   ),
                                  // ),
                                  // เพิ่มเมนู My History
                                  PopupMenuItem(
                                    value: 'my_history',
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: Colors.purple.shade50,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.history_rounded,
                                              size: 18,
                                              color: Colors.purple.shade700,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'My History',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  'See You History Here',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
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
                                onSelected: (String value) async {
                                  Widget page;

                                  // if (value == 'verify_threads') {
                                  //   page = PendingThreadsPage();
                                  // } else if (value ==
                                  //     'verify_threads_replied') {
                                  //   page = PendingThreadsRepliedPage();

                                  if (value == 'my_history') {
                                    page =
                                        userMyHistoryPage(); // หน้าใหม่สำหรับประวัติ
                                  } else {
                                    return;
                                  }

                                  final shouldRefresh = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => page,
                                    ),
                                  );

                                  if (shouldRefresh == true) {
                                    fetchThreads();
                                    fetchPendingThreadsCount();
                                    fetchPendingRepliedThreadsCount();
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final thread = filteredThreads[index];

                      final likedByUser = thread['is_liked'] == 1;
                      final coins = thread['coins'] ?? 0;
                      final formattedCoins = NumberFormat(
                        '#,###',
                      ).format(coins);

                      return InkWell(
                        onTap: () async {
                          final shouldRefresh = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ThreadRepliesUserPage(
                                thread: thread,
                                likedByUser: likedByUser,
                              ),
                            ),
                          );
                          if (shouldRefresh == true) {
                            await fetchThreads();
                            fetchPendingRepliedThreadsCount();
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color.fromARGB(
                                        255,
                                        227,
                                        238,
                                        248,
                                      ), // ฟ้าอ่อน
                                      const Color.fromARGB(
                                        255,
                                        241,
                                        243,
                                        245,
                                      ), // ขาวนวล
                                      const Color.fromARGB(
                                        255,
                                        218,
                                        227,
                                        236,
                                      ), // // ฟ้าอ่อน
                                    ],
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(24),
                                    topRight: Radius.circular(24),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, -4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (_selectedUser != null &&
                                                  _selectedUser!['User_ID'] ==
                                                      thread['User_ID']) {
                                                _selectedUser = null;
                                              } else {
                                                _selectedUser = thread;
                                              }
                                            });
                                          },
                                          child: Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(0xFFCEBFA3),
                                                width: 2,
                                              ),
                                            ),
                                            child: ClipOval(
                                              child: Image.network(
                                                thread['picture_url'],
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Container(
                                                      color: Colors.grey[200],
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    thread['username'],
                                                    style: const TextStyle(
                                                      color: Color(0xFF2C3E50),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Icon(
                                                    Icons.verified,
                                                    size: 16,
                                                    color: Colors.teal,
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    timeAgo(
                                                      thread['created_at'],
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                // obfuscateEmail(
                                                thread['email'] ?? '',

                                                style: const TextStyle(
                                                  fontSize: 12.3,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 9),

                                    // ข้อความของ thread
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        thread['message'],
                                        style: const TextStyle(
                                          fontSize: 15,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    Divider(
                                      color: const Color.fromARGB(
                                        255,
                                        185,
                                        171,
                                        171,
                                      ),
                                      thickness: 0.7,
                                    ),
                                    const SizedBox(height: 6),

                                    // ปุ่ม Like / Comment / Report
                                    Row(
                                      children: [
                                        // Report
                                        // Container(
                                        //   width: 36,
                                        //   height: 36,
                                        //   decoration: BoxDecoration(
                                        //     shape: BoxShape.circle,
                                        //     gradient: LinearGradient(
                                        //       colors: [
                                        //         Colors.redAccent.shade200,
                                        //         Colors.deepOrange.shade400,
                                        //       ],
                                        //     ),
                                        //     boxShadow: [
                                        //       BoxShadow(
                                        //         color: Colors.redAccent
                                        //             .withOpacity(0.3),
                                        //         blurRadius: 6,
                                        //         offset: const Offset(2, 3),
                                        //       ),
                                        //     ],
                                        //   ),
                                        //   child: IconButton(
                                        //     padding: EdgeInsets.zero,
                                        //     constraints: const BoxConstraints(),
                                        //     icon: const Icon(
                                        //       Icons
                                        //           .report_gmailerrorred_rounded,
                                        //       size: 18,
                                        //       color: Colors.white,
                                        //     ),
                                        //     onPressed: () =>
                                        //         _showRejectDialog2(thread),
                                        //     tooltip: "Report this thread",
                                        //   ),
                                        // ),
                                        const Spacer(),

                                        // Like button
                                        InkWell(
                                          onTap: () {
                                            toggleLike(
                                              thread['Thread_ID'],
                                              likedByUser,
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: likedByUser
                                                  ? Colors.pink.shade50
                                                  : Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: likedByUser
                                                    ? Colors.pink.shade200
                                                    : Colors.grey.shade300,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.favorite,
                                                  size: 18,
                                                  color: likedByUser
                                                      ? Colors.pink.shade400
                                                      : Colors.grey[600],
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '${thread['total_likes']}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: likedByUser
                                                        ? Colors.pink.shade600
                                                        : Colors.grey[700],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // Comment button
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.indigo.shade50,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: Colors.indigo.shade100,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.comment,
                                                size: 18,
                                                color: Colors.indigo,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${thread['total_comments']}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.indigo,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Verified Badge
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.teal, Colors.blueAccent],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.verified,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: filteredThreads.length),
                  ),

                  const SliverPadding(padding: EdgeInsets.only(bottom: 90)),
                ],
              ),
            ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFFCEBFA3),
            unselectedItemColor: Colors.grey,
            // backgroundColor: Colors.white,
            elevation: 8,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events),
                label: 'Leaderboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.memory),
                label: 'AI Assistant',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.forum),
                label: 'Threads',
              ),
            ],
          ),
        ),
      ),

      bottomSheet: _selectedUser != null
          ? GestureDetector(
              // onVerticalDragUpdate: (details) {
              //   // ถ้าเลื่อนลงมากกว่า 50 pixels ให้ปิด
              //   if (details.delta.dy > 10) {
              //     setState(() {
              //       _selectedUser = null;
              //     });
              //   }
              // },
              onTap: () {
                // ถ้าคลิกนอกเนื้อหาให้ปิด
                // setState(() {
                //   _selectedUser = null;
                // });
              },
              child: Container(
                padding: EdgeInsets.only(),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color.fromARGB(255, 46, 45, 45), // เทาเข้มด้านล่าง
                      const Color.fromARGB(255, 136, 133, 133), // เทาอ่อนด้านบน
                      const Color.fromARGB(255, 46, 45, 45), // เทาเข้มด้านล่าง
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 16,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ส่วนหัว

                      // Container สำหรับ Banner และ Avatar ที่ซ้อนกัน
                      Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Banner
                          Container(
                            margin: EdgeInsets.only(
                              bottom: 40,
                            ), // ระยะห่างสำหรับ Avatar
                            child: buildUserBanner(
                              _selectedUser?['picture_url'],
                            ),
                          ),

                          // Avatar (วางซ้อนลงบน Banner)
                          Positioned(
                            bottom: 0, // ทำให้ Avatar ยื่นออกมาจาก Banner
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.blue[100],
                                backgroundImage:
                                    (_selectedUser!['picture_url'] != null &&
                                        _selectedUser!['picture_url']
                                            .isNotEmpty)
                                    ? NetworkImage(
                                        _selectedUser!['picture_url'],
                                      )
                                    : null,
                                child:
                                    (_selectedUser!['picture_url'] == null ||
                                        _selectedUser!['picture_url'].isEmpty)
                                    ? Text(
                                        _selectedUser!['username'][0]
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[800],
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.close_rounded, size: 40),
                                  color: const Color.fromARGB(
                                    255,
                                    237,
                                    235,
                                    235,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedUser = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 290,
                            right: -60,
                            child: Icon(
                              Icons.lock_outlined,
                              size: 120,
                              color: const Color.fromARGB(
                                255,
                                0,
                                0,
                                0,
                              ).withOpacity(0.1),
                            ),
                          ),
                          Positioned(
                            bottom: -550,
                            left: 40,
                            child: Icon(
                              Icons.group,
                              size: 340,
                              color: const Color.fromARGB(
                                255,
                                9,
                                9,
                                9,
                              ).withOpacity(0.4),
                            ),
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedUser = null;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(
                                  8,
                                ), // ทำให้ Icon มีพื้นที่รอบ ๆ
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.redAccent.shade100,
                                      Colors.red.shade700,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.4),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 28,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ชื่อและ email (ลดระยะห่างจาก Avatar)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 7,
                          bottom: 16,
                        ), // ลดจาก 60 เป็น 50
                        child: Column(
                          children: [
                            Text(
                              _selectedUser!['username'],
                              style: TextStyle(
                                fontSize: 22, // เพิ่มขนาดฟอนต์
                                fontWeight: FontWeight.w800, // ตัวหนากว่าเดิม
                                color: const Color.fromARGB(255, 255, 255, 255),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 6), // เพิ่มระยะห่างเล็กน้อย
                            (_selectedUser!['User_ID'] == userId)
                                ? Text(
                                    (_selectedUser!['email']),
                                    style: TextStyle(
                                      fontSize: 15, // เพิ่มขนาดฟอนต์เล็กน้อย
                                      color: const Color.fromARGB(
                                        255,
                                        222,
                                        220,
                                        220,
                                      ),
                                      fontWeight:
                                          FontWeight.w500, // ตัวหนาปานกลาง
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                : Text(
                                    obfuscateEmail(_selectedUser!['email']),
                                    style: TextStyle(
                                      fontSize: 15, // เพิ่มขนาดฟอนต์เล็กน้อย
                                      color: const Color.fromARGB(
                                        255,
                                        222,
                                        220,
                                        220,
                                      ),
                                      fontWeight:
                                          FontWeight.w500, // ตัวหนาปานกลาง
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsGeometry.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // ชิปข้อมูล
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildInfoChip(
                                  Icons.badge_outlined,
                                  "User ID",
                                  "${_selectedUser!['User_ID']}",
                                  color: Colors.blue,
                                ),
                                if (_selectedUser!['role'] != null &&
                                    _selectedUser!['role'].isNotEmpty)
                                  _buildInfoChip(
                                    Icons.manage_accounts,
                                    "Role",
                                    "${_selectedUser!['role']}",
                                    color: Colors.teal,
                                  ),
                                _buildInfoChip(
                                  _selectedUser!['status'] == "Active"
                                      ? Icons.verified_user_outlined
                                      : Icons.block_outlined,
                                  "Status",
                                  _selectedUser!['status'],
                                  color: _selectedUser!['status'] == "Active"
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                _buildInfoChip(
                                  Icons.monetization_on_outlined,
                                  "Coins",
                                  "${_selectedUser!['formattedCoins']}",
                                  color: Colors.orange,
                                ),
                                if (_selectedUser!['review_total_likes'] !=
                                    null)
                                  _buildInfoChip(
                                    Icons.favorite_outline,
                                    "Likes",
                                    "${_selectedUser!['review_total_likes']}",
                                    color: Colors.pink,
                                  ),
                                if (_selectedUser!['total_reviews'] != null)
                                  _buildInfoChip(
                                    Icons.reviews_outlined,
                                    "Reviews",
                                    "${_selectedUser!['total_reviews']}",
                                    color: const Color.fromARGB(
                                      255,
                                      183,
                                      52,
                                      222,
                                    ),
                                  ),
                              ],
                            ),

                            if (_selectedUser!['ban_info'] != null &&
                                _selectedUser!['ban_info'].isNotEmpty) ...[
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange[200]!,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.orange[700],
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        "Ban Info: ${_selectedUser!['ban_info']}",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.orange[800],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Avatar
                    // Avatar
                    GestureDetector(
                      onTap: () {
                        if (userId != null) {
                          _fetchCurrentUserInfo(userId!);
                        }
                      },
                      child: CircleAvatar(
                        radius: 22,
                        backgroundImage: profileImageUrl != null
                            ? NetworkImage(profileImageUrl!)
                            : null,
                        backgroundColor: Colors.grey.shade300,
                        child: profileImageUrl == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Expanded(
                    //   child: TextField(
                    //     controller: _textController,
                    //     maxLines: null,
                    //     keyboardType: TextInputType.multiline,
                    //     decoration: InputDecoration(
                    //       hintText: 'Write a new thread...',
                    //       border: InputBorder.none,
                    //     ),
                    //   ),
                    // ),
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 10,
                            ),
                          ),
                          TextField(
                            controller: _textController,
                            maxLines: null,
                            cursorColor: Colors.black,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Write a new thread...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                              filled: true,
                              fillColor: Color(0xFFF0F0F0),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (text) {
                              final words = text.split(' ');
                              final lastWord = words.isNotEmpty
                                  ? words.last
                                  : '';

                              // if (lastWord.startsWith('@')) {
                              //   final mentionText = lastWord
                              //       .substring(1)
                              //       .toLowerCase();
                              //   setState(() {
                              //     currentMention = mentionText;
                              //     mentionSuggestions = allUsers
                              //         .where(
                              //           (user) =>
                              //               user['username']
                              //                   .toLowerCase()
                              //                   .startsWith(mentionText) &&
                              //               user['User_ID'] != userId,
                              //         )
                              //         .toList();
                              //     showSuggestions = mentionSuggestions.isNotEmpty;
                              //   });
                              // }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Send Button
                    InkWell(
                      onTap: isSending ? null : sendThread,
                      borderRadius: BorderRadius.circular(30),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: isSending
                              ? const LinearGradient(
                                  colors: [Colors.grey, Colors.grey],
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFFCEBFA3),
                                    Color(0xFFB89C7D),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.brown.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: isSending
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

      // ... โค้ด bottomSheet ข้างต้น

      // แทนที่ส่วน bottomSheet ที่ถูกคอมเมนต์ออกด้วยโค้ดนี้
    );
  }
}

String obfuscateEmail(String email) {
  if (email.endsWith('@lamduan.mfu.ac.th')) {
    final domain = '@lamduan.mfu.ac.th';
    if (email.length > domain.length + 2) {
      final prefix = email.substring(0, 2);
      return '$prefix********$domain';
    }
  } else if (email.endsWith('@mfu.ac.th')) {
    final domain = '@mfu.ac.th';
    if (email.length > domain.length + 2) {
      final prefix = email.substring(0, 2);
      return '$prefix********$domain';
    }
  } else {
    // สำหรับเมลปกติ
    final atIndex = email.indexOf('@');
    if (atIndex > 3) {
      final prefix = email.substring(0, 3);
      final domain = email.substring(atIndex);
      return '$prefix********$domain';
    }
  }
  return email; // กรณีอื่น ๆ
}
