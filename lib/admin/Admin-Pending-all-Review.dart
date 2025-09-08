import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/login.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class RestaurantallPendingrewiewPage extends StatefulWidget {
  @override
  _RestaurantallPendingrewiewPageState createState() =>
      _RestaurantallPendingrewiewPageState();
}

class _RestaurantallPendingrewiewPageState
    extends State<RestaurantallPendingrewiewPage>
    with SingleTickerProviderStateMixin {
  int? userId;
  late TabController _tabController;
  List<dynamic> _reviewApprovalHistory = [];
  List<dynamic> _myReviews = [];
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
    _tabController = TabController(length: 2, vsync: this);
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
      await Future.wait([_fetchReviewApprovalHistory()]);
    } catch (e) {
      print('Error fetching data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchReviewApprovalHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final response = await http.get(
        Uri.parse('http://10.214.52.39:8080/Pending_review-all-restaurants'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _isLoading = false;
        setState(() {
          _reviewApprovalHistory = data.map((review) {
            // Helper function to safely convert any value to double

            // กำหนดสถานะของ review
            String status;
            if (review['admin_action_taken'] == 'Banned') {
              status = 'Banned';
            } else if (review['admin_action_taken'] == 'Safe') {
              status = 'Posted';
            } else {
              status = 'Pending';
            }

            return {
              'Review_ID': review['Review_ID'],
              'Restaurant_ID': review['Restaurant_ID'],
              'restaurant_name': review['restaurant_name'],
              'restaurant_location': review['location'],
              'rating_overall': review['rating_overall'],
              'rating_hygiene': review['rating_hygiene'],
              'rating_flavor': review['rating_flavor'],
              'rating_service': review['rating_service'],
              'comment': review['comment'],
              'total_likes': review['total_likes'],
              'created_at': review['created_at'],
              'ai_evaluation': review['ai_evaluation'],
              'message_status': review['message_status'],
              'status': status,

              // User info
              'user_id': review['user_id'],
              'user_username': review['user_username'],
              'user_email': review['user_email'],
              'user_fullname': review['user_fullname'],
              'user_picture': review['user_picture'],

              // Restaurant info
              'restaurant_photo': review['photos'],
              'restaurant_category': review['category'],
              'restaurant_operating_hours': review['operating_hours'],
              'restaurant_phone': review['phone_number'],

              // Admin info
              'admin_id': review['admin_id'],
              'admin_username': review['admin_username'],
              'admin_fullname': review['admin_fullname'],
              'admin_picture': review['admin_picture'],
              'admin_action_taken': review['admin_action_taken'],
              'admin_checked_at': review['admin_checked_at'],
              'reason_for_taken': review['reason_for_taken'],
            };
          }).toList();
        });
      } else if (response.statusCode == 401) {
        // Token หมดอายุ
        _showAlert(context, jsonDecode(response.body)['error']);
        return;
      } else if (response.statusCode == 403) {
        // User ถูกแบน - แสดง alert ตามที่ต้องการ
        _showAlert(context, jsonDecode(response.body)['error']);
        return;
      }
    } catch (e) {
      print('Error fetching review approval history: $e');
    }
  }

  void _showAlert(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // ผู้ใช้ต้องกดปุ่ม OK ก่อนปิด
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 5,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Colors.orangeAccent, Colors.deepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 50,
                color: Colors.white,
              ),
              const SizedBox(height: 15),
              Text(
                'Warning',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsetsGeometry.only(top: 10),
          child: Text(
            'Manage Pending Reviews',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: const Color.fromARGB(255, 255, 253, 253),
              shadows: [
                Shadow(
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                  color: const Color.fromARGB(255, 68, 68, 68).withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        toolbarHeight: 70,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 16, 14, 14)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 229, 210, 173),
                const Color.fromARGB(255, 229, 210, 173),
                // สิ้นสุด
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      // Body ปกติ
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF7F4EF),
              Color(0xFFF7F4EF),
              Color(0xFFF7F4EF),
            ], // สิ้นสุด],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? _buildLoadingView()
            : TabBarView(
                controller: _tabController,
                children: [_buildReviewApprovalHistory()],
              ),
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
            'Loading review history...',
            style: TextStyle(color: _secondaryTextColor, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewApprovalHistory() {
    return _reviewApprovalHistory.isEmpty
        ? _buildEmptyView('No review approval history found')
        : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _reviewApprovalHistory.length,
            itemBuilder: (context, index) {
              final item = _reviewApprovalHistory[index];
              return _buildReviewApprovalItem(item);
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
                Icons.restaurant_outlined,
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
              'Your restaurant reviews will appear here',
              style: TextStyle(fontSize: 14, color: _secondaryTextColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewApprovalItem(Map<String, dynamic> item) {
    final action = item['admin_action_taken'];
    Color statusColor;
    String statusText;
    Color containerColor;
    IconData statusIcon;
    bool isExpanded = false;

    switch (action) {
      case 'Safe':
        statusColor = _successColor;
        statusText = 'Approvedddd';
        containerColor = _successColor.withOpacity(0.05);
        statusIcon = Icons.check_circle_outline;
        break;
      case 'Banned':
        statusColor = _dangerColor;
        statusText = 'Bannedddddd';
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
                  // Restaurant Header
                  SizedBox(height: 4),

                  // User info and ratings
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
                          child: item['user_picture'] != null
                              ? Image.network(
                                  item['user_picture'],
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
                              ' ${item['user_username'] ?? 'Unknown User'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: _textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _formatDate(
                                item['created_at'],
                              ), // This should already return a string
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
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

                      // Overall rating
                    ],
                  ),

                  SizedBox(height: 16),
                  // Review comment
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Color(0xFFE8EAED), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Restaurant header
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 63,
                                height: 60,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _primaryColor.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: item['restaurant_photo'] != null
                                    ? Image.network(
                                        item['restaurant_photo'],
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                color: _primaryColor
                                                    .withOpacity(0.1),
                                                child: Icon(
                                                  Icons.restaurant,
                                                  color: _primaryColor,
                                                  size: 28,
                                                ),
                                              );
                                            },
                                      )
                                    : Container(
                                        color: _primaryColor.withOpacity(0.1),
                                        child: Icon(
                                          Icons.restaurant,
                                          color: _primaryColor,
                                          size: 28,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['restaurant_name'] ??
                                        'Unknown Restaurant',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Column(children: []),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 14,
                                        color: _secondaryTextColor,
                                      ),
                                      SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${item['restaurant_location']} MFU  • ${item['restaurant_category']?.replaceAll('_', ' ') ?? ''}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _secondaryTextColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 14),

                        // Divider line (เพื่อแยกหัวกับ comment)
                        Divider(color: Colors.grey[200], thickness: 1),

                        SizedBox(height: 10),

                        // Comment section
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item['comment'] ?? 'No comment',
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontSize: 15,
                              color: _textColor,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // Rating breakdown
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFE8EAED), width: 1),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Overall Rating',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            // SizedBox(height: 20),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: _primaryColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        item['rating_overall'] ?? '0.0',
                                        style: TextStyle(
                                          color: _textColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        _buildRatingBar(
                          'Hygiene',
                          item['rating_hygiene'].toDouble() ?? 0.0,
                        ),
                        SizedBox(height: 8),
                        _buildRatingBar(
                          'Flavor',
                          item['rating_flavor'].toDouble() ?? 0.0,
                        ),
                        SizedBox(height: 8),
                        _buildRatingBar(
                          'Service',
                          item['rating_service'].toDouble() ?? 0.0,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // Status details
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
                                  'Review Details',
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
                          if (action == 'Posted') SizedBox(height: 12),
                          Divider(
                            color: statusColor.withOpacity(0.2),
                            height: 1,
                          ),
                          SizedBox(height: 12),

                          _buildEnhancedInfoRow(
                            'Review ID',
                            'ID ${item['Review_ID']}',
                            Icons.reviews,
                            action == 'Pending'
                                ? _warningColor
                                : const Color.fromARGB(255, 255, 10, 10),
                          ),

                          if (item['ai_evaluation'] != null)
                            _buildEnhancedInfoRow(
                              'AI Analysis',
                              item['ai_evaluation'],
                              Icons.psychology_outlined,
                              action == 'Pending'
                                  ? _warningColor
                                  : const Color.fromARGB(255, 255, 10, 10),
                            ),

                          if (item['user_username'] != null)
                            _buildEnhancedInfoRow(
                              action == 'Banned' ? 'Banned by' : 'written by',
                              item['user_username'],
                              Icons.admin_panel_settings,
                              action == 'Pending'
                                  ? _warningColor
                                  : const Color.fromARGB(255, 255, 10, 10),
                            ),

                          if (item['user_email'] != null)
                            _buildEnhancedInfoRow(
                              action == 'Banned' ? 'Reason' : 'Writer Email',
                              item['user_email'],
                              Icons.email_outlined,
                              action == 'Pending'
                                  ? _warningColor
                                  : const Color.fromARGB(255, 255, 10, 10),
                            ),

                          if (item['admin_checked_at'] != null)
                            _buildEnhancedInfoRow(
                              'Written at',
                              _formatDate(item['admin_checked_at']),
                              Icons.calendar_today,
                              action == 'Pending'
                                  ? _warningColor
                                  : const Color.fromARGB(255, 255, 10, 10),
                            ),
                          if (item['message_status'] != null)
                            _buildEnhancedInfoRow(
                              item['message_status'] == 'Banned'
                                  ? 'Current Review Status'
                                  : 'Current Review Status',
                              item['message_status'],
                              Icons.info_outline,
                              item['message_status'] == 'Pending'
                                  ? _warningColor
                                  : const Color.fromARGB(255, 255, 10, 10),
                            ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Approve Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _successColor.withOpacity(
                            0.7,
                          ), // สีเขียวสำหรับ approve
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12), // โค้งมน
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          elevation: 3,
                        ),
                        onPressed: () => _showApproveDialog(item['Review_ID']),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text(
                          "Approve",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Reject Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _dangerColor.withOpacity(
                            0.8,
                          ), // สีแดงสำหรับ reject
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          elevation: 3,
                        ),
                        onPressed: () => _showRejectDialog(item['Review_ID']),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text(
                          "Reject",
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  Future<void> _showApproveDialog(int reviewId) async {
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
                // Animated Icon
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

                // Title
                Text(
                  'Confirm Approval',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
                SizedBox(height: 12),

                // Message
                Text(
                  'Are you sure you want to approve this review?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: _secondaryTextColor,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Cancel Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black.withOpacity(0.7),
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

                    // Approve Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _approveReview(reviewId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _successColor.withOpacity(0.7),
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

  Future<void> _showRejectDialog(int reviewId) async {
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
                // Animated Warning Icon
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

                // Title
                Text(
                  'Confirm Rejection',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
                SizedBox(height: 12),

                // Message
                Text(
                  'Are you sure you want to reject this review?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: _secondaryTextColor,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 20),

                // Reason Input Field
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

                // Buttons Row
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black.withOpacity(0.7),
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

                    // Reject Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _rejectReview(
                            reviewId,
                            reason: reasonController.text,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _dangerColor.withOpacity(0.8),
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

  Future<void> _approveReview(int reviewId) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.214.52.39:8080/api/reviews/approve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reviewId': reviewId, 'adminId': userId}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showSnackBar('Review approved successfully');
        setState(() {
          _reviewApprovalHistory.removeWhere(
            (item) => item['Review_ID'] == reviewId,
          );
        });
      } else {
        throw Exception(responseData['message'] ?? 'Failed to approve review');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    }
  }

  Future<void> _rejectReview(int reviewId, {String reason = ''}) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.214.52.39:8080/api/reviews/reject'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reviewId': reviewId,
          'adminId': userId,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Review rejected successfully');
        setState(() {
          _reviewApprovalHistory.removeWhere(
            (item) => item['Review_ID'] == reviewId,
          );
        });
      } else {
        throw Exception('Failed to reject review');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.black),
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

  Widget _buildRatingBar(String label, double rating) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: LinearProgressIndicator(
            value: rating / 5,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(_getRatingColor(rating)),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 12),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _getRatingColor(rating),
          ),
        ),
      ],
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green[800]!; // Excellent
    if (rating >= 4.0) return Colors.lightGreen[600]!; // Very Good
    if (rating >= 3.5) return Colors.lime[600]!; // Good
    if (rating >= 3.0) return Colors.amber[600]!; // Average
    if (rating >= 2.5) return Colors.orange[600]!; // Below Average
    if (rating >= 2.0) return Colors.deepOrange[600]!; // Poor
    return Colors.red[700]!; // Very Poor
  }

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

  Widget _buildMetricChipWithIcon(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
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
      DateTime date = DateTime.parse(dateString).toLocal();
      return DateFormat('MMM d, y · h:mm a').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }
}
