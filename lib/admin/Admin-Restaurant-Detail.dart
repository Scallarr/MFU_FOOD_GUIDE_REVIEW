import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myapp/admin/Admin-AddMenu.dart';
import 'package:myapp/admin/Admin-EditMenu.dart';
import 'package:myapp/admin/Admin-Pending_Review.dart';
import 'package:myapp/login.dart';
import 'package:myapp/wtite_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/restaurant_model.dart';
import 'package:intl/intl.dart';
import 'package:myapp/admin/Admin-AddMenu.dart';

// import 'package:myapp/admin/Admin-Home.dart';

class RestaurantDetailAdminPage extends StatefulWidget {
  final int restaurantId;

  const RestaurantDetailAdminPage({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailAdminPage> createState() =>
      _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailAdminPage> {
  Restaurant? restaurant;
  bool isLoading = true;
  bool isExpanded = false;
  Map<String, dynamic>? _selectedUser;
  bool isReviewExpanded = false;
  final Color _primaryColor = Color(0xFF4285F4);
  final Color _successColor = Color(0xFF34A853);
  final Color _warningColor = Color(0xFFFBBC05);
  final Color _dangerColor = Color(0xFFEA4335);
  final Color _cardColor = Colors.white;
  final Color _textColor = Color(0xFF202124);
  final Color _secondaryTextColor = Color(0xFF5F6368);
  final Color _colorButton = Color.fromARGB(255, 75, 73, 73);

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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final uri = Uri.parse(
        'http://10.214.52.39:8080/restaurant/${widget.restaurantId}'
        '${userId != null ? '?user_id=$userId' : ''}',
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          restaurant = Restaurant.fromJson(data);
          // print('restaurant.id = ${restaurant}'); // 👈 ต้องได้ค่าที่ไม่ใช่ null
          // print('restaurant.id = ${Restaurant}'); // 👈 ต้องได้ค่าที่ไม่ใช่ null
          // print(
          //   // 'user.id = ${reviews!.id}',
          // ); // 👈 ต้องได้ค่าที่ไม่ใช่ null
          likedReviews = {for (var r in restaurant!.reviews) r.id: r.isLiked};
          isLoading = false;
        });
        // print(data.runtimeType);
      } else if (response.statusCode == 401) {
        // Token หมดอายุ
        _showAlert(context, 'Session expired');
        return;
      } else if (response.statusCode == 403) {
        // User ถูกแบน - แสดง alert ตามที่ต้องการ
        _showAlert(context, 'Your account has been banned.');
        return;
      } else {
        print('Failed to load restaurant. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
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

  Widget _buildInfoChip(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    final baseColor = color ?? Colors.blue;

    return Container(
      width: 120, // ให้ขนาดเท่ากัน
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            baseColor.withOpacity(0.95),
            const Color.fromARGB(255, 174, 174, 174).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.15),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 3, 3, 3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 22,
              color: const Color.fromARGB(255, 255, 255, 255),
            ),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 255, 255, 255),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color.fromARGB(255, 220, 216, 216),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildUserBanner(String? imageUrl) {
    final placeholder =
        "https://via.placeholder.com/400x200.png?text=No+Image"; // fallback

    return Container(
      width: double.infinity,
      height: 430,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              (imageUrl != null && imageUrl.isNotEmpty)
                  ? imageUrl
                  : placeholder,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey[600],
                      size: 48,
                    ),
                  ),
                );
              },
            ),
            // gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool isProcessing = false;
  Future<void> likeReview(int reviewId) async {
    if (userId == null) {
      print("User not logged in");
      return;
    }
    if (isProcessing) return;
    isProcessing = true;

    final url = Uri.parse('http://10.214.52.39:8080/review/$reviewId/like');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    try {
      final response = await http.post(
        url,
        body: json.encode({'user_id': userId}),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
              email: oldReview.email,
              ai_evaluation: oldReview.ai_evaluation,
              User_ID: oldReview.User_ID,
              status: oldReview.status,
              usertotalLikes: oldReview.usertotalLikes,
              coins: oldReview.coins,
              role: oldReview.role,
              total_reviews: oldReview.total_reviews,
            );

            restaurant!.reviews[index] = updatedReview;

            // 如果当前显示的用户信息是被点赞的用户，更新用户信息
            if (_selectedUser != null &&
                _selectedUser!['User_ID'] == oldReview.User_ID) {
              // 使用 then 来处理异步操作，避免使用 await
              fetchUserInfo(oldReview.User_ID).then((updatedUserInfo) {
                if (updatedUserInfo != null) {
                  setState(() {
                    _selectedUser = updatedUserInfo;
                  });
                }
              });
            }
          }
        });

        // await updateLeaderboard();
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

  Future<Map<String, dynamic>?> fetchUserInfo(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final uri = Uri.parse('http://10.214.52.39:8080/user/info/$userId');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        return {
          'User_ID': userId,
          'username': userData['username'] ?? '',
          'email': userData['email'] ?? '',
          'total_likes': userData['total_likes'] ?? 0,
          'total_reviews': userData['total_reviews'] ?? 0,
          'coins': userData['coins'] ?? 0,
          'status': userData['status'] ?? '',
          'picture_url': userData['picture_url'] ?? '',
          'role': userData['role'] ?? '',
        };
      } else {
        print('Failed to fetch user info. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching user info: $e');
      return null;
    }
  }

  Future<void> updateLeaderboard() async {
    try {
      final url = Uri.parse('http://10.214.52.39:8080/leaderboard/update-auto');
      // สมมติว่า backend ต้องการเดือนปีใน body (format 'YYYY-MM')
      // คุณอาจจะเก็บเดือนปีที่เหมาะสมไว้ในตัวแปร เช่น currentMonthYear
      final currentMonthYear = DateTime.now();
      final formattedMonth =
          "${currentMonthYear.year.toString()}-${currentMonthYear.month.toString().padLeft(2, '0')}";
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final response = await http.post(
        url,
        body: json.encode({'month_year': formattedMonth}),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
        backgroundColor: const Color(0xFFCEBFA3),
        appBar: AppBar(title: Text('Restaurant Details')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(
              'Restaurant Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: const Color(0xFFCEBFA3),
            floating: true, // ทำให้เลื่อนขึ้นมาได้ทันที
            snap: true, // เลื่อนลงซ่อนทันที
            elevation: 4,
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                // Refresh the previous page and go back
                Navigator.pop(
                  context,
                  true,
                ); // 'true' indicates a refresh is needed
              },
            ),
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
                            child: Row(
                              children: [
                                Text(
                                  restaurant!.name,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                  ),
                                ),
                                SizedBox(width: 7),
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.blue,
                                  size: 21,
                                ),
                              ],
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
                          color: const Color.fromARGB(255, 255, 255, 255),
                        ),
                        label: Text(
                          restaurant!.category,
                          style: TextStyle(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            fontWeight: FontWeight.w500,
                            fontSize: 17,
                          ),
                        ),
                        backgroundColor: _colorButton, // สีน้ำตาลโกโก้ดูหรู
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
                                  isReviewExpanded = false;

                                  // เรียกฟังก์ชันโหลดร้านใหม่ หรือดึงข้อมูลใหม่
                                  _loadUserId();

                                  fetchRestaurant();
                                  // ← ถ้ามีฟังก์ชันนี้ในหน้าแรก
                                });
                              }
                            },

                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(
                                255,
                                245,
                                240,
                                230,
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical:
                                    14, // ไม่ต้องกำหนด horizontal เพราะกว้างเต็มแล้ว
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              side: BorderSide(
                                color: Color.fromARGB(255, 225, 225, 225),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              'Write a Review',
                              style: TextStyle(
                                fontSize: 16,
                                color: const Color.fromARGB(255, 37, 18, 18),
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
      bottomSheet: _selectedUser != null
          ? Container(
              padding: EdgeInsets.only(),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color.fromARGB(255, 46, 45, 45), // เทาเข้มด้านล่าง
                    const Color.fromARGB(255, 136, 133, 133), // เทาอ่อนด้านบน
                    const Color.fromARGB(255, 46, 45, 45), // เทาเข้มด้านล่าง
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ส่วนหัว

                    // Container สำหรับ Banner และ Avatar ที่ซ้อนกัน
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Banner
                        Container(
                          margin: EdgeInsets.only(
                            bottom: 40,
                          ), // ระยะห่างสำหรับ Avatar
                          child: buildUserBanner(_selectedUser?['picture_url']),
                        ),

                        // Avatar (วางซ้อนลงบน Banner)
                        Positioned(
                          bottom: 0, // ทำให้ Avatar ยื่นออกมาจาก Banner
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.blue[100],
                              backgroundImage:
                                  (_selectedUser!['picture_url'] != null &&
                                      _selectedUser!['picture_url'].isNotEmpty)
                                  ? NetworkImage(_selectedUser!['picture_url'])
                                  : null,
                              child:
                                  (_selectedUser!['picture_url'] == null ||
                                      _selectedUser!['picture_url'].isEmpty)
                                  ? Text(
                                      _selectedUser!['username'][0]
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[800],
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(Icons.close_rounded, size: 40),
                                color: const Color.fromARGB(255, 237, 235, 235),
                                onPressed: () {
                                  setState(() {
                                    _selectedUser = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 400,
                          right: -60,
                          child: Icon(
                            Icons.lock_outlined,
                            size: 120,
                            color: const Color.fromARGB(
                              255,
                              0,
                              0,
                              0,
                            ).withOpacity(0.1),
                          ),
                        ),
                        Positioned(
                          top: 400,
                          left: -60,
                          child: Icon(
                            Icons.lock_outlined,
                            size: 120,
                            color: const Color.fromARGB(
                              255,
                              0,
                              0,
                              0,
                            ).withOpacity(0.1),
                          ),
                        ),
                        Positioned(
                          top: 290,
                          right: -60,
                          child: Icon(
                            Icons.lock_outlined,
                            size: 120,
                            color: const Color.fromARGB(
                              255,
                              0,
                              0,
                              0,
                            ).withOpacity(0.1),
                          ),
                        ),
                        Positioned(
                          bottom: -550,
                          left: 40,
                          child: Icon(
                            Icons.group,
                            size: 340,
                            color: const Color.fromARGB(
                              255,
                              9,
                              9,
                              9,
                            ).withOpacity(0.4),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedUser = null;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(
                                8,
                              ), // ทำให้ Icon มีพื้นที่รอบ ๆ
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.redAccent.shade100,
                                    Colors.red.shade700,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 28,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ชื่อและ email (ลดระยะห่างจาก Avatar)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 7,
                        bottom: 16,
                      ), // ลดจาก 60 เป็น 50
                      child: Column(
                        children: [
                          Text(
                            _selectedUser!['username'],
                            style: TextStyle(
                              fontSize: 22, // เพิ่มขนาดฟอนต์
                              fontWeight: FontWeight.w800, // ตัวหนากว่าเดิม
                              color: const Color.fromARGB(255, 255, 255, 255),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 6), // เพิ่มระยะห่างเล็กน้อย
                          Text(
                            obfuscateEmail(_selectedUser!['email']),
                            style: TextStyle(
                              fontSize: 15, // เพิ่มขนาดฟอนต์เล็กน้อย
                              color: const Color.fromARGB(255, 222, 220, 220),
                              fontWeight: FontWeight.w500, // ตัวหนาปานกลาง
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsetsGeometry.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ชิปข้อมูล
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildInfoChip(
                                Icons.badge_outlined,
                                "User ID",
                                "${_selectedUser!['User_ID']}",
                                color: Colors.blue,
                              ),
                              if (_selectedUser!['role'] != null &&
                                  _selectedUser!['role'].isNotEmpty)
                                _buildInfoChip(
                                  Icons.manage_accounts,
                                  "Role",
                                  "${_selectedUser!['role']}",
                                  color: Colors.teal,
                                ),
                              _buildInfoChip(
                                _selectedUser!['status'] == "Active"
                                    ? Icons.verified_user_outlined
                                    : Icons.block_outlined,
                                "Status",
                                _selectedUser!['status'],
                                color: _selectedUser!['status'] == "Active"
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              _buildInfoChip(
                                Icons.monetization_on_outlined,
                                "Coins",
                                '${formatCoins(_selectedUser!['coins'])} ',
                                color: Colors.orange,
                              ),
                              if (_selectedUser!['total_likes'] != null)
                                _buildInfoChip(
                                  Icons.favorite_outline,
                                  "Likes",
                                  "${_selectedUser!['total_likes']}",
                                  color: Colors.pink,
                                ),
                              if (_selectedUser!['total_reviews'] != null)
                                _buildInfoChip(
                                  Icons.reviews_outlined,
                                  "Reviews",
                                  "${_selectedUser!['total_reviews']}",
                                  color: const Color.fromARGB(
                                    255,
                                    183,
                                    52,
                                    222,
                                  ),
                                ),
                            ],
                          ),

                          if (_selectedUser!['ban_info'] != null &&
                              _selectedUser!['ban_info'].isNotEmpty) ...[
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange[700],
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Ban Info: ${_selectedUser!['ban_info']}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.orange[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            ), // Verify Button with Notification Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                InkWell(
                  onTap: () async {
                    final shouldRefresh = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            Addmenu(restaurantId: restaurant!.id),
                      ),
                    );
                    if (shouldRefresh) {
                      fetchRestaurant();
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(124, 0, 0, 0), // Brown 400
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(
                            255,
                            0,
                            0,
                            0,
                          ).withOpacity(0.3),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 20, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Add ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 12),

        // แสดงเมนู
        ...menusToShow.map(
          (menu) => Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 8,
            margin: EdgeInsets.symmetric(vertical: 15),
            child: InkWell(
              onTap: () {
                // เมื่อคลิกที่ Card จะไปยังหน้าแก้ไข
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => EditMenuPage(menuId: menu.id),
                //   ),
                // );
              },
              child: Padding(
                padding: const EdgeInsets.all(0.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ส่วนแสดงรูปภาพ
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                      ),
                      child: Image.network(
                        menu.imageUrl,
                        width: 180,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 16),
                    // ส่วนแสดงข้อมูลเมนู
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
                              color: Color.fromARGB(255, 94, 66, 31),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ปุ่มเมนูแบบ Popup
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Color.fromARGB(255, 162, 95, 7),
                        size: 28,
                      ),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditMenuPage(
                                menuId: menu.id,
                                currentThaiName: menu.nameTH,
                                currentEnglishName: menu
                                    .nameEN, // Make sure your model has this
                                currentPrice: menu.price,
                                currentImageUrl: menu.imageUrl,
                                restaurantId: restaurant!.id,
                              ),
                            ),
                          );

                          if (result == true) {
                            fetchRestaurant(); // Refresh the menu list
                          }
                        } else if (value == 'delete') {
                          _showDeleteDialog(context, menu.id);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Edit Menu'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete Menu'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
                  backgroundColor: _colorButton,
                  foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: const Color.fromARGB(
                        255,
                        230,
                        212,
                        212,
                      ), // ← สีเส้นขอบที่ต้องการ
                      width: 1.5, // ← ความหนาของเส้นขอบ
                    ),
                  ),
                ),
                child: Text(
                  isExpanded ? "Show Less Menu ▲" : "View Full Menu ▼",
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                InkWell(
                  onTap: () async {
                    final shouldRefresh = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PendingReviewsPage(restaurantId: restaurant!.id),
                      ),
                    );
                    if (shouldRefresh) {
                      fetchRestaurant();
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 76, 74, 74), // Brown 400
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.brown.withOpacity(0.3),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 20, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Verify',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Notification Badge - Fixed condition and variable
                if (restaurant!.pendingReviewsCount > 0)
                  Positioned(
                    right: -5,
                    top: -20,
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 219, 31, 31),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        '${restaurant!.pendingReviewsCount}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        ...reviewsToShow.map((review) {
          final isLiked = likedReviews[review.id] ?? false;

          return Card(
            // color: const Color.fromARGB(255, 255, 239, 210),
            color: const Color.fromARGB(255, 255, 255, 255),
            margin: EdgeInsets.symmetric(vertical: 10),
            elevation: 14,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(12),
                  ),

                  // ... child widget อื่น ๆ
                  child: Container(
                    constraints: BoxConstraints(minHeight: 100),
                    // padding: EdgeInsets.all(15),
                    padding: EdgeInsets.only(
                      left: 15,
                      top: 13,
                      right: 14,
                      bottom: 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: GestureDetector(
                                onTap: () async {
                                  setState(() {
                                    if (_selectedUser != null &&
                                        _selectedUser!['User_ID'] ==
                                            review.User_ID) {
                                      _selectedUser = null;
                                    } else {
                                      // 先显示加载中的状态
                                      _selectedUser = {
                                        'User_ID': review.User_ID,
                                        'username': review.username,
                                        'email': review.email,
                                        'total_likes': review.usertotalLikes,
                                        'coins': review.coins,
                                        'status': review.status,
                                        'picture_url': review.pictureUrl,
                                        'role': review.role,
                                        'total_reviews': review.total_reviews,
                                        'isLoading': true, // 添加加载状态
                                      };
                                    }
                                  });

                                  // 获取最新的用户信息
                                  final updatedUserInfo = await fetchUserInfo(
                                    review.User_ID,
                                  );
                                  if (updatedUserInfo != null) {
                                    setState(() {
                                      _selectedUser = updatedUserInfo;
                                    });
                                  }
                                },
                                child: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    review.pictureUrl,
                                  ),
                                  radius: 33,
                                  backgroundColor: Colors.grey[200],
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(right: 0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  review.username,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14.5,
                                                  ),
                                                ),
                                                SizedBox(width: 7),
                                                Icon(
                                                  Icons.check_circle,
                                                  color: Colors.blue,
                                                  size: 19,
                                                ),
                                              ],
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              getTimeAgo(
                                                    DateTime.parse(
                                                      review.createdAt,
                                                    ).toLocal(), // ✅ แปลงเป็น Local
                                                  ).isNotEmpty
                                                  ? getTimeAgo(
                                                      DateTime.parse(
                                                        review.createdAt,
                                                      ).toLocal(), // ✅
                                                    )
                                                  : _formatDate(
                                                      review.createdAt,
                                                    ),
                                              style: TextStyle(
                                                color: const Color.fromARGB(
                                                  255,
                                                  0,
                                                  0,
                                                  0,
                                                ),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          obfuscateEmail(review.email),
                                          style: TextStyle(fontSize: 10.5),
                                        ),
                                        SizedBox(height: 7),
                                        Row(
                                          children: List.generate(5, (i) {
                                            if (i <
                                                review.ratingOverall.floor()) {
                                              return Icon(
                                                Icons.star,
                                                size: 24,
                                                color: Colors.amber,
                                              );
                                            } else if (i <
                                                    review.ratingOverall &&
                                                review.ratingOverall - i >=
                                                    0.5) {
                                              return Icon(
                                                Icons.star_half,
                                                size: 24,
                                                color: Colors.amber,
                                              );
                                            } else {
                                              return Icon(
                                                Icons.star_border,
                                                size: 24,
                                                color: Colors.amber,
                                              );
                                            }
                                          }),
                                        ),
                                        SizedBox(height: 10),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: 0),
                                  Padding(
                                    padding: EdgeInsetsGeometry.only(
                                      right: 7,
                                      top: 10,
                                      bottom: 0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Column(
                                          // mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                if (userId != null) {
                                                  likeReview(review.id);
                                                }
                                              },
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  right: 0,
                                                  left: 60,
                                                  top: 25,
                                                  bottom: 0,
                                                ), // ปรับตามต้องการ
                                                child: Icon(
                                                  Icons.favorite,
                                                  color: isLiked
                                                      ? Colors.red
                                                      : Colors.grey,
                                                  size: 40,
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Padding(
                                              padding: EdgeInsets.only(
                                                left: 60,
                                                bottom: 5,
                                              ), // ปรับตามต้องการ
                                              child: Text(
                                                "${review.totalLikes} Likes",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  // color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 7),
                        // ข้อความรีวิว - ย้ายมาอยู่ใต้รูป
                        Padding(
                          padding: EdgeInsets.only(
                            right: 0,
                            left: 0, // เพิ่ม padding ซ้ายเพื่อจัดตำแหน่ง
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              review.comment,
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),

                        SizedBox(height: 10),
                        Divider(height: 1),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.analytics,
                                  size: 20,
                                  color: Color(0xFF4285F4),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  "AI Analysis: ${review.ai_evaluation ?? 'N/A'}",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF4285F4),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsetsGeometry.all(14),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.redAccent.shade200,
                                      Colors.deepOrange.shade400,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.redAccent.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(2, 3),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    Icons.report_gmailerrorred_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => _showRejectDialog2(
                                    review.id,
                                    review.User_ID,
                                  ),
                                  tooltip:
                                      "Report this review", // เพิ่ม tooltip เวลา hover
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 29,
                  left: 11,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 212, 58, 58),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.verified,
                      size: 25,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),

        // ปุ่ม View Full Review / Show Less
        if (restaurant!.reviews.length > 3) SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              setState(() {
                isReviewExpanded = !isReviewExpanded;
              });
            },
            style: TextButton.styleFrom(
              backgroundColor: _colorButton,
              foregroundColor: const Color.fromARGB(255, 255, 255, 255),
              padding: EdgeInsets.symmetric(vertical: 13),
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

  void _showDeleteDialog(BuildContext context, int menuId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ยืนยันการลบ'),
          content: Text('คุณแน่ใจว่าต้องการลบเมนูนี้หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                _deleteMenu(menuId); // เรียกฟังก์ชันลบเมนู
                Navigator.pop(context);
              },
              child: Text('ลบ', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteMenu(int menuId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://10.214.52.39:8080/Delete/menus/$menuId'),
      );
      if (response.statusCode == 200) {
        fetchRestaurant();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ลบเมนูสำเร็จ')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  Future<void> _showRejectDialog2(int reviewID, int reviewuserID) async {
    print("📌 reviewID = $reviewID, User_ID = $reviewuserID"); // Debug log
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
                Text(
                  'Confirm Rejection',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Are you sure you want to reject this thread?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: _secondaryTextColor,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 20),
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
                Row(
                  children: [
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
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _banThread2(
                            reviewID,
                            reviewuserID,

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

  String formatCoins(dynamic coins) {
    int value = 0;

    if (coins != null) {
      if (coins is int) {
        value = coins;
      } else if (coins is String) {
        value = int.tryParse(coins) ?? 0;
      }
    }

    return NumberFormat('#,###').format(value);
  }

  // เพิ่มเมธอดสำหรับเรียก API แบน
  Future<void> _banThread2(
    int reviewID,
    int reviewuserID, {

    String reason = '',
  }) async {
    try {
      final int review_ID = reviewID;

      final rejectionReason = reason.isEmpty ? 'Inappropriate message' : reason;

      final response = await http.post(
        Uri.parse('http://10.214.52.39:8080/review/AdminManual-check/reject'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'rewiewId': review_ID,
          'adminId': userId,
          'reviewuserID': reviewuserID,
          'reason': rejectionReason,
          'restaurantId': widget.restaurantId,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Thread banned successfully')));
        fetchRestaurant(); // รีเฟรชรายการ threads
      } else {
        throw Exception('Failed to ban thread');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
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

String getTimeAgo(DateTime dateTimeUtc) {
  final localDateTime = dateTimeUtc.toLocal(); // ✅ แปลงเป็นเวลา Local
  final now = DateTime.now();
  final difference = now.difference(localDateTime);

  if (difference.inSeconds < 10) {
    return 'Just now';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} minutes ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hours ago';
  } else if (difference.inDays == 1) {
    return 'Yesterday';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  } else {
    return ''; // You can use _formatDate() instead later
  }
}

String obfuscateEmail(String email) {
  if (email.endsWith('@lamduan.mfu.ac.th')) {
    final domain = '@lamduan.mfu.ac.th';
    if (email.length > domain.length + 2) {
      final prefix = email.substring(0, 2);
      return '$prefix********$domain';
    }
  } else if (email.endsWith('@mfu.ac.th')) {
    final domain = '@mfu.ac.th';
    return '**********$domain';
  } else {
    // กรณีอื่น ๆ
    final atIndex = email.indexOf('@');
    if (atIndex != -1) {
      final prefix = email.substring(0, 4);
      final domain = email.substring(atIndex);
      return '$prefix**********$domain';
    }
  }

  return email; // ถ้า format ไม่ใช่ email
}
