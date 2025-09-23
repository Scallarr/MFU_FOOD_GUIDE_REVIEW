import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/Atlas-model.dart';
import 'package:myapp/RestaurantHistory.dart';
import 'package:myapp/admin/Admin-AddRestaurant.dart';
import 'package:myapp/admin/Admin-Dashboard.dart';
import 'package:myapp/admin/Admin-Leaderboard.dart';
import 'package:myapp/admin/Admin-Pending-all-Review.dart';
import 'package:myapp/admin/Admin-Pending_Review.dart';
import 'package:myapp/admin/Admin-Restaurant-Detail.dart';
import 'package:myapp/admin/Admin-Restaurant-History.dart';
import 'package:myapp/admin/Admin-Thread.dart';
import 'package:myapp/admin/Admin-profile-info.dart';
import 'package:myapp/dashboard.dart';
import 'package:myapp/Profileinfo.dart';
import 'package:myapp/leaderboard.dart';
import 'package:myapp/login.dart';
import 'package:myapp/restaurantDetail.dart';
import 'package:myapp/admin/Admin-Edit-Restaurant.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/threads.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:async';

class Restaurant {
  final int id;
  final String name;
  final String location;
  final String operatingHours;
  final String phoneNumber;
  final String photoUrl;
  final double ratingOverall;
  final double ratingHygiene;
  final double ratingFlavor;
  final double ratingService;
  final String category;
  final int pendingReviewsCount;
  final int postedReviewsCount;

  Restaurant({
    required this.id,
    required this.name,
    required this.location,
    required this.operatingHours,
    required this.phoneNumber,
    required this.photoUrl,
    required this.ratingOverall,
    required this.ratingHygiene,
    required this.ratingFlavor,
    required this.ratingService,
    required this.category,
    required this.pendingReviewsCount,
    required this.postedReviewsCount,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['Restaurant_ID'],
      name: json['restaurant_name'],
      location: json['location'],
      operatingHours: json['operating_hours'],
      phoneNumber: json['phone_number'],
      photoUrl: json['photos'],
      ratingOverall: double.parse(json['rating_overall_avg'].toString()),
      ratingHygiene: double.parse(json['rating_hygiene_avg'].toString()),
      ratingFlavor: double.parse(json['rating_flavor_avg'].toString()),
      ratingService: double.parse(json['rating_service_avg'].toString()),
      category: json['category'],
      pendingReviewsCount: json['pending_reviews_count'] ?? 0,
      postedReviewsCount: json['posted_reviews_count'] ?? 0,
    );
  }
}

class RestaurantListPageUser extends StatefulWidget {
  @override
  _RestaurantListPageState createState() => _RestaurantListPageState();
  final bool reload;

  const RestaurantListPageUser({super.key, this.reload = false});
}

class _RestaurantListPageState extends State<RestaurantListPageUser>
    with TickerProviderStateMixin {
  // ✅ เพิ่ม mixin นี้

  late Future<List<Restaurant>> futureRestaurants;
  List<Restaurant> allRestaurants = [];
  String searchQuery = '';
  String sortBy = '';
  bool ratingAscending = false;
  String? filterLocation;
  String? filterCategory;
  String? profileImageUrl;
  int? userId;
  late AnimationController _lockIconController; // ✅ เพิ่ม AnimationController
  late Animation<double> _lockIconAnimation; // ✅ เพิ่ม Animation
  bool _isDeleting = false;

  int get totalPendingReviews {
    return allRestaurants.fold(
      0,
      (sum, restaurant) => sum + restaurant.pendingReviewsCount,
    );
  }

  final List<String> locationOptions = [
    'D1',
    'E1',
    'E2',
    'C5',
    'S2',
    'M-SQUARE',
    'LAMDUAN',
  ];

  final List<String> categoryOptions = ['Main_dish', 'Snack', 'Drinks'];

  final double buttonHeight = 36;
  final double buttonWidth = 137;
  int _selectedIndex = 0;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();

    // ✅ Initialize animation controller สำหรับไอคอนล็อค
    _lockIconController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _lockIconAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _lockIconController, curve: Curves.easeInOut),
    );

    loadUserIdAndFetchProfile();
    futureRestaurants = fetchRestaurants();
    futureRestaurants.then((list) {
      setState(() {
        allRestaurants = list;
        _precacheRestaurantImages();
      });
    });
  }

  @override
  void dispose() {
    _lockIconController.dispose(); // ✅ อย่าลืม dispose controller
    super.dispose();
  }

  void _precacheRestaurantImages() {
    for (var restaurant in allRestaurants) {
      try {
        precacheImage(
          CachedNetworkImageProvider(_validateImageUrl(restaurant.photoUrl)),
          context,
        );
      } catch (e) {
        debugPrint('Failed to precache image: ${restaurant.photoUrl}');
      }
    }
  }

  String _validateImageUrl(String url) {
    if (url.isEmpty) return 'https://via.placeholder.com/400';
    if (!url.startsWith('http')) return 'https://$url';
    return url;
  }

  Future<void> loadUserIdAndFetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getInt('user_id');

    if (storedUserId != null) {
      setState(() {
        userId = storedUserId;
      });

      await fetchProfilePicture(userId!);
    }
  }

  Future<void> fetchProfilePicture(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('http://172.27.112.167:8080/user-profile/$userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          profileImageUrl = _validateImageUrl(data['picture_url']);
        });
      } else {
        debugPrint('Failed to load profile picture');
      }
    } catch (e) {
      debugPrint('Error fetching profile picture: $e');
    }
  }

  Future<List<Restaurant>> fetchRestaurants() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        _showAlert(context, 'Access Denied Because Invalid Token');
        return [];
      }

      final response = await http.get(
        Uri.parse('http://172.27.112.167:8080/restaurants'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        List jsonList = json.decode(response.body);
        return jsonList.map((json) => Restaurant.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        _showAlert(context, 'Session expired');
        return [];
      } else if (response.statusCode == 403) {
        final data = json.decode(response.body);

        // แก้ไขการ parse วันที่
        DateTime? expectedUnban;
        if (data['expectedUnbanDate'] != null) {
          try {
            // ลอง parse ในรูปแบบต่างๆ
            expectedUnban = DateTime.tryParse(data['expectedUnbanDate']);
            if (expectedUnban == null && data['expectedUnbanDate'] is String) {
              // ลองแปลงจาก timestamp string
              final timestamp = int.tryParse(data['expectedUnbanDate']);
              if (timestamp != null) {
                expectedUnban = DateTime.fromMillisecondsSinceEpoch(timestamp);
              }
            }
          } catch (e) {
            debugPrint('Error parsing expectedUnbanDate: $e');
          }
        }

        _showBanDialog(
          context,
          reason: data['reason'] ?? "Unknown",
          ban_duration_days: data['ban_duration_days'] as int?, // nullable
          banDate: data['banDate'] ?? "N/A",
          expectedUnban: expectedUnban,
        );
        return [];
      } else {
        throw Exception('Failed to load restaurants: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching restaurants: $e');
      _showAlert(context, 'Failed to load restaurants.');
      return [];
    }
  }

  void _showBanDialog(
    BuildContext context, {
    required String reason,
    required int? ban_duration_days,
    required String banDate,
    DateTime? expectedUnban,
  }) {
    // Format วันที่ให้แสดงแค่วันที่ ไม่ต้องมีเวลา
    String formatDateOnly(String dateString) {
      try {
        final dateTime = DateTime.parse(dateString);
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } catch (e) {
        return dateString; // หาก parse ไม่ได้ return ค่าเดิม
      }
    }

    String formatExpectedUnban(DateTime? date) {
      if (date == null) return "Permanent";
      return '${date.day}/${date.month}/${date.year}';
    }

    // State สำหรับ remaining time
    final remainingTimeNotifier = ValueNotifier<String>(
      expectedUnban == null ? "Permanent Ban" : "Calculating...",
    );

    Timer? timer;
    if (expectedUnban != null) {
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        final now = DateTime.now();
        final diff = expectedUnban.difference(now);

        if (diff.isNegative) {
          remainingTimeNotifier.value = "Ban Expired (pending unban)";
          t.cancel();
        } else {
          final days = diff.inDays;
          final hours = diff.inHours % 24;
          final minutes = diff.inMinutes % 60;
          final seconds = diff.inSeconds % 60;
          remainingTimeNotifier.value =
              "${days}d ${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s";
        }
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative elements
                Positioned(
                  top: -20,
                  right: -20,
                  child: Icon(
                    Icons.lock_outlined,
                    size: 120,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -30,
                  child: Icon(
                    Icons.security,
                    size: 100,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ แก้ไขเป็น AnimatedBuilder สำหรับไอคอนล็อค
                      AnimatedBuilder(
                        animation: _lockIconAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _lockIconAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFE74C3C).withOpacity(0.2),
                                border: Border.all(
                                  color: const Color(0xFFE74C3C),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.lock_outline_rounded,
                                size: 48,
                                color: Color(0xFFE74C3C),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Title
                      const Text(
                        "Account Restricted",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // Subtitle
                      const Text(
                        "Your account has been temporarily suspended",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // Information Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(
                          left: 50,
                          right: 0,
                          top: 20,
                          bottom: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildInfoRow("Reason", reason),
                            const SizedBox(height: 12),
                            _buildInfoRow("Ban Date", formatDateOnly(banDate)),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              "Ban Duration",
                              ban_duration_days != null
                                  ? "$ban_duration_days Days"
                                  : "Permanent Ban",
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Countdown Timer (แสดงเฉพาะถ้าไม่ใช่แบนถาวร)
                      if (expectedUnban != null)
                        ValueListenableBuilder<String>(
                          valueListenable: remainingTimeNotifier,
                          builder: (context, remainingTime, _) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C3E50),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(
                                    0xFFE74C3C,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    "TIME REMAINING",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    remainingTime,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFE74C3C),
                                      fontFamily: 'Monospace',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C3E50),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE74C3C).withOpacity(0.3),
                            ),
                          ),
                          child: const Text(
                            "PERMANENT BAN",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE74C3C),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),

                      const SizedBox(height: 28),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE74C3C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 24,
                            ),
                            elevation: 4,
                          ),
                          onPressed: () async {
                            timer?.cancel();
                            await _googleSignIn.signOut();
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.clear();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => LoginScreen()),
                              (route) => false,
                            );
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.exit_to_app, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Sign Out",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Support Text
                      GestureDetector(
                        onTap: () {
                          // Handle support contact
                        },
                        child: const Text(
                          "Contact support if you believe this is a mistake",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                            decoration: TextDecoration.underline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() async {
      // ✅ ตรงนี้จะถูกเรียกเสมอ หลัง dialog หาย (ไม่ว่าจะปิดยังไง)
      timer?.cancel();
      await _googleSignIn.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            "$label:",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  void _goToLogin(BuildContext context) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  void _showAlert(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
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

  List<Restaurant> get filteredAndSortedRestaurants {
    List<Restaurant> filtered = allRestaurants.where((res) {
      final query = searchQuery.toLowerCase();
      final matchesSearch =
          res.name.toLowerCase().contains(query) ||
          res.location.toLowerCase().contains(query) ||
          res.category.toLowerCase().contains(query);

      final matchesLocation = filterLocation == null || filterLocation!.isEmpty
          ? true
          : res.location.toLowerCase() == filterLocation!.toLowerCase();

      final matchesCategory = filterCategory == null || filterCategory!.isEmpty
          ? true
          : res.category.toLowerCase() == filterCategory!.toLowerCase();

      return matchesSearch && matchesLocation && matchesCategory;
    }).toList();

    if (sortBy == 'rating') {
      filtered.sort(
        (a, b) => ratingAscending
            ? a.ratingOverall.compareTo(b.ratingOverall)
            : b.ratingOverall.compareTo(a.ratingOverall),
      );
    }

    return filtered;
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LeaderboardPageUser()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => userChatbotScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ThreadsUserPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDeleting) {
      return Scaffold(
        backgroundColor: Colors.black.withOpacity(0.3),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final restaurantsToShow = filteredAndSortedRestaurants;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 233, 225, 210),
              Color(0xFFF7F4EF),
              Color(0xFFF7F4EF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              toolbarHeight: 80,
              backgroundColor: const Color.fromARGB(255, 229, 210, 173),

              pinned: false,
              floating: true,
              snap: true,
              elevation: 6,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              title: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MFU FOOD GUIDE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                        color: const Color.fromARGB(255, 255, 255, 255),
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final shouldRefresh = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePageUser(),
                          ),
                        );

                        if (shouldRefresh == true) {
                          fetchProfilePicture(userId!);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: profileImageUrl == null
                            ? CircleAvatar(
                                backgroundColor: Colors.grey[300],
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 40,
                                ),
                                radius: 27,
                              )
                            : CircleAvatar(
                                backgroundImage: NetworkImage(profileImageUrl!),
                                radius: 27,
                                backgroundColor: Colors.grey[300],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar
            // ในส่วนของ SliverPadding ที่มี Search Bar ให้เพิ่ม PopupMenuButton ด้านขวา
            SliverPadding(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 14),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search restaurants Name...',
                          hintStyle: TextStyle(
                            color: Color.fromARGB(
                              255,
                              0,
                              0,
                              0,
                            ).withOpacity(0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF5D4037),
                          ),
                          filled: true,
                          fillColor: Color(0xFFF5F0E6),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Color.fromARGB(255, 108, 76, 44),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Color.fromARGB(255, 122, 80, 38),
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Color.fromARGB(255, 141, 71, 50),
                              width: 2.5,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          color: Color.fromARGB(255, 34, 31, 30),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    // เพิ่ม PopupMenuButton ตรงนี้
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Color(0xFF5D4037),
                        size: 30,
                      ),
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem(
                          value: 'history',
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 8),

                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.history,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                SizedBox(width: 15),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('My  History'),
                                      // if (totalPendingReviews > 0)
                                      // Text(
                                      //   'See Your History here',
                                      //   style: TextStyle(
                                      //     fontSize: 12,
                                      //     color: Colors.grey.shade600,
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ),

                                // if (totalPendingReviews > 0)
                                //   Container(
                                //     width: 24,
                                //     height: 24,
                                //     decoration: BoxDecoration(
                                //       color: Color(0xFFFF4757),
                                //       shape: BoxShape.circle,
                                //     ),
                                //     child: Center(
                                //       child: Text(
                                //         '$totalPendingReviews',
                                //         style: TextStyle(
                                //           color: Colors.white,
                                //           fontSize: 11,
                                //           fontWeight: FontWeight.bold,
                                //         ),
                                //       ),
                                //     ),
                                //   ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      onSelected: (String value) async {
                        if (value == 'history') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RestaurantReviewHistoryUserPage(),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Filter Buttons
            SliverPadding(
              padding: const EdgeInsets.only(top: 15, left: 14),
              sliver: SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 105,
                        child: SortButton(
                          label: 'Rating',
                          selected: sortBy == 'rating',
                          icon: sortBy == 'rating'
                              ? Icon(
                                  ratingAscending
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 20,
                                  color: Colors.white,
                                )
                              : Icon(
                                  Icons.star,
                                  size: 20,
                                  color: Colors.yellow,
                                ),
                          onTap: () {
                            setState(() {
                              if (sortBy != 'rating') {
                                sortBy = 'rating';
                                ratingAscending = false;
                              } else {
                                if (!ratingAscending) {
                                  ratingAscending = true;
                                } else {
                                  sortBy = '';
                                }
                              }
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 7),
                      SizedBox(
                        width: buttonWidth,
                        child: Container(
                          height: buttonHeight,
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: filterLocation == null
                                  ? const Color.fromARGB(255, 43, 43, 43)
                                  : const Color.fromARGB(255, 248, 248, 248),
                              width: 1.0,
                            ),
                            color: filterLocation == null
                                ? Colors.white
                                : const Color.fromARGB(255, 0, 0, 0),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: filterLocation ?? '',
                              isExpanded: true,
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: filterLocation == null
                                    ? Colors.black54
                                    : Colors.white,
                              ),
                              dropdownColor: const Color.fromARGB(
                                255,
                                203,
                                166,
                                136,
                              ),
                              items: [
                                DropdownMenuItem(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 19,
                                        color: filterLocation == null
                                            ? Colors.blue
                                            : const Color.fromARGB(
                                                255,
                                                0,
                                                0,
                                                0,
                                              ),
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        'All location',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  value: '',
                                ),
                                ...locationOptions.map(
                                  (loc) => DropdownMenuItem(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 20,
                                          color: filterLocation == null
                                              ? const Color.fromARGB(
                                                  255,
                                                  0,
                                                  0,
                                                  0,
                                                )
                                              : const Color.fromARGB(
                                                  255,
                                                  226,
                                                  226,
                                                  226,
                                                ),
                                        ),
                                        SizedBox(width: 3),
                                        Text(loc),
                                      ],
                                    ),
                                    value: loc,
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  filterLocation = value == '' ? null : value;
                                });
                              },
                              style: TextStyle(
                                fontSize: 12,
                                color: filterLocation == null
                                    ? const Color.fromARGB(221, 3, 3, 3)
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 7),
                      SizedBox(
                        width: 125,
                        child: Container(
                          height: buttonHeight,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: filterCategory == null
                                  ? const Color.fromARGB(255, 0, 0, 0)
                                  : const Color.fromARGB(255, 248, 248, 248),
                              width: 1.0,
                            ),
                            color: filterCategory == null
                                ? Colors.white
                                : Colors.black,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: filterCategory ?? '',
                              isExpanded: true,
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: filterCategory == null
                                    ? Colors.black54
                                    : Colors.white,
                              ),
                              dropdownColor: const Color.fromARGB(
                                255,
                                203,
                                166,
                                136,
                              ),
                              items: [
                                DropdownMenuItem(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.restaurant_menu,
                                        size: 17,
                                        color: filterCategory == null
                                            ? const Color.fromARGB(
                                                136,
                                                209,
                                                0,
                                                0,
                                              )
                                            : Colors.white,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'All Type',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  value: '',
                                ),
                                ...categoryOptions.map(
                                  (cat) => DropdownMenuItem(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.restaurant_menu,
                                          size: 15,
                                          color: filterCategory == null
                                              ? const Color.fromARGB(
                                                  137,
                                                  0,
                                                  0,
                                                  0,
                                                )
                                              : Colors.white,
                                        ),
                                        SizedBox(width: 4),
                                        Text(cat.replaceAll('_', ' ')),
                                      ],
                                    ),
                                    value: cat,
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  filterCategory = value == '' ? null : value;
                                });
                              },
                              style: TextStyle(
                                fontSize: 11,
                                color: filterCategory == null
                                    ? const Color.fromARGB(221, 3, 3, 3)
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Restaurant List
            _buildRestaurantListContent(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFFCEBFA3),
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            elevation: 8,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events),
                label: 'Leaderboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.memory),
                label: 'AI Assistant',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.forum),
                label: 'Threads',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantListContent() {
    if (allRestaurants.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
      );
    }

    if (filteredAndSortedRestaurants.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            'No restaurants found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final res = filteredAndSortedRestaurants[index];
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          child: Material(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            clipBehavior: Clip.antiAlias,
            elevation: 14,
            child: InkWell(
              borderRadius: BorderRadius.circular(5),
              onTap: () async {
                try {
                  final shouldRefresh = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          RestaurantDetailUserPage(restaurantId: res.id),
                    ),
                  );

                  if (shouldRefresh == true) {
                    _refreshRestaurantData();
                  }
                } catch (e) {
                  debugPrint('Navigation error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error during navigation')),
                  );
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  Stack(
                    children: [
                      // Hero Image with retryable cached network image
                      Container(
                        height: 230,
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: RetryableCachedImage(
                            imageUrl: res.photoUrl,
                            maxRetry: 3,
                          ),
                        ),
                      ),

                      // Dark overlay gradient
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.2),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Rating Badge
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 20,
                              ),
                              SizedBox(width: 6),
                              Text(
                                res.ratingOverall.toStringAsFixed(1),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Admin controls
                    ],
                  ),

                  // Content Section
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    res.name,
                                    style: TextStyle(
                                      fontSize: 22,
                                      color: Color(0xFF5D4037),
                                      fontWeight: FontWeight.w500,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_rounded,
                                        size: 16,
                                        color: Colors.red[400],
                                      ),
                                      SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${res.location}, MFU',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: const Color.fromARGB(
                                              255,
                                              100,
                                              98,
                                              98,
                                            ),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.verified_rounded,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Category Chip - Enhanced
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFF5F5F5),
                                    Color(0xFFE0E0E0),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: Color(0xFF9E9E9E),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.restaurant_menu_rounded,
                                    size: 18,
                                    color: Color(0xFF5D4037),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    res.category.replaceAll('_', ' '),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF3E2723),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Reviews Count - Enhanced
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF424242),
                                    Color(0xFF212121),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.reviews_rounded,
                                    size: 20,
                                    color: Color.fromARGB(255, 255, 254, 252),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    '${res.postedReviewsCount}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 2,
                                          offset: Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        // Rating Progress Bars
                        Column(
                          children: [
                            _buildRatingIndicator('Hygiene', res.ratingHygiene),
                            SizedBox(height: 8),
                            _buildRatingIndicator('Flavor', res.ratingFlavor),
                            SizedBox(height: 8),
                            _buildRatingIndicator('Service', res.ratingService),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }, childCount: filteredAndSortedRestaurants.length),
    );
  }

  Widget _buildRatingIndicator(String label, double rating) {
    final color = _getRatingColor(rating);
    final segments = 5;
    final segmentValue = rating / segments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            Text(
              rating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Row(
          children: List.generate(segments, (index) {
            final segmentWidth =
                (MediaQuery.of(context).size.width - 70) / segments;
            final segmentRating = (rating - index).clamp(0.0, 1.0);

            return Container(
              height: 12,
              width: segmentWidth,
              margin: EdgeInsets.only(right: index == segments - 1 ? 0 : 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(index == 0 ? 6 : 0),
                  right: Radius.circular(index == segments - 1 ? 6 : 0),
                ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: segmentWidth * segmentRating,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(index == 0 ? 6 : 0),
                      right: Radius.circular(index == segments - 1 ? 6 : 0),
                    ),
                  ),
                ),
              ),
            );
          }),
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

  void _refreshRestaurantData() {
    setState(() {
      futureRestaurants = fetchRestaurants();
      futureRestaurants.then((list) {
        setState(() {
          allRestaurants = list;
          _precacheRestaurantImages();
        });
      });
    });
  }
}

class RetryableCachedImage extends StatefulWidget {
  final String imageUrl;
  final int maxRetry;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const RetryableCachedImage({
    required this.imageUrl,
    this.maxRetry = 3,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  });

  @override
  _RetryableCachedImageState createState() => _RetryableCachedImageState();
}

class _RetryableCachedImageState extends State<RetryableCachedImage> {
  int _retryCount = 0;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ?? _buildDefaultErrorWidget();
    }

    return CachedNetworkImage(
      imageUrl: _validateImageUrl(widget.imageUrl),
      width: widget.width,
      height: widget.height,
      fit: widget.fit ?? BoxFit.cover,
      cacheManager:
          RestaurantCacheManager.instance, // ใช้ Cache Manager ที่กำหนดเอง
      placeholder: (context, url) =>
          widget.placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, url, error) {
        if (_retryCount < widget.maxRetry) {
          Future.delayed(Duration(seconds: 1), () {
            _retryCount++;
            setState(() {});
          });
          return widget.placeholder ?? _buildDefaultPlaceholder();
        } else {
          _hasError = true;
          return widget.errorWidget ?? _buildDefaultErrorWidget();
        }
      },
      fadeInDuration: Duration(milliseconds: 300),
      fadeOutDuration: Duration(milliseconds: 300),
      httpHeaders: {'Cache-Control': 'max-age=31536000'}, // 1 ปีในหน่วยวินาที
    );
  }

  String _validateImageUrl(String url) {
    if (url.isEmpty) return 'https://via.placeholder.com/400';
    if (!url.startsWith('http')) return 'https://$url';
    return url;
  }

  Widget _buildDefaultPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        color: Colors.white,
        width: widget.width,
        height: widget.height,
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      color: Colors.grey[200],
      width: widget.width,
      height: widget.height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
            if (_retryCount < widget.maxRetry)
              TextButton(
                onPressed: () {
                  setState(() {
                    _retryCount++;
                    _hasError = false;
                  });
                },
                child: Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}

class SortButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? icon;
  final double fontSize;

  const SortButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.fontSize = 3,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: icon ?? const SizedBox.shrink(),
      label: Text(label, style: TextStyle(fontSize: 11)),
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(36),
        backgroundColor: selected ? Colors.black : Colors.white,
        foregroundColor: selected ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class RestaurantCacheManager {
  static const String key = 'restaurantImagesCache';
  static const Duration cacheDuration = Duration(days: 365); // 1 ปี
  static const int maxCacheObjects = 1000; // จำกัดจำนวนไฟล์สูงสุด

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: cacheDuration,
      maxNrOfCacheObjects: maxCacheObjects,
      repo: JsonCacheInfoRepository(databaseName: key),
    ),
  );
}
