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

  @override
  void initState() {
    super.initState();
    _loadUserID();
  }

  Future<void> _loadUserID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('User_ID');
    });
    fetchThreads();
  }

  Future<void> fetchThreads() async {
    final response = await http.get(
      Uri.parse(
        'https://mfu-food-guide-review.onrender.com/get_threads',
      ), // 🔁 เปลี่ยนเป็น API จริง
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
      Uri.parse('https://mfu-food-guide-review.onrender.com/toggle_like'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'User_ID': userId,
        'Thread_ID': threadId,
        'liked': !liked, // สลับสถานะ
      }),
    );

    if (response.statusCode == 200) {
      fetchThreads(); // reload UI
    } else {
      throw Exception('Failed to toggle like');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food Threads 🧵'), centerTitle: true),
      body: ListView.builder(
        itemCount: threads.length,
        itemBuilder: (context, index) {
          final thread = threads[index];
          final likedByUser = thread['liked_by_user'] == 1;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(thread['profile_picture']),
              ),
              title: Text(thread['fullname']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(thread['time_posted']),
                  const SizedBox(height: 4),
                  Text(thread['message']),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          likedByUser ? Icons.favorite : Icons.favorite_border,
                          color: likedByUser ? Colors.red : Colors.grey,
                        ),
                        onPressed: () {
                          toggleLike(thread['Thread_ID'], likedByUser);
                        },
                      ),
                      Text('${thread['total_likes']}'),
                      const SizedBox(width: 12),
                      const Icon(Icons.comment, size: 20),
                      const SizedBox(width: 4),
                      Text('${thread['total_comments']}'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
