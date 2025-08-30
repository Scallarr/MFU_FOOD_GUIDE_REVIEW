import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PendingRepliesAdminPage extends StatefulWidget {
  final int threadId;

  const PendingRepliesAdminPage({super.key, required this.threadId});

  @override
  State<PendingRepliesAdminPage> createState() =>
      _PendingRepliesAdminPageState();
}

class _PendingRepliesAdminPageState extends State<PendingRepliesAdminPage> {
  List<Map<String, dynamic>> pendingReplies = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPendingReplies();
  }

  Future<void> fetchPendingReplies() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://mfu-food-guide-review.onrender.com/threads-replied/pending/${widget.threadId}',
        ),
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          pendingReplies = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch pending replies')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> updateReplyStatus(int replyId, String status) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://mfu-food-guide-review.onrender.com/api/update-reply-status',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'reply_id': replyId, 'status': status}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reply $status successfully'),
            backgroundColor: status == 'Approved' ? Colors.green : Colors.red,
          ),
        );
        // Refresh the list
        await fetchPendingReplies();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update reply status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
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

  Widget _buildPendingReplyItem(Map<String, dynamic> reply) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(
                    reply['picture_url'] ??
                        'https://e7.pngegg.com/pngimages/84/165/png-clipart-united-states-avatar-organization-information-user-avatar-service-computer-wallpaper-thumbnail.png',
                  ),
                  radius: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reply['username'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Replied to: ${reply['replied_to_username']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  timeAgo(reply['created_at'] ?? ''),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                reply['message'] ?? '',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: reply['ai_evaluation'] == 'Inappropriate'
                        ? Colors.red[100]
                        : Colors.green[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'AI: ${reply['ai_evaluation'] ?? 'N/A'}',
                    style: TextStyle(
                      color: reply['ai_evaluation'] == 'Inappropriate'
                          ? Colors.red[800]
                          : Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Status: Pending',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    updateReplyStatus(reply['Thread_reply_ID'], 'Approved');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.check, size: 18, color: Colors.white),
                  label: const Text(
                    'Approve',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    updateReplyStatus(reply['Thread_reply_ID'], 'Rejected');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.close, size: 18, color: Colors.white),
                  label: const Text(
                    'Reject',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pending Replies for Thread #${widget.threadId}'),
        backgroundColor: const Color(0xFFCEBFA3),
        foregroundColor: Colors.black,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFCEBFA3)),
              ),
            )
          : pendingReplies.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No pending replies for this thread',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchPendingReplies,
              color: const Color(0xFFCEBFA3),
              child: ListView.builder(
                itemCount: pendingReplies.length,
                itemBuilder: (context, index) {
                  final reply = pendingReplies[index];
                  return _buildPendingReplyItem(reply);
                },
              ),
            ),
    );
  }
}
