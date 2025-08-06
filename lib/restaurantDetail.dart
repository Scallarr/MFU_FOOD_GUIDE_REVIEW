import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myapp/wtite_review.dart';
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
  bool isExpanded = false;
  bool isReviewExpanded = false;

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
          print(
            'restaurant.id = ${restaurant!.id}',
          ); // 👈 ต้องได้ค่าที่ไม่ใช่ null
          likedReviews = {for (var r in restaurant!.reviews) r.id: r.isLiked};
          isLoading = false;
        });
        print(data);
      } else {
        print('Failed to load restaurant. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  bool isProcessing = false;
  Future<void> likeReview(int reviewId) async {
    if (userId == null) {
      print("User not logged in");
      return;
    }
    if (isProcessing) return;
    isProcessing = true;

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

        // **เพิ่มตรงนี้** เรียก API อัพเดต leaderboard
        await updateLeaderboard();

        isProcessing = false;
      } else {
        print('Failed to like/unlike review');
        print('Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        isProcessing = false;
      }
    } catch (e) {
      print('Error liking/unliking review: $e');
      isProcessing = false;
    }
  }

  Future<void> updateLeaderboard() async {
    try {
      final url = Uri.parse(
        'https://mfu-food-guide-review.onrender.com/leaderboard/update-auto',
      );
      // สมมติว่า backend ต้องการเดือนปีใน body (format 'YYYY-MM')
      // คุณอาจจะเก็บเดือนปีที่เหมาะสมไว้ในตัวแปร เช่น currentMonthYear
      final currentMonthYear = DateTime.now();
      final formattedMonth =
          "${currentMonthYear.year.toString()}-${currentMonthYear.month.toString().padLeft(2, '0')}";

      final response = await http.post(
        url,
        body: json.encode({'month_year': formattedMonth}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print('Leaderboard updated successfully');
      } else {
        print('Failed to update leaderboard');
        print('Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error updating leaderboard: $e');
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
                        avatar: Icon(
                          Icons.local_offer_rounded,
                          size: 18,
                          color: const Color.fromARGB(255, 83, 83, 83),
                        ),
                        label: Text(
                          restaurant!.category,
                          style: TextStyle(
                            color: const Color.fromARGB(255, 95, 94, 94),
                            fontWeight: FontWeight.w500,
                            fontSize: 17,
                          ),
                        ),
                        backgroundColor: const Color.fromARGB(
                          255,
                          228,
                          192,
                          135,
                        ), // สีน้ำตาลโกโก้ดูหรู
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(
                              thickness: 1.5,
                              endIndent: 10,
                              color: Colors.grey,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Colors.orange,
                              size: 20,
                            ),
                          ),
                          const Expanded(
                            child: Divider(
                              thickness: 1.5,
                              indent: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildRatingSection(),
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(
                              thickness: 1.5,
                              endIndent: 10,
                              color: Colors.grey,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Colors.orange,
                              size: 20,
                            ),
                          ),
                          const Expanded(
                            child: Divider(
                              thickness: 1.5,
                              indent: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildMenuSection(),
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(
                              thickness: 1.5,
                              endIndent: 10,
                              color: Colors.grey,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Colors.orange,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 50),
                          const Expanded(
                            child: Divider(
                              thickness: 1.5,
                              indent: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildReviewSection(),
                      SizedBox(height: 20),
                      Center(
                        child: SizedBox(
                          width: double.infinity, // เต็มความกว้าง
                          child: ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WriteReviewPage(
                                    restaurant: {
                                      'name': restaurant!.name,
                                      'category': restaurant!.category,
                                      'location': restaurant!.location,
                                      'imageUrl': restaurant!.photoUrl,
                                      'RestaurantID': restaurant!.id,
                                    },
                                  ),
                                ),
                              );

                              // ถ้ามีการ submit review แล้ว result == true
                              if (result == true) {
                                // เรียก setState เพื่อรีเฟรชข้อมูล
                                setState(() {
                                  // เรียกฟังก์ชันโหลดร้านใหม่ หรือดึงข้อมูลใหม่
                                  _loadUserId();
                                  fetchRestaurant(); // ← ถ้ามีฟังก์ชันนี้ในหน้าแรก
                                });
                              }
                            },

                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                75,
                                73,
                                73,
                              ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFFCE4EC), // พื้นหลังชมพูอ่อน
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 18,
              color: Color.fromARGB(255, 162, 95, 7), // ชมพูเข้ม
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15.5,
                color: Colors.grey[900],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
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
                color: const Color.fromARGB(255, 83, 82, 77),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    '${restaurant!.ratingOverall.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color.fromARGB(255, 244, 244, 244),
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.star,
                    color: Color.fromARGB(255, 255, 255, 255),
                    size: 22,
                  ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              if (value >= index + 1) {
                return const Icon(Icons.star, color: Colors.amber, size: 22);
              } else if (value > index && value < index + 1) {
                return const Icon(
                  Icons.star_half,
                  color: Colors.amber,
                  size: 22,
                );
              } else {
                return const Icon(
                  Icons.star_border,
                  color: Colors.amber,
                  size: 22,
                );
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    final menusToShow = isExpanded
        ? restaurant!.menus
        : restaurant!.menus.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '📋 Menu ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.black87,
                ),
              ),

              TextSpan(
                text: '(${restaurant!.menus.length} items)',
                style: TextStyle(
                  fontWeight: FontWeight.normal, // ✅ ตัวบาง
                  fontSize: 20,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 12),

        // แสดงเมนู
        ...menusToShow.map(
          (menu) => Card(
            // color: const Color.fromARGB(255, 240, 231, 183),
            color: const Color.fromARGB(255, 251, 236, 224),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 15),
            child: Padding(
              padding: const EdgeInsets.all(0.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(0),
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(0),
                    ),
                    child: Image.network(
                      menu.imageUrl,
                      width: 180,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          menu.nameTH,
                          style: TextStyle(fontSize: 15, color: Colors.black),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "฿ ${menu.price}",
                          style: TextStyle(
                            color: Color.fromARGB(255, 94, 66, 31), // ชมพูเข้ม
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 25),
                    child: Icon(
                      Icons.local_dining_rounded,
                      color: Color.fromARGB(255, 162, 95, 7), // ชมพูเข้ม,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        SizedBox(height: 8),

        // ปุ่ม View Full Menu / Show Less
        if (restaurant!.menus.length > 3)
          Padding(
            padding: EdgeInsets.all(0),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 250, 235, 223),
                  foregroundColor: const Color.fromARGB(255, 51, 50, 50),
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: const Color.fromARGB(
                        255,
                        184,
                        153,
                        140,
                      ), // ← สีเส้นขอบที่ต้องการ
                      width: 1.5, // ← ความหนาของเส้นขอบ
                    ),
                  ),
                ),
                child: Text(
                  isExpanded ? "Show Less ▲" : "View Full Menu ▼",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewSection() {
    final reviewsToShow = isReviewExpanded
        ? restaurant!.reviews
        : restaurant!.reviews.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '📝 Reviews ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
              TextSpan(
                text: '(${restaurant!.reviews.length} items)',
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),

        ...reviewsToShow.map((review) {
          final isLiked = likedReviews[review.id] ?? false;

          return Card(
            // color: const Color.fromARGB(255, 255, 239, 210),
            color: const Color.fromARGB(255, 247, 235, 216),
            margin: EdgeInsets.symmetric(vertical: 10),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              constraints: BoxConstraints(minHeight: 100),
              // padding: EdgeInsets.all(15),
              padding: EdgeInsets.only(
                left: 15,
                top: 15,
                right: 15,
                bottom: 13,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 17),
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(review.pictureUrl),
                      radius: 44,
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Stack(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: 80),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review.username,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
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
                                    );
                                  } else if (i < review.ratingOverall &&
                                      review.ratingOverall - i >= 0.5) {
                                    return Icon(
                                      Icons.star_half,
                                      size: 20,
                                      color: Colors.amber,
                                    );
                                  } else {
                                    return Icon(
                                      Icons.star_border,
                                      size: 20,
                                      color: Colors.amber,
                                    );
                                  }
                                }),
                              ),
                              SizedBox(height: 10),
                              Padding(
                                padding: EdgeInsets.only(
                                  right: 20,
                                ), // ปรับตามต้องการ
                                child: Text(
                                  review.comment,
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              SizedBox(height: 10),
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
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: 18,
                                    top: 3,
                                  ), // ปรับตามต้องการ
                                  child: Icon(
                                    Icons.favorite,
                                    color: isLiked ? Colors.red : Colors.grey,
                                    size: 40,
                                  ),
                                ),
                              ),
                              SizedBox(height: 4),
                              Padding(
                                padding: EdgeInsets.only(
                                  left: 18,
                                  bottom: 20,
                                ), // ปรับตามต้องการ
                                child: Text(
                                  "${review.totalLikes} Likes",
                                  style: TextStyle(
                                    fontSize: 11,
                                    // color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              // SizedBox(height: 20),
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

        // ปุ่ม View Full Review / Show Less
        if (restaurant!.reviews.length > 3)
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                setState(() {
                  isReviewExpanded = !isReviewExpanded;
                });
              },
              style: TextButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 231, 219, 202),
                foregroundColor: const Color.fromARGB(255, 51, 50, 50),
                padding: EdgeInsets.symmetric(vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: const Color.fromARGB(
                      255,
                      177,
                      145,
                      131,
                    ), // ← สีเส้นขอบที่ต้องการ
                    width: 1.5, // ← ความหนาของเส้นขอบ
                  ),
                ),
              ),
              child: Text(
                isReviewExpanded ? "Show Less ▲" : "View Full Reviews ▼",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
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
