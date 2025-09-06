import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PendingReviewsPage extends StatefulWidget {
  final int restaurantId;

  const PendingReviewsPage({Key? key, required this.restaurantId})
    : super(key: key);

  @override
  _PendingReviewsPageState createState() => _PendingReviewsPageState();
}

class _PendingReviewsPageState extends State<PendingReviewsPage> {
  List<dynamic> pendingReviews = [];
  List<dynamic> filteredReviews = [];
  bool isLoading = true;
  int? _expandedReviewId;
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
  bool isExpanded = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingReviews();
    searchController.addListener(_filterReviews);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filterReviews() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredReviews = pendingReviews.where((review) {
        final username = review['username']?.toString().toLowerCase() ?? '';
        return username.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchPendingReviews() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');

    try {
      final response = await http.get(
        Uri.parse(
          'http://10.0.3.201:8080/reviews/pending?restaurantId=${widget.restaurantId}',
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          pendingReviews = jsonDecode(response.body);
          filteredReviews = pendingReviews;
          isLoading = false;
          print(filteredReviews);
        });
      } else {
        throw Exception('Failed to load reviews');
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

  void _toggleReviewExpansion(int reviewId) {
    setState(() {
      _expandedReviewId = _expandedReviewId == reviewId ? null : reviewId;
    });
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
                          backgroundColor: _dangerColor.withOpacity(0.7),
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
        title: Text('Pending Reviews', style: TextStyle(color: Colors.white)),
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
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by username...',
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
          // Reviews List
          Expanded(
            child: isLoading
                ? _buildLoadingView()
                : filteredReviews.isEmpty
                ? _buildEmptyView()
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    itemCount: filteredReviews.length,
                    itemBuilder: (context, index) {
                      final review = filteredReviews[index];
                      return _buildReviewCard(review);
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
            'Loading reviews...',
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
            Icons.reviews_outlined,
            size: 64,
            color: _secondaryTextColor.withOpacity(0.3),
          ),
          SizedBox(height: 20),
          Text(
            'No pending reviews',
            style: TextStyle(
              fontSize: 18,
              color: _textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'New reviews will appear here',
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

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final action = review['message_status'];
    Color statusColor;
    String statusText;
    Color containerColor;
    IconData statusIcon;

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

    // ใช้ StatefulBuilder เพื่อจัดการ state ภายใน card
    return StatefulBuilder(
      builder: (context, setState) {
        bool isExpanded = _expandedReviewId == review['Review_ID'];

        return Container(
          margin: EdgeInsets.only(bottom: 16, top: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
                  // ... (ส่วนอื่นๆ ของ UI เหมือนเดิม)
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
                          child: review['picture_url'] != null
                              ? Image.network(
                                  review['picture_url'],
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
                              ' ${review['username'] ?? 'Unknown User'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: _textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _formatDate(
                                review['created_at'],
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

                  SizedBox(height: 20),
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
                                child: review['photos'] != null
                                    ? Image.network(
                                        review['photos'],
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
                                    review['restaurant_name'] ??
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
                                          '${review['location']} MFU  • ${review['category']?.replaceAll('_', ' ') ?? ''}',
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
                            review['comment'] ?? 'No comment',
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

                  SizedBox(height: 20),

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
                                        review['rating_overall'] ?? '0.0',
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
                          review['rating_hygiene'].toDouble() ?? 0.0,
                        ),
                        SizedBox(height: 8),
                        _buildRatingBar(
                          'Flavor',
                          review['rating_flavor'].toDouble() ?? 0.0,
                        ),
                        SizedBox(height: 8),
                        _buildRatingBar(
                          'Service',
                          review['rating_service'].toDouble() ?? 0.0,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Status details section - แก้ไขส่วนนี้
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
                                // ใช้ setState ของ StatefulBuilder เพื่ออัปเดต UI
                                setState(() {
                                  if (isExpanded) {
                                    _expandedReviewId = null;
                                  } else {
                                    _expandedReviewId = review['Review_ID'];
                                  }
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
                            'ID ${review['Review_ID']}',
                            Icons.reviews,
                            action == 'Pending' ? _warningColor : _primaryColor,
                          ),

                          if (review['ai_evaluation'] != null)
                            _buildEnhancedInfoRow(
                              'AI Analysis',
                              review['ai_evaluation'],
                              Icons.psychology_outlined,
                              action == 'Pending'
                                  ? _warningColor
                                  : _primaryColor,
                            ),

                          if (review['username'] != null)
                            _buildEnhancedInfoRow(
                              action == 'Banned' ? 'Banned by' : 'Written by',
                              review['username'],
                              Icons.person_outline,
                              action == 'Pending'
                                  ? _warningColor
                                  : _primaryColor,
                            ),

                          if (review['email'] != null)
                            _buildEnhancedInfoRow(
                              action == 'Banned' ? 'Reason' : 'Writer Email',
                              review['email'],
                              Icons.email_outlined,
                              action == 'Pending'
                                  ? _warningColor
                                  : _primaryColor,
                            ),

                          if (review['created_at'] != null)
                            _buildEnhancedInfoRow(
                              'Written at',
                              _formatDate(review['created_at']),
                              Icons.calendar_today,
                              action == 'Pending'
                                  ? _warningColor
                                  : _primaryColor,
                            ),

                          if (review['message_status'] != null)
                            _buildEnhancedInfoRow(
                              'Current Status',
                              review['message_status'],
                              Icons.info_outline,
                              action == 'Pending'
                                  ? _warningColor
                                  : _primaryColor,
                            ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Approve Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _successColor.withOpacity(0.7),
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
                        onPressed: () =>
                            _showApproveDialog(review['Review_ID']),
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
                          backgroundColor: _dangerColor.withOpacity(0.8),
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
                        onPressed: () => _showRejectDialog(review['Review_ID']),
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

  Widget _buildRatingRow(String label, dynamic rating) {
    final value = double.tryParse(rating.toString()) ?? 0.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: _secondaryTextColor, fontSize: 14)),
        Row(
          children: [
            _buildStars(value),
            SizedBox(width: 12),
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          size: 18,
          color: index < rating ? _warningColor : Colors.grey[400],
        );
      }),
    );
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

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';

    try {
      DateTime date = DateTime.parse(dateString).toLocal();
      return DateFormat('MMM d, y · h:mm a').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  Future<void> _approveReview(int reviewId) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.3.201:8080/api/reviews/approve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reviewId': reviewId, 'adminId': userId}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showSnackBar(
          responseData['message'] ?? 'Review approved successfully',
        );
        _fetchPendingReviews();
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
        Uri.parse('http://10.0.3.201:8080/api/reviews/reject'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reviewId': reviewId,
          'adminId': userId,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Review rejected successfully');
        _fetchPendingReviews();
      } else {
        throw Exception('Failed to reject review');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    }
  }
}
