import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/Profileinfo.dart';
import 'package:myapp/admin/Admin-Dashboard.dart';
import 'package:myapp/admin/Admin-Home.dart';
import 'package:myapp/admin/Admin-Thread.dart';
import 'package:myapp/admin/Admin-profile-info.dart';
import 'package:myapp/chatbot.dart';
import 'package:myapp/dashboard.dart';
import 'dart:convert';
import 'package:myapp/home.dart';
import 'package:myapp/threads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardPageAdmin extends StatefulWidget {
  const LeaderboardPageAdmin({super.key});

  @override
  State<LeaderboardPageAdmin> createState() => _LeaderboardPageAdminState();
}

class _LeaderboardPageAdminState extends State<LeaderboardPageAdmin> {
  List<dynamic> topUsers = [];
  List<dynamic> topRestaurants = [];
  int _selectedIndex = 1;
  String monthYear = '';
  int? userId;
  String? profileImageUrl;

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
        // Already on leaderboard
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatbotScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ThreadsAdminPage()),
        );
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchLeaderboard();

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
        Uri.parse(
          'https://mfu-food-guide-review.onrender.com/user-profile/$userId',
        ),
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
      color: const Color.fromARGB(255, 255, 255, 255),
      elevation: 9,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
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
                Positioned(
                  top: -5,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 212, 58, 58),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.verified,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            // Username และ Stats พร้อมไอคอนกดแสดง SnackBar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.check_circle,
                        color: Colors.blue,
                        size: 22,
                      ),
                    ],
                  ),
                  Text(
                    obfuscateEmail(user['email'] ?? ''),
                    style: TextStyle(fontSize: 10.3),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: EdgeInsetsGeometry.only(top: 2),
                    child: Row(
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
                          child: Padding(
                            padding: EdgeInsets.only(top: 7),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.thumb_up,
                                  size: 21,
                                  color: Colors.brown,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${user['total_likes']}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.brown.shade700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
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
                          child: Padding(
                            padding: EdgeInsets.only(top: 7),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.rate_review,
                                  size: 25,
                                  color: Colors.brown,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${user['total_reviews']}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.brown.shade700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Rank number
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 83, 82, 77),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.shade300.withOpacity(0.9),
                    offset: const Offset(2, 5),
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
      color: const Color.fromARGB(255, 250, 250, 250),
      elevation: 9,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Rank number (ย้ายมาอยู่ซ้าย)
                Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.only(left: 16, right: 14),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 83, 82, 77),
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
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              final snackBar = SnackBar(
                                content: Text(
                                  'Overall Rating of This Restaurant',
                                ),
                                duration: const Duration(seconds: 2),
                              );
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(snackBar);
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
                                  '${double.parse(restaurant['overall_rating'].toString()).toStringAsFixed(1)}',
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: Colors.brown.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          GestureDetector(
                            onTap: () {
                              final snackBar = SnackBar(
                                content: Text(
                                  'Total Reviews of This Restaurant on This Month ',
                                ),
                                duration: const Duration(seconds: 2),
                              );
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(snackBar);
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Icons.rate_review,
                                  size: 23,
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
            Positioned(
              top: -10,
              left: 357,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 3, 129, 232),
                  borderRadius: BorderRadius.circular(6),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
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
              toolbarHeight: 70,
              backgroundColor: const Color(0xFFCEBFA3),
              pinned: false,
              floating: true,
              snap: true,
              elevation: 4,
              title: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ), // ปรับตามต้องการ
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Leaderboard',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePageAdmin(),
                          ),
                        );
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
            ),

            SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '🏆 Monthly Like Leaders ',
                        style: TextStyle(
                          fontSize: 18,
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
                            color: Color.fromARGB(255, 80, 77, 77),
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
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 32,
                            color: Colors.brown.shade700,
                          ),

                          Text(
                            ' Best Restaurants ',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (monthYear.isNotEmpty)
                        Text(
                          '($monthYear)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Color.fromARGB(255, 80, 77, 77),
                          ),
                        ),
                    ],
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
    final domain = '@gmail.com';
    return '**********$domain';
  }

  return email; // กรณีอื่น ๆ
}
