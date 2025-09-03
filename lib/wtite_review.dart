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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Write a Review'),
            floating: true,
            snap: true,
            backgroundColor: Color.fromARGB(255, 231, 219, 202),
            elevation: 2,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: Image.network(
                      widget.restaurant['imageUrl'] ??
                          'https://via.placeholder.com/400',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.restaurant['name'] ?? 'Restaurant Name',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Chip(
                          label: Text(
                            widget.restaurant['category'] ?? 'Main Dish',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: const Color.fromARGB(
                            255,
                            83,
                            82,
                            77,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Row(
                        children: [
                          // คุณสามารถเปิดส่วน location ได้ถ้าต้องการ
                          // const Icon(Icons.location_on, size: 18, color: Colors.grey),
                          // const SizedBox(width: 4),
                          // Text(
                          //   '${widget.restaurant['location'] ?? 'Mae Fah Luang University'} Mae Fah Luang University',
                          //   style: const TextStyle(
                          //     color: Color.fromARGB(255, 54, 51, 51),
                          //   ),
                          // ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildRatingSection('Hygiene Rating', hygieneRating, (
                          rating,
                        ) {
                          setState(() => hygieneRating = rating);
                        }),
                        const SizedBox(height: 12),
                        _buildRatingSection('Flavor Rating', flavorRating, (
                          rating,
                        ) {
                          setState(() => flavorRating = rating);
                        }),
                        const SizedBox(height: 12),
                        _buildRatingSection('Service Rating', serviceRating, (
                          rating,
                        ) {
                          setState(() => serviceRating = rating);
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: EdgeInsetsGeometry.only(left: 17, right: 17),
                    child: Column(
                      // mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Write your comment:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(
                            1,
                          ), // เพิ่ม padding เล็กน้อยให้ขอบไม่เบียด
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.black,
                            ), // ขอบด้านนอก
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: commentController,
                            maxLength: 70,
                            maxLines: 3,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.all(12),
                              hintText: 'Type your comment here...',
                              border: InputBorder
                                  .none, // ไม่ใช้ขอบของ TextField ซ้ำ
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Padding(
                    padding: EdgeInsetsGeometry.only(
                      left: 10,
                      right: 10,
                      bottom: 20,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            66,
                            66,
                            61,
                          ),
                          elevation: 6,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Submit Review',
                          style: TextStyle(
                            fontSize: 17,
                            color: Color.fromARGB(255, 232, 232, 232),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(
    String title,
    int currentRating,
    Function(int) onRatingSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            int ratingValue = index + 1;
            bool isSelected = currentRating == ratingValue;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: ElevatedButton(
                onPressed: () => onRatingSelected(ratingValue),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected
                      ? Color.fromARGB(255, 75, 73, 73)
                      : const Color.fromARGB(255, 255, 255, 255),
                  foregroundColor: isSelected
                      ? Colors.white
                      : const Color.fromARGB(255, 0, 0, 0),
                  side: const BorderSide(
                    color: Color.fromARGB(255, 0, 0, 0),
                  ), // ขอบดำ
                  minimumSize: const Size(45, 45), // ขนาดปุ่มใหญ่ขึ้น
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // มุมโค้ง
                  ),
                  elevation: 0, // ปุ่มไม่มีเงา
                ),
                child: Text(
                  ratingValue.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> submitReview() async {
    // --- Validation ก่อน ---
    if (hygieneRating == 0 || flavorRating == 0 || serviceRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please rate all categories.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a comment.')));
      return;
    }

    // --- Confirm Dialog ก่อนส่ง ---
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  size: 60,
                  color: Color.fromARGB(255, 247, 103, 25),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Confirm Submission',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 247, 103, 25),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Are you sure you want to submit this review?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.7),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.deepPurple),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFEA4335).withOpacity(0.7),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          'Submit',
                          style: TextStyle(fontSize: 16, color: Colors.white),
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

    if (confirmed != true) {
      // ผู้ใช้กด Cancel หรือปิด dialog
      return;
    }

    // --- ส่งข้อมูลไป Backend หลังจากผู้ใช้กดยืนยัน ---
    try {
      var url = Uri.parse(
        'https://mfu-food-guide-review.onrender.com/submit_reviews',
      );
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Restaurant_ID': widget.restaurant['RestaurantID'],
          'rating_hygiene': hygieneRating,
          'rating_flavor': flavorRating,
          'rating_service': serviceRating,
          'comment': commentController.text.trim(),
          'User_ID': userId,
        }),
      );

      if (response.statusCode == 200) {
        final resJson = jsonDecode(response.body);
        if (resJson['message_status'] == 'Pending') {
          // แสดง dialog เตือนเนื้อหาไม่เหมาะสม
          await showDialog(
            context: context,
            builder: (context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 10,
                backgroundColor: Colors.white,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(66, 94, 81, 81),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.5),
                              blurRadius: 12,
                              spreadRadius: 1,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 56,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Warning!',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your comment contains inappropriate content and is pending review.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 6,
                            shadowColor: const Color.fromARGB(
                              255,
                              0,
                              0,
                              0,
                            ).withOpacity(0.6),
                          ),
                          child: const Text(
                            'OK',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Posted Reviewed Successfully!')),
          );
        }

        Navigator.pop(context, true);
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
