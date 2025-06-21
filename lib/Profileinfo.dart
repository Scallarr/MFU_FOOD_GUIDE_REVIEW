import 'dart:convert';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String error = '';
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    loadUserIdAndFetch();
  }

  Future<void> loadUserIdAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      setState(() {
        error = 'User ID not found in SharedPreferences';
        isLoading = false;
      });
      return;
    }

    await fetchUserData(userId);
  }

  Future<void> fetchUserData(int userId) async {
    try {
      final url = Uri.parse(
        'https://mfu-food-guide-review.onrender.com/user-profile/$userId',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          userData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load user info';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(child: Text(error))
          : buildProfile(),
    );
  }

  Widget buildProfile() {
    final data = userData!;
    final pictureUrl = data['picture_url'];
    final fullname = data['fullname'] ?? '';
    final username = data['username'] ?? '';
    final email = data['email'] ?? '';
    final bio = data['bio'] ?? '';
    final coins = data['coins'] ?? 0;
    final status = data['status'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: pictureUrl != null
                ? NetworkImage(pictureUrl)
                : const AssetImage('assets/default_avatar.png')
                      as ImageProvider,
          ),
          const SizedBox(height: 10),
          Text(
            fullname,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, color: Colors.orange),
              const SizedBox(width: 4),
              Text('$coins coins'),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              // TODO: ไปหน้า Profile Shop
            },
            child: const Text('Profile Shop'),
          ),
          const SizedBox(height: 20),
          buildProfileField(
            Icons.person,
            'First Name',
            fullname.split(' ').first,
          ),
          buildProfileField(
            Icons.person_outline,
            'Last Name',
            fullname.split(' ').last,
          ),
          buildProfileField(Icons.account_circle, 'Username', username),
          buildProfileField(Icons.email, 'Email', email),
          buildProfileField(Icons.verified_user, 'Status', status),
          buildProfileField(Icons.info, 'Bio', bio),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () async {
              await _googleSignIn.signOut();
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // ล้างข้อมูล
              // TODO: กลับไปหน้า login
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false, // ลบหน้าเก่าออกหมด
              );
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget buildProfileField(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: TextEditingController(text: value),
          readOnly: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
