import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/Profileinfo.dart';
import 'package:myapp/admin/Admin-Dashboard.dart';
import 'package:myapp/admin/Admin-Home.dart';
import 'package:myapp/admin/Admin-Thread.dart';
import 'package:myapp/admin/Admin-profile-info.dart';
import 'package:myapp/Atlas-model.dart';
import 'package:myapp/admin/Admin_atlas-model.dart';
import 'package:myapp/admin/Admin_nexus-model.dart';
import 'package:myapp/dashboard.dart';
import 'dart:convert';
import 'package:myapp/home.dart';
import 'package:myapp/login.dart';
import 'package:myapp/threads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  Map<String, dynamic>? _selectedUser;
  bool _hasCheckedReward = false;

  // ตัวเลือกเดือน
  final List<String> _months = [
    'January',
    'Febuary',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    fetchLeaderboard();
    loadUserIdAndFetchProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRewardAfterBuild();
    });
  }

  void _checkRewardAfterBuild() async {
    // Small delay to ensure UI is built
    await Future.delayed(Duration(milliseconds: 500));
    if (!_hasCheckedReward) {
      await checkPreviousMonthReward(context);
      _hasCheckedReward = true;
    }
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
        Uri.parse('http://172.22.173.39:8080/user-profile/$userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          profileImageUrl = data['picture_url'];
        });
      } else {
        print('Failed to load profile picture');
      }
    } catch (e) {
      print('Error fetching profile picture: $e');
    }
  }

  // Update the checkPreviousMonthReward method
  Future<void> checkPreviousMonthReward(BuildContext context) async {
    if (_hasCheckedReward) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final currentMonthKey = 'reward_shown_${now.year}-${now.month}';
    // final rewardShown = prefs.getBool(currentMonthKey) ?? false;

    // if (rewardShown) {
    //   print('Already shown reward for current month');
    //   return;
    // }

    final token = prefs.getString('jwt_token');
    if (token == null) return;

    try {
      final response = await http.put(
        Uri.parse('http://172.22.173.39:8080/leaderboard/coins/previous-month'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['hasData'] == true) {
          _showMonthlyRewardAlert(
            context,
            data['month_name'],
            data['month_year'],
            data['rank'],
            data['coins_awarded'],
            data['total_likes'],
            data['total_reviews'],
            // data['totalreviews'],
            // data['totallikes'],
            // data['username'],
            // data['email'],
            // data['profile_image'],
            // data['role'],
            // data['status'],
            // data[''],
          );
          await prefs.setBool(currentMonthKey, true);
        } else if (data['message'] != null) {
          _showAlert2(context, data['message']);
          await prefs.setBool(currentMonthKey, true);
        }
      }
    } catch (e) {
      print('Error checking previous month reward: $e');
    }
  }

  // Add error handling to fetchLeaderboard
  Future<void> fetchLeaderboard({String? customMonthYear}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        _showAlert(context, 'Session expired');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      String url = 'http://172.22.173.39:8080/leaderboard/update';
      if (customMonthYear != null) {
        url += '?month_year=$customMonthYear';
      }

      final response = await http
          .get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'})
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          topUsers = data['topUsers'] ?? [];
          topRestaurants = data['topRestaurants'] ?? [];
          monthYear = data['month_year'] ?? '';

          _isLoading = false;
        });
      } else {
        _handleErrorResponse(response);
      }
    } catch (e) {
      print('Error fetching leaderboard: $e');
      setState(() {
        _isLoading = false;
      });
      _showAlert(context, 'Network error: ${e.toString()}');
    }
  }

  void _handleErrorResponse(http.Response response) {
    switch (response.statusCode) {
      case 401:
        _showAlert(context, 'Session expired');
        break;
      case 403:
        _showAlert(context, 'Your account has been banned.');
        break;
      default:
        _showAlert(
          context,
          'Failed to load leaderboard: ${response.statusCode}',
        );
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _showMonthlyRewardAlert(
    BuildContext context,
    String previousMonthName,
    int month_year,
    int rank,
    int coinsAwarded,
    int totalLikes,
    int totalReviews,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Colors.red, Color.fromARGB(255, 244, 244, 243)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trophy Icon
              Icon(
                Icons.emoji_events,
                size: 70,
                color: Colors.deepOrange.shade700,
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                '🏆 Monthly Ranking Result – $previousMonthName',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade900,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),
              _buildRewardItem(
                'year',
                '$month_year',
                Icons.calendar_month,
                const Color.fromARGB(255, 0, 0, 0),
              ),
              const SizedBox(height: 14),
              // Ranking Info
              _buildRewardItem(
                'month',
                '$previousMonthName',
                Icons.calendar_month,
                const Color.fromARGB(255, 0, 0, 0),
              ),

              const SizedBox(height: 14),
              // Ranking Info
              _buildRewardItem(
                'Rank',
                '$rank',
                Icons.leaderboard,
                Colors.blueAccent,
              ),

              const SizedBox(height: 14),

              // Coins Awarded
              _buildRewardItem(
                'Coins Earned',
                '$coinsAwarded',
                Icons.monetization_on,
                Colors.amber.shade700,
              ),

              const SizedBox(height: 14),

              // Total Likes
              _buildRewardItem(
                'Total Likes',
                '$totalLikes',
                Icons.thumb_up,
                Colors.pinkAccent,
              ),

              const SizedBox(height: 14),

              // Total Reviews
              _buildRewardItem(
                'Total Reviews',
                '$totalReviews',
                Icons.rate_review,
                Colors.green,
              ),

              const SizedBox(height: 28),

              // OK Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(
                      255,
                      245,
                      11,
                      11,
                    ).withOpacity(0.7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 3,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Got it!',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardItem(
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.brown.shade800,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _showAlert2(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('รางวัล!'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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

  // ฟังก์ชันเลือกเดือน/ปี
  Future<void> _selectMonthYear(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });

      // แปลงวันที่เป็นรูปแบบ YYYY-MM
      final selectedMonthYear = DateFormat('yyyy-MM').format(picked);
      await fetchLeaderboard(customMonthYear: selectedMonthYear);
    }
  }

  // ฟังก์ชันเลือกเดือนจาก dropdown
  void _selectMonthFromDropdown(String? month) {
    if (month != null) {
      final monthIndex = _months.indexOf(month) + 1;
      final monthString = monthIndex.toString().padLeft(2, '0');
      final selectedMonthYear = '${_selectedDate.year}-$monthString';
      fetchLeaderboard(customMonthYear: selectedMonthYear);
    }
  }

  // ฟังก์ชันเลือกปีจาก dropdown
  void _selectYearFromDropdown(String? year) {
    if (year != null) {
      final selectedYear = int.parse(year);
      setState(() {
        _selectedDate = DateTime(selectedYear, _selectedDate.month);
      });
      final monthString = _selectedDate.month.toString().padLeft(2, '0');
      final selectedMonthYear = '$year-$monthString';
      fetchLeaderboard(customMonthYear: selectedMonthYear);
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
                GestureDetector(
                  onTap: () {
                    print(user);
                    setState(() {
                      if (_selectedUser != null &&
                          _selectedUser!['User_ID'] == user['User_ID']) {
                        _selectedUser = null;
                      } else {
                        _selectedUser = {
                          ...user, // เอาข้อมูล user เดิมมาใส่ก่อน
                          'coins': user['coins'] ?? 0,
                          'formattedCoins': NumberFormat(
                            '#,###',
                          ).format(int.tryParse(user['coins'].toString()) ?? 0),
                        };
                      }
                    });
                  },
                  child: Container(
                    width: 90,
                    height: 90,
                    margin: const EdgeInsets.only(left: 16, right: 18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.brown.shade700,
                        width: 2,
                      ),
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
                          (restaurant['photos'] != null &&
                              restaurant['photos'].isNotEmpty)
                          ? NetworkImage(restaurant['photos'])
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
      body: _selectedUser != null
          ? Container(
              color: Color.fromARGB(
                255,
                116,
                115,
                113,
              ).withOpacity(1), // ความเข้มของดำ
              child: Center(
                child: Text(
                  "",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 127, 45, 45),
                    fontSize: 18,
                  ),
                ),
              ),
            )
          : Column(
              children: [
                // Header with date selector
                _buildHeader(context),

                // Content
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () => fetchLeaderboard(),
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverList(
                                delegate: SliverChildListDelegate([
                                  const SizedBox(height: 20),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          '🏆 Monthly Like Leaders ',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (monthYear.isNotEmpty)
                                          Text(
                                            '($monthYear)',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontStyle: FontStyle.italic,
                                              color: Color.fromARGB(
                                                255,
                                                80,
                                                77,
                                                77,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...topUsers.asMap().entries.map(
                                    (entry) =>
                                        buildUserCard(entry.value, entry.key),
                                  ),
                                  const Divider(thickness: 2, height: 32),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                              color: Color.fromARGB(
                                                255,
                                                80,
                                                77,
                                                77,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...topRestaurants.asMap().entries.map(
                                    (entry) => buildRestaurantCard(
                                      entry.value,
                                      entry.key,
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                ]),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
      bottomSheet: _selectedUser != null
          ? GestureDetector(
              // onVerticalDragUpdate: (details) {
              //   // ถ้าเลื่อนลงมากกว่า 50 pixels ให้ปิด
              //   if (details.delta.dy > 10) {
              //     setState(() {
              //       _selectedUser = null;
              //     });
              //   }
              // },
              onTap: () {
                // ถ้าคลิกนอกเนื้อหาให้ปิด
                // setState(() {
                //   _selectedUser = null;
                // });
              },
              child: Container(
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
                            child: buildUserBanner(
                              _selectedUser?['profile_image'],
                            ),
                          ),

                          // Avatar (วางซ้อนลงบน Banner)
                          Positioned(
                            bottom: 0, // ทำให้ Avatar ยื่นออกมาจาก Banner
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
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
                                    (_selectedUser!['profile_image'] != null &&
                                        _selectedUser!['profile_image']
                                            .isNotEmpty)
                                    ? NetworkImage(
                                        _selectedUser!['profile_image'],
                                      )
                                    : null,
                                child:
                                    (_selectedUser!['profile_image'] == null ||
                                        _selectedUser!['profile_image'].isEmpty)
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
                                  color: const Color.fromARGB(
                                    255,
                                    237,
                                    235,
                                    235,
                                  ),
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
                            (_selectedUser!['User_ID'] == userId)
                                ? Text(
                                    (_selectedUser!['email']),
                                    style: TextStyle(
                                      fontSize: 15, // เพิ่มขนาดฟอนต์เล็กน้อย
                                      color: const Color.fromARGB(
                                        255,
                                        222,
                                        220,
                                        220,
                                      ),
                                      fontWeight:
                                          FontWeight.w500, // ตัวหนาปานกลาง
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                : Text(
                                    obfuscateEmail(_selectedUser!['email']),
                                    style: TextStyle(
                                      fontSize: 15, // เพิ่มขนาดฟอนต์เล็กน้อย
                                      color: const Color.fromARGB(
                                        255,
                                        222,
                                        220,
                                        220,
                                      ),
                                      fontWeight:
                                          FontWeight.w500, // ตัวหนาปานกลาง
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
                                  "${_selectedUser!['formattedCoins']}",
                                  color: Colors.orange,
                                ),
                                if (_selectedUser!['totallikes'] != null)
                                  _buildInfoChip(
                                    Icons.favorite_outline,
                                    "Likes",
                                    "${_selectedUser!['totallikes']}",
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
                                  border: Border.all(
                                    color: Colors.orange[200]!,
                                  ),
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
              ),
            )
          : null,
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
      height: 400,
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFCEBFA3),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Leaderboard',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: Colors.white,
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
                        builder: (context) => ProfilePageAdmin(),
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
            const SizedBox(height: 16),
            // Date selector
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _months[_selectedDate.month - 1],
                    items: _months.map((String month) {
                      return DropdownMenuItem<String>(
                        value: month,
                        child: Text(month),
                      );
                    }).toList(),
                    onChanged: _selectMonthFromDropdown,
                    decoration: InputDecoration(
                      labelText: 'Select Month',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDate.year.toString(),
                    items: List.generate(5, (index) {
                      final year = DateTime.now().year - index;
                      return DropdownMenuItem<String>(
                        value: year.toString(),
                        child: Text(year.toString()),
                      );
                    }).toList(),
                    onChanged: _selectYearFromDropdown,
                    decoration: InputDecoration(
                      labelText: 'Select Year',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _selectMonthYear(context),
                  icon: Icon(Icons.calendar_today, color: Colors.white),
                  tooltip: 'เลือกวันที่',
                ),
              ],
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
