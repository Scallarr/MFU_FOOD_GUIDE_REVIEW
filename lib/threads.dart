import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ThreadsPage extends StatefulWidget {
  const ThreadsPage({super.key});

  @override
  State<ThreadsPage> createState() => _ThreadsPageState();
}

class _ThreadsPageState extends State<ThreadsPage> {
  List threads = [];
  int? userId;
  TextEditingController _textController = TextEditingController();

  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUserID();
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
        _textController.clear();
        fetchThreads();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thread posted successfully')),
        );
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

  @override
  Widget build(BuildContext context) {
    // กรอง threads ตาม search query
    final filteredThreads = threads.where((thread) {
      final message = thread['message'].toString().toLowerCase();
      final fullname = thread['fullname'].toString().toLowerCase();
      final status = thread['status']?.toString().toLowerCase() ?? '';
      return message.contains(_searchQuery) ||
          fullname.contains(_searchQuery) ||
          status.contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF), // สีพื้นหลังอ่อนๆ
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            centerTitle: true,
            floating: true,
            snap: true,
            pinned: false,
            backgroundColor: const Color(0xFFCEBFA3),
            expandedHeight: 70,
            flexibleSpace: const FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 16, bottom: 12),
              title: Text(
                'Food Threads 🧵',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
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
            ),
            elevation: 4,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final thread = filteredThreads[index];
              final likedByUser = thread['is_liked'] == 1;

              return Container(
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
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      thread['fullname'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      timeAgo(thread['created_at']),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
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
                          const SizedBox(height: 7),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              InkWell(
                                onTap: () {
                                  toggleLike(thread['Thread_ID'], likedByUser);
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
              );
            }, childCount: filteredThreads.length),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 90)),
        ],
      ),

      bottomSheet: Container(
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
            CircleAvatar(
              radius: 22,
              backgroundImage: userId != null
                  ? NetworkImage(
                      'https://mfu-food-guide-review.onrender.com/user_profile_picture/$userId',
                    )
                  : null,
              backgroundColor: Colors.grey.shade300,
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
