import 'package:flutter/material.dart';
import 'package:myapp/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? photoUrl;
  String? name;
  String? email;
  String? role;
  String bio = '';
  int totalLikes = 0;
  int totalReviews = 0;
  int coins = 0;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final userId = prefs.getInt('user_id');

    if (userId != null && token != null) {
      // โหลดรูป ชื่อ อีเมล และ role จาก SharedPreferences
      setState(() {
        photoUrl = prefs.getString('user_photo');
        name = prefs.getString('user_name');
        email = prefs.getString('user_email');
        role = prefs.getString('user_role');
      });

      // โหลดข้อมูลเพิ่มเติมจาก API
      final response = await http.get(
        Uri.parse(
          'https://mfu-food-guide-review.onrender.com/user/info/$userId',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          bio = data['bio'] ?? '';
          totalLikes = data['total_likes'] ?? 0;
          totalReviews = data['total_reviews'] ?? 0;
          coins = data['coins'] ?? 0;
        });
      } else {
        print('Failed to fetch user details');
      }
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // ล้าง SharedPreferences

    // Logout จาก Google SignIn
    await GoogleSignIn().signOut();

    // กลับไปหน้า Login และลบหน้า Home ออกจาก stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Confirm Logout'),
                  content: Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await logout();
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (photoUrl != null && photoUrl!.isNotEmpty)
              CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(photoUrl!),
              ),
            SizedBox(height: 16),
            Text(
              name ?? 'No Name',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              email ?? '',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 12),
            Text('Role: ${role ?? 'User'}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 12),
            Text(
              'Bio: $bio',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text('Total Likes: $totalLikes'),
            Text('Total Reviews: $totalReviews'),
            Text('Coins: $coins'),
          ],
        ),
      ),
    );
  }
}
