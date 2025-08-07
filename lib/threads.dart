import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThreadPage extends StatefulWidget {
  const ThreadPage({Key? key}) : super(key: key);

  @override
  _ThreadPageState createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  List<dynamic> threads = [];
  int currentUserId = 0;

  @override
  void initState() {
    super.initState();
    loadUserId();
    fetchThreads();
  }

  Future<void> loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getInt('User_ID') ?? 0;
    });
  }

  Future<void> fetchThreads() async {
    final response = await http.get(
      Uri.parse('https://mfu-food-guide-review.onrender.com/get_threads'),
    );
    if (response.statusCode == 200) {
      setState(() {
        threads = json.decode(response.body);
      });
    } else {
      print('Failed to load threads');
    }
  }

  Future<void> toggleLike(int threadId, bool isLiked) async {
    final url = isLiked
        ? 'https://mfu-food-guide-review.onrender.com/unlike_thread'
        : 'https://mfu-food-guide-review.onrender.com/like_thread';

    final response = await http.post(
      Uri.parse(url),
      body: {
        'User_ID': currentUserId.toString(),
        'Thread_ID': threadId.toString(),
      },
    );

    if (response.statusCode == 200) {
      fetchThreads(); // Refresh threads
    } else {
      print('Failed to toggle like');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food Threads')),
      body: ListView.builder(
        itemCount: threads.length,
        itemBuilder: (context, index) {
          final thread = threads[index];
          final isLiked = thread['is_liked'] == 1;
          final formattedTime = DateFormat(
            'yyyy-MM-dd HH:mm',
          ).format(DateTime.parse(thread['created_at']));

          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(thread['picture_url']),
              ),
              title: Text(thread['fullname']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(thread['message']),
                  Text(
                    'Posted on $formattedTime',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.grey,
                        ),
                        onPressed: () =>
                            toggleLike(thread['Thread_ID'], isLiked),
                      ),
                      Text('${thread['Total_likes']} Likes'),
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
