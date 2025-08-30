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
import 'package:myapp/admin/Admin-pendingThreadsReplied.dart';
import 'package:myapp/admin/Admin-profile-info.dart';
import 'package:myapp/dashboard.dart';
import 'package:myapp/home.dart';
import 'package:myapp/leaderboard.dart';
import 'package:myapp/thread_reply.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThreadsAdminPage extends StatefulWidget {
  const ThreadsAdminPage({super.key});

  @override
  State<ThreadsAdminPage> createState() => _ThreadsAdminPageState();
}

class _ThreadsAdminPageState extends State<ThreadsAdminPage> {
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
  int _pendingRepliedThreadsCount = 0;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
        Uri.parse('https://mfu-food-guide-review.onrender.com/threads/pending'),
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
        Uri.parse(
          'https://mfu-food-guide-review.onrender.com/threads-replied/pending',
        ),
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
        Uri.parse(
          'https://mfu-food-guide-review.onrender.com/user-profile/$userId',
        ),
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
      final int threadId = int.parse(thread['Thread_ID'].toString());
      final rejectionReason = reason.isEmpty ? 'Inappropriate message' : reason;
      final response = await http.post(
        Uri.parse('https://mfu-food-guide-review.onrender.com/threads/reject'),
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
    if (userId == null) return;
    final response = await http.get(
      Uri.parse(
        'https://mfu-food-guide-review.onrender.com/all_threads/$userId',
      ),
    );

    if (response.statusCode == 200) {
      setState(() {
        threads = json.decode(response.body);
      });
      print('f');
      print(threads);
      fetchPendingThreadsCount();
    } else {
      throw Exception('Failed to load threads');
    }
  }

  Future<void> toggleLike(int threadId, bool liked) async {
    final response = await http.post(
      Uri.parse('https://mfu-food-guide-review.onrender.com/like_thread'),
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
        Uri.parse(
          'https://mfu-food-guide-review.onrender.com/user_profile_picture/$userId',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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

    try {
      final response = await http.post(
        Uri.parse('https://mfu-food-guide-review.onrender.com/create_thread'),
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
            const SnackBar(content: Text('Thread posted successfully')),
          );
        }
      } else {
        throw Exception('Failed to post thread');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String timeAgo(String datetimeString) {
    DateTime dateTime = DateTime.parse(datetimeString).toLocal();
    Duration diff = DateTime.now().difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minutes ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else {
      return '${diff.inDays} days ago';
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RestaurantListPageAdmin()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LeaderboardPageAdmin()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatbotScreen()),
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

  @override
  Widget build(BuildContext context) {
    // กรอง threads ตาม search query
    final filteredThreads = threads.where((thread) {
      final message = thread['message'].toString().toLowerCase();
      final fullname = thread['username'].toString().toLowerCase();
      final status = thread['status']?.toString().toLowerCase() ?? '';
      return message.contains(_searchQuery) ||
          fullname.contains(_searchQuery) ||
          status.contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF), // สีพื้นหลังอ่อนๆ
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            toolbarHeight: 70,
            backgroundColor: const Color(0xFFCEBFA3),
            pinned: false,
            floating: true,
            snap: true,
            elevation: 4,
            title: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ), // ปรับตามต้องการ
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Food Threads',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black38,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final shouldRefresh = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfilePageAdmin(),
                        ),
                      );

                      if (shouldRefresh == true) {
                        fetchProfilePicture(userId!);
                      }
                    },
                    child: profileImageUrl == null
                        ? CircleAvatar(
                            backgroundColor: Colors.grey[300],
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 40,
                            ),
                            radius: 27, // ขนาดใหญ่
                          )
                        : CircleAvatar(
                            backgroundImage: NetworkImage(profileImageUrl!),
                            radius: 27, // ขนาดใหญ่
                            backgroundColor: Colors.grey[300],
                          ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                              hintText: 'Search threads...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
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
                          PopupMenuItem(
                            value: 'verify_threads',
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.verified_outlined,
                                      size: 18,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Verify Threads',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (_pendingThreadsCount > 0)
                                          Text(
                                            '$_pendingThreadsCount pending',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (_pendingThreadsCount > 0)
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFFF4757),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$_pendingThreadsCount',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'verify_threads_replied',
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.reply_all_rounded,
                                      size: 18,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Verify Threads Replied',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        if (_pendingRepliedThreadsCount >
                                            0) // เปลี่ยนเป็น _pendingRepliedThreadsCount
                                          Text(
                                            '$_pendingRepliedThreadsCount pending', // เปลี่ยนเป็น _pendingRepliedThreadsCount
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (_pendingRepliedThreadsCount >
                                      0) // เปลี่ยนเป็น _pendingRepliedThreadsCount
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFFF4757),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$_pendingRepliedThreadsCount', // เปลี่ยนเป็น _pendingRepliedThreadsCount
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        onSelected: (String value) async {
                          Widget page;

                          if (value == 'verify_threads') {
                            page = PendingThreadsPage();
                          } else if (value == 'verify_threads_replied') {
                            page = PendingThreadsRepliedPage();
                          } else {
                            return;
                          }

                          final shouldRefresh = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => page),
                          );

                          if (shouldRefresh == true) {
                            fetchThreads();
                            fetchPendingThreadsCount(); // รีเฟรชจำนวน pending threads
                            fetchPendingRepliedThreadsCount(); // รีเฟรชจำนวน pending replied threads
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

              return InkWell(
                onTap: () async {
                  final shouldRefresh = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ThreadRepliesAdminPage(thread: thread),
                    ),
                  );

                  if (shouldRefresh == true) {
                    await fetchThreads(); // ฟังก์ชันโหลด thread ใหม่
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(
                                255,
                                0,
                                0,
                                0,
                              ).withOpacity(0.20), // สีเงาและความโปร่งใส
                              spreadRadius: 3, // ขนาดเงา
                              blurRadius: 5, // ความฟุ้งของเงา
                              offset: const Offset(0, 4), // ตำแหน่งเงา (x, y)
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage: NetworkImage(
                                    thread['picture_url'],
                                  ),
                                  backgroundColor: Colors.grey.shade200,
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
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),

                                          Icon(
                                            Icons.verified,
                                            size: 16,
                                            color: Colors.blue,
                                          ),
                                          Spacer(),

                                          Text(
                                            timeAgo(thread['created_at']),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        obfuscateEmail(thread['email'] ?? ''),
                                        style: TextStyle(fontSize: 12.3),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                thread['message'],
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.report,
                                        color: const Color.fromARGB(
                                          255,
                                          144,
                                          143,
                                          143,
                                        ),
                                      ),
                                      onPressed: () =>
                                          _showRejectDialog(thread),
                                    ),
                                  ],
                                ),
                                Spacer(),
                                InkWell(
                                  onTap: () {
                                    toggleLike(
                                      thread['Thread_ID'],
                                      likedByUser,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: likedByUser
                                          ? Colors.red.shade100
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: likedByUser
                                            ? Colors.red
                                            : const Color.fromARGB(
                                                255,
                                                102,
                                                100,
                                                100,
                                              ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.favorite,
                                          size: 18,
                                          color: likedByUser
                                              ? Colors.red
                                              : const Color.fromARGB(
                                                  255,
                                                  0,
                                                  0,
                                                  0,
                                                ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${thread['total_likes']}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: likedByUser
                                                ? Colors.red.shade700
                                                : const Color.fromARGB(
                                                    255,
                                                    0,
                                                    0,
                                                    0,
                                                  ),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.comment,
                                        size: 18,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${thread['total_comments']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 20),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 212, 58, 58),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 175, 128, 52),
        unselectedItemColor: Colors.grey,
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
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Threads'),
        ],
      ),
      bottomSheet: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            FutureBuilder<String?>(
              future: fetchUserPictureUrl(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey.shade300,
                    child: const CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError || snapshot.data == null) {
                  return CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey.shade300,
                    child: const Icon(Icons.person),
                  );
                } else {
                  return CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(snapshot.data!),
                    backgroundColor: Colors.grey.shade300,
                  );
                }
              },
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color.fromARGB(221, 148, 143, 143),
                  ),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: Scrollbar(
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText: 'Write a new thread...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            InkWell(
              onTap: sendThread,
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.deepOrangeAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
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
    return '**********$domain';
  }
  return email; // กรณีอื่น ๆ
}
