import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ThreadRepliesPage extends StatefulWidget {
  final Map thread;

  const ThreadRepliesPage({super.key, required this.thread});

  @override
  State<ThreadRepliesPage> createState() => _ThreadRepliesPageState();
}

class _ThreadRepliesPageState extends State<ThreadRepliesPage> {
  List replies = [];
  bool isLoading = true;
  int? currentUserId;

  TextEditingController _replyController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    fetchReplies();
    loadUserId();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getInt('user_id');
    });
  }

  Future<void> fetchReplies() async {
    final threadId = widget.thread['Thread_ID'] ?? 0;
    final url = Uri.parse(
      'https://mfu-food-guide-review.onrender.com/api/thread_replies/$threadId',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final filteredReplies = data;
        setState(() {
          replies = filteredReplies;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching replies: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> sendReply() async {
    if (_replyController.text.trim().isEmpty || currentUserId == null) return;

    setState(() {
      _isSending = true;
    });

    final message = _replyController.text.trim();
    final threadId = widget.thread['Thread_ID'] ?? 0;

    try {
      final response = await http.post(
        Uri.parse('https://mfu-food-guide-review.onrender.com/api/send_reply'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'User_ID': currentUserId,
          'Thread_ID': threadId,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _replyController.clear();
        });
        await fetchReplies();
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

  @override
  Widget build(BuildContext context) {
    final thread = widget.thread;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        title: Text(
          'Replies to ${thread['fullname']} ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
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
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const SizedBox(height: 18),
            _buildThreadItem(thread),
            const SizedBox(height: 16),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : replies.isEmpty
                  ? const Center(child: Text('No replies found'))
                  : ListView.builder(
                      itemCount: replies.length,
                      itemBuilder: (context, index) {
                        final reply = replies[index];
                        return _buildReplyItem(reply);
                      },
                    ),
            ),

            // --- เพิ่มช่องใส่ Reply ด้านล่าง ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                  // รูปโปรไฟล์ซ้ายสุด
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: currentUserId != null
                        ? NetworkImage(
                            'https://mfu-food-guide-review.onrender.com/user_profile_picture/$currentUserId',
                          )
                        : null,
                    backgroundColor: Colors.grey.shade300,
                  ),
                  const SizedBox(width: 10),

                  // ช่องพิมพ์ข้อความ
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Write a reply...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Color(0xFFF0F0F0),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // ปุ่มส่ง
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
  Widget _buildThreadItem(Map thread) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(thread['picture_url'] ?? ''),
                radius: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            thread['fullname'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                    Text(
                      timeAgo(thread['created_at'] ?? ''),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(thread['message'] ?? '', style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red),
                ),

                child: Row(
                  children: [
                    const Icon(Icons.favorite, size: 18, color: Colors.red),
                    const SizedBox(width: 7),
                    Text('${thread['total_likes'] ?? 0}'),
                  ],
                ),
              ),
              const SizedBox(width: 30),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color.fromARGB(255, 73, 108, 223),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.comment,
                      size: 20,
                      color: Color.fromARGB(255, 11, 127, 223),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '${thread['total_comments'] ?? 0} ',
                      style: TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyItem(Map reply) {
    final isMe = reply['User_ID'] == currentUserId;
    print(currentUserId);
    print(reply['User_ID']);
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: isMe
          ? [
              // Bubble + Name + Time (ขวา)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.only(
                    left: 14,
                    right: 14,
                    top: 13,
                    bottom: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          0.2,
                        ), // สีเงาและความโปร่งใส
                        spreadRadius: 4, // ขนาดเงา
                        blurRadius: 5, // ความฟุ้งของเงา
                        offset: const Offset(0, 4), // ตำแหน่งเงา (x, y)
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            reply['fullname'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                          const Icon(
                            Icons.check_circle,
                            color: Colors.blue,
                            size: 15,
                          ),
                          const Spacer(),
                          Text(
                            timeAgo(reply['created_at'] ?? ''),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),

                          const SizedBox(width: 5),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        reply['message'] ?? '',
                        textAlign: TextAlign.left,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Profile Picture (ขวา)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(reply['picture_url'] ?? ''),
                    radius: 30,
                  ),
                  Positioned(
                    top: -7,
                    left: 40,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 212, 69, 69),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(
                        Icons.verified,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ]
          : [
              // Profile Picture (ซ้าย)
              // Profile Picture (ซ้าย) + verified icon
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(reply['picture_url'] ?? ''),
                    radius: 30,
                  ),
                  Positioned(
                    top: -5,
                    left: -5,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 212, 58, 58),
                        borderRadius: BorderRadius.circular(7),
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
              const SizedBox(width: 10),

              const SizedBox(width: 10),
              // Bubble + Name + Time
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          0.2,
                        ), // สีเงาและความโปร่งใส
                        spreadRadius: 4, // ขนาดเงา
                        blurRadius: 5, // ความฟุ้งของเงา
                        offset: const Offset(0, 4), // ตำแหน่งเงา (x, y)
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Time
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  reply['fullname'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.blue,
                                  size: 15,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            timeAgo(reply['created_at'] ?? ''),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        reply['message'] ?? '',
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
