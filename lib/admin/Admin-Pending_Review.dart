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
          'https://mfu-food-guide-review.onrender.com/reviews/pending?restaurantId=${widget.restaurantId}',
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          pendingReviews = jsonDecode(response.body);
          filteredReviews = pendingReviews;
          isLoading = false;
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

                    // Approve Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _approveReview(reviewId);
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
    Text(formatDate(review['created_at']), style: TextStyle(fontSize: 14));

    final overallRating =
        double.tryParse(review['rating_overall'].toString()) ?? 0.0;
    final isExpanded = _expandedReviewId == review['Review_ID'];

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
              // User Info and Rating
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _primaryColor.withOpacity(0.1),
                    ),
                    child: review['picture_url'] != null
                        ? ClipOval(
                            child: Container(
                              width: 60,
                              height: 60,
                              child: Image.network(
                                review['picture_url'],
                                fit: BoxFit.cover,
                                width: 66,
                                height: 48,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                      child: Icon(
                                        Icons.person,
                                        color: _primaryColor,
                                        size: 24,
                                      ),
                                    ),
                                loadingBuilder:
                                    (
                                      BuildContext context,
                                      Widget child,
                                      ImageChunkEvent? loadingProgress,
                                    ) {
                                      if (loadingProgress == null) return child;
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
                              ),
                            ),
                          )
                        : Icon(Icons.person, color: _primaryColor),
                  ),

                  SizedBox(width: 16),

                  // User Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review['username'] ?? 'Anonymous',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          formatDate(review['created_at']),
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  // Overall Rating
                  _buildRatingChip(overallRating),
                ],
              ),

              SizedBox(height: 20),

              // Review Comment
              if (review['comment']?.isNotEmpty ?? false) ...[
                Text(
                  review['comment'],
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: _textColor,
                  ),
                ),
                SizedBox(height: 20),
              ],

              // Toggle for Details
              InkWell(
                onTap: () => _toggleReviewExpansion(review['Review_ID']),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rating Details',
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

              // Detailed Ratings (Conditional)
              if (isExpanded) ...[
                SizedBox(height: 16),
                _buildRatingRow('Overall', review['rating_overall']),
                SizedBox(height: 8),
                _buildRatingRow('Hygiene', review['rating_hygiene']),
                SizedBox(height: 8),
                _buildRatingRow('Flavor', review['rating_flavor']),
                SizedBox(height: 8),
                _buildRatingRow('Service', review['rating_service']),
                SizedBox(height: 20),
                _buildAIStatus(review['ai_evaluation']),
              ],
              SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _showRejectDialog(review['Review_ID']),
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
                    onPressed: () => _showApproveDialog(review['Review_ID']),
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

  Widget _buildRatingChip(double rating) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 60, 59, 59),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 16, color: Colors.white),
          SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
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

    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: colors[status]!.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
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
      ),
    );
  }

  Future<void> _approveReview(int reviewId) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://mfu-food-guide-review.onrender.com/api/reviews/approve',
        ),
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
        Uri.parse(
          'https://mfu-food-guide-review.onrender.com/api/reviews/reject',
        ),
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
