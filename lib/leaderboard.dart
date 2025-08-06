import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/Dashboard.dart';
import 'dart:convert';
import 'package:myapp/home.dart';
import 'package:myapp/threads.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<dynamic> topUsers = [];
  List<dynamic> topRestaurants = [];
  int _selectedIndex = 1;
  String monthYear = '';

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RestaurantListPage()),
        );
        break;
      case 1:
        // Already on leaderboard
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ThreadsPage()),
        );
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchLeaderboard();
  }

  Future<void> fetchLeaderboard() async {
    try {
      final response = await http.get(
        Uri.parse('https://mfu-food-guide-review.onrender.com/leaderboard'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          topUsers = data['topUsers'] ?? [];
          topRestaurants = data['topRestaurants'] ?? [];
          monthYear = data['month_year'] ?? 'f';
        });
      } else {
        print('Failed to load leaderboard');
      }
    } catch (e) {
      print('Error fetching leaderboard: $e');
    }
  }

  Widget buildUserCard(Map<String, dynamic> user, int rank) {
    return Card(
      color: const Color.fromARGB(255, 208, 186, 153), // สีพื้นหลังธีมนี้
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar ขนาดใหญ่เต็มกรอบซ้ายสุด
            Container(
              width: 90,
              height: 90,
              margin: const EdgeInsets.only(left: 16, right: 18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.brown.shade700, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.shade400.withOpacity(0.3),
                    offset: const Offset(0, 3),
                    blurRadius: 5,
                  ),
                ],
                image: DecorationImage(
                  image:
                      user['profile_image'] != null &&
                          user['profile_image'].isNotEmpty
                      ? NetworkImage(user['profile_image'])
                      : const AssetImage('assets/default_user.png')
                            as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Username และ Stats พร้อมไอคอนกดแสดง SnackBar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['username'] ?? '',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.brown.shade900,
                      shadows: [
                        Shadow(
                          color: Colors.brown.shade200,
                          offset: const Offset(0, 0),
                          blurRadius: 1,
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Number of likes the user received in this month',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.thumb_up,
                              size: 20,
                              color: Colors.brown,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${user['total_likes']}',
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.brown.shade700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Number of Reviews that User write in this month',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.rate_review,
                              size: 23,
                              color: Colors.brown,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${user['total_reviews']}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.brown.shade700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Rank number
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.amber.shade200,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.shade300.withOpacity(0.4),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '${rank + 1}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.brown.shade300,
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget buildRestaurantCard(Map<String, dynamic> restaurant, int rank) {
    return Card(
      color: const Color.fromARGB(255, 203, 189, 168),
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Rank number (ย้ายมาอยู่ซ้าย)
            Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(left: 16, right: 14),
              decoration: BoxDecoration(
                color: Colors.amber.shade200,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.shade300.withOpacity(0.4),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '${rank + 1}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 255, 255, 255),
                  shadows: [
                    Shadow(
                      color: Colors.brown.shade300,
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),

            // ชื่อร้าน และคะแนน
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant['restaurant_name'] ?? '',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.brown.shade900,
                      shadows: [
                        Shadow(
                          color: Colors.brown.shade200,
                          offset: const Offset(0, 0),
                          blurRadius: 1,
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          final snackBar = SnackBar(
                            content: Text('Overall Rating of This Restaurant'),
                            duration: const Duration(seconds: 2),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 20,
                              color: Colors.brown.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${restaurant['overall_rating']}',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.brown.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      GestureDetector(
                        onTap: () {
                          final snackBar = SnackBar(
                            content: Text(
                              'Total Reviews of This Restaurant on This Month ',
                            ),
                            duration: const Duration(seconds: 2),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.rate_review,
                              size: 22,
                              color: Colors.brown.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${restaurant['total_reviews']}',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.brown.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 5),

            // รูปภาพร้าน (ย้ายมาขวาถัดจาก rank)
            Container(
              width: 90,
              height: 90,
              margin: const EdgeInsets.only(right: 18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.brown.shade700, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.shade400.withOpacity(0.3),
                    offset: const Offset(0, 3),
                    blurRadius: 5,
                  ),
                ],
                image: DecorationImage(
                  image:
                      (restaurant['restaurant_image'] != null &&
                          restaurant['restaurant_image'].isNotEmpty)
                      ? NetworkImage(restaurant['restaurant_image'])
                      : const AssetImage('assets/default_restaurant.png')
                            as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 175, 128, 52),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Leaderboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Threads'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchLeaderboard,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: const Color.fromARGB(255, 221, 187, 136),
              pinned: false,
              floating: true,
              snap: true,
              elevation: 4,
              title: const Text('Leaderboard'),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text(
                        '🏆 Top Users',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (monthYear.isNotEmpty)
                        Text(
                          '($monthYear)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...topUsers.asMap().entries.map(
                  (entry) => buildUserCard(entry.value, entry.key),
                ),
                const Divider(thickness: 2, height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '🍽️ Top Restaurants',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                ...topRestaurants.asMap().entries.map(
                  (entry) => buildRestaurantCard(entry.value, entry.key),
                ),
                const SizedBox(height: 30),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
