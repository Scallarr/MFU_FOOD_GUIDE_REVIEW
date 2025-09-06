import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/admin/Admin-Thread-Reply-Pending.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThreadRepliesAdminPage extends StatefulWidget {
  final Map thread;
  final bool likedByUser;

  const ThreadRepliesAdminPage({
    super.key,
    required this.thread,
    required this.likedByUser,
  });

  @override
  State<ThreadRepliesAdminPage> createState() => _ThreadRepliesAdminPageState();
}

class _ThreadRepliesAdminPageState extends State<ThreadRepliesAdminPage> {
  List replies = [];
  bool isLoading = true;
  int? userId;
  String? profilePictureUrl;
  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> mentionSuggestions = [];
  bool showSuggestions = false;
  String currentMention = '';
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
      'http://10.0.3.201:8080/user_profile_picture/$userId',
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

  Future<void> fetchReplies() async {
    final threadId = widget.thread['Thread_ID'] ?? 0;
    final url = Uri.parse(
      'http://10.0.3.201:8080/api/thread_replies/$threadId',
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
        Uri.parse('http://10.0.3.201:8080/api/all_users'),
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
        Uri.parse('http://10.0.3.201:8080/api/send_reply'),
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
  //     Uri.parse('http://10.0.3.201:8080/like_thread'),
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
          'http://10.0.3.201:8080/threads-replied/AdminManual-check/reject',
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
        Uri.parse('http://10.0.3.201:8080/api/pending_replies_count/$threadId'),
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
        Uri.parse('http://10.0.3.201:8080/all_threads/$userId'),
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true); // ส่งค่ากลับว่าให้รีเฟรชหน้าก่อนหน้า
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
                  CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        (profilePictureUrl != null &&
                            profilePictureUrl!.isNotEmpty)
                        ? NetworkImage(profilePictureUrl!)
                        : const NetworkImage(
                            'https://e7.pngegg.com/pngimages/84/165/png-clipart-united-states-avatar-organization-information-user-avatar-service-computer-wallpaper-thumbnail.png',
                          ),
                    backgroundColor: Colors.grey.shade200,
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
                  Container(
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
                  GestureDetector(
                    onTap: () async {
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
                        await fetchPendingRepliesCount();
                      }
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 43, 43, 43),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color.fromARGB(255, 86, 86, 86),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                size: 20,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Verify Reply',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Notification Badge
                        if (pendingRepliesCount > 0)
                          Positioned(
                            right: -5,
                            top: -20,
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 219, 31, 31),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                '$pendingRepliesCount',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
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
                  margin: EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color.fromARGB(255, 192, 212, 245)
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
                                      fontSize: 15,
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
                Positioned(
                  bottom: -8,
                  right: -1,
                  child: IconButton(
                    icon: Icon(
                      Icons.report_gmailerrorred,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                    onPressed: () => _showRejectDialog(reply),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Report this message',
                  ),
                ),
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
        CircleAvatar(
          backgroundImage: NetworkImage(reply['picture_url'] ?? ''),
          radius: 24,
          backgroundColor: Colors.grey[200],
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
            fontSize: 15,
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
