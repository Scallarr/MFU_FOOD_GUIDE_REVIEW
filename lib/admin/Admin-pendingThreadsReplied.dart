import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PendingThreadsRepliedPage extends StatefulWidget {
  const PendingThreadsRepliedPage({Key? key}) : super(key: key);

  @override
  _PendingThreadsRepliedPageState createState() =>
      _PendingThreadsRepliedPageState();
}

class _PendingThreadsRepliedPageState extends State<PendingThreadsRepliedPage> {
  List<dynamic> pendingThreads = [];
  List<dynamic> filteredThreads = [];
  bool isLoading = true;
  int? _expandedThreadId;
  int? userId;
  TextEditingController searchController = TextEditingController();

  // Colors
  final Color _primaryColor = Color(0xFF4285F4);
  final Color _successColor = Color(0xFF34A853);
  final Color _warningColor = Color(0xFFFBBC05);
  final Color _dangerColor = Color(0xFFEA4335);
  final Color _cardColor = Colors.white;
  final Color _textColor = Color(0xFF202124);
  final Color _secondaryTextColor = Color(0xFF5F6368);

  @override
  void initState() {
    super.initState();
    _fetchPendingThreads();
    searchController.addListener(_filterThreads);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filterThreads() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredThreads = pendingThreads.where((thread) {
        final username = thread['username']?.toString().toLowerCase() ?? '';
        final message = thread['message']?.toString().toLowerCase() ?? '';
        final repliedTo =
            thread['replied_to_username']?.toString().toLowerCase() ?? '';
        final ID = thread['Thread_reply_ID'].toString().toLowerCase();
        return username.contains(query) ||
            message.contains(query) ||
            repliedTo.contains(query) ||
            ID.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchPendingThreads() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');

    try {
      final response = await http.get(
        Uri.parse(
          'http://10.0.3.201:8080/threads-replied/pending',
          // 'https://mfu-food-guide-review.onrender.com/threads-replied/pending',
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          pendingThreads = jsonDecode(response.body);
          filteredThreads = pendingThreads;
          isLoading = false;
          print(filteredThreads);
        });
      } else {
        throw Exception('Failed to load threads');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Error: ${e.toString()}');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.black),
    );
  }

  void _toggleThreadExpansion(int threadId) {
    setState(() {
      _expandedThreadId = _expandedThreadId == threadId ? null : threadId;
    });
  }

  Future<void> _showApproveDialog(int threadId) async {
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
            padding: EdgeInsets.all(20),
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
                          color: _successColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_outline,
                          size: 40,
                          color: _successColor,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),
                Text(
                  'Confirm Approval',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Are you sure you want to approve this replied thread?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: _secondaryTextColor,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black,
                          side: BorderSide(color: Colors.black),
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
                          _approveThread(threadId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Approve',
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

  Future<void> _showRejectDialog(int threadId) async {
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
                  'Are you sure you want to reject this replied thread?',
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
                          _rejectThread(
                            threadId,
                            reason: reasonController.text,
                          );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        title: Text(
          'Pending Replied Threads',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFCEBFA3),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by username, message, or replied to...',
                hintStyle: TextStyle(fontSize: 12),
                prefixIcon: Icon(Icons.search, color: _secondaryTextColor),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? _buildLoadingView()
                : filteredThreads.isEmpty
                ? _buildEmptyView()
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    itemCount: filteredThreads.length,
                    itemBuilder: (context, index) {
                      final thread = filteredThreads[index];
                      return _buildThreadCard(thread);
                    },
                  ),
          ),
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
            'Loading replied threads...',
            style: TextStyle(color: _secondaryTextColor, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.reply_outlined,
            size: 64,
            color: _secondaryTextColor.withOpacity(0.3),
          ),
          SizedBox(height: 20),
          Text(
            'No pending replied threads',
            style: TextStyle(
              fontSize: 18,
              color: _textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'New replied threads will appear here',
            style: TextStyle(color: _secondaryTextColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String formatDate(String? dateString) {
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

  Widget _buildThreadCard(Map<String, dynamic> thread) {
    final date = DateFormat(
      'MMM d, y · h:mm a',
    ).format(DateTime.parse(thread['created_at']));
    final isExpanded = _expandedThreadId == thread['Thread_ID'];
    final totalLikes = thread['Total_likes'] ?? 0;
    final repliedToUsername = thread['replied_to_username'] ?? 'Unknown';

    return Container(
      margin: EdgeInsets.only(bottom: 16, top: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 7,
            spreadRadius: 1,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 0.5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _primaryColor.withOpacity(0.1),
                    ),
                    child: thread['picture_url'] != null
                        ? ClipOval(
                            child: Image.network(
                              thread['picture_url'],
                              fit: BoxFit.cover,
                              width: 60,
                              height: 60,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                    child: Icon(
                                      Icons.person,
                                      color: _primaryColor,
                                      size: 24,
                                    ),
                                  ),
                            ),
                          )
                        : Icon(Icons.person, color: _primaryColor),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          thread['username'] ?? 'Anonymous',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          formatDate(thread['created_at']),
                          style: TextStyle(
                            fontSize: 12,
                            color: _secondaryTextColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.reply,
                              size: 14,
                              color: _secondaryTextColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Replying to $repliedToUsername',
                              style: TextStyle(
                                fontSize: 12,
                                color: _primaryColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildLikesChip(totalLikes),
                ],
              ),
              SizedBox(height: 20),
              _buildMessage(thread['message'] ?? ''),

              SizedBox(height: 20),
              InkWell(
                onTap: () => _toggleThreadExpansion(thread['Thread_ID']),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Thread Details',
                        style: TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: _primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded) ...[
                SizedBox(height: 16),
                _buildAIStatus(thread['ai_evaluation']),
                SizedBox(height: 16),
                _buildAdminStatus(thread['admin_decision']),
              ],
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () =>
                        _showRejectDialog(thread['Thread_reply_ID']),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red,
                      side: BorderSide(color: _dangerColor),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Reject'),
                  ),
                  SizedBox(width: 25),
                  ElevatedButton(
                    onPressed: () =>
                        _showApproveDialog(thread['Thread_reply_ID']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Approve',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLikesChip(int likes) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 60, 59, 59),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, size: 16, color: Colors.white),
          SizedBox(width: 4),
          Text(
            likes.toString(),
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
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
          Icon(icons[status], size: 18, color: colors[status]),
          SizedBox(width: 8),
          Text(
            'AI Analysis: ',
            style: TextStyle(color: _secondaryTextColor, fontSize: 14),
          ),
          Text(
            status,
            style: TextStyle(
              color: colors[status],
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStatus(String status) {
    final colors = {
      'Posted': _successColor,
      'Pending': _warningColor,
      'Banned': _dangerColor,
    };

    final icons = {
      'Posted': Icons.check_circle,
      'Pending': Icons.access_time,
      'Banned': Icons.block,
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
          Icon(icons[status], size: 18, color: colors[status]),
          SizedBox(width: 8),
          Text(
            'Status: ',
            style: TextStyle(color: _secondaryTextColor, fontSize: 14),
          ),
          Text(
            status,
            style: TextStyle(
              color: colors[status],
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveThread(int threadId) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.3.201:8080/threads-replied/approve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'threadId': threadId,
          'adminId': userId,
          'status': 'Posted',
          'reason': 'Appropriate message',
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showSnackBar(
          responseData['message'] ?? 'Replied thread approved successfully',
        );
        setState(() {
          pendingThreads.removeWhere(
            (thread) => thread['Thread_reply_ID'] == threadId,
          );
          filteredThreads = pendingThreads;
        });
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to approve replied thread',
        );
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    }
  }

  Future<void> _rejectThread(int threadId, {String reason = ''}) async {
    try {
      final rejectionReason = reason.isEmpty ? 'Inappropriate message' : reason;
      final response = await http.post(
        Uri.parse('http://10.0.3.201:8080/threads-replied/reject'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'threadId': threadId,
          'adminId': userId,
          'reason': rejectionReason,
          'status': 'Banned',
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Replied thread rejected successfully');
        setState(() {
          pendingThreads.removeWhere(
            (thread) => thread['Thread_reply_ID'] == threadId,
          );
          filteredThreads = pendingThreads;
        });
      } else {
        throw Exception('Failed to reject replied thread');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    }
  }
}

Widget _buildMessage(String message) {
  final regex = RegExp(r'(@\w+)');
  final matches = regex.allMatches(message);

  if (matches.isEmpty) {
    return Text(
      message,
      style: TextStyle(fontSize: 18, color: const Color.fromARGB(255, 0, 0, 0)),
    );
  }

  List<TextSpan> spans = [];
  int start = 0;

  for (final match in matches) {
    if (match.start > start) {
      spans.add(
        TextSpan(
          text: message.substring(start, match.start),
          style: TextStyle(
            fontSize: 20,
            height: 1.6,
            color: const Color.fromARGB(255, 0, 0, 0),
          ),
        ),
      );
    }

    spans.add(
      TextSpan(
        text: match.group(0),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: const Color.fromARGB(255, 255, 0, 0), // สีของ @mention
        ),
      ),
    );

    start = match.end;
  }

  if (start < message.length) {
    spans.add(
      TextSpan(
        text: message.substring(start),
        style: TextStyle(
          fontSize: 20,
          height: 1.6,
          color: const Color.fromARGB(255, 0, 0, 0),
        ),
      ),
    );
  }

  return RichText(text: TextSpan(children: spans));
}
