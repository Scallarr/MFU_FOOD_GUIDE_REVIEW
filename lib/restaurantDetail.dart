import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'restaurant_model.dart';

class RestaurantDetailPage extends StatefulWidget {
  final int restaurantId;

  const RestaurantDetailPage({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  Restaurant? restaurant;
  bool isLoading = true;

  int? userId;
  Map<int, bool> likedReviews = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadUserId();
    await fetchRestaurant();
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
      final uri = Uri.parse(
        'https://mfu-food-guide-review.onrender.com/restaurant/${widget.restaurantId}'
        '${userId != null ? '?user_id=$userId' : ''}',
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          restaurant = Restaurant.fromJson(data);
          likedReviews = {for (var r in restaurant!.reviews) r.id: r.isLiked};
          isLoading = false;
        });
      } else {
        print('Failed to load restaurant. Status code: ${response.statusCode}');
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
              isLiked: likedNow,
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
  @override
  @override
  @override
  Widget build(BuildContext context) {
    if (isLoading || restaurant == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Restaurant Details')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(restaurant!.name),
            backgroundColor: const Color.fromARGB(255, 221, 187, 136),
            floating: true, // ทำให้เลื่อนขึ้นมาได้ทันที
            snap: true, // เลื่อนลงซ่อนทันที
            elevation: 4,
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: Image.network(
                    restaurant!.photoUrl,
                    height: 250,
                    width: MediaQuery.of(context).size.width,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              restaurant!.name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                            ),
                          ),
                          Icon(Icons.favorite, color: Colors.red, size: 28),
                        ],
                      ),
                      SizedBox(height: 12),
                      Chip(
                        label: Text(restaurant!.category),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                      ),
                      SizedBox(height: 12),
                      _infoRow(
                        Icons.location_on,
                        '${restaurant!.location}   MAH FAH LUANG UNIVERSITY',
                      ),
                      SizedBox(height: 12),
                      _infoRow(
                        Icons.access_time,
                        'Open Time :${restaurant!.operatingHours}',
                      ),
                      SizedBox(height: 12),
                      _infoRow(Icons.phone, restaurant!.phoneNumber),
                      Divider(height: 32),
                      _buildRatingSection(),
                      Divider(height: 32),
                      _buildMenuSection(),
                      Divider(height: 32),
                      _buildReviewSection(),
                      SizedBox(height: 5),
                      Center(
                        child: SizedBox(
                          width: double.infinity, // เต็มความกว้าง
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: เขียนรีวิว
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(
                                vertical:
                                    14, // ไม่ต้องกำหนด horizontal เพราะกว้างเต็มแล้ว
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Write a Review',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Overall Rating",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                height: 1.2,
              ),
            ),
            SizedBox(width: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 0, 0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    '${restaurant!.ratingOverall.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.star, color: Colors.amber, size: 22),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildRatingRow("Hygiene", restaurant!.ratingHygiene),
        _buildRatingRow("Flavor", restaurant!.ratingFlavor),
        _buildRatingRow("Service", restaurant!.ratingService),
      ],
    );
  }

  Widget _buildRatingRow(String label, double value) {
    int rounded = value.round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (index) => Icon(
                index < rounded ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 22,
              ),
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
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        SizedBox(height: 12),
        ...restaurant!.menus.map(
          (menu) => Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 4,
            child: Container(
              height: 80, // ปรับความสูงของ Card ตามต้องการ
              padding: EdgeInsets.all(0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Image.network(
                      menu.imageUrl,
                      width: 120, // ปรับขนาดรูปภาพให้ใหญ่ขึ้น
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          menu.nameTH,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Price ${menu.price} Baht",
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 18), // ขยับเข้ามาจากขอบขวา
                    child: Icon(
                      Icons.restaurant,
                      size: 25,
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              // TODO: View full menu
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: EdgeInsets.symmetric(vertical: 0), // ลบ horizontal ออก
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(
                color: const Color.fromARGB(255, 0, 0, 0),
                width: 2,
              ),
            ),
            child: Text(
              "View Full Menu",
              style: TextStyle(
                color: const Color.fromARGB(255, 253, 253, 253),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
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
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        SizedBox(height: 16),
        ...restaurant!.reviews.map((review) {
          final isLiked = likedReviews[review.id] ?? false;
          return Card(
            margin: EdgeInsets.symmetric(vertical: 10), // เพิ่มระยะระหว่าง Card
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              constraints: BoxConstraints(
                minHeight: 100,
              ), // เพิ่มความสูงขั้นต่ำ
              padding: EdgeInsets.all(15), // เพิ่ม padding ภายใน
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(review.pictureUrl),
                    radius: 30, // ขยาย Avatar ให้ใหญ่ขึ้นเล็กน้อย
                    backgroundColor: Colors.grey[200],
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Stack(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            top: 0,
                            right: 80,
                          ), // เพิ่มระยะด้านขวา
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review.username,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: List.generate(5, (i) {
                                  if (i < review.ratingOverall.floor()) {
                                    return Icon(
                                      Icons.star,
                                      size: 20,
                                      color: Colors.amber,
                                    ); // เต็ม
                                  } else if (i < review.ratingOverall &&
                                      review.ratingOverall - i >= 0.5) {
                                    return Icon(
                                      Icons.star_half,
                                      size: 20,
                                      color: Colors.amber,
                                    ); // ครึ่ง
                                  } else {
                                    return Icon(
                                      Icons.star_border,
                                      size: 20,
                                      color: Colors.amber,
                                    ); // ว่าง
                                  }
                                }),
                              ),

                              SizedBox(height: 10),
                              Text(
                                review.comment,
                                style: TextStyle(fontSize: 15.5, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                _formatDate(review.createdAt),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 12),
                              GestureDetector(
                                onTap: () {
                                  if (userId != null) {
                                    likeReview(review.id);
                                  }
                                },
                                child: Icon(
                                  Icons.favorite,
                                  color: isLiked ? Colors.red : Colors.grey,
                                  size: 30,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "${review.totalLikes} Likes",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
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
