import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ThreadRepliesPage extends StatefulWidget {
  final Map thread;

  const ThreadRepliesPage({super.key, required this.thread});

  @override
  State<ThreadRepliesPage> createState() => _ThreadRepliesPageState();
}

class _ThreadRepliesPageState extends State<ThreadRepliesPage> {
  List replies = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReplies();
  }

  Future<void> fetchReplies() async {
    final threadId =
        widget.thread['Thread_ID'] ?? widget.thread['Thread_ID'] ?? 0;
    print(threadId);
    // แก้ URL เป็นของ backend จริงของคุณ
    final url = Uri.parse(
      'https://mfu-food-guide-review.onrender.com/api/thread_replies/$threadId',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);

        // กรองเฉพาะ admin_decision = 'Posted' ถ้ายังไม่กรองที่ backend
        final filteredReplies = data
            .where((r) => r['admin_decision'] == 'Posted')
            .toList();

        setState(() {
          replies = filteredReplies;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        // แสดง error หรือข้อความไม่เจอได้
      }
    } catch (e) {
      print('Error fetching replies: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thread = widget.thread;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        title: Text('Replies to ${thread['fullname']}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildThreadItem(thread),
            const SizedBox(height: 16),
            const Divider(thickness: 1),
            const SizedBox(height: 16),
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
          ],
        ),
      ),
    );
  }

  Widget _buildThreadItem(Map thread) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
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
                        Text(
                          thread['fullname'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text('${thread['total_likes'] ?? 0}'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.comment, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text('${thread['total_comments'] ?? 0}'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyItem(Map reply) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(reply['profile_image'] ?? ''),
            radius: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    Text(
                      reply['fullname'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, size: 14, color: Colors.blue),
                    const Spacer(),
                    Text(
                      timeAgo(reply['created_at'] ?? ''),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  reply['message'] ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
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
