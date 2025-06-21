import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'restaurant_model.dart'; // <-- Model class ที่คุณสร้างไว้

class RestaurantDetailPage extends StatefulWidget {
  final int restaurantId;

  const RestaurantDetailPage({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  Restaurant? restaurant;
  bool isLoading = true;

  int? userId; // เก็บ user id จาก SharedPreferences
  Map<int, bool> likedReviews = {}; // เก็บสถานะไลค์ของแต่ละรีวิว

  @override
  void initState() {
    super.initState();
    _loadUserId();
    fetchRestaurant();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getInt('user_id');
    setState(() {
      userId = storedUserId;
    });
  }

  Future<void> fetchRestaurant() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://mfu-food-guide-review.onrender.com/restaurant/${widget.restaurantId}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          restaurant = Restaurant.fromJson(data);
          isLoading = false;
        });
      } else {
        print('Failed to load restaurant');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> likeReview(int reviewId) async {
    if (userId == null) {
      print("User not logged in");
      return;
    }
    final url = Uri.parse(
      'https://mfu-food-guide-review.onrender.com/review/$reviewId/like',
    );
    try {
      final response = await http.post(
        url,
        body: json.encode({'user_id': userId}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        final likedNow = resData['liked'] as bool;

        setState(() {
          likedReviews[reviewId] = likedNow;

          final index = restaurant!.reviews.indexWhere((r) => r.id == reviewId);
          if (index != -1) {
            final oldReview = restaurant!.reviews[index];
            final updatedLikes = likedNow
                ? oldReview.totalLikes + 1
                : (oldReview.totalLikes > 0 ? oldReview.totalLikes - 1 : 0);

            final updatedReview = Review(
              id: oldReview.id,
              ratingOverall: oldReview.ratingOverall,
              comment: oldReview.comment,
              username: oldReview.username,
              pictureUrl: oldReview.pictureUrl,
              totalLikes: updatedLikes,
              createdAt: oldReview.createdAt,
            );

            restaurant!.reviews[index] = updatedReview;
          }
        });
      } else {
        print('Failed to like/unlike review');
        print('Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error liking/unliking review: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || restaurant == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Restaurant Details')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(restaurant!.name)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                restaurant!.photoUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  restaurant!.name,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Icon(Icons.favorite, color: Colors.red),
              ],
            ),
            SizedBox(height: 6),
            Chip(label: Text(restaurant!.category)),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on, size: 16),
                SizedBox(width: 5),
                Text(restaurant!.location),
              ],
            ),
            Row(
              children: [
                Icon(Icons.access_time, size: 16),
                SizedBox(width: 5),
                Text('Open ${restaurant!.operatingHours}'),
              ],
            ),
            Row(
              children: [
                Icon(Icons.phone, size: 16),
                SizedBox(width: 5),
                Text(restaurant!.phoneNumber),
              ],
            ),
            Divider(height: 30),
            _buildRatingSection(),
            Divider(height: 30),
            _buildMenuSection(),
            Divider(height: 30),
            _buildReviewSection(),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: เขียนรีวิว
                },
                child: Text('Write a Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Overall Rating",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    '${restaurant!.ratingOverall}',
                    style: TextStyle(fontSize: 16),
                  ),
                  Icon(Icons.star, color: Colors.amber, size: 18),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        _buildRatingRow("Hygiene", restaurant!.ratingHygiene),
        _buildRatingRow("Flavor", restaurant!.ratingFlavor),
        _buildRatingRow("Service", restaurant!.ratingService),
      ],
    );
  }

  Widget _buildRatingRow(String label, double value) {
    int rounded = value.round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label'),
          SizedBox(width: 10),
          ...List.generate(
            5,
            (index) => Icon(
              index < rounded ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Menu",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        ...restaurant!.menus.map(
          (menu) => Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  menu.imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(menu.nameTH),
              subtitle: Text("Price ${menu.price} Bath"),
              trailing: Icon(Icons.clear, color: Colors.black54),
            ),
          ),
        ),
        SizedBox(height: 8),
        Center(
          child: OutlinedButton(
            onPressed: () {
              // TODO: View full menu
            },
            child: Text("View Full Menu"),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Reviews",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        ...restaurant!.reviews.map((review) {
          final isLiked = likedReviews[review.id] ?? false;
          return Card(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(review.pictureUrl),
                    radius: 25,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                review.username,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              _formatDate(review.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < review.ratingOverall.round()
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 16,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(review.comment),
                        SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "${review.totalLikes} Likes",
                              style: TextStyle(fontSize: 12),
                            ),
                            SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                if (!isLiked && userId != null) {
                                  likeReview(review.id);
                                }
                              },
                              child: Icon(
                                Icons.favorite,
                                color: isLiked ? Colors.red : Colors.grey,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  String _formatDate(String rawDate) {
    final date = DateTime.parse(rawDate);
    return "${_monthAbbr(date.month)} ${date.day}, ${date.year}";
  }

  String _monthAbbr(int month) {
    const months = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month];
  }
}
