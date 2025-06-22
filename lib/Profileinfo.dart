import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/home.dart';
import 'package:myapp/login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Map<String, dynamic>? userData;
  bool isLoading = true;
  String error = '';

  // Editing flags
  bool isEditingUsername = false;
  bool isEditingBio = false;

  // Controllers
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

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
        error = 'User ID not found';
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
        final data = json.decode(response.body);
        setState(() {
          userData = data;
          usernameController.text = data['username'] ?? '';
          bioController.text = data['bio'] ?? '';
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

  Future<void> updateUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;

    final url = Uri.parse(
      'https://mfu-food-guide-review.onrender.com/user-profile/update/$userId',
    );

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': usernameController.text,
        'bio': bioController.text,
      }),
    );

    if (response.statusCode == 200) {
      await fetchUserData(userId);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const RestaurantListPage(reload: true),
            ),
            (route) => false,
          ),
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
    final fullname = data['fullname'] ?? '';
    final email = data['email'] ?? '';
    final status = data['status'] ?? '';
    final coins = data['coins'] ?? 0;
    final totalLikes = data['total_likes'] ?? 0;
    final totalReviews = data['total_reviews'] ?? 0;
    final pictureUrl = data['picture_url'];

    final firstName = fullname.split(' ').first;
    final lastName = fullname.split(' ').length > 1
        ? fullname.split(' ').sublist(1).join(' ')
        : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 70,
            backgroundImage: pictureUrl != null
                ? NetworkImage(pictureUrl)
                : const AssetImage('assets/default_avatar.png')
                      as ImageProvider,
          ),
          const SizedBox(height: 12),
          Text(
            fullname,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, color: Colors.orange),
              const SizedBox(width: 4),
              Text('$coins coins'),
            ],
          ),
          const SizedBox(height: 16),

          // 🔥 Card summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildStatCard(Icons.thumb_up, 'Likes', totalLikes, Colors.red),
              const SizedBox(width: 12),
              buildStatCard(
                Icons.rate_review,
                'Reviews',
                totalReviews,
                Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 24),

          buildReadonlyField(Icons.person, 'First Name', firstName),
          buildReadonlyField(Icons.person_outline, 'Last Name', lastName),
          buildReadonlyField(Icons.email, 'Email', email),
          buildReadonlyField(Icons.verified_user, 'Status', status),

          buildEditableField(
            icon: Icons.account_circle,
            label: 'Username',
            controller: usernameController,
            isEditing: isEditingUsername,
            onEdit: () {
              setState(() {
                if (isEditingUsername) updateUserData();
                isEditingUsername = !isEditingUsername;
              });
            },
          ),
          buildEditableField(
            icon: Icons.info_outline,
            label: 'Bio',
            controller: bioController,
            isEditing: isEditingBio,
            onEdit: () {
              setState(() {
                if (isEditingBio) updateUserData();
                isEditingBio = !isEditingBio;
              });
            },
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // TODO: Go to profile shop
            },
            child: const Text('Profile Shop'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () async {
              await _googleSignIn.signOut();
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget buildStatCard(IconData icon, String label, int value, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildReadonlyField(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
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
        ],
      ),
    );
  }

  Widget buildEditableField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: Icon(
                  isEditing ? Icons.check : Icons.edit,
                  color: isEditing ? Colors.green : Colors.blue,
                ),
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            readOnly: !isEditing,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
