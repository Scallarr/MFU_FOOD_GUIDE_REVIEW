import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class MyHistoryPage extends StatefulWidget {
  @override
  _MyHistoryPageState createState() => _MyHistoryPageState();
}

class _MyHistoryPageState extends State<MyHistoryPage>
    with SingleTickerProviderStateMixin {
  int? userId;
  late TabController _tabController;
  List<dynamic> _threadApprovalHistory = [];
  List<dynamic> _replyApprovalHistory = [];
  List<dynamic> _myThreads = [];
  List<dynamic> _myReplies = [];
  bool _isLoading = true;

  // Colors
  final Color _primaryColor = Color(0xFF4285F4);
  final Color _successColor = Color(0xFF34A853);
  final Color _warningColor = Color(0xFFFBBC05);
  final Color _dangerColor = Color(0xFFEA4335);
  final Color _cardColor = Colors.white;
  final Color _textColor = Color(0xFF202124);
  final Color _secondaryTextColor = Color(0xFF5F6368);
  final Color _appBarColor = Color(0xFFCEBFA3);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('user_id');
    });
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _fetchThreadApprovalHistory(),
        _fetchReplyApprovalHistory(),
        _fetchMyThreads(),
        _fetchMyReplies(),
      ]);
    } catch (e) {
      print('Error fetching data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchThreadApprovalHistory() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://mfu-food-guide-review.onrender.com/api/admin_thread_history/$userId',
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _threadApprovalHistory = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error fetching thread approval history: $e');
    }
  }

  Future<void> _fetchReplyApprovalHistory() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://mfu-food-guide-review.onrender.com/api/admin_reply_history/$userId',
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _replyApprovalHistory = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error fetching reply approval history: $e');
    }
  }

  Future<void> _fetchMyThreads() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://mfu-food-guide-review.onrender.com/api/my_threads/$userId',
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _myThreads = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error fetching my threads: $e');
    }
  }

  Future<void> _fetchMyReplies() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://mfu-food-guide-review.onrender.com/api/my_replies/$userId',
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _myReplies = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error fetching my replies: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F4EF),
      appBar: AppBar(
        title: Text('My History', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: _appBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Thread Approval'),
            Tab(text: 'Reply Approval'),
            Tab(text: 'My Threads'),
            Tab(text: 'My Replies'),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildThreadApprovalHistory(),
                _buildReplyApprovalHistory(),
                _buildMyThreads(),
                _buildMyReplies(),
              ],
            ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _primaryColor, strokeWidth: 3),
          SizedBox(height: 20),
          Text(
            'Loading your history...',
            style: TextStyle(color: _secondaryTextColor, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildThreadApprovalHistory() {
    return _threadApprovalHistory.isEmpty
        ? _buildEmptyView('No thread approval history found')
        : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _threadApprovalHistory.length,
            itemBuilder: (context, index) {
              final item = _threadApprovalHistory[index];
              return _buildThreadApprovalItem(item);
            },
          );
  }

  Widget _buildReplyApprovalHistory() {
    return _replyApprovalHistory.isEmpty
        ? _buildEmptyView('No reply approval history found')
        : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _replyApprovalHistory.length,
            itemBuilder: (context, index) {
              final item = _replyApprovalHistory[index];
              return _buildReplyApprovalItem(item);
            },
          );
  }

  Widget _buildMyThreads() {
    return _myThreads.isEmpty
        ? _buildEmptyView('No threads found')
        : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _myThreads.length,
            itemBuilder: (context, index) {
              final thread = _myThreads[index];
              return _buildThreadItem(thread);
            },
          );
  }

  Widget _buildMyReplies() {
    return _myReplies.isEmpty
        ? _buildEmptyView('No replies found')
        : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _myReplies.length,
            itemBuilder: (context, index) {
              final reply = _myReplies[index];
              return _buildReplyItem(reply);
            },
          );
  }

  Widget _buildEmptyView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 64,
            color: _secondaryTextColor.withOpacity(0.3),
          ),
          SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: _textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreadApprovalItem(Map<String, dynamic> item) {
    final action = item['admin_action_taken'];
    Color statusColor;
    String statusText;

    switch (action) {
      case 'Safe':
        statusColor = _successColor;
        statusText = 'Approved';
        break;
      case 'Banned':
        statusColor = _dangerColor;
        statusText = 'Rejected';
        break;
      default:
        statusColor = _warningColor;
        statusText = 'Pending';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatusChip(statusText, statusColor),
                  Spacer(),
                  Text(
                    _formatDate(item['admin_checked_at']),
                    style: TextStyle(fontSize: 12, color: _secondaryTextColor),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                item['message'] ?? 'No message',
                style: TextStyle(
                  fontSize: 16,
                  color: _textColor,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Text(
                'Author: ${item['author_username']}',
                style: TextStyle(fontSize: 14, color: _secondaryTextColor),
              ),
              if (item['reason_for_taken'] != null) ...[
                SizedBox(height: 8),
                Text(
                  'Reason: ${item['reason_for_taken']}',
                  style: TextStyle(fontSize: 14, color: _secondaryTextColor),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyApprovalItem(Map<String, dynamic> item) {
    final action = item['admin_action_taken'];
    Color statusColor;
    String statusText;

    switch (action) {
      case 'Safe':
        statusColor = _successColor;
        statusText = 'Approved';
        break;
      case 'Banned':
        statusColor = _dangerColor;
        statusText = 'Rejected';
        break;
      default:
        statusColor = _warningColor;
        statusText = 'Pending';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatusChip(statusText, statusColor),
                  Spacer(),
                  Text(
                    _formatDate(item['admin_checked_at']),
                    style: TextStyle(fontSize: 12, color: _secondaryTextColor),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Reply: ${item['message'] ?? 'No message'}',
                style: TextStyle(
                  fontSize: 16,
                  color: _textColor,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Text(
                'Thread: ${item['thread_message'] ?? 'No thread message'}',
                style: TextStyle(
                  fontSize: 14,
                  color: _secondaryTextColor,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Text(
                'Author: ${item['author_username']}',
                style: TextStyle(fontSize: 14, color: _secondaryTextColor),
              ),
              if (item['reason_for_taken'] != null) ...[
                SizedBox(height: 8),
                Text(
                  'Reason: ${item['reason_for_taken']}',
                  style: TextStyle(fontSize: 14, color: _secondaryTextColor),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThreadItem(Map<String, dynamic> thread) {
    final status = thread['admin_decision'];
    Color statusColor;
    String statusText;

    switch (status) {
      case 'Posted':
        statusColor = _successColor;
        statusText = 'Posted';
        break;
      case 'Banned':
        statusColor = _dangerColor;
        statusText = 'Banned';
        break;
      default:
        statusColor = _warningColor;
        statusText = 'Pending';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatusChip(statusText, statusColor),
                  Spacer(),
                  Text(
                    _formatDate(thread['created_at']),
                    style: TextStyle(fontSize: 12, color: _secondaryTextColor),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                thread['message'] ?? 'No message',
                style: TextStyle(
                  fontSize: 16,
                  color: _textColor,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildMetricChip(
                    Icons.favorite,
                    '${thread['Total_likes'] ?? 0}',
                  ),
                  SizedBox(width: 8),
                  _buildMetricChip(
                    Icons.reply,
                    '${thread['reply_count'] ?? 0}',
                  ),
                ],
              ),
              if (thread['ai_evaluation'] != null) ...[
                SizedBox(height: 12),
                _buildAIStatus(thread['ai_evaluation']),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyItem(Map<String, dynamic> reply) {
    final status = reply['admin_decision'];
    Color statusColor;
    String statusText;

    switch (status) {
      case 'Posted':
        statusColor = _successColor;
        statusText = 'Posted';
        break;
      case 'Banned':
        statusColor = _dangerColor;
        statusText = 'Banned';
        break;
      default:
        statusColor = _warningColor;
        statusText = 'Pending';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatusChip(statusText, statusColor),
                  Spacer(),
                  Text(
                    _formatDate(reply['created_at']),
                    style: TextStyle(fontSize: 12, color: _secondaryTextColor),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Reply: ${reply['message'] ?? 'No message'}',
                style: TextStyle(
                  fontSize: 16,
                  color: _textColor,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Text(
                'Thread: ${reply['thread_message'] ?? 'No thread message'}',
                style: TextStyle(
                  fontSize: 14,
                  color: _secondaryTextColor,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildMetricChip(
                    Icons.favorite,
                    '${reply['total_Likes'] ?? 0}',
                  ),
                ],
              ),
              if (reply['ai_evaluation'] != null) ...[
                SizedBox(height: 12),
                _buildAIStatus(reply['ai_evaluation']),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _secondaryTextColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _secondaryTextColor),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: _secondaryTextColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIStatus(String status) {
    final colors = {
      'Safe': _successColor,
      'Inappropriate': _dangerColor,
      'Undetermined': _warningColor,
    };

    final icons = {
      'Safe': Icons.check_circle,
      'Inappropriate': Icons.warning,
      'Undetermined': Icons.help_outline,
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors[status]!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icons[status], size: 16, color: colors[status]),
          SizedBox(width: 8),
          Text(
            'AI Analysis: ',
            style: TextStyle(color: _secondaryTextColor, fontSize: 12),
          ),
          Text(
            status,
            style: TextStyle(
              color: colors[status],
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, y · h:mm a').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }
}
