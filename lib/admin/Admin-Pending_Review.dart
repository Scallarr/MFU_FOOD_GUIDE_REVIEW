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
  bool isLoading = true;
  int? _expandedReviewId;
  int? userId; // Track which review is expanded

  // Colors
  final Color _primaryColor = Color(0xFF4285F4); // Blue
  final Color _successColor = Color(0xFF34A853); // Green
  final Color _warningColor = Color(0xFFFBBC05); // Yellow
  final Color _dangerColor = Color(0xFFEA4335); // Red
  final Color _cardColor = Colors.white;
  final Color _textColor = Color(0xFF202124);
  final Color _secondaryTextColor = Color(0xFF5F6368);

  @override
  void initState() {
    super.initState();
    _fetchPendingReviews();
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
      SnackBar(
        content: Text(message),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleReviewExpansion(int reviewId) {
    setState(() {
      if (_expandedReviewId == reviewId) {
        _expandedReviewId = null; // Collapse if already expanded
      } else {
        _expandedReviewId = reviewId; // Expand this review
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        title: Text(
          'Pending Reviews',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFCEBFA3),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? _buildLoadingView()
          : pendingReviews.isEmpty
          ? _buildEmptyView()
          : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 15),
              itemCount: pendingReviews.length,
              itemBuilder: (context, index) {
                final review = pendingReviews[index];
                return _buildReviewCard(review);
              },
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

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final date = DateFormat(
      'MMM d, y · h:mm a',
    ).format(DateTime.parse(review['created_at']));
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
        shadowColor: Colors.transparent, // Disable Card's default shadow
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
                              width: 60, // Explicit width
                              height: 60, // Explicit height
                              child: Image.network(
                                review['picture_url'],
                                fit: BoxFit.cover,
                                width: 66, // Match container size
                                height: 48, // Match container size
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                      child: Icon(
                                        Icons.person,
                                        color: _primaryColor,
                                        size: 24, // Adjusted icon size
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
                          date,
                          style: TextStyle(
                            fontSize: 13,
                            color: _secondaryTextColor,
                          ),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () => _rejectReview(review['Review_ID']),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _dangerColor,
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
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _approveReview(review['Review_ID']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _successColor,
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

  Color _getRatingColor(double rating) {
    if (rating >= 4) return Colors.black;
    if (rating >= 2.5) return _warningColor;
    return _dangerColor;
  }

  Future<void> _approveReview(int reviewId) async {
    try {
      final response = await http.put(
        Uri.parse('https://your-api.com/reviews/$reviewId/approve'),
        body: jsonEncode({
          'admin_user_id':
              userId, // The User_ID of the admin (from your auth system)
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Review approved successfully');
        _fetchPendingReviews();
      } else {
        throw Exception('Failed to approve review');
      }
    } catch (e) {
      _showSnackBar('Error approving review: ${e.toString()}');
    }
  }

  Future<void> _rejectReview(int reviewId) async {
    try {
      final response = await http.put(
        Uri.parse('https://your-api.com/reviews/$reviewId'),
        body: jsonEncode({
          'admin_user_id':
              userId, // The User_ID of the admin (from your auth system)
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Review rejected successfully');
        _fetchPendingReviews();
      } else {
        throw Exception('Failed to reject review');
      }
    } catch (e) {
      _showSnackBar('Error rejecting review: ${e.toString()}');
    }
  }
}
