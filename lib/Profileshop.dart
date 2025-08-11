import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/admin/Admin-Addprofile.dart';
import 'package:myapp/admin/Admin-Editprofile-picture.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfileShopUserPage extends StatefulWidget {
  const ProfileShopUserPage({Key? key}) : super(key: key);

  @override
  State<ProfileShopUserPage> createState() => _ProfileShopAdminPageState();
}

class _ProfileShopAdminPageState extends State<ProfileShopUserPage> {
  List<Map<String, dynamic>> profiles = [];
  bool isLoading = true;
  String errorMsg = "";
  int currentCoins = 1250;
  int? userId;

  @override
  void initState() {
    super.initState();
    loadUserAndFetchProfiles();
  }

  Future<void> loadUserAndFetchProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    print(profiles); // debug ก่อนว่ามีค่าอะไร
    if (userId == 0) {
      setState(() {
        errorMsg = "User ID not found.";
        isLoading = false;
      });
      return;
    }
    await fetchProfiles();
  }

  // ในส่วนของ fetchProfiles() ให้ปรับการเรียงลำดับข้อมูล
  Future<void> fetchProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    print(userId);
    final url = Uri.parse(
      'https://mfu-food-guide-review.onrender.com/profile-exchange/$userId',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isNotEmpty) {
          int userCoinsFromApi = data[0]['user_coins'] ?? 0;

          // เรียงลำดับโดยให้โปรไฟล์ที่ยังไม่ซื้อแสดงก่อน
          data.sort((a, b) {
            if (a['is_purchased'] == 0 && b['is_purchased'] == 1) {
              return -1; // a มาก่อน b
            } else if (a['is_purchased'] == 1 && b['is_purchased'] == 0) {
              return 1; // b มาก่อน a
            }
            return 0; // ไม่มีการเปลี่ยนแปลงลำดับ
          });

          setState(() {
            currentCoins = userCoinsFromApi;
            profiles = data
                .map(
                  (item) => {
                    "id": item['Profile_Shop_ID'],
                    "name": item['Profile_Name'],
                    "description": item['Description'],
                    "coins": item['Required_Coins'],
                    "image": item['Image_URL'],
                    "is_purchased": item['is_purchased'],
                  },
                )
                .toList();
            isLoading = false;
          });
        } else {
          setState(() {
            errorMsg = "No profiles found.";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMsg = "Server error: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMsg = "Failed to fetch data: $e";
        isLoading = false;
      });
    }
  }

  // เมธอดแก้ไขโปรไฟล์
  Future<void> editProfile(Map<String, dynamic> profile) async {
    // final result = await Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => AddProfilePage(
    //       profileToEdit: profile,
    //     ),
    //   ),
    // );

    // if (result == true) {
    //   await fetchProfiles();
    // }
  }

  // เมธอดลบโปรไฟล์
  Future<void> deleteProfile(int profileId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Delete"),
        content: Text("Are you sure you want to delete this profile?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final url = Uri.parse(
      'https://mfu-food-guide-review.onrender.com/delete_profile/$profileId',
    );

    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Profile deleted successfully")));
        await fetchProfiles();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to delete profile")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting profile: $e")));
    }
  }

  Future<void> buyProfile(int profileId, int cost, String imageurl) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (currentCoins < cost) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Insufficient coins.")));
      return;
    }

    final url = Uri.parse(
      'https://mfu-food-guide-review.onrender.com/purchase_profile',
    ); // เปลี่ยน URL

    final body = jsonEncode({
      'user_id': userId,
      'profile_id': profileId,
      'coins_spent': cost,
      'image_url': imageurl,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        await fetchProfiles();
        // อัพเดต UI หลังซื้อสำเร็จ

        // setState(() {
        //   currentCoins -= cost;
        //   // อัพเดตสถานะ is_purchased ของโปรไฟล์ที่ซื้อ
        //   final index = profiles.indexWhere((p) => p['id'] == profileId);
        //   if (index != -1) {
        //     profiles[index]['is_purchased'] = true;
        //   }
        // });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Purchase successful!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Purchase failed: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Purchase error: $e")));
    }
  }

  Widget buildProfileCard(Map<String, dynamic> profile) {
    bool isPurchased = profile['is_purchased'] == 1;
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ส่วนแสดงข้อมูลโปรไฟล์
                Text(
                  profile['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                CircleAvatar(
                  radius: 70,
                  backgroundImage: NetworkImage(profile['image'] ?? ''),
                  backgroundColor: Colors.grey[200],
                ),
                const SizedBox(height: 12),
                Text(
                  "${profile['coins'] ?? 0} Coins",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      isPurchased ? Icons.check_circle : Icons.shopping_cart,
                      size: 20,
                    ),
                    label: Text(
                      isPurchased ? "Purchased" : "Buy",
                      style: TextStyle(fontSize: 14),
                    ),
                    onPressed: isPurchased
                        ? null
                        : () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  backgroundColor: Colors.white,
                                  title: Row(
                                    children: [
                                      Icon(
                                        Icons.shopping_cart,
                                        color: Colors.orange,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        "Confirm Purchase",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.warning,
                                        size: 90,
                                        color: const Color.fromARGB(
                                          255,
                                          0,
                                          0,
                                          0,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        "Do you want to buy this profile for ${profile['coins']} coins?",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  actionsAlignment:
                                      MainAxisAlignment.spaceAround,
                                  actionsPadding: EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 18,
                                  ),
                                  actions: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.of(
                                          context,
                                        ).pop(); // ปิด dialog
                                      },
                                      icon: Icon(Icons.close),
                                      label: Text("Cancel"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(
                                          255,
                                          78,
                                          104,
                                          206,
                                        ),
                                        foregroundColor: const Color.fromARGB(
                                          255,
                                          255,
                                          255,
                                          255,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.of(
                                          context,
                                        ).pop(); // ปิด dialog
                                        buyProfile(
                                          profile['id'],
                                          profile['coins'],
                                          profile['image'],
                                        );
                                      },
                                      icon: Icon(Icons.check_circle),
                                      label: Text("Confirm"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(
                                          255,
                                          217,
                                          76,
                                          76,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: isPurchased
                          ? Colors.grey
                          : const Color.fromARGB(255, 229, 76, 29),
                      foregroundColor: isPurchased
                          ? Colors.grey
                          : const Color.fromARGB(255, 249, 249, 249),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // เปลี่ยนจาก IconButton เป็น PopupMenuButton
          // ในเมธอด buildProfileCard
          // Positioned(
          //   top: 8,
          //   right: 8,
          //   child: PopupMenuButton<String>(
          //     icon: Icon(Icons.more_vert, color: Colors.grey[700]),
          //     onSelected: (value) {
          //       if (value == 'edit') {
          //         Navigator.push(
          //           context,
          //           MaterialPageRoute(
          //             builder: (context) => EditProfilePage(profile: profile),
          //           ),
          //         ).then((shouldRefresh) {
          //           if (shouldRefresh == true) {
          //             fetchProfiles();
          //           }
          //         });
          //       } else if (value == 'delete') {
          //         _showDeleteConfirmation(profile['id']);
          //       }
          //     },
          //     itemBuilder: (BuildContext context) => [
          //       PopupMenuItem<String>(
          //         value: 'edit',
          //         child: Row(
          //           children: [
          //             Icon(Icons.edit, color: Colors.blue),
          //             SizedBox(width: 8),
          //             Text('Edit Profile'),
          //           ],
          //         ),
          //       ),
          //       PopupMenuItem<String>(
          //         value: 'delete',
          //         child: Row(
          //           children: [
          //             Icon(Icons.delete, color: Colors.red),
          //             SizedBox(width: 8),
          //             Text('Delete Profile'),
          //           ],
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Future<void> _navigateToEditProfile(Map<String, dynamic> profile) async {
    // final result = await Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => AddProfilePage(
    //       profileToEdit: profile,
    //     ),
    //   ),
    // );

    // if (result == true) {
    //   await fetchProfiles();
    // }
  }

  Future<void> _showDeleteConfirmation(int profileId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Delete"),
        content: Text("Are you sure you want to delete this profile?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteProfile(profileId);
    }
  }

  Future<void> _deleteProfile(int profileId) async {
    try {
      final url = Uri.parse(
        'https://mfu-food-guide-review.onrender.com/delete_profile/$profileId',
      );

      final response = await http.delete(url);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Profile deleted successfully")));
        await fetchProfiles(); // โหลดข้อมูลใหม่หลังลบสำเร็จ
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to delete profile")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting profile: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F4EF),
        appBar: AppBar(title: Text("Profile Shop")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMsg.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F4EF),
        appBar: AppBar(title: const Text("Profile Shop")),
        body: Center(child: Text(errorMsg)),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F4EF),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: const Color(0xFFCEBFA3),
              pinned: false, // เลื่อนลงแล้วหาย
              floating: true, // เลื่อนขึ้นแล้วโผล่
              snap: true,
              centerTitle: true,
              title: const Text(
                "Profile Shop",
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
              elevation: 4,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text("Your Current Balance"),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.monetization_on, size: 36),
                              const SizedBox(width: 8),
                              Text(
                                currentCoins.toString(),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Choose a Profile Image",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: profiles.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.55,
                          ),
                      itemBuilder: (context, index) {
                        return buildProfileCard(profiles[index]);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // floatingActionButton: FloatingActionButton(
        //   backgroundColor: const Color.fromARGB(255, 235, 188, 117),
        //   child: Icon(Icons.add, color: Colors.white),
        //   onPressed: () {
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(builder: (context) => AddProfilePage()),
        //     ).then((shouldRefresh) {
        //       if (shouldRefresh == true) {
        //         loadUserAndFetchProfiles();
        //       }
        //     });
        //   },
        // ),
      ),
    );
  }
}
