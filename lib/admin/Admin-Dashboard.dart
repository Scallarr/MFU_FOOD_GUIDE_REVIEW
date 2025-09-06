import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/Profileinfo.dart';
import 'package:myapp/admin/Admin-Home.dart';
import 'package:myapp/admin/Admin-Leaderboard.dart';
import 'package:myapp/admin/Admin-Thread.dart';
import 'package:myapp/admin/Admin-profile-info.dart';
import 'dart:convert';

import 'package:myapp/home.dart';
import 'package:myapp/leaderboard.dart';
import 'package:myapp/threads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardPageAdminState();
}

class _DashboardPageAdminState extends State<DashboardAdmin> {
  List<dynamic> restaurants = [];
  bool isLoading = true;
  int _selectedIndex = 2;
  Map<String, int> foodTypeCount = {};
  Map<String, int> locationCount = {};
  Map<int, int> ratingCount = {};
  double avgRating = 0.0;
  String? profileImageUrl;
  int? userId;

  final List<String> locations = [
    'D1',
    'E1',
    'E2',
    'C5',
    'M-SQUARE',
    'LAMDUAN',
    'S2',
  ];

  @override
  void initState() {
    super.initState();
    fetchRestaurants();
    loadUserIdAndFetchProfile();
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
        Uri.parse('http://10.0.3.201:8080/user-profile/$userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          profileImageUrl = data['picture_url'];
          print(profileImageUrl);
        });
      } else {
        print('Failed to load profile picture');
      }
    } catch (e) {
      print('Error fetching profile picture: $e');
    }
  }

  Future<void> fetchRestaurants() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.3.201:8080/restaurants'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;

        Map<String, int> locCount = {};
        int totalRestaurants = data.length;
        double totalRatingSum = 0;
        Map<int, int> rateCount = {5: 0, 4: 0, 3: 0, 2: 0};

        for (var item in data) {
          final restaurant = item as Map<String, dynamic>;

          String foodType = (restaurant['category'] ?? '').toString();
          foodTypeCount[foodType] = (foodTypeCount[foodType] ?? 0) + 1;

          String loc = (restaurant['location'] ?? '').toString();
          locCount[loc] = (locCount[loc] ?? 0) + 1;

          double overall =
              double.tryParse(
                (restaurant['rating_overall_avg'] ?? '0').toString(),
              ) ??
              0.0;
          totalRatingSum += overall;

          int star = overall.round();
          if (rateCount.containsKey(star)) {
            rateCount[star] = rateCount[star]! + 1;
          }
        }

        setState(() {
          restaurants = data;
          locationCount = locCount;
          avgRating = totalRestaurants > 0
              ? totalRatingSum / totalRestaurants
              : 0.0;
          ratingCount = rateCount;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            toolbarHeight: 70,
            centerTitle: true,
            title: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black38,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final shouldRefresh = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfilePageAdmin(),
                        ),
                      );

                      if (shouldRefresh == true) {
                        fetchProfilePicture(userId!);
                      }
                    },
                    child: profileImageUrl == null
                        ? CircleAvatar(
                            backgroundColor: Colors.grey[300],
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 40,
                            ),
                            radius: 27, // ขนาดใหญ่
                          )
                        : CircleAvatar(
                            backgroundImage: NetworkImage(profileImageUrl!),
                            radius: 27, // ขนาดใหญ่
                            backgroundColor: Colors.grey[300],
                          ),
                  ),
                ],
              ),
            ),
            backgroundColor: const Color(0xFFCEBFA3),
            floating: false, // เลื่อนแล้วไม่ลอย
            pinned: false, // เลื่อนแล้วหายไป
            snap: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Summary Cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSummaryCard(
                      'Total Restaurants',
                      restaurants.length.toString(),
                      icon: Icons.restaurant_menu,
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                    _buildSummaryCard(
                      'Average Rating',
                      avgRating.toStringAsFixed(1),
                      icon: Icons.star_rate_rounded,
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // By Location
                _buildSectionTitle('Restaurants by Location'),
                const SizedBox(height: 10),
                _buildProgressCard(
                  locationCount,
                  Colors.redAccent,
                  Colors.red.shade100,
                ),

                const SizedBox(height: 30),

                // By Rating
                _buildSectionTitle('Restaurants by Rating'),
                const SizedBox(height: 10),
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [5, 4, 3, 2].map((star) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: _buildRatingCountRow(
                            star,
                            ratingCount[star] ?? 0,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // By Food Type
                _buildSectionTitle('Restaurants by Food Type'),
                const SizedBox(height: 10),
                _buildProgressCard(
                  foodTypeCount,
                  Colors.orange.shade300,
                  Colors.orange.shade100,
                ),
              ]),
            ),
          ),
        ],
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   currentIndex: _selectedIndex,
      //   onTap: _onItemTapped,
      //   type: BottomNavigationBarType.fixed,
      //   selectedItemColor: const Color.fromARGB(255, 175, 128, 52),
      //   unselectedItemColor: Colors.grey,
      //   items: [
      //     BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.emoji_events),
      //       label: 'Leaderboard',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.dashboard),
      //       label: 'Dashboard',
      //     ),
      //     BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Threads'),
      //   ],
      // ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value, {
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 10,
      shadowColor: color.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 38, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildProgressCard(Map<String, int> data, Color color, Color bgColor) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: data.entries.map((entry) {
            int count = entry.value;
            double progress = restaurants.isNotEmpty
                ? count / restaurants.length
                : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0, 1),
                        color: color,
                        backgroundColor: bgColor,
                        minHeight: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    count.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRatingCountRow(int star, int count) {
    double progress = restaurants.isNotEmpty ? count / restaurants.length : 0.0;

    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            star,
            (index) => const Icon(
              Icons.star,
              size: 20,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            5 - star,
            (index) => const Icon(
              Icons.star_border,
              size: 20,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 14,
              color: Colors.brown.shade400,
              backgroundColor: Colors.brown.shade100,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          count.toString(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RestaurantListPageAdmin()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LeaderboardPageAdmin()),
        );
        break;
      case 2:
        // Already dashboard
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ThreadsAdminPage()),
        );
        break;
    }
  }
}
