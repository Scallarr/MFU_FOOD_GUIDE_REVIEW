import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    _fetchPendingReviews();
  }

  Future<void> _fetchPendingReviews() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://your-api.com/reviews/pending?restaurantId=${widget.restaurantId}',
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          pendingReviews = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load pending reviews');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _approveReview(int reviewId) async {
    try {
      final response = await http.put(
        Uri.parse('https://your-api.com/reviews/$reviewId/approve'),
      );

      if (response.statusCode == 200) {
        _fetchPendingReviews(); // Refresh the list
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Review approved successfully')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error approving review')));
    }
  }

  Future<void> _rejectReview(int reviewId) async {
    try {
      final response = await http.delete(
        Uri.parse('https://your-api.com/reviews/$reviewId'),
      );

      if (response.statusCode == 200) {
        _fetchPendingReviews(); // Refresh the list
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Review rejected successfully')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error rejecting review')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pending Reviews'),
        backgroundColor: Colors.black87,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : pendingReviews.isEmpty
          ? Center(child: Text('No pending reviews'))
          : ListView.builder(
              itemCount: pendingReviews.length,
              itemBuilder: (context, index) {
                final review = pendingReviews[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review['user_name'] ?? 'Anonymous',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(review['comment']),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            Text(' ${review['rating']}'),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _rejectReview(review['id']),
                              child: Text(
                                'Reject',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _approveReview(review['id']),
                              child: Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
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
