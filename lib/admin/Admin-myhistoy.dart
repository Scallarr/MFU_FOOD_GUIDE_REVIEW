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
    final prefs = await SharedPreferences.getInstance();
    final Admin = prefs.getInt('user_id');
    try {
      final response = await http.get(
        Uri.parse(
          'https://mfu-food-guide-review.onrender.com/api/my_admin_thread_replies/$Admin',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          _replyApprovalHistory = data.map((reply) {
            // กำหนดสถานะของ reply
            String status;
            if (reply['reply_admin_decision'] == 'Banned') {
              status = 'Banned';
            } else if (reply['reply_admin_decision'] == 'Posted') {
              status = 'Posted';
            } else {
              status = 'Posted';
            }

            return {
              'Thread_reply_ID': reply['Thread_reply_ID'],
              'Thread_ID': reply['Thread_ID'],
              'reply_message': reply['reply_message'],
              'reply_created_at': reply['reply_created_at'],
              'reply_total_Likes': reply['reply_total_Likes'],
              'reply_ai_evaluation': reply['reply_ai_evaluation'],
              'reply_admin_decision': reply['reply_admin_decision'],
              'status': status,

              // Author info
              'reply_author_id': reply['reply_author_id'],
              'reply_author_username': reply['reply_author_username'],
              'reply_author_email': reply['reply_author_email'],
              'reply_author_fullname': reply['reply_author_fullname'],
              'reply_author_picture': reply['reply_author_picture'],

              // Thread info
              'thread_id': reply['thread_id'],
              'thread_message': reply['thread_message'],
              'thread_created_at': reply['thread_created_at'],
              'thread_admin_decision': reply['thread_admin_decision'],
              'thread_total_like': reply['thread_totallikes'],
              'thread_author_username': reply['thread_author_username'],
              'thread_author_fullname': reply['thread_author_fullname'],
              'thread_author_picture': reply['thread_author_picture'],

              // Admin info
              'admin_id': reply['admin_id'],
              'admin_username': reply['admin_username'],
              'admin_fullname': reply['admin_fullname'],
              'admin_picture': reply['admin_picture'],
              'admin_action_taken': reply['admin_action_taken'],
              'admin_checked_at': reply['admin_checked_at'],
              'reason_for_taken': reply['reason_for_taken'],
            };
          }).toList();
        });
        print('Reply data: ${json.encode(data[0])}'); // ดูโครงสร้างข้อมูลแรก
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
        final List<dynamic> data = json.decode(response.body);

        // จัดการข้อมูลที่ได้รับจาก API
        setState(() {
          _myThreads = data.map((thread) {
            // กำหนดสถานะของโพสต์
            String status;
            if (thread['admin_action_taken'] == 'Banned') {
              status = 'Banned';
            } else if (thread['admin_decision'] == 'Posted') {
              status = 'Posted';
            } else {
              status = 'Pending';
            }

            return {
              'Thread_ID': thread['Thread_ID'],
              'message': thread['message'],
              'created_at': thread['created_at'],
              'Total_likes': thread['Total_likes'],
              'reply_count': thread['reply_count'],
              'ai_evaluation': thread['ai_evaluation'],
              'admin_decision': thread['admin_decision'],
              'status': status,
              'author_username': thread['author_username'],
              'author_email': thread['author_email'],
              'author_picture': thread['author_picture'],
              'admin_username': thread['admin_username'],
              'admin_action_taken': thread['admin_action_taken'],
              'admin_checked_at': thread['admin_checked_at'],
              'reason_for_taken':
                  thread['reason_for_taken'] ??
                  'Not Found Inappropriate Message',
            };
          }).toList();
        });
      } else {
        print('Failed to fetch threads: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching my threads: $e');
    }
  }

  Future<void> _fetchMyReplies() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://mfu-food-guide-review.onrender.com/api/my_thread_replies/$userId',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data2 = json.decode(response.body);

        // จัดการข้อมูลที่ได้รับจาก API
        setState(() {
          _myReplies = data2.map((thread) {
            // กำหนดสถานะของโพสต์
            String status;
            if (thread['reply_admin_decision'] == 'Banned') {
              status = 'Banned';
            } else if (thread['reply_admin_decision'] == 'Posted') {
              status = 'Posted';
            } else {
              status = 'Pending';
            }

            return {
              'Thread_ID': thread['Thread_ID'],
              'Thread_message': thread['thread_message'],
              'Thread_username': thread['thread_author_username'],
              'Thread_picture': thread['thread_author_picture'],
              'Thread_create_at': thread['thread_created_at'],
              'Thread_admin_decision': thread['thread_admin_decision'],
              'Thread_reply_ID': thread['Thread_reply_ID'],
              'message': thread['reply_message'],
              'created_at': thread['reply_created_at'],
              'Total_likes': thread['thread_total_like'],
              // 'reply_count': thread['reply_count'],
              'ai_evaluation': thread['reply_ai_evaluation'],
              'admin_decision': thread['reply_admin_decision'],
              'status': status,
              'author_username': thread['reply_author_username'],
              'author_email': thread['reply_author_email'],
              'author_picture': thread['reply_author_picture'],
              'admin_username': thread['admin_username'],

              'admin_checked_at': thread['admin_checked_at'],
              'reason_for_taken': thread['reason_for_taken'],
            };
          }).toList();
        });
      } else {
        print('Failed to fetch threads: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching my threads: $e');
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
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_outlined,
                size: 60,
                color: _primaryColor.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                color: _textColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Your content will appear here once created',
              style: TextStyle(fontSize: 14, color: _secondaryTextColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadApprovalItem(Map<String, dynamic> item) {
    final action = item['admin_action_taken'];
    Color statusColor;
    String statusText;
    Color containerColor;
    IconData statusIcon;
    bool isExpanded = true;

    switch (action) {
      case 'Safe':
        statusColor = _successColor;
        statusText = 'Approved';
        containerColor = _successColor.withOpacity(0.05);
        statusIcon = Icons.check_circle_outline;
        break;
      case 'Banned':
        statusColor = _dangerColor;
        statusText = 'Banned';
        containerColor = _dangerColor.withOpacity(0.05);
        statusIcon = Icons.block;
        break;
      default:
        statusColor = _warningColor;
        statusText = 'Pending';
        containerColor = _warningColor.withOpacity(0.05);
        statusIcon = Icons.access_time;
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: statusColor.withOpacity(0.3), width: 2),
            ),
            color: _cardColor,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Author Avatar
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _primaryColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: item['thread_author_picture'] != null
                              ? Image.network(
                                  item['thread_author_picture'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: _primaryColor.withOpacity(0.1),
                                      child: Icon(
                                        Icons.person,
                                        color: _primaryColor,
                                        size: 20,
                                      ),
                                    );
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                            strokeWidth: 2,
                                            color: _primaryColor,
                                          ),
                                        );
                                      },
                                )
                              : Container(
                                  color: _primaryColor.withOpacity(0.1),
                                  child: Icon(
                                    Icons.person,
                                    color: _primaryColor,
                                    size: 20,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Author: ${item['thread_author_username'] ?? 'Unknown User'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: _textColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatDate(item['admin_checked_at']),
                              style: TextStyle(
                                fontSize: 11,
                                color: _secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ), // Header with status and date
                      Row(
                        children: [
                          // Enhanced status chip with icon
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor.withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 16, color: statusColor),
                                SizedBox(width: 6),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 10),
                  Divider(
                    color: const Color.fromARGB(255, 226, 225, 225),
                    thickness: 1,
                  ),

                  SizedBox(height: 10),
                  // Thread message with improved background and border
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE8EAED), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      item['thread_message'] ?? 'No message',
                      style: TextStyle(
                        fontSize: 16,
                        color: _textColor,
                        height: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Author information
                  SizedBox(height: 16),

                  // Enhanced status details container
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    statusIcon,
                                    size: 18,
                                    color: statusColor,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Approval Details',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: statusColor,
                                size: 22,
                              ),
                              onPressed: () {
                                setState(() {
                                  isExpanded = !isExpanded;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),

                        if (isExpanded) ...[
                          SizedBox(height: 12),
                          Divider(
                            color: statusColor.withOpacity(0.2),
                            height: 1,
                          ),
                          SizedBox(height: 12),

                          // Action details
                          if (action == 'Banned') ...[
                            // Admin information
                            _buildEnhancedInfoRow(
                              'Thread ID',
                              'ID ${item['Thread_ID']}',
                              Icons.forum,
                              _dangerColor,
                            ),
                            _buildEnhancedInfoRow(
                              'Author by',
                              item['thread_author_username'] ?? 'Unknown Admin',
                              Icons.admin_panel_settings,
                              _dangerColor,
                            ),
                            if (item['admin_username'] != null)
                              _buildEnhancedInfoRow(
                                'Admin Action',
                                item['admin_username'],
                                Icons.person,
                                _dangerColor,
                              ),
                            if (item['reason_for_taken'] != null)
                              _buildEnhancedInfoRow(
                                'Reason for Banned',
                                item['reason_for_taken'],
                                Icons.info_outline,
                                _dangerColor,
                              ),
                          ] else if (action == 'Safe') ...[
                            // Admin information
                            _buildEnhancedInfoRow(
                              'Thread ID',
                              'ID ${item['Thread_ID']}',
                              Icons.forum,
                              _successColor,
                            ),
                            _buildEnhancedInfoRow(
                              'Author by',
                              item['thread_author_username'] ?? 'Unknown Admin',
                              Icons.admin_panel_settings,
                              _successColor,
                            ),
                            if (item['admin_username'] != null)
                              _buildEnhancedInfoRow(
                                'Admin Action',
                                item['admin_username'],
                                Icons.person,
                                _successColor,
                              ),
                            _buildEnhancedInfoRow(
                              'Reason for Approved',
                              item['reason_for_taken'] ??
                                  'Not Found Inappropriate Language',
                              Icons.info_outline,
                              _successColor,
                            ),
                          ],

                          // Timestamp
                          if (item['admin_checked_at'] != null)
                            _buildEnhancedInfoRow(
                              'Reviewed at',
                              _formatDate(item['admin_checked_at']),
                              Icons.calendar_today,
                              _successColor,
                            ),
                          // ใช้ใน widget
                          _buildEnhancedInfoRow(
                            'Status Threads',
                            (item['admin_action_taken'] == 'Safe')
                                ? 'Posted'
                                : item['admin_action_taken'],
                            getThreadStatusIcon(item['admin_action_taken']),
                            _successColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildMetricChipWithIcon(
                        Icons.favorite_outline,
                        '${item['Total_likes'] ?? 20}',
                        _getBackgroundColor(item['admin_action_taken']),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData getThreadStatusIcon(String status) {
    switch (status) {
      case 'Safe':
      case 'Posted':
        return Icons.check_circle;
      case 'Banned':
        return Icons.block;
      case 'Pending':
        return Icons.hourglass_empty;
      default:
        return Icons.forum;
    }
  }

  Widget _buildReplyApprovalItem(Map<String, dynamic> item) {
    final action = item['admin_action_taken'];
    final aiEvaluation = item['reply_ai_evaluation'];
    Color statusColor;
    String statusText;
    Color containerColor;
    IconData statusIcon;
    bool isExpanded = false;

    switch (action) {
      case 'Posted':
        statusColor = _successColor;
        statusText = 'Posted';
        containerColor = _successColor.withOpacity(0.05);
        statusIcon = Icons.check_circle_outline;
        break;
      case 'Banned':
        statusColor = _dangerColor;
        statusText = 'Banned';
        containerColor = _dangerColor.withOpacity(0.05);
        statusIcon = Icons.block;
        break;
      default:
        statusColor = _warningColor;
        statusText = 'Pending';
        containerColor = _warningColor.withOpacity(0.05);
        statusIcon = Icons.access_time;
    }

    // กำหนดสถานะของ Thread ต้นฉบับ
    final threadStatus = item['thread_admin_decision'];
    Color threadStatusColor;
    String threadStatusText;

    switch (threadStatus) {
      case 'Posted':
        threadStatusColor = _successColor;
        threadStatusText = 'Posted';
        break;
      case 'Banned':
        threadStatusColor = _dangerColor;
        threadStatusText = 'Banned';
        break;
      default:
        threadStatusColor = _warningColor;
        threadStatusText = 'Pending';
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: statusColor.withOpacity(0.3), width: 2),
            ),
            color: _cardColor,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with user avatar and info
                  Row(
                    children: [
                      // User Avatar
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _primaryColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: item['reply_author_picture'] != null
                              ? Image.network(
                                  item['reply_author_picture'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: _primaryColor.withOpacity(0.1),
                                      child: Icon(
                                        Icons.person,
                                        color: _primaryColor,
                                        size: 30,
                                      ),
                                    );
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                            strokeWidth: 2,
                                            color: _primaryColor,
                                          ),
                                        );
                                      },
                                )
                              : Container(
                                  color: _primaryColor.withOpacity(0.1),
                                  child: Icon(
                                    Icons.person,
                                    color: _primaryColor,
                                    size: 30,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['reply_author_username'] ?? 'Unknown User',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              _formatDate(item['reply_created_at']),
                              style: TextStyle(
                                fontSize: 11,
                                color: _secondaryTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Enhanced status chip with icon
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 16, color: statusColor),
                            SizedBox(width: 6),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 13),
                  Divider(
                    color: const Color.fromARGB(255, 226, 225, 225),
                    thickness: 1,
                  ),

                  SizedBox(height: 25),

                  // Original thread info with enhanced UI
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Color(0xFFE8EAED), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Main content
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10), // Space for the title
                            // Thread author info
                            Row(
                              children: [
                                // Thread Author Avatar
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _primaryColor.withOpacity(0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: item['thread_author_picture'] != null
                                        ? Image.network(
                                            item['thread_author_picture'],
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    color: _primaryColor
                                                        .withOpacity(0.1),
                                                    child: Icon(
                                                      Icons.person,
                                                      color: _primaryColor,
                                                      size: 20,
                                                    ),
                                                  );
                                                },
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value:
                                                      loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                      : null,
                                                  strokeWidth: 2,
                                                  color: _primaryColor,
                                                ),
                                              );
                                            },
                                          )
                                        : Container(
                                            color: _primaryColor.withOpacity(
                                              0.1,
                                            ),
                                            child: Icon(
                                              Icons.person,
                                              color: _primaryColor,
                                              size: 20,
                                            ),
                                          ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['thread_author_username'] ??
                                            'Unknown User',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _textColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        _formatDate(item['thread_created_at']),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Thread status chip
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: threadStatusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: threadStatusColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    threadStatusText,
                                    style: TextStyle(
                                      color: threadStatusColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 05),

                            Divider(
                              color: const Color.fromARGB(255, 226, 225, 225),
                              thickness: 1,
                            ),

                            SizedBox(height: 10),
                            // Thread message
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Color(0xFFE8EAED),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                item['thread_message'] ?? 'No thread message',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _textColor,
                                  height: 1.4,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(height: 20),
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.end,
                            //   children: [
                            //     _buildMetricChipWithIcon(
                            //       Icons.favorite_outline,
                            //       '${item['thread_total_like'] ?? 0}',
                            //       _getBackgroundColor(
                            //         item['thread_admin_decision'],
                            //       ),
                            //     ),
                            //   ],
                            // ),
                          ],
                        ),

                        // Title positioned on top border
                        Positioned(
                          top: -30,
                          left: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 255, 255, 255),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color.fromARGB(255, 207, 207, 207),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 14,
                                  color: _primaryColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Replying to this thread',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),

                  SizedBox(height: 30),
                  // Reply message with improved background and border
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(0xFFE8EAED),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          item['reply_message'] ?? 'No message',
                          style: TextStyle(
                            fontSize: 16,
                            color: _textColor,
                            height: 1.5,
                          ),
                        ),
                      ),

                      // 🟢 ตรงนี้ต้องอยู่ใน Stack ด้วย
                      Positioned(
                        top: -20, // ปรับตำแหน่งให้อยู่บนขอบ
                        left: 17,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color.fromARGB(255, 207, 207, 207),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 14,
                                color: _primaryColor,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Replying Message',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 22),

                  // Enhanced status details container
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    statusIcon,
                                    size: 18,
                                    color: statusColor,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Status Details',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: statusColor,
                                size: 22,
                              ),
                              onPressed: () {
                                setState(() {
                                  isExpanded = !isExpanded;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),

                        if (isExpanded) ...[
                          SizedBox(height: 12),
                          Divider(
                            color: statusColor.withOpacity(0.2),
                            height: 1,
                          ),
                          SizedBox(height: 12),

                          // Status-specific information with better formatting
                          if (statusText == 'Banned') ...[
                            _buildEnhancedInfoRow(
                              'Thread ID',
                              'ID ${item['Thread_ID']}',
                              Icons.forum,
                              _dangerColor,
                            ),
                            _buildEnhancedInfoRow(
                              'Reply ID',
                              'ID ${item['Thread_reply_ID']}',
                              Icons.reply,
                              _dangerColor,
                            ),
                            if (item['ai_evaluation'] != null)
                              _buildEnhancedInfoRow(
                                'AI Analysis',
                                item['ai_evaluation'],
                                Icons.psychology_outlined,
                                _dangerColor,
                              ),
                            if (item['admin_username'] != null)
                              _buildEnhancedInfoRow(
                                'Admin Action',
                                'Banned by ${item['admin_username']}',
                                Icons.gavel,
                                _dangerColor,
                              ),
                            if (item['reason_for_taken'] != null)
                              _buildEnhancedInfoRow(
                                'Reason For Banned',
                                item['reason_for_taken'],
                                Icons.info_outline,
                                _dangerColor,
                              ),
                            if (item['admin_checked_at'] != null)
                              _buildEnhancedInfoRow(
                                'Action Taken',
                                _formatDate(item['admin_checked_at']),
                                Icons.calendar_today,
                                _dangerColor,
                              ),
                            _buildEnhancedInfoRow(
                              'Status Threads Reply',
                              (item['admin_action_taken'] == 'Safe')
                                  ? 'Posted'
                                  : item['admin_action_taken'],
                              getThreadStatusIcon(item['admin_action_taken']),
                              _dangerColor,
                            ),
                          ] else if (statusText == 'Posted') ...[
                            _buildEnhancedInfoRow(
                              'Thread ID',
                              'ID ${item['Thread_ID']}',
                              Icons.forum,
                              Colors.green,
                            ),
                            _buildEnhancedInfoRow(
                              'Reply ID',
                              'ID ${item['Thread_reply_ID']}',
                              Icons.reply,
                              Colors.green,
                            ),
                            if (item['ai_evaluation'] != null)
                              _buildEnhancedInfoRow(
                                'AI Analysis',
                                item['ai_evaluation'],
                                Icons.psychology_outlined,
                                Colors.green,
                              ),
                            if (item['admin_username'] != null)
                              _buildEnhancedInfoRow(
                                'Admin Action',
                                'Approved by ${item['admin_username']}',
                                Icons.gavel,
                                Colors.green,
                              ),
                            if (item['reason_for_taken'] != null)
                              _buildEnhancedInfoRow(
                                'Reason For Approved',
                                item['reason_for_taken'],
                                Icons.info_outline,
                                Colors.green,
                              ),
                            if (item['admin_checked_at'] != null)
                              _buildEnhancedInfoRow(
                                'Action Taken',
                                _formatDate(item['admin_checked_at']),
                                Icons.calendar_today,
                                Colors.green,
                              ),
                            _buildEnhancedInfoRow(
                              'Status Threads Reply',
                              (item['admin_action_taken'] == 'Safe')
                                  ? 'Posted'
                                  : item['admin_action_taken'],
                              getThreadStatusIcon(item['admin_action_taken']),
                              Colors.green,
                            ),
                          ] else if (statusText == 'Pending') ...[
                            _buildEnhancedInfoRow(
                              'Thread Id',
                              item['thread_id'].toString() ?? 'Unknown Admin',
                              Icons.admin_panel_settings,
                              Colors.green,
                            ),
                            _buildEnhancedInfoRow(
                              'Thread Reply Id',
                              item['Thread_reply_ID'].toString() ??
                                  'Unknown Admin',
                              Icons.admin_panel_settings,
                              Colors.green,
                            ),
                            _buildEnhancedInfoRow(
                              'Estimated Time',
                              'Usually reviewed within 24 hours',
                              Icons.schedule,
                              Colors.green,
                            ),
                            if (item['ai_evaluation'] != null)
                              _buildEnhancedInfoRow(
                                'AI Analysis',
                                item['ai_evaluation'],
                                Icons.psychology_outlined,
                                Colors.green,
                              ),
                          ],
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThreadItem(Map<String, dynamic> thread) {
    final status = thread['status'];
    Color statusColor;
    String statusText;
    Color containerColor;
    IconData statusIcon;
    bool isExpanded = true;

    switch (status) {
      case 'Posted':
        statusColor = _successColor;
        statusText = 'Posted';
        containerColor = _successColor.withOpacity(0.05);
        statusIcon = Icons.check_circle_outline;
        break;
      case 'Banned':
        statusColor = _dangerColor;
        statusText = 'Banned';
        containerColor = _dangerColor.withOpacity(0.05);
        statusIcon = Icons.block;
        break;
      default:
        statusColor = _warningColor;
        statusText = 'Pending';
        containerColor = _warningColor.withOpacity(0.05);
        statusIcon = Icons.access_time;
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              // Add border based on status
              side: BorderSide(color: statusColor.withOpacity(0.3), width: 2),
            ),
            color: _cardColor,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with user avatar and info
                  Row(
                    children: [
                      // User Avatar
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _primaryColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: thread['author_picture'] != null
                              ? Image.network(
                                  thread['author_picture'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: _primaryColor.withOpacity(0.1),
                                      child: Icon(
                                        Icons.person,
                                        color: _primaryColor,
                                        size: 30,
                                      ),
                                    );
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                            strokeWidth: 2,
                                            color: _primaryColor,
                                          ),
                                        );
                                      },
                                )
                              : Container(
                                  color: _primaryColor.withOpacity(0.1),
                                  child: Icon(
                                    Icons.person,
                                    color: _primaryColor,
                                    size: 30,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              thread['author_username'] ?? 'Unknown User',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              _formatDate(thread['created_at']),
                              style: TextStyle(
                                fontSize: 11,
                                color: _secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Enhanced status chip with icon
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 16, color: statusColor),
                            SizedBox(width: 6),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 10),

                  Divider(
                    color: const Color.fromARGB(255, 226, 225, 225),
                    thickness: 1,
                  ),

                  SizedBox(height: 10),
                  // Thread message with improved background and border
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFE8EAED), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      thread['message'] ?? 'No message',
                      style: TextStyle(
                        fontSize: 16,
                        color: _textColor,
                        height: 1.5,
                      ),
                    ),
                  ),

                  SizedBox(height: 22),

                  // Enhanced status details container
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    statusIcon,
                                    size: 18,
                                    color: statusColor,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Status Details',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: statusColor,
                                size: 22,
                              ),
                              onPressed: () {
                                setState(() {
                                  isExpanded = !isExpanded;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),

                        if (isExpanded) ...[
                          SizedBox(height: 12),
                          Divider(
                            color: statusColor.withOpacity(0.2),
                            height: 1,
                          ),
                          SizedBox(height: 12),

                          // Status-specific information with better formatting
                          if (status == 'Banned') ...[
                            _buildEnhancedInfoRow(
                              'Thread ID',
                              'ID ' + thread['Thread_ID'].toString(),
                              Icons.forum,
                              _dangerColor,
                            ),
                            _buildEnhancedInfoRow(
                              'Ai Analysis',
                              thread['ai_evaluation'],
                              Icons.psychology_outlined,
                              _dangerColor,
                            ),
                            _buildEnhancedInfoRow(
                              'Admin Action',
                              'Banned by ${thread['admin_username'] ?? 'Unknown Admin'}',
                              Icons.gavel,
                              _dangerColor,
                            ),
                            if (thread['reason_for_taken'] != null)
                              _buildEnhancedInfoRow(
                                'Reason',
                                thread['reason_for_taken'],
                                Icons.info_outline,
                                _dangerColor,
                              ),
                            if (thread['admin_checked_at'] != null)
                              _buildEnhancedInfoRow(
                                'Action Taken',
                                _formatDate(thread['admin_checked_at']),
                                Icons.calendar_today,
                                _dangerColor,
                              ),
                          ] else if (status == 'Posted') ...[
                            _buildEnhancedInfoRow(
                              'Thread ID',
                              'ID ${thread['Thread_ID']}',
                              Icons.forum,
                              _successColor,
                            ),

                            if (thread['ai_evaluation'] != null)
                              _buildEnhancedInfoRow(
                                'AI Analysis',
                                thread['ai_evaluation'],
                                Icons.psychology_outlined,
                                _successColor,
                              ),
                            if (thread['ai_evaluation']?.contains(
                                      'Inappropriate',
                                    ) ==
                                    true ||
                                thread['admin_username'] != null)
                              _buildEnhancedInfoRow(
                                'Approved by',
                                thread['admin_username'] ?? 'Unknown Admin',
                                Icons.admin_panel_settings,
                                _successColor,
                              ),
                            if (thread['ai_evaluation']?.contains(
                                      'Inappropriate',
                                    ) ==
                                    true &&
                                thread['reason_for_taken'] != null)
                              _buildEnhancedInfoRow(
                                'Approval Reason',
                                thread['reason_for_taken'],
                                Icons.info_outline,
                                _successColor,
                              ),
                            if (thread['ai_evaluation']?.contains(
                                      'Inappropriate',
                                    ) ==
                                    true &&
                                thread['admin_checked_at'] != null)
                              _buildEnhancedInfoRow(
                                'Approved At',
                                _formatDate(thread['admin_checked_at']),
                                Icons.calendar_today,
                                _successColor,
                              ),
                          ] else if (status == 'Pending') ...[
                            _buildEnhancedInfoRow(
                              'Thread ID',
                              'ID ' + thread['Thread_ID'].toString(),
                              Icons.forum,
                              _warningColor,
                            ),
                            _buildEnhancedInfoRow(
                              'Current Status',
                              'Awaiting admin approval',
                              Icons.access_time,
                              _warningColor,
                            ),
                            _buildEnhancedInfoRow(
                              'Estimated Time',
                              'Usually reviewed within 24 hours',
                              Icons.schedule,
                              _warningColor,
                            ),
                            if (thread['ai_evaluation'] != null)
                              _buildEnhancedInfoRow(
                                'AI Analysis',
                                thread['ai_evaluation'],
                                Icons.psychology_outlined,
                                _warningColor,
                              ),
                          ],
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildMetricChipWithIcon(
                        Icons.favorite_outline,
                        '${thread['Total_likes'] ?? 0}',
                        _getBackgroundColor(thread['admin_decision']),
                      ),
                      // _buildMetricChipWithIcon(
                      //   Icons.reply_outlined,
                      //   '${thread['reply_count'] ?? 0}',
                      //   _primaryColor,
                      // ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(String? decision) {
    switch (decision) {
      case 'Posted':
        return _successColor.withOpacity(0.5); // เขียว
      case 'Safe':
        return _successColor.withOpacity(0.5); // เขียว
      case 'Banned':
        return _dangerColor.withOpacity(0.5); // แดง
      case 'Pending':
        return _warningColor.withOpacity(0.5); // เหลืองทอง
      default:
        return const Color.fromARGB(255, 0, 0, 0); // fallback
    }
  }

  // New helper method for enhanced info rows
  Widget _buildEnhancedInfoRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 32, child: Icon(icon, size: 18, color: color)),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: _secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: _textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyItem(Map<String, dynamic> reply) {
    final status = reply['status'];
    Color statusColor;
    String statusText;
    Color containerColor;
    IconData statusIcon;
    bool isExpanded = false;

    switch (status) {
      case 'Posted':
        statusColor = _successColor;
        statusText = 'Posted';
        containerColor = _successColor.withOpacity(0.05);
        statusIcon = Icons.check_circle_outline;
        break;
      case 'Banned':
        statusColor = _dangerColor;
        statusText = 'Banned';
        containerColor = _dangerColor.withOpacity(0.05);
        statusIcon = Icons.block;
        break;
      default:
        statusColor = _warningColor;
        statusText = 'Pending';
        containerColor = _warningColor.withOpacity(0.05);
        statusIcon = Icons.access_time;
    }

    // กำหนดสถานะของ Thread ต้นฉบับ
    final threadStatus = reply['Thread_admin_decision'];
    Color threadStatusColor;
    String threadStatusText;

    switch (threadStatus) {
      case 'Posted':
        threadStatusColor = _successColor;
        threadStatusText = 'Posted';
        break;
      case 'Banned':
        threadStatusColor = _dangerColor;
        threadStatusText = 'Banned';
        break;
      default:
        threadStatusColor = _warningColor;
        threadStatusText = 'Pending';
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: statusColor.withOpacity(0.3), width: 2),
            ),
            color: _cardColor,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with user avatar and info
                  Row(
                    children: [
                      // User Avatar
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _primaryColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: reply['author_picture'] != null
                              ? Image.network(
                                  reply['author_picture'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: _primaryColor.withOpacity(0.1),
                                      child: Icon(
                                        Icons.person,
                                        color: _primaryColor,
                                        size: 30,
                                      ),
                                    );
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                            strokeWidth: 2,
                                            color: _primaryColor,
                                          ),
                                        );
                                      },
                                )
                              : Container(
                                  color: _primaryColor.withOpacity(0.1),
                                  child: Icon(
                                    Icons.person,
                                    color: _primaryColor,
                                    size: 30,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reply['author_username'] ?? 'Unknown User',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              _formatDate(reply['created_at']),
                              style: TextStyle(
                                fontSize: 11,
                                color: _secondaryTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Enhanced status chip with icon
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 16, color: statusColor),
                            SizedBox(width: 6),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 10),
                  Divider(
                    color: const Color.fromARGB(255, 226, 225, 225),
                    thickness: 1,
                  ),

                  SizedBox(height: 20),
                  // Original thread info with enhanced UI
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Color(0xFFE8EAED), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Main content
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 17), // Space for the title
                            // Thread author info
                            Row(
                              children: [
                                // Thread Author Avatar
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _primaryColor.withOpacity(0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: reply['Thread_picture'] != null
                                        ? Image.network(
                                            reply['Thread_picture'],
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    color: _primaryColor
                                                        .withOpacity(0.1),
                                                    child: Icon(
                                                      Icons.person,
                                                      color: _primaryColor,
                                                      size: 20,
                                                    ),
                                                  );
                                                },
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value:
                                                      loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                      : null,
                                                  strokeWidth: 2,
                                                  color: _primaryColor,
                                                ),
                                              );
                                            },
                                          )
                                        : Container(
                                            color: _primaryColor.withOpacity(
                                              0.1,
                                            ),
                                            child: Icon(
                                              Icons.person,
                                              color: _primaryColor,
                                              size: 20,
                                            ),
                                          ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reply['Thread_username'] ??
                                            'Unknown User',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _textColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        _formatDate(reply['Thread_create_at']),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _secondaryTextColor,
                                        ),
                                      ),
                                      SizedBox(height: 0),
                                    ],
                                  ),
                                ),
                                // Thread status chip
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: threadStatusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: threadStatusColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    threadStatusText,
                                    style: TextStyle(
                                      color: threadStatusColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 0),
                            Divider(
                              color: const Color.fromARGB(255, 226, 225, 225),
                              thickness: 1,
                            ),

                            SizedBox(height: 5),
                            // Thread message
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Color(0xFFE8EAED),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                reply['Thread_message'] ?? 'No thread message',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _textColor,
                                  height: 1.4,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(height: 17),
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.end,
                            //   children: [
                            //     _buildMetricChipWithIcon(
                            //       Icons.favorite_outline,
                            //       '${reply['Total_likes'] ?? 10010}',
                            //       _getBackgroundColor(
                            //         reply['Thread_admin_decision'],
                            //       ),
                            //     ),
                            //   ],
                            // ),
                          ],
                        ),

                        // Title positioned on top border
                        Positioned(
                          top: -30,
                          left: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 255, 255, 255),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color.fromARGB(255, 207, 207, 207),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 14,
                                  color: _primaryColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Replying to this thread',
                                  style: TextStyle(
                                    fontSize: 13,

                                    color: _primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 45),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Reply message with improved background and border
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(0xFFE8EAED),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          reply['message'] ?? 'No message',
                          style: TextStyle(
                            fontSize: 16,
                            color: _textColor,
                            height: 1.5,
                          ),
                        ),
                      ),
                      Positioned(
                        top: -20,
                        left: 15,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color.fromARGB(255, 207, 207, 207),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 14,
                                color: _primaryColor,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Replying Message',
                                style: TextStyle(
                                  fontSize: 13,

                                  color: _primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 22),

                  // Enhanced status details container
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    statusIcon,
                                    size: 18,
                                    color: statusColor,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Status Details',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: statusColor,
                                size: 22,
                              ),
                              onPressed: () {
                                setState(() {
                                  isExpanded = !isExpanded;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),

                        if (isExpanded) ...[
                          SizedBox(height: 12),
                          Divider(
                            color: statusColor.withOpacity(0.2),
                            height: 1,
                          ),
                          SizedBox(height: 12),

                          // Status-specific information with better formatting
                          if (status == 'Banned') ...[
                            _buildEnhancedInfoRow(
                              'Thread ID',
                              'ID ${reply['Thread_ID']}',
                              Icons.forum,
                              _dangerColor,
                            ),
                            _buildEnhancedInfoRow(
                              'Reply ID',
                              'ID ${reply['Thread_reply_ID']}',
                              Icons.reply,
                              _dangerColor,
                            ),

                            if (reply['ai_evaluation'] != null)
                              _buildEnhancedInfoRow(
                                'AI Analysis',
                                reply['ai_evaluation'],
                                Icons.psychology_outlined,
                                _dangerColor,
                              ),
                            if (reply['admin_username'] != null)
                              _buildEnhancedInfoRow(
                                'Admin Action',
                                'Banned by ${reply['admin_username']}',
                                Icons.gavel,
                                _dangerColor,
                              ),
                            if (reply['reason_for_taken'] != null)
                              _buildEnhancedInfoRow(
                                'Reason For Banned',
                                reply['reason_for_taken'],
                                Icons.info_outline,
                                _dangerColor,
                              ),
                            if (reply['admin_checked_at'] != null)
                              _buildEnhancedInfoRow(
                                'Action Taken',
                                _formatDate(reply['admin_checked_at']),
                                Icons.calendar_today,
                                _dangerColor,
                              ),
                          ] else if (status == 'Posted') ...[
                            _buildEnhancedInfoRow(
                              'Thread ID',
                              'ID ${reply['Thread_ID']}',
                              Icons.forum,
                              _successColor,
                            ),
                            _buildEnhancedInfoRow(
                              'Reply ID',
                              'ID ${reply['Thread_reply_ID']}',
                              Icons.reply,
                              Colors.green,
                            ),
                            _buildEnhancedInfoRow(
                              'Visibility',
                              'Publicly visible to all users',
                              Icons.visibility,
                              _successColor,
                            ),
                            if (reply['ai_evaluation'] != null)
                              _buildEnhancedInfoRow(
                                'AI Analysis',
                                reply['ai_evaluation'],
                                Icons.psychology_outlined,
                                _successColor,
                              ),
                            if (reply['ai_evaluation']?.contains(
                                      'Inappropriate',
                                    ) ==
                                    true ||
                                reply['admin_username'] != null)
                              _buildEnhancedInfoRow(
                                'Approved by',
                                reply['admin_username'] ?? 'Unknown Admin',
                                Icons.admin_panel_settings,
                                _successColor,
                              ),
                            if (reply['ai_evaluation']?.contains(
                                      'Inappropriate',
                                    ) ==
                                    true &&
                                reply['reason_for_taken'] != null)
                              _buildEnhancedInfoRow(
                                'Approval Reason',
                                reply['reason_for_taken'],
                                Icons.info_outline,
                                _successColor,
                              ),
                            if (reply['ai_evaluation']?.contains(
                                      'Inappropriate',
                                    ) ==
                                    true &&
                                reply['admin_checked_at'] != null)
                              _buildEnhancedInfoRow(
                                'Approved At',
                                _formatDate(reply['admin_checked_at']),
                                Icons.calendar_today,
                                _successColor,
                              ),
                          ] else if (status == 'Pending') ...[
                            _buildEnhancedInfoRow(
                              'Thread ID',
                              'ID ${reply['Thread_ID']}',
                              Icons.forum,
                              _warningColor,
                            ),
                            _buildEnhancedInfoRow(
                              'Reply ID',
                              'ID ${reply['Thread_reply_ID']}',
                              Icons.reply,
                              _warningColor,
                            ),
                            _buildEnhancedInfoRow(
                              'Current Status',
                              'Awaiting admin approval',
                              Icons.access_time,
                              _warningColor,
                            ),
                            _buildEnhancedInfoRow(
                              'Estimated Time',
                              'Usually reviewed within 24 hours',
                              Icons.schedule,
                              _warningColor,
                            ),
                            if (reply['ai_evaluation'] != null)
                              _buildEnhancedInfoRow(
                                'AI Analysis',
                                reply['ai_evaluation'],
                                Icons.psychology_outlined,
                                _warningColor,
                              ),
                          ],
                        ],
                      ],
                    ),
                  ),

                  // SizedBox(height: 20),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.end,
                  //   children: [
                  //     Wrap(
                  //       spacing: 12,
                  //       children: [
                  //         _buildMetricChipWithIcon(
                  //           Icons.favorite_outline,
                  //           '${reply['Total_likes'] ?? 0}    ',
                  //           Colors.black,
                  //         ),
                  //       ],
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ),
        );
      },
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

  Widget _buildMetricChipWithIcon(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
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
      'Safe': Icons.check_circle_outline,
      'Inappropriate': Icons.warning_amber_outlined,
      'Undetermined': Icons.help_outline_outlined,
    };

    final texts = {
      'Safe': 'Safe',
      'Inappropriate': 'Inappropriate',
      'Undetermined': 'Review Needed',
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors[status]!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors[status]!.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icons[status], size: 18, color: colors[status]),
          SizedBox(width: 6),
          Text(
            texts[status]!,
            style: TextStyle(
              color: colors[status],
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';

    try {
      // แปลง string เป็น DateTime
      DateTime date = DateTime.parse(
        dateString,
      ); // JSON จาก MySQL เป็นเวลาตรงไทย

      // ใช้ local time ของ device (ถ้าต้องการ)
      date = date.toLocal();

      // แปลงเป็น format readable
      return DateFormat('MMM d, y · h:mm a').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }
}
