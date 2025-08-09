import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/Profileshop.dart';
import 'package:myapp/home.dart';
import 'package:myapp/login.dart';
import 'package:myapp/restaurantDetail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

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

  bool isEditingUsername = false;
  bool isEditingBio = false;

  late TextEditingController usernameController;
  late TextEditingController bioController;

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
        final decoded = json.decode(response.body);
        setState(() {
          userData = decoded;
          isLoading = false;
          error = '';

          usernameController = TextEditingController(
            text: userData!['username'] ?? '',
          );
          bioController = TextEditingController(text: userData!['bio'] ?? '');
          isEditingUsername = false;
          isEditingBio = false;
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

  Future<List<Map<String, dynamic>>> fetchProfilePictures(int userId) async {
    final url = Uri.parse(
      'https://mfu-food-guide-review.onrender.com/user-profile-pictures/$userId',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load pictures');
    }
  }

  Future<void> setActiveProfilePicture(int userId, int pictureId) async {
    final url = Uri.parse(
      'https://mfu-food-guide-review.onrender.com/user-profile-pictures/set-active',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userId': userId, 'pictureId': pictureId}),
    );
    if (response.statusCode == 200) {
      await fetchUserData(userId);
    }
  }

  Future<void> updateProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User ID not found')));
      return;
    }

    final url = Uri.parse(
      'https://mfu-food-guide-review.onrender.com/user-profile/update/$userId',
    );

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': usernameController.text.trim(),
        'bio': bioController.text.trim(),
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      await fetchUserData(userId);
      setState(() {
        isEditingUsername = false;
        isEditingBio = false;
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
    }
  }

  Widget buildPictureSelector(List<Map<String, dynamic>> pictures, int userId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Choose Your Profile Picture',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),

          /// ✅ ใช้ Container จำกัดความสูง แล้วให้ GridView scroll ได้
          Container(
            height: 410, // 👈 ปรับสูงสุดที่เหมาะกับหน้าจอ
            child: GridView.builder(
              itemCount: pictures.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final pic = pictures[index];
                final isActive = pic['is_active'] == 1;

                return InkWell(
                  onTap: () async {
                    Navigator.pop(context);
                    await setActiveProfilePicture(
                      userData!['User_ID'],
                      pic['Picture_ID'],
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive ? Colors.green : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            pic['picture_url'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                      if (isActive)
                        const Positioned(
                          top: 6,
                          right: 6,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 12,
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 24,
                            ),
                          ),
                        ),
                      // Positioned(
                      //   top: -5,
                      //   left: 8,
                      //   child: Container(
                      //     padding: const EdgeInsets.all(4),
                      //     decoration: BoxDecoration(
                      //       color: const Color.fromARGB(255, 212, 58, 58),
                      //       borderRadius: BorderRadius.circular(10),
                      //     ),
                      //     child: const Icon(
                      //       Icons.verified,
                      //       size: 30,
                      //       color: Colors.white,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEditableField(
    IconData icon,
    String label,
    TextEditingController controller,
    bool isEditing,
    VoidCallback onEditPressed,
    VoidCallback onCancelPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  if (isEditing) {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Save'),
                        content: const Text('Do you want to save changes?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color.fromARGB(
                                255,
                                255,
                                255,
                                255,
                              ),
                              backgroundColor: const Color.fromARGB(
                                255,
                                0,
                                0,
                                0,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                220,
                                4,
                                4,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      onEditPressed();
                    }
                  } else {
                    onEditPressed();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isEditing
                        ? Colors.green.shade100
                        : Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEditing ? Icons.check : Icons.edit,
                    size: 20,
                    color: isEditing ? Colors.green : Colors.blue,
                  ),
                ),
              ),
              if (isEditing) const SizedBox(width: 8),
              if (isEditing)
                GestureDetector(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Discard Changes?'),
                        content: const Text(
                          'Are you sure you want to cancel and discard your changes?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color.fromARGB(
                                255,
                                245,
                                248,
                                251,
                              ),
                              backgroundColor: const Color.fromARGB(
                                255,
                                0,
                                0,
                                0,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Keep Editing'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Discard',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      onCancelPressed();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 20, color: Colors.red),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            maxLength: 13,
            controller: controller,
            readOnly: !isEditing,
            // เพิ่ม inputFormatters เพื่อป้องกันการพิมพ์เว้นวรรค
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
            decoration: InputDecoration(
              filled: isEditing,
              fillColor: Colors.yellow[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
          ),
        ],
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

  @override
  void dispose() {
    usernameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 233, 232, 231),
        appBar: AppBar(
          title: const Text(
            'My Profile',
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
          backgroundColor: const Color(0xFFCEBFA3),
        ),
        body: Center(child: Text(error)),
      );
    }

    final data = userData!;
    final fullname = data['fullname'] ?? '';
    final email = data['email'] ?? '';
    final pictureUrl = data['picture_url'];
    final coins = data['coins'] ?? 0;
    final status = data['status'] ?? 'Active';
    final totalLikes = data['total_likes'] ?? 0;
    final totalReviews = data['total_reviews'] ?? 0;

    final firstName = fullname.split(' ').first;
    final lastName = fullname.split(' ').length > 1
        ? fullname.split(' ').sublist(1).join(' ')
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFFCEBFA3),
            floating: true,
            snap: true,
            centerTitle: true,
            title: const Text(
              'My Profile',
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => RestaurantListPage(reload: true),
                ),
                (route) => false,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final userId = prefs.getInt('user_id');
                      if (userId != null) {
                        final pictures = await fetchProfilePictures(userId);
                        showModalBottomSheet(
                          context: context,
                          builder: (_) =>
                              buildPictureSelector(pictures, userId),
                        );
                      }
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 70,
                          backgroundImage: pictureUrl != null
                              ? NetworkImage(pictureUrl)
                              : const AssetImage('assets/default_avatar.png')
                                    as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 20,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -5,
                          left: -20,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 212, 58, 58),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.verified,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userData?['username'] ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          220,
                          193,
                          149,
                        ),
                        foregroundColor: const Color.fromARGB(255, 94, 85, 85),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            12,
                          ), // ปรับค่าตรงนี้ให้โค้งตามต้องการ
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 0,
                        ), // ความสูงของปุ่ม
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileShopPage(),
                          ),
                        ).then((shouldRefresh) {
                          if (shouldRefresh == true) {
                            // รีโหลดข้อมูล หรือ setState
                            loadUserIdAndFetch(); // หรือฟังก์ชันที่ใช้โหลดข้อมูล user
                          }
                        });
                      },

                      child: const Text(
                        'Profile Shop',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(Icons.thumb_up, 'Likes', totalLikes),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        Icons.rate_review,
                        'Reviews',
                        totalReviews,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  buildReadonlyField(Icons.person, 'First Name', firstName),
                  buildReadonlyField(
                    Icons.person_outline,
                    'Last Name',
                    lastName,
                  ),
                  buildReadonlyField(Icons.email, 'Email', email),
                  buildReadonlyField(Icons.verified_user, 'Status', status),
                  buildEditableField(
                    Icons.account_circle,
                    'Username',
                    usernameController,
                    isEditingUsername,
                    () async {
                      if (isEditingUsername) {
                        await updateProfile();
                        setState(() {
                          isEditingUsername = false;
                        });
                      } else {
                        setState(() {
                          isEditingUsername = true;
                        });
                      }
                    },
                    () {
                      setState(() {
                        isEditingUsername = false;
                        usernameController.text = userData?['username'] ?? '';
                      });
                    },
                  ),
                  buildEditableField(
                    Icons.info_outline,
                    'Bio',
                    bioController,
                    isEditingBio,
                    () async {
                      if (isEditingBio) {
                        await updateProfile();
                        setState(() {
                          isEditingBio = false;
                        });
                      } else {
                        setState(() {
                          isEditingBio = true;
                        });
                      }
                    },
                    () {
                      setState(() {
                        isEditingBio = false;
                        bioController.text = userData?['bio'] ?? '';
                      });
                    },
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            12,
                          ), // ปรับค่าตรงนี้ให้โค้งตามต้องการ
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 0,
                        ), // ความสูงของปุ่ม
                      ),
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
                      child: const Text(
                        'Log Out',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildStatCard(IconData icon, String label, int value) {
  return Expanded(
    child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 10,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: icon == Icons.thumb_up ? Colors.red : Colors.blue,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    ),
  );
}
