import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WriteReviewPage extends StatefulWidget {
  final dynamic restaurant; // รับ restaurant object ที่ส่งมา

  const WriteReviewPage({Key? key, required this.restaurant}) : super(key: key);

  @override
  _WriteReviewPageState createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  int hygieneRating = 0;
  int flavorRating = 0;
  int serviceRating = 0;
  final TextEditingController commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Write a Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Section 1: Restaurant Info ---
            Text(
              widget.restaurant['name'] ?? 'Restaurant Name',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),
            Image.network(
              widget.restaurant['imageUrl'] ??
                  'https://via.placeholder.com/400',
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Chip(label: Text(widget.restaurant['category'] ?? 'Main Dish')),
                const SizedBox(width: 8),
                const Icon(Icons.location_on, size: 18),
                Text(
                  widget.restaurant['location'] ?? 'Mae Fah Luang University',
                ),
              ],
            ),
            const Divider(height: 30),

            // --- Section 2: Ratings ---
            _buildRatingSection('Hygiene Rating', hygieneRating, (rating) {
              setState(() {
                hygieneRating = rating;
              });
            }),
            _buildRatingSection('Flavor Rating', flavorRating, (rating) {
              setState(() {
                flavorRating = rating;
              });
            }),
            _buildRatingSection('Service Rating', serviceRating, (rating) {
              setState(() {
                serviceRating = rating;
              });
            }),

            const SizedBox(height: 20),

            // --- Section 3: Comment Box ---
            const Text('Write your comment:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: commentController,
              maxLines: 4,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Type your comment here...',
              ),
            ),

            const SizedBox(height: 20),

            // --- Section 4: Submit Button ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B4949),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Submit Review',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Rating Section Builder ---
  Widget _buildRatingSection(
    String title,
    int currentRating,
    Function(int) onRatingSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            int ratingValue = index + 1;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: () => onRatingSelected(ratingValue),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentRating == ratingValue
                      ? Colors.black
                      : Colors.white,
                  foregroundColor: currentRating == ratingValue
                      ? Colors.white
                      : Colors.black,
                  side: BorderSide(color: Colors.grey.shade400),
                  minimumSize: const Size(40, 40),
                ),
                child: Text(ratingValue.toString()),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // --- Submit Review Function ---
  Future<void> submitReview() async {
    print(widget.restaurant);
    // --- Validation ก่อน ---
    if (hygieneRating == 0 || flavorRating == 0 || serviceRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please rate all categories.')),
      );
      return;
    }

    if (commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a comment.')));
      return;
    }

    // --- ส่งข้อมูลไป Backend ---
    try {
      var url = Uri.parse(
        'https://mfu-food-guide-review.onrender.com/submit_reviews',
      ); // เปลี่ยน URL จริงตรงนี้
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Restaurant_ID': widget.restaurant['RestaurantID'], // ใส่ id ของร้าน
          'rating_hygiene': hygieneRating,
          'rating_flavor': flavorRating,
          'rating_service': serviceRating,
          'comment': commentController.text.trim(),
          'User_ID': userId, // ถ้ามี user id ส่งมาด้วย
        }),
      );
      print('HygieneRating: $hygieneRating');
      print('FlavorRating: $flavorRating');
      print('ServiceRating: $serviceRating');
      print('UserID: $userId');
      print('RestaurantID: ${widget.restaurant['RestaurantID']}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review Submitted Successfully!')),
        );

        Navigator.pop(context); // กลับหน้าก่อนหน้า
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to submit review. Code: ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
