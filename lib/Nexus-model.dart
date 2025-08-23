import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/admin/Admin-Dashboard.dart';
import 'package:myapp/admin/Admin-Home.dart';
import 'package:myapp/admin/Admin-Leaderboard.dart';
import 'package:myapp/admin/Admin-Thread.dart';
import 'package:myapp/Atlas-model.dart';
import 'package:myapp/admin/Admin-profile-info.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Restaurant Model
class Restaurant {
  final int restaurantId;
  final String restaurantName;
  final String location;
  final String? operatingHours;
  final String? phoneNumber;
  final String? photos;
  final double? ratingOverallAvg;
  final double? ratingHygieneAvg;
  final double? ratingFlavorAvg;
  final double? ratingServiceAvg;
  final String? category;
  final int postedReviewsCount;
  final int pendingReviewsCount;
  final int bannedReviewsCount;
  final int totalReviewsCount;

  Restaurant({
    required this.restaurantId,
    required this.restaurantName,
    required this.location,
    this.operatingHours,
    this.phoneNumber,
    this.photos,
    this.ratingOverallAvg,
    this.ratingHygieneAvg,
    this.ratingFlavorAvg,
    this.ratingServiceAvg,
    this.category,
    required this.postedReviewsCount,
    required this.pendingReviewsCount,
    required this.bannedReviewsCount,
    required this.totalReviewsCount,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      restaurantId: json['Restaurant_ID'] ?? 0,
      restaurantName: json['restaurant_name'] ?? '',
      location: json['location'] ?? '',
      operatingHours: json['operating_hours'],
      phoneNumber: json['phone_number'],
      photos: json['photos'],
      ratingOverallAvg: json['rating_overall_avg'] != null
          ? double.tryParse(json['rating_overall_avg'].toString())
          : null,
      ratingHygieneAvg: json['rating_hygiene_avg'] != null
          ? double.tryParse(json['rating_hygiene_avg'].toString())
          : null,
      ratingFlavorAvg: json['rating_flavor_avg'] != null
          ? double.tryParse(json['rating_flavor_avg'].toString())
          : null,
      ratingServiceAvg: json['rating_service_avg'] != null
          ? double.tryParse(json['rating_service_avg'].toString())
          : null,
      category: json['category'],
      postedReviewsCount: json['posted_reviews_count'] ?? 0,
      pendingReviewsCount: json['pending_reviews_count'] ?? 0,
      bannedReviewsCount: json['banned_reviews_count'] ?? 0,
      totalReviewsCount: json['total_reviews_count'] ?? 0,
    );
  }
}

// ฟังก์ชัน global สำหรับดึงรูปโปรไฟล์
Future<String?> fetchProfilePicture(int userId) async {
  try {
    final response = await http.get(
      Uri.parse(
        'https://mfu-food-guide-review.onrender.com/user-profile/$userId',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['picture_url'];
    } else {
      print('Failed to load profile picture');
      return null;
    }
  } catch (e) {
    print('Error fetching profile picture: $e');
    return null;
  }
}

// ฟังก์ชันสำหรับดึงข้อมูลผู้ใช้จาก API
Future<Map<String, dynamic>?> fetchUserProfile(int userId) async {
  try {
    final response = await http.get(
      Uri.parse(
        'https://mfu-food-guide-review.onrender.com/user-profile/$userId',
      ),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('Failed to load user profile: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error fetching user profile: $e');
    return null;
  }
}

// ฟังก์ชันสำหรับดึงข้อมูลร้านอาหาร
Future<List<Restaurant>> fetchRestaurants() async {
  try {
    final response = await http.get(
      Uri.parse('https://mfu-food-guide-review.onrender.com/restaurants'),
    );

    if (response.statusCode == 200) {
      List jsonList = json.decode(response.body);
      return jsonList.map((json) => Restaurant.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load restaurants: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error fetching restaurants: $e');
    throw Exception('Failed to load restaurants');
  }
}

class Chatbot2Screen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<Chatbot2Screen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  String? profileImageUrl;
  int? userId;
  int _selectedIndex = 2;
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;
  FocusNode _focusNode = FocusNode();
  bool _showAppBar = true;
  Map<String, dynamic>? userProfile;
  String _currentModel = 'Nexus'; // โมเดลเริ่มต้น
  bool _showModelSelector = false;
  List<Restaurant> allRestaurants = [];

  @override
  void initState() {
    super.initState();
    loadUserIdAndFetchProfile();
    _addWelcomeMessage();

    // ดึงข้อมูลร้านอาหาร
    fetchRestaurants()
        .then((restaurants) {
          setState(() {
            allRestaurants = restaurants;
          });
        })
        .catchError((error) {
          print('Error loading restaurants: $error');
        });

    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _typingAnimation = CurvedAnimation(
      parent: _typingAnimationController,
      curve: Curves.easeInOut,
    );

    // เพิ่ม listener สำหรับ scroll controller
    _scrollController.addListener(() {
      // ตรวจจับการเลื่อนและซ่อน/แสดง AppBar
      if (_scrollController.offset > 100 && _showAppBar) {
        setState(() {
          _showAppBar = false;
        });
      } else if (_scrollController.offset <= 100 && !_showAppBar) {
        setState(() {
          _showAppBar = true;
        });
      }
    });

    // เพิ่ม listener สำหรับ keyboard
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        // เมื่อ keyboard เปิด ให้เลื่อนไปยังด้านล่าง
        scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _typingAnimationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> loadUserIdAndFetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getInt('user_id');

    if (storedUserId != null) {
      setState(() {
        userId = storedUserId;
      });

      // ดึงรูปโปรไฟล์
      final imageUrl = await fetchProfilePicture(userId!);
      final profileData = await fetchUserProfile(userId!);
      setState(() {
        profileImageUrl = imageUrl;
        userProfile = profileData;
      });
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage =
        "👋 Hello!\n"
        "I'm Nexus, your assistant in the MFU Food Guide & Review app 🥘✨\n\n"
        "I can help you with restaurants, reviews, profiles, coins, "
        "and other app services 💡\n"
        "Ask me anytime!";

    setState(() {
      _messages.add({
        "role": "bot",
        "content": welcomeMessage,
        "timestamp": DateTime.now().toString(),
      });
    });

    // เลื่อนไปยังข้อความล่าสุดหลังจากเพิ่มข้อความต้อนรับ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToBottom();
    });
  }

  // ฟังก์ชันสร้างคำตอบเกี่ยวกับร้านอาหาร
  String _generateRestaurantResponse(String userMessage) {
    userMessage = userMessage.toLowerCase();

    // ค้นหาร้านอาหารโดยชื่อ
    if (userMessage.contains('ชื่อ') || userMessage.contains('name')) {
      final regex = RegExp(r'ชื่อ(.+)|name(.+)');
      final match = regex.firstMatch(userMessage);
      if (match != null) {
        final searchTerm = (match.group(1) ?? match.group(2))?.trim();
        if (searchTerm != null && searchTerm.isNotEmpty) {
          final foundRestaurants = allRestaurants
              .where(
                (restaurant) => restaurant.restaurantName
                    .toLowerCase()
                    .contains(searchTerm),
              )
              .toList();

          if (foundRestaurants.isNotEmpty) {
            if (foundRestaurants.length == 1) {
              final restaurant = foundRestaurants.first;
              return "🍽️ พบร้านอาหาร: ${restaurant.restaurantName}\n"
                  "📍 ตำแหน่ง: ${restaurant.location}\n"
                  "⭐ คะแนนรวม: ${restaurant.ratingOverallAvg?.toStringAsFixed(1) ?? 'N/A'}\n"
                  "🕒 เวลาเปิด: ${restaurant.operatingHours ?? 'ไม่ระบุ'}\n"
                  "📞 โทร: ${restaurant.phoneNumber ?? 'ไม่ระบุ'}\n"
                  "📝 มีรีวิวทั้งหมด: ${restaurant.totalReviewsCount} รีวิว";
            } else {
              String response = "🍽️ พบร้านอาหารที่ตรงกับ \"$searchTerm\":\n\n";
              for (var restaurant in foundRestaurants.take(5)) {
                response +=
                    "• ${restaurant.restaurantName} (⭐ ${restaurant.ratingOverallAvg?.toStringAsFixed(1) ?? 'N/A'})\n";
              }
              if (foundRestaurants.length > 5) {
                response += "\nและอีก ${foundRestaurants.length - 5} ร้าน...";
              }
              return response;
            }
          } else {
            return "ขออภัย ไม่พบร้านอาหารที่ชื่อ中包含 \"$searchTerm\"";
          }
        }
      }
    }

    // แนะนำร้านอาหารที่มีคะแนนสูง
    if (userMessage.contains('ดี') ||
        userMessage.contains('recommend') ||
        userMessage.contains('แนะนำ') ||
        userMessage.contains('สูง')) {
      final highRatedRestaurants =
          allRestaurants.where((r) => r.ratingOverallAvg != null).toList()
            ..sort(
              (a, b) =>
                  (b.ratingOverallAvg ?? 0).compareTo(a.ratingOverallAvg ?? 0),
            );

      if (highRatedRestaurants.isNotEmpty) {
        String response = "🏆 ร้านอาหารที่มีคะแนนสูงสุด:\n\n";
        for (var i = 0; i < min(3, highRatedRestaurants.length); i++) {
          final restaurant = highRatedRestaurants[i];
          response +=
              "${i + 1}. ${restaurant.restaurantName} - ⭐ ${restaurant.ratingOverallAvg?.toStringAsFixed(1)}\n"
              "   📍 ${restaurant.location}\n\n";
        }
        return response;
      }
    }

    // นับจำนวนร้านอาหารทั้งหมด
    if (userMessage.contains('กี่ร้าน') ||
        userMessage.contains('ทั้งหมด') ||
        userMessage.contains('total')) {
      return "🍽️ มีร้านอาหารทั้งหมด ${allRestaurants.length} ร้านในระบบ";
    }

    // แสดงร้านอาหารทั้งหมด (จำกัดจำนวน)
    if
    // (userMessage.contains('ทั้งหมด') ||
    (userMessage.contains('all') || userMessage.contains('list')) {
      String response = "📋 รายการร้านอาหารทั้งหมด (แสดง 10 ร้านแรก):\n\n";
      for (var i = 0; i < min(10, allRestaurants.length); i++) {
        final restaurant = allRestaurants[i];
        response +=
            "• ${restaurant.restaurantName} (⭐ ${restaurant.ratingOverallAvg?.toStringAsFixed(1) ?? 'N/A'})\n";
      }
      if (allRestaurants.length > 10) {
        response += "\nและอีก ${allRestaurants.length - 10} ร้าน...";
      }
      return response;
    }

    // คำตอบเริ่มต้นเกี่ยวกับร้านอาหาร
    return "🍽️ ฉันสามารถช่วยคุณเกี่ยวกับร้านอาหารได้!\n\n"
        "คุณสามารถถามฉันเกี่ยวกับ:\n"
        "• ร้านอาหารที่มีคะแนนสูง\n"
        "• ร้านอาหารตามชื่อ\n"
        "• จำนวนร้านอาหารทั้งหมด\n"
        "• รายการร้านอาหาร\n\n"
        "ลองถามเช่น:\n"
        "- \"ร้านอาหารที่มีคะแนนสูงสุด\"\n"
        "- \"ร้านชื่อว่า [ชื่อร้าน]\"\n"
        "- \"มีร้านอาหารทั้งหมดกี่ร้าน\"";
  }

  void sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add({
        "role": "user",
        "content": message,
        "timestamp": DateTime.now().toString(),
      });
      _controller.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToBottom();
    });

    // ตรวจสอบคำถามเกี่ยวกับ coins
    if (message.toLowerCase().contains('coin') ||
        message.toLowerCase().contains('coins') ||
        message.toLowerCase().contains('เหรียญ') ||
        message.toLowerCase().contains('คะแนน')) {
      setState(() {
        _isLoading = true;
      });

      // รอสักครู่เพื่อแสดงการโหลด
      await Future.delayed(Duration(milliseconds: 500));

      if (userProfile != null) {
        final coins = userProfile!['coins'] ?? 0;
        setState(() {
          _messages.add({
            "role": "bot",
            "content": "You have $coins coins",
            "timestamp": DateTime.now().toString(),
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            scrollToBottom();
          });
          _isLoading = false;
        });
      } else {
        setState(() {
          _messages.add({
            "role": "bot",
            "content": "ไม่สามารถโหลดข้อมูล coins ได้",
            "timestamp": DateTime.now().toString(),
          });
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollToBottom();
        });
      }
    }
    // ตรวจสอบคำถามเกี่ยวกับร้านอาหาร
    else if (message.toLowerCase().contains('restaurant') ||
        message.toLowerCase().contains('ร้าน') ||
        message.toLowerCase().contains('อาหาร') ||
        message.toLowerCase().contains('กิน') ||
        message.toLowerCase().contains('recommend') ||
        message.toLowerCase().contains('แนะนำ')) {
      setState(() {
        _isLoading = true;
      });

      // รอสักครู่เพื่อแสดงการโหลด
      await Future.delayed(Duration(milliseconds: 500));

      if (allRestaurants.isNotEmpty) {
        String response = _generateRestaurantResponse(message);
        setState(() {
          _messages.add({
            "role": "bot",
            "content": response,
            "timestamp": DateTime.now().toString(),
          });
          _isLoading = false;
        });
      } else {
        setState(() {
          _messages.add({
            "role": "bot",
            "content": "ขออภัย ยังไม่สามารถโหลดข้อมูลร้านอาหารได้ในขณะนี้",
            "timestamp": DateTime.now().toString(),
          });
          _isLoading = false;
        });
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom();
      });
    } else if (message.toLowerCase().contains('username') ||
        message.toLowerCase() == 'user' ||
        message.toLowerCase().contains('my username') ||
        message.toLowerCase().contains('ชื่อผู้ใช้')) {
      setState(() {
        _isLoading = true;
      });

      // รอสักครู่เพื่อแสดงการโหลด
      await Future.delayed(Duration(milliseconds: 500));

      if (userProfile != null) {
        final username = userProfile!['username'] ?? 0;
        setState(() {
          _messages.add({
            "role": "bot",
            "content": " Hello, $username ",
            "timestamp": DateTime.now().toString(),
          });
          _isLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollToBottom();
        });
      } else {
        setState(() {
          _messages.add({
            "role": "bot",
            "content": "ไม่สามารถโหลดข้อมูล coins ได้",
            "timestamp": DateTime.now().toString(),
          });
          _isLoading = false;
        });
      }
    } else if (message.toLowerCase().contains('mail') ||
        message.toLowerCase() == 'email' ||
        message.toLowerCase().contains('gmail') ||
        message.toLowerCase().contains('เมล') ||
        message.toLowerCase().contains('อีเมล')) {
      setState(() {
        _isLoading = true;
      });

      // รอสักครู่เพื่อแสดงการโหลด
      await Future.delayed(Duration(milliseconds: 500));

      if (userProfile != null) {
        final username = userProfile!['email'] ?? 0;
        setState(() {
          _messages.add({
            "role": "bot",
            "content": " Your Email is, $username ",
            "timestamp": DateTime.now().toString(),
          });
          _isLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollToBottom();
        });
      } else {
        setState(() {
          _messages.add({
            "role": "bot",
            "content": "ไม่สามารถโหลดข้อมูล coins ได้",
            "timestamp": DateTime.now().toString(),
          });
          _isLoading = false;
        });
      }
    } else if (message.toLowerCase().contains('nexus') ||
        message.toLowerCase() == 'ทั่วไป') {
      setState(() {
        _messages.add({
          "role": "bot",
          "content": "Nexus model is Use Now",
          "timestamp": DateTime.now().toString(),
        });
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom();
      });
    } else if (message.toLowerCase().contains('fullname') ||
        message.toLowerCase().contains('full name') ||
        message.toLowerCase().contains('ชื่อจริง') ||
        message.toLowerCase().contains('นามสกุล') ||
        message.toLowerCase().contains('ชื่อ-นามสกุล')) {
      setState(() {
        _isLoading = true;
      });

      // รอสักครู่เพื่อแสดงการโหลด
      await Future.delayed(Duration(milliseconds: 500));

      if (userProfile != null) {
        final fullname = userProfile!['fullname'] ?? 0;
        setState(() {
          _messages.add({
            "role": "bot",
            "content": " Your Fullname is, $fullname ",
            "timestamp": DateTime.now().toString(),
          });
          _isLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollToBottom();
        });
      } else {
        setState(() {
          _messages.add({
            "role": "bot",
            "content": "ไม่สามารถโหลดข้อมูล coins ได้",
            "timestamp": DateTime.now().toString(),
          });
          _isLoading = false;
        });
      }
    }
    // ตรวจสอบว่าผู้ใช้พิมพ์คำว่า "dashboard" หรือไม่
    else if (message.toLowerCase().contains('dashboard') ||
        message.toLowerCase().contains('แดชบอร์ด') ||
        (message.toLowerCase().contains('ภาพรวม'))) {
      // แสดงข้อความตอบรับก่อนนำทาง
      setState(() {
        _messages.add({
          "role": "bot",
          "content": "Redirect To Dashboard...",
          "timestamp": DateTime.now().toString(),
        });
      });

      // รอสักครู่แล้วนำทางไปยังหน้า Dashboard
      Future.delayed(Duration(milliseconds: 1500), () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DashboardAdmin()),
        );
      });
    } else {
      // สำหรับข้อความอื่นๆ ให้แสดงข้อความตอบกลับคงที่
      setState(() {
        _isLoading = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom();
      });
      // จำลองการโหลดข้อมูล
      await Future.delayed(Duration(seconds: 1));

      setState(() {
        _messages.add({
          "role": "bot",
          "content":
              "⚠️ Your command is not valid.\n"
              "You can ask about:\n"
              "- Coins / Points\n"
              "- Username\n"
              "- Email\n"
              "- Fullname\n"
              "- Restaurants / Food recommendations\n"
              "- Dashboard / Overview\n"
              "\n"
              "💡 For other questions outside your account or the app, please use the Atlas model.",

          "timestamp": DateTime.now().toString(),
        });
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FB),
      body: Column(
        children: [
          // AppBar ที่สามารถซ่อนได้เมื่อเลื่อน
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: _showAppBar ? 90 : 0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFCEBFA3), Color(0xFFB39D70)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: OverflowBox(
              maxHeight: 90,
              child: Container(
                padding: EdgeInsets.only(left: 20, right: 20, top: 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Nexus Model',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 25,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 4,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                      ],
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
                              backgroundColor: Colors.white.withOpacity(0.3),
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 26,
                              ),
                              radius: 24,
                            )
                          : CircleAvatar(
                              backgroundImage: NetworkImage(profileImageUrl!),
                              radius: 24,
                              backgroundColor: Colors.grey[300],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_showModelSelector)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Color(0xFFF7F4EF), // สีพื้นหลังอ่อนๆ
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose A Model',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 12),

                  // โมเดลปัจจุบัน
                  _buildModelOption(
                    'Atlas',
                    'Atlas',
                    'Your all-around companion.\nAsk about anything outside the app.',
                  ),
                  SizedBox(height: 12),

                  // โมเดลสำหรับแอป
                  _buildModelOption(
                    'Nexus',
                    'Nexus',
                    'Your personal app assistant.\nAnswers about your account & data.',
                  ),
                ],
              ),
            ),

          // ส่วนแสดงข้อความแชท
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                // ตรวจจับการเลื่อน
                if (scrollNotification is ScrollUpdateNotification) {
                  if (scrollNotification.metrics.pixels > 100 && _showAppBar) {
                    setState(() {
                      _showAppBar = false;
                    });
                  } else if (scrollNotification.metrics.pixels <= 100 &&
                      !_showAppBar) {
                    setState(() {
                      _showAppBar = true;
                    });
                  }
                }
                return false;
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [const Color(0xFFF7F4EF), const Color(0xFFF7F4EF)],
                  ),
                ),
                child: ListView(
                  controller: _scrollController,
                  padding: EdgeInsets.only(bottom: 8, top: 16),
                  children: [
                    // แสดงการ์ดข้อมูลผู้ใช้หากมีข้อมูล
                    if (userProfile != null)
                      UserProfileCard(
                        userProfile: userProfile!,
                        profileImageUrl: profileImageUrl,
                      ),

                    // แสดงข้อความแชท
                    ..._messages.map((msg) {
                      final isUser = msg['role'] == 'user';
                      final content = msg['content'] ?? '';
                      final timestamp = msg['timestamp'] ?? '';

                      return ChatBubble(
                        message: content,
                        isUser: isUser,
                        isError: content.toLowerCase().contains('error'),
                        timestamp: timestamp,
                        userId: userId,
                        showModelSelector: _showModelSelector,
                        onToggleModelSelector: (value) {
                          setState(() {
                            _showModelSelector = value;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              scrollToBottom();
                            }); // Update state from parent
                          });
                        },
                        current_model: _currentModel,
                      );
                    }).toList(),

                    // แสดงตัวบ่งชี้การพิมพ์หากกำลังโหลด
                    if (_isLoading)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: TypingIndicator(),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Input field
          MessageInputField(
            controller: _controller,
            onSend: sendMessage,
            isLoading: _isLoading,
            userId: userId,
            focusNode: _focusNode,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildModelOption(String id, String title, String description) {
    bool isSelected = _currentModel == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentModel = id;
        });

        if (id == 'Atlas') {
          _messages.add({
            "role": "bot",
            "content": "🔄 Switching to Atlas model....",
            "timestamp": DateTime.now().toString(),
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            scrollToBottom();
          });

          Future.delayed(const Duration(milliseconds: 3000), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ChatbotScreen()),
            );
          });
        } else if (id == 'Nexus') {
          // แสดงข้อความเล็กๆ ก่อนปิด
          _messages.add({
            "role": "bot",
            "content": "Nexus model is Use Now",
            "timestamp": DateTime.now().toString(),
          });
          scrollToBottom();

          // ปิด dropdown
          setState(() {
            _showModelSelector = false; // ทำให้ container หายไป
          });

          // สามารถเรียก Navigator.push หรืออะไรก็ได้ถ้าต้องการ
          // Future.delayed(Duration(milliseconds: 300), () { ... });
        } else {
          print("Selected: $id");
        }
      },
      child: Container(
        padding: EdgeInsets.all(20),
        margin: EdgeInsets.only(bottom: 0, top: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.blueAccent! : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: isSelected ? Colors.blueAccent : Colors.grey[600],
              size: 26,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFFB39D70),
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
          elevation: 10,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events_rounded),
              label: 'Leaderboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.memory),
              label: 'AI Assistant',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined),
              activeIcon: Icon(Icons.forum_rounded),
              label: 'Threads',
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

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
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ThreadsAdminPage()),
        );
        break;
    }
  }
}

// ฟังก์ชันช่วยเหลือสำหรับการจัดรูปแบบวันที่
bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  final messageDate = DateTime(date.year, date.month, date.day);

  if (messageDate == today) {
    return 'Today';
  } else if (messageDate == yesterday) {
    return 'Yesterday';
  } else {
    return '${date.day}/${date.month}/${date.year + 543}'; // แปลงเป็น พ.ศ.
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final bool isError;
  final String timestamp;
  final int? userId;
  final bool showModelSelector; // Add this
  final Function(bool) onToggleModelSelector; // Add this
  final String current_model;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isUser,
    this.isError = false,
    required this.timestamp,
    required this.userId,
    required this.showModelSelector, // Add this
    required this.onToggleModelSelector, // Add this
    required this.current_model, // Add this
  }) : super(key: key);

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  @override
  // ใน Widget ChatBubble
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // ข้อความแชท
          Stack(
            clipBehavior: Clip.none, // อนุญาตให้ dropdown โผล่ออกนอกกรอบได้
            children: [
              Row(
                mainAxisAlignment: isUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar สำหรับบอท (ด้านซ้าย)
                  if (!isUser && !isError)
                    GestureDetector(
                      onTap: () {
                        // เปิด/ปิดตัวเลือกโมเดลเมื่อกดที่ Avatar AI
                        onToggleModelSelector(!showModelSelector);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 53, 53, 53),
                              Color.fromARGB(255, 255, 38, 38),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.rocket_launch_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),

                  // ข้อความและเวลา
                  Flexible(
                    child: Column(
                      crossAxisAlignment: isUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isError
                                ? Colors.red[100]?.withOpacity(0.9)
                                : isUser
                                ? Color(0xFF4A5568) // สีเทาอมน้ำเงินดูPremium
                                : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                              bottomLeft: isUser
                                  ? Radius.circular(20)
                                  : Radius.circular(8),
                              bottomRight: isUser
                                  ? Radius.circular(8)
                                  : Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isUser ? 0.3 : 0.1,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                                spreadRadius: 0.5,
                              ),
                            ],
                            border: isUser
                                ? null
                                : Border.all(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                          ),
                          child: Text(
                            message,
                            style: TextStyle(
                              color: isError
                                  ? Colors.red[900]
                                  : isUser
                                  ? Colors.white
                                  : Color(
                                      0xFF2D3748,
                                    ), // สีข้อความเข้มขึ้นนิดหน่อย
                              fontSize: 14,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),

                        // เวลาอยู่ใต้ข้อความ
                        Padding(
                          padding: EdgeInsets.only(
                            top: 6,
                            right: isUser ? 8 : 0,
                            left: isUser ? 0 : 8,
                          ),
                          child: Text(
                            _formatTime(timestamp),
                            style: TextStyle(
                              fontSize: 10, // เล็กกว่านิดหน่อย
                              color: Colors.grey[500], // สีอ่อนลง
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ระยะห่างสำหรับ user
                  if (isUser) SizedBox(width: 10),

                  // Avatar สำหรับ user (ด้านขวา)
                  if (isUser && !isError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 6),
                      child: FutureBuilder<String?>(
                        future: userId != null
                            ? fetchProfilePicture(userId!)
                            : Future.value(null),
                        builder: (context, snapshot) {
                          // if (snapshot.connectionState == ConnectionState.waiting) {
                          //   return CircleAvatar(
                          //     radius: 22,
                          //     backgroundColor: Colors.grey.shade300,
                          //     child: const CircularProgressIndicator(
                          //       strokeWidth: 2,
                          //       valueColor: AlwaysStoppedAnimation<Color>(
                          //         Colors.white,
                          //       ),
                          //     ),
                          //   );
                          // } else
                          if (snapshot.hasError || snapshot.data == null) {
                            return CircleAvatar(
                              radius: 22,
                              backgroundColor: Color(0xFFB39D70),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 22,
                              ),
                            );
                          } else {
                            return CircleAvatar(
                              radius: 22,
                              backgroundImage: NetworkImage(snapshot.data!),
                              backgroundColor: Colors.grey.shade300,
                            );
                          }
                        },
                      ),
                    ),
                ],
              ),
              // if (showModelSelector && !isUser && !isError)
              //   Positioned(
              //     top: 200, // โผล่เหนือข้อความ
              //     left: 50, // ชิดซ้าย avatar
              //     child: _buildModelSelector(context),
              //   ),
            ],
          ),
        ],
      ),
    );
  }
}

class MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isLoading;
  final int? userId;
  final FocusNode focusNode;

  const MessageInputField({
    Key? key,
    required this.controller,
    required this.onSend,
    required this.isLoading,
    this.userId,
    required this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FutureBuilder<String?>(
            future: userId != null
                ? fetchProfilePicture(userId!)
                : Future.value(null),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey.shade300,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                );
              } else if (snapshot.hasError || snapshot.data == null) {
                return CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFFB39D70),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 22,
                  ),
                );
              } else {
                return CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage(snapshot.data!),
                  backgroundColor: Colors.grey.shade300,
                );
              }
            },
          ),
          SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.grey[300]!, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      onSubmitted: (_) => onSend(),
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  isLoading
                      ? Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFB39D70),
                              ),
                            ),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.send_rounded,
                            color: Color(0xFFB39D70),
                            size: 26,
                          ),
                          onPressed: onSend,
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

// ในส่วนของ TypingIndicator Widget
class TypingIndicator extends StatefulWidget {
  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Create staggered animations for each dot
    _dotAnimations = List.generate(3, (index) {
      return Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.2, // Stagger the start time for each dot
            1.0,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar สำหรับ AI (ด้านซ้าย)
          Container(
            width: 40,
            height: 40,
            margin: EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color.fromARGB(255, 248, 2, 2), Color(0xFF9D50BB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),

          // ข้อความกำลังพิมพ์
          Container(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAnimatedDot(0),
                SizedBox(width: 5),
                _buildAnimatedDot(1),
                SizedBox(width: 5),
                _buildAnimatedDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _dotAnimations[index].value,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Color(0xFFB39D70),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

// เพิ่ม Widget ใหม่สำหรับแสดงข้อมูลผู้ใช้
class UserProfileCard extends StatelessWidget {
  final Map<String, dynamic> userProfile;
  final String? profileImageUrl;

  const UserProfileCard({
    Key? key,
    required this.userProfile,
    this.profileImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  'Today',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7E8B9F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // _buildStatItem(
              //   'Reviews',
              //   userProfile['total_reviews']?.toString() ?? '0',
              // ),
              // _buildStatItem(
              //   'Likes',
              //   userProfile['total_likes']?.toString() ?? '0',
              // ),
              // _buildStatItem('Coins', userProfile['coins']?.toString() ?? '0'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB39D70),
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
