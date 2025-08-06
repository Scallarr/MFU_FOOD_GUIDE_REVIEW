import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfileShopPage extends StatefulWidget {
  const ProfileShopPage({Key? key}) : super(key: key);

  @override
  State<ProfileShopPage> createState() => _ProfileShopPageState();
}

class _ProfileShopPageState extends State<ProfileShopPage> {
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

    if (userId == 0) {
      setState(() {
        errorMsg = "User ID not found.";
        isLoading = false;
      });
      return;
    }
    await fetchProfiles();
  }

  Future<void> fetchProfiles() async {
    final url = Uri.parse(
      'https://mfu-food-guide-review.onrender.com/profile-exchange/$userId',
    ); // เปลี่ยน URL ตามจริง
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          profiles = data
              .map(
                (item) => {
                  "id": item['Profile_Shop_ID'],
                  "name": item['Profile_Name'],
                  "description": item['Description'],
                  "coins": item['Required_Coins'],
                  "image": item['Image_URL'],
                  "is_purchased": item['is_purchased'] == 1,
                },
              )
              .toList();
          isLoading = false;
        });
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

  Future<void> buyProfile(int profileId, int cost) async {
    if (currentCoins < cost) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Insufficient coins.")));
      return;
    }

    final url = Uri.parse(
      'https://your-backend-api.com/api/purchase_profile',
    ); // เปลี่ยน URL

    final body = jsonEncode({
      'user_id': userId,
      'profile_id': profileId,
      'coins_spent': cost,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        // อัพเดต UI หลังซื้อสำเร็จ
        setState(() {
          currentCoins -= cost;
          // อัพเดตสถานะ is_purchased ของโปรไฟล์ที่ซื้อ
          final index = profiles.indexWhere((p) => p['id'] == profileId);
          if (index != -1) {
            profiles[index]['is_purchased'] = true;
          }
        });
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
    bool isPurchased = profile['is_purchased'] ?? false;
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            profile['name'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          CircleAvatar(
            radius: 45,
            backgroundImage: NetworkImage(profile['image']),
          ),
          const SizedBox(height: 8),
          Text(profile['description']),
          const SizedBox(height: 8),
          Text("${profile['coins']} Coins"),
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isPurchased ? Colors.grey : Colors.red,
            ),
            onPressed: isPurchased
                ? null
                : () {
                    buyProfile(profile['id'], profile['coins']);
                  },
            child: Text(isPurchased ? "Purchased" : "Buy"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Profile Shop")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMsg.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile Shop")),
        body: Center(child: Text(errorMsg)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Profile Shop")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
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
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                "Choose a Profile Image",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: profiles.map(buildProfileCard).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
