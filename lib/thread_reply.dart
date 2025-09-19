import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/admin/Admin-Thread-Reply-Pending.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ThreadRepliesUserPage extends StatefulWidget {
  final Map thread;
  final bool likedByUser;

  const ThreadRepliesUserPage({
    super.key,
    required this.thread,
    required this.likedByUser,
  });

  @override
  State<ThreadRepliesUserPage> createState() => _ThreadRepliesAdminPageState();
}

class _ThreadRepliesAdminPageState extends State<ThreadRepliesUserPage> {
  List replies = [];
  bool isLoading = true;
  int? userId;
  String? profilePictureUrl;
  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> mentionSuggestions = [];
  bool showSuggestions = false;
  String currentMention = '';
  Map<dynamic, dynamic>? _selectedUser;
  String? profileImageUrl;
  String? pictureUrl;
  ScrollController _scrollController = ScrollController();
  int pendingRepliesCount = 0;
  final Color _primaryColor = Color(0xFF4285F4);
  final Color _successColor = Color(0xFF34A853);
  final Color _warningColor = Color(0xFFFBBC05);
  final Color _dangerColor = Color(0xFFEA4335);
  final Color _cardColor = Colors.white;
  final Color _textColor = Color(0xFF202124);
  final Color _secondaryTextColor = Color(0xFF5F6368);

  TextEditingController _replyController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    fetchReplies();
    loadUserId();
    fetchAllUsers();
    fetchProfilePicture();
    fetchPendingRepliesCount();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('user_id');
    });
  }

  Future<void> fetchProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');
    print(userId);

    if (userId == null) return;
    final url = Uri.parse(
      'http://172.22.173.39:8080/user_profile_picture/$userId',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);
        setState(() {
          profilePictureUrl = data['picture_url'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching profile picture: $e');
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

  Future<void> fetchReplies() async {
    final threadId = widget.thread['Thread_ID'] ?? 0;
    final url = Uri.parse(
      'http://172.22.173.39:8080/api/thread_replies/$threadId',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          replies = data;
          isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (_scrollController.hasClients) {
            // หน่วงเวลาสั้น ๆ ให้ UI โหลดเสร็จ
            await Future.delayed(const Duration(milliseconds: 400));
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching replies: $e');
      setState(() => isLoading = false);
    } // เลื่อนลงล่างหลังโหลดข้อมูลเสร็จ (เพิ่ม delay เล็กน้อยเพื่อให้ ListView สร้าง widget เสร็จ)
  }

  Future<void> fetchAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('http://172.22.173.39:8080/api/all_users'),
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          allUsers = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  Future<void> sendReply() async {
    if (_replyController.text.trim().isEmpty || userId == null) return;

    setState(() {
      _isSending = true;
    });

    final message = _replyController.text.trim();
    final threadId = widget.thread['Thread_ID'] ?? 0;

    try {
      final response = await http.post(
        Uri.parse('http://172.22.173.39:8080/api/send_reply'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'User_ID': userId,
          'Thread_ID': threadId,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          _replyController.clear();
        });
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text(
        //       'Reply sent successfully!',
        //       style: TextStyle(color: Colors.white),
        //     ),
        //     backgroundColor: Color.fromARGB(255, 0, 0, 0),
        //     duration: Duration(seconds: 2),
        //   ),
        // );
        if (responseData['ai_evaluation'] == 'Inappropriate') {
          // แสดง dialog แจ้งเตือนคำหยาบ
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
                        'Your comment contains inappropriate content and is pending review.',
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
          await fetchPendingRepliesCount();
        }

        await fetchReplies();
        await refreshThreadData();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to send reply')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    setState(() {
      _isSending = false;
    });
  }

  // Future<void> toggleLike(int threadId, bool liked) async {
  //   final response = await http.post(
  //     Uri.parse('http://172.22.173.39:8080/like_thread'),
  //     headers: {'Content-Type': 'application/json'},
  //     body: json.encode({
  //       'User_ID': userId,
  //       'Thread_ID': threadId,
  //       'liked': !liked, // toggle
  //     }),
  //   );

  //   if (response.statusCode == 200) {
  //   await refreshThreadData();
  //   } else {
  //     throw Exception('Failed to toggle like');
  //   }
  // }

  Future<void> _showRejectDialog(Map<dynamic, dynamic> reply) async {
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
                          _banThread(reply, reason: reasonController.text);
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

  Future<void> _banThread(
    Map<dynamic, dynamic> reply, {
    String reason = '',
  }) async {
    try {
      final int threadId = int.parse(reply['Thread_reply_ID'].toString());
      final rejectionReason = reason.isEmpty ? 'Inappropriate message' : reason;
      final response = await http.post(
        Uri.parse(
          'http://172.22.173.39:8080/threads-replied/AdminManual-check/reject',
        ),
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
        fetchReplies();
        refreshThreadData(); // รีเฟรชรายการ threads
      } else {
        throw Exception('Failed to ban thread');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> fetchPendingRepliesCount() async {
    try {
      final threadId = widget.thread['Thread_ID'];
      final likedByUser = widget.likedByUser;
      final response = await http.get(
        Uri.parse(
          'http://172.22.173.39:8080/api/pending_replies_count/$threadId',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          pendingRepliesCount = data['count'] ?? 0;
        });
      }
    } catch (e) {
      print('Error fetching pending replies count: $e');
    }
  }

  Future<void> refreshThreadData() async {
    try {
      final threadId = widget.thread['Thread_ID'];
      final response = await http.get(
        Uri.parse('http://172.22.173.39:8080/all_threads/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> allThreads = json.decode(response.body);

        // หา thread ที่ต้องการโดยใช้ Thread_ID
        final updatedThread = allThreads.firstWhere(
          (thread) => thread['Thread_ID'] == threadId,
          orElse: () => null,
        );

        if (updatedThread != null) {
          setState(() {
            widget.thread.clear();
            widget.thread.addAll(updatedThread);
          });
        } else {
          print('Thread not found in response');
        }
      } else {
        print('Failed to refresh threads: ${response.statusCode}');
      }
    } catch (e) {
      print('Error refreshing thread: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final thread = widget.thread;
    final likedByUser = widget.likedByUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: _selectedUser == null
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(
                    context,
                    true,
                  ); // ส่งค่ากลับว่าให้รีเฟรชหน้าก่อนหน้า
                },
              ),
              title: Text(
                'Replies to ${thread['username']} ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
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
              backgroundColor: const Color(0xFFCEBFA3),
              foregroundColor: Colors.black,
              actions: [
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.verified_user, size: 30),
                      onPressed: () async {
                        final shouldRefresh = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PendingRepliesAdminPage(
                              threadId: widget.thread['Thread_ID'],
                            ),
                          ),
                        );
                        if (shouldRefresh == true) {
                          await fetchReplies();
                          await refreshThreadData();
                          await fetchPendingRepliesCount(); // รีเฟรชจำนวนหลังจากกลับมา
                        }
                      },
                      tooltip: 'Review pending replies for this thread',
                    ),
                  ],
                ),
              ],
            )
          : AppBar(
              backgroundColor: Color.fromARGB(
                255,
                116,
                115,
                113,
              ).withOpacity(1),
            ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    const SizedBox(height: 18),
                    _buildThreadItem(thread, likedByUser),
                    const SizedBox(height: 16),
                    const SizedBox(height: 20),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : replies.isEmpty
                          ? const Center(child: Text('No replies found'))
                          : ListView.builder(
                              controller: _scrollController,
                              itemCount: replies.length,
                              itemBuilder: (context, index) {
                                final reply = replies[index];
                                return _buildReplyItem(reply);
                              },
                            ),
                    ),
                    if (showSuggestions)
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          itemCount: mentionSuggestions.length,
                          itemBuilder: (context, index) {
                            final user = mentionSuggestions[index];
                            return ListTile(
                              leading:
                                  (user['picture_url'] != null &&
                                      user['picture_url'].isNotEmpty)
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        user['picture_url'],
                                      ),
                                    )
                                  : const CircleAvatar(
                                      child: Icon(Icons.person, size: 24),
                                    ),
                              title: Text(user['username']),
                              onTap: () {
                                final text = _replyController.text;
                                final words = text.split(' ');
                                if (words.isNotEmpty) {
                                  words.removeLast();
                                  words.add('@${user['username']}');
                                }
                                final newText = words.join(' ') + ' ';
                                _replyController.text = newText;
                                _replyController.selection =
                                    TextSelection.fromPosition(
                                      TextPosition(
                                        offset: _replyController.text.length,
                                      ),
                                    );

                                setState(() {
                                  showSuggestions = false;
                                });
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // **Input Reply ด้านล่าง แยกออกมา**
            Container(
              margin: EdgeInsets.zero, // เอา padding/margin ออกให้ชิดขอบล่าง
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (userId != null) {
                        _fetchCurrentUserInfo(userId!);
                      }
                    },
                    child: CircleAvatar(
                      radius: 22,
                      backgroundImage: profilePictureUrl != null
                          ? NetworkImage(profilePictureUrl!)
                          : null,
                      backgroundColor: Colors.grey.shade300,
                      child: profilePictureUrl == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 10,
                          ),
                          child: RichText(
                            text: _buildHighlightText(_replyController.text),
                          ),
                        ),
                        TextField(
                          controller: _replyController,
                          maxLines: null,
                          cursorColor: Colors.black,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Write a reply...',
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
                            final lastWord = words.isNotEmpty ? words.last : '';

                            if (lastWord.startsWith('@')) {
                              final mentionText = lastWord
                                  .substring(1)
                                  .toLowerCase();
                              setState(() {
                                currentMention = mentionText;
                                mentionSuggestions = allUsers
                                    .where(
                                      (user) =>
                                          user['username']
                                              .toLowerCase()
                                              .startsWith(mentionText) &&
                                          user['User_ID'] != userId,
                                    )
                                    .toList();
                                showSuggestions = mentionSuggestions.isNotEmpty;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  _isSending
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : InkWell(
                          onTap: sendReply,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.deepOrangeAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _selectedUser!['username'],
                                  style: TextStyle(
                                    fontSize: 22, // เพิ่มขนาดฟอนต์
                                    fontWeight:
                                        FontWeight.w800, // ตัวหนากว่าเดิม
                                    color: const Color.fromARGB(
                                      255,
                                      255,
                                      255,
                                      255,
                                    ),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(width: 5),
                                Icon(
                                  Icons.verified,
                                  size: 22,
                                  color: const Color.fromARGB(255, 10, 10, 10),
                                ),
                              ],
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
          : null,
    );
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
      height: 410,
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

  // ... _buildThreadItem() และ _buildReplyItem() ตามเดิม
  Widget _buildThreadItem(Map thread, bool likedByUser) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4), // สีเงาและความโปร่งใส
            spreadRadius: 3, // ขนาดเงา
            blurRadius: 5, // ความฟุ้งของเงา
            offset: const Offset(0, 4), // ตำแหน่งเงา (x, y)
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_selectedUser != null &&
                            _selectedUser!['User_ID'] == thread['User_ID']) {
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
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.grey[200]),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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

                            Icon(Icons.verified, size: 16, color: Colors.blue),
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
                          style: TextStyle(
                            fontSize: 12.3,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 9),

              SizedBox(height: 5),

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
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
              ),
              const SizedBox(height: 10),

              Divider(color: Colors.grey.shade300, thickness: 0.7),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ปุ่ม Verify อยู่ชิดซ้าย
                  // GestureDetector(
                  //   onTap: () async {
                  //     final shouldRefresh = await Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => PendingRepliesAdminPage(
                  //           threadId: widget.thread['Thread_ID'],
                  //         ),
                  //       ),
                  //     );
                  //     if (shouldRefresh == true) {
                  //       await fetchReplies();
                  //       await refreshThreadData();
                  //       await fetchPendingRepliesCount();
                  //     }
                  //   },
                  //   child: Stack(
                  //     clipBehavior: Clip.none,
                  //     children: [
                  //       Container(
                  //         padding: const EdgeInsets.symmetric(
                  //           horizontal: 15,
                  //           vertical: 6,
                  //         ),
                  //         decoration: BoxDecoration(
                  //           color: const Color.fromARGB(255, 43, 43, 43),
                  //           borderRadius: BorderRadius.circular(20),
                  //           border: Border.all(
                  //             color: const Color.fromARGB(255, 86, 86, 86),
                  //           ),
                  //         ),
                  //         child: Row(
                  //           mainAxisSize: MainAxisSize.min,
                  //           children: [
                  //             Icon(
                  //               Icons.verified,
                  //               size: 20,
                  //               color: Colors.white,
                  //             ),
                  //             SizedBox(width: 8),
                  //             Text(
                  //               'Verify Reply',
                  //               style: TextStyle(
                  //                 color: Colors.white,
                  //                 fontWeight: FontWeight.bold,
                  //                 fontSize: 12.5,
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       ),

                  //       // Notification Badge
                  //       if (pendingRepliesCount > 0)
                  //         Positioned(
                  //           right: -5,
                  //           top: -20,
                  //           child: Container(
                  //             padding: EdgeInsets.all(6),
                  //             decoration: BoxDecoration(
                  //               color: const Color.fromARGB(255, 219, 31, 31),
                  //               shape: BoxShape.circle,
                  //               border: Border.all(
                  //                 color: Colors.white,
                  //                 width: 2,
                  //               ),
                  //             ),
                  //             child: Text(
                  //               '$pendingRepliesCount',
                  //               style: TextStyle(
                  //                 color: Colors.white,
                  //                 fontSize: 12,
                  //                 fontWeight: FontWeight.bold,
                  //               ),
                  //             ),
                  //           ),
                  //         ),
                  //     ],
                  //   ),
                  // ),
                  Spacer(),
                  // Like และ Comment อยู่ชิดขวา
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Report

                      // Like button
                      InkWell(
                        // onTap: () {
                        //   toggleLike(thread['Thread_ID'], likedByUser);
                        // },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: likedByUser
                                ? Colors.red.shade50
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: likedByUser
                                  ? Colors.red.shade200
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.favorite,
                                size: 18,
                                color: likedByUser
                                    ? Colors.red
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${thread['total_likes']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: likedByUser
                                      ? Colors.red.shade700
                                      : Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),

                      // Comment button
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.comment,
                              size: 18,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 6),
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
                      const SizedBox(width: 10),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: -5,
            left: -5,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 212, 58, 58),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.verified, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyItem(Map reply) {
    final isMe = reply['User_ID'] == userId;
    final isPending = reply['status'] == 'pending';
    final isRejected = reply['status'] == 'rejected';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          // Avatar ซ้าย
          if (!isMe) ...[_buildAvatar(reply), const SizedBox(width: 10)],

          // Bubble + Report Button (Stack)
          Flexible(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Bubble
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.only(
                    top: 12,
                    bottom: 30,
                    left: 15,
                    right: 15,
                  ),
                  margin: EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color.fromARGB(255, 216, 228, 235)
                        : const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.only(
                      topLeft: isMe
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                      topRight: isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                      bottomLeft: const Radius.circular(18),
                      bottomRight: const Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 7,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username + Email + Time
                      Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Name
                              Text(
                                reply['username'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.5,
                                  color: Color.fromARGB(255, 33, 33, 33),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.blue,
                              ),

                              // Email
                            ],
                          ),
                          const Spacer(),
                          // Time + Checkmark
                          Row(
                            children: [
                              Text(
                                timeAgo(reply['created_at'] ?? ''),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (isMe) ...[],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Status Indicator
                      if (isPending || isRejected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isPending
                                ? const Color(0xFFFBBC05).withOpacity(0.2)
                                : const Color(0xFFEA4335).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPending ? Icons.access_time : Icons.warning,
                                size: 12,
                                color: isPending
                                    ? const Color(0xFFFBBC05)
                                    : const Color(0xFFEA4335),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isPending ? 'Pending Review' : 'Rejected',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: isPending
                                      ? const Color(0xFFFBBC05)
                                      : const Color(0xFFEA4335),
                                ),
                              ),
                            ],
                          ),
                        ),

                      Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child:
                                // Message Text
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: isMe
                                          ? const Color.fromARGB(255, 0, 0, 0)
                                          : const Color(0xFF202124),
                                      height: 1.4,
                                    ),
                                    children: _buildMessageWithMentions(
                                      reply['message'] ?? '',
                                    ),
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Report Button (ทุกคน) อยู่ด้านนอกขวาล่าง
                // Positioned(
                //   bottom: -8,
                //   right: -1,
                //   child: IconButton(
                //     icon: Icon(
                //       Icons.report_gmailerrorred,
                //       size: 20,
                //       color: Colors.grey[600],
                //     ),
                //     onPressed: () => _showRejectDialog(reply),
                //     padding: EdgeInsets.zero,
                //     constraints: const BoxConstraints(),
                //     tooltip: 'Report this message',
                //   ),
                // ),
              ],
            ),
          ),

          // Avatar ขวา
          if (isMe) ...[const SizedBox(width: 10), _buildAvatar(reply)],
        ],
      ),
    );
  }

  // Avatar + Verified
  Widget _buildAvatar(Map reply) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              if (_selectedUser != null &&
                  _selectedUser!['User_ID'] == reply['User_ID']) {
                _selectedUser = null;
              } else {
                _selectedUser = reply;
              }
            });
          },
          child: CircleAvatar(
            backgroundImage: NetworkImage(reply['picture_url'] ?? ''),
            radius: 24,
            backgroundColor: Colors.grey[200],
          ),
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF4285F4),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.verified, size: 14, color: Colors.white),
          ),
        ),
      ],
    );
  }

  List<TextSpan> _buildMessageWithMentions(String message) {
    final RegExp regex = RegExp(r'@[\w]+'); // หา pattern @username
    final List<TextSpan> spans = [];

    int start = 0;
    final matches = regex.allMatches(message);

    for (final match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(text: message.substring(start, match.start)));
      }

      final mentionText = message.substring(match.start, match.end);

      spans.add(
        TextSpan(
          text: mentionText,
          style: TextStyle(
            fontSize: 18,
            color: const Color.fromARGB(255, 233, 0, 0),
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = match.end;
    }

    if (start < message.length) {
      spans.add(TextSpan(text: message.substring(start)));
    }

    return spans;
  }

  TextSpan _buildHighlightText(String text) {
    final RegExp exp = RegExp(r'(@\w+)');
    final List<TextSpan> spans = [];
    int start = 0;

    final matches = exp.allMatches(text);

    for (final match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      );
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return TextSpan(
      style: const TextStyle(color: Colors.black, fontSize: 10),
      children: spans,
    );
  }

  String timeAgo(String datetimeString) {
    if (datetimeString.isEmpty) return '';
    try {
      DateTime dateTime = DateTime.parse(datetimeString).toLocal();
      Duration diff = DateTime.now().difference(dateTime);

      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      return '${diff.inDays} days ago';
    } catch (e) {
      return '';
    }
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
