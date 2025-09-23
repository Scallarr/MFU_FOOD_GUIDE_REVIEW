import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/Profileinfo.dart';
import 'package:myapp/admin/Admin-Dashboard.dart';
import 'package:myapp/admin/Admin-Home.dart';
import 'package:myapp/admin/Admin-Leaderboard.dart';
import 'package:myapp/admin/Admin-Thread.dart';
import 'package:myapp/Atlas-model.dart';
import 'package:myapp/admin/Admin-profile-info.dart';
import 'package:myapp/dashboard.dart';
import 'package:myapp/home.dart';
import 'package:myapp/leaderboard.dart';
import 'package:myapp/threads.dart';
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
      Uri.parse('http://172.22.173.39:8080/user-profile/$userId'),
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
      Uri.parse('http://172.22.173.39:8080/user-profile/$userId'),
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
      Uri.parse('http://172.22.173.39:8080/restaurants'),
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

class userChatbot2Screen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<userChatbot2Screen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  String? profileImageUrl;
  int? userId;
  int _selectedIndex = 2;
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;
  FocusNode _focusNode = FocusNode();
  bool _showAppBar = true;
  bool _isBotTyping = false; // เพิ่มตัวแปรนี้
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

  Future<List<dynamic>> fetchRestaurantsByCuisine({
    required String? cuisine,
    String? region,
    String? location,
  }) async {
    final queryParams = {
      if (cuisine != null) 'cuisine': cuisine,
      if (region != null) 'region': region,
      if (location != null) 'location': location,
    };

    final uri = Uri.http(
      "172.22.173.39:8080",
      "/restaurants/cuisine",
      queryParams,
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load restaurants");
    }
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

  bool awaitingCategoryChoice = false;
  bool awaitingLocationChoice = false;
  String? selectedCategory;

  // ✅ fetch categories
  Future<List<String>> fetchCategories() async {
    final res = await http.get(
      Uri.parse("http://172.22.173.39:8080/restaurants/categories"),
    );
    if (res.statusCode == 200) {
      return List<String>.from(json.decode(res.body));
    } else {
      throw Exception("Failed to load categories");
    }
  }

  // ✅ fetch locations
  Future<List<String>> fetchLocations() async {
    final res = await http.get(
      Uri.parse("http://172.22.173.39:8080/restaurants/locations"),
    );
    if (res.statusCode == 200) {
      return List<String>.from(json.decode(res.body));
    } else {
      throw Exception("Failed to load locations");
    }
  }

  // ✅ fetch restaurants by category + location
  Future<List<dynamic>> fetchRestaurants2(
    String? category,
    String? location,
  ) async {
    final res = await http.get(
      Uri.parse(
        "http://172.22.173.39:8080/restaurants/search?category=$category&location=$location",
      ),
    );
    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception("Failed to load restaurants");
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
        "I'm Nexus, your assistant in the MFU Food Guide & Review app \n\n"
        "I can help you with restaurants, reviews, profiles, coins, "
        "and other app services 💡\n\n"
        " + + + + + + + + + + + + + + + + + + \n"
        "You can type commands like:\n"
        "1️⃣ User Information\n"
        "2️⃣ Restaurant Recommendetion\n"
        "3️⃣ Dashboard Overview\n"
        " + + + + + + + + + + + + + + + + + +  \n"
        "   For other questions outside your account or the app, please use the Atlas model.";

    setState(() {
      _messages.add({
        "role": "bot",
        "content": welcomeMessage,
        "timestamp": DateTime.now().toString(),
        "shouldAnimate": false, // เพิ่ม field นี้
      });
    });

    // เลื่อนไปยังข้อความล่าสุดหลังจากเพิ่มข้อความต้อนรับ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToBottom();
    });
  }

  bool awaitingCuisineChoice = false;
  bool awaitingRegionChoice = false;
  bool awaitingCuisineLocationChoice = false;
  bool awaitingUserChoice = false; // อยู่ระดับ class
  bool awaitingRestaurantChoice = false;
  String? selectedCuisine;
  String? selectedRegion; // ระดับ class
  // สมมติ awaitingUserChoice, awaitingRestaurantChoice อยู่ระดับ class
  // และตัวแปรอื่นๆ เช่น _messages, _isLoading, _isBotTyping, userProfile มีอยู่แล้ว
  bool awaitingDietTypeChoice = false;
  bool awaitingDietLocationChoice = false;
  String? selectedDietType;
  bool awaitingRestaurantTypeChoice = false;
  bool awaitingRestaurantTypeLocationChoice = false;
  String? selectedRestaurantType;
  bool awaitingServiceTypeChoice = false;
  bool awaitingServiceTypeLocationChoice = false;
  String? selectedServiceType;

  void sendMessage() async {
    final raw = _controller.text;
    final message = raw.trim();
    if (message.isEmpty || _isBotTyping || _isLoading) return;

    // add user message
    setState(() {
      _messages.add({
        "role": "user",
        "content": message,
        "timestamp": DateTime.now().toString(),
        "shouldAnimate": false,
      });
      _controller.clear();
      _isBotTyping = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());

    final msgLower = message.toLowerCase();

    // 1) ถ้ากำลังรอ User Profile choice -> handle นั่นก่อน (priority)
    if (awaitingUserChoice) {
      await _handleUserProfileChoice(msgLower);
      setState(() => _isBotTyping = false);
      return;
    }

    // 2) ถ้ากำลังรอ Restaurant choice -> handle นั่นก่อน
    if (awaitingRestaurantChoice) {
      await _handleRestaurantChoice(msgLower);
      setState(() => _isBotTyping = false);
      return;
    }

    // 3) ถ้าไม่มี awaiting flags ให้ตรวจว่าผู้ใช้เรียกเมนูไหน
    if (RegExp(r'^1$').hasMatch(message) ||
        msgLower == 'profile' ||
        msgLower == 'user profile' ||
        msgLower.contains('user profile')) {
      // show user profile menu
      setState(() {
        _messages.add({
          "role": "bot",
          "content":
              " User Information Commands:\n"
              "+ + + + + + + + + + + + + + + + + + \n"
              "1️⃣ View Full Name\n"
              "2️⃣ View Username\n"
              "3️⃣ View Email\n"
              "4️⃣ View Dashboard\n"
              "5️⃣ View Total Reviews\n"
              "6️⃣ View Coins\n"
              "7️⃣ View Role\n"
              "8️⃣ Exit\n"
              "+ + + + + + + + + + + + + + + + + + \n"
              "Type the number or name of the information you want to see.",
          "timestamp": DateTime.now().toString(),
          "shouldAnimate": true,
        });

        awaitingUserChoice = true;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
      setState(() => _isBotTyping = false);
      return;
    }

    if (RegExp(r'^2$').hasMatch(message) ||
        msgLower == 'restaurant' ||
        msgLower == 'restaurants' ||
        msgLower.contains('restaurant')) {
      // show restaurant menu
      setState(() {
        _messages.add({
          "role": "bot",
          "content":
              "🍽 Restaurant Recommendetion \n"
              " + + + + + + + + + + + + + + + + + + \n"
              "You can type commands like:\n"
              "1️⃣ Category\n"
              "2️⃣ Cuisine by Nation\n"
              "3️⃣ Diet Type\n"
              "4️⃣ Restaurant Type\n"
              "5️⃣ Service Type\n"
              "6️⃣ Exit\n"
              " + + + + + + + + + + + + + + + + + + \n"
              "Type the number or name of the information you want to see.",
          "timestamp": DateTime.now().toString(),
          "shouldAnimate": true,
        });
        awaitingRestaurantChoice = true;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
      // setState(() => _isBotTyping = false);
      return;
    }
    if (RegExp(r'^3$').hasMatch(message) ||
        msgLower == 'dashboard' ||
        msgLower == 'overview' ||
        msgLower.contains('over')) {
      // case "4":
      //   // ต้องเพิ่มข้อความก่อน navigate

      //   WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());

      //   Future.delayed(Duration(milliseconds: 1000), () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (context) => Dashboard()),
      //     );
      //   });
      //   return; // return ทันทีหลังจาก navigate
      // show restaurant menu

      setState(() {
        _messages.add({
          "role": "bot",
          "content": "Redirecting to Dashboard...",
          "timestamp": DateTime.now().toString(),
          "shouldAnimate": true,
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
        awaitingUserChoice = false;
        Future.delayed(Duration(milliseconds: 2500), () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Dashboard()),
          );
        });
        return; // return ทันทีหลังจาก navigate
        // show restaurant menu
        //   _isLoading = false;
      });

      _isLoading = false;

      WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
      // setState(() => _isBotTyping = false);
      return;
    }

    // 4) default fallback
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(Duration(milliseconds: 800));
    setState(() {
      _messages.add({
        "role": "bot",
        "content":
            "⚠️ Your command is not valid.\n"
            " + + + + + + + + + + + + + + + + + + \n"
            "You can type commands like:\n"
            "1️⃣ User Information\n"
            "2️⃣ Restaurant Recommendetion\n"
            "3️⃣ Dashboard Overview\n"
            " + + + + + + + + + + + + + + + + + +  \n"
            "   For other questions outside your account or the app, please use the Atlas model.",
        "timestamp": DateTime.now().toString(),
        "shouldAnimate": true,
      });
      _isLoading = false;
      _isBotTyping = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
  }

  // ----------------- helper: user profile choices -----------------
  Future<void> _handleUserProfileChoice(String option) async {
    setState(() => _isLoading = true);
    await Future.delayed(Duration(milliseconds: 400));

    String content = '';
    final opt = option.trim().toLowerCase();
    bool shouldExit = false;

    switch (opt) {
      case "1":
      case "fullname":
      case "full":
        content =
            " Your Fullname is\n"
            "+ + + + + + + + + + + + + + + + + + \n"
            "➡️ ${userProfile!['fullname'] ?? 'Not set'}\n"
            "+ + + + + + + + + + + + + + + + + +\n"
            "▶️ User Information Commands:\n"
            "1️⃣ View Full Name\n"
            "2️⃣ View Username\n"
            "3️⃣ View Email\n"
            "4️⃣ View Total Reviews\n"
            "5️⃣ View Coins\n"
            "6️⃣ View Role\n"
            "7️⃣ Exit\n"
            "+ + + + + + + + + + + + + + + + + + \n"
            "Type the number or name of the information you want to see.";
        break;

      case "2":
      case "username":
      case "user":
        content =
            "📝 Your Username is\n"
            "+ + + + + + + + + + + + + + + + + +\n"
            "▶️ ${userProfile!['username'] ?? 'Not set'}\n"
            "+ + + + + + + + + + + + + + + + + + \n"
            "➡️ User Information Commands:\n"
            "1️⃣ View Full Name\n"
            "2️⃣ View Username\n"
            "3️⃣ View Email\n"
            "4️⃣ View Dashboard\n"
            "5️⃣ View Total Reviews\n"
            "6️⃣ View Coins\n"
            "7️⃣ View Role\n"
            "8️⃣ Exit\n"
            "+ + + + + + + + + + + + + + + + + + \n"
            "Type the number or name of the information you want to see.";
        break;

      case "3":
      case "email":
        content =
            "📝 Your Email That Registered is\n"
            "+ + + + + + + + + + + + + + + + + + \n"
            "${userProfile!['email'] ?? 'Not set'}\n"
            "+ + + + + + + + + + + + + + + + + + \n"
            "➡️User Information Commands:\n"
            "1️⃣ View Full Name\n"
            "2️⃣ View Username\n"
            "3️⃣ View Email\n"
            "4️⃣ View Total Reviews\n"
            "5️⃣ View Coins\n"
            "6️⃣ View Role\n"
            "7️⃣ Exit\n"
            "+ + + + + + + + + + + + + + + + + + \n"
            "Type the number or name of the information you want to see.";
        break;

      // case "4":
      //   // ต้องเพิ่มข้อความก่อน navigate
      //   setState(() {
      //     _messages.add({
      //       "role": "bot",
      //       "content": "Redirecting to Dashboard...",
      //       "timestamp": DateTime.now().toString(),
      //       "shouldAnimate": true,
      //     });
      //     _isLoading = false;
      //     awaitingUserChoice = false;
      //   });

      //   WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());

      //   Future.delayed(Duration(milliseconds: 1000), () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (context) => Dashboard()),
      //     );
      //   });
      //   return; // return ทันทีหลังจาก navigate

      case "4":
      case "total reviews":
      case "total":
        int totalReviews = userProfile!['total_reviews'] ?? 0;
        final reviews = userProfile!['reviews'] as List<dynamic>? ?? [];

        String reviewSummary = "";
        if (reviews.isNotEmpty) {
          for (var r in reviews) {
            reviewSummary +=
                """━━━━━━━━━━━━━━━━━━━━
 ${r['restaurant_name']}
 Location: ${r['location']}
 Reviews: ${r['review_count']}
""";
          }
          reviewSummary += "━━━━━━━━━━━━━━━━━━━━";
        } else {
          reviewSummary = "You haven't reviewed any restaurants yet.";
        }

        content =
            "📝 Review Summary \n"
            "+ + + + + + + + + + + + + + + + + + \n"
            "▶️ $totalReviews reviews\n"
            "+ + + + + + + + + + + + + + + + + + \n\n"
            "$reviewSummary"
            "\n+ + + + + + + + + + + + + + + + + \n"
            "➡️User Information Commands:\n"
            "1️⃣ View Full Name\n"
            "2️⃣ View Username\n"
            "3️⃣ View Email\n"
            "4️⃣ View Total Reviews\n"
            "5️⃣ View Coins\n"
            "6️⃣ View Role\n"
            "7️⃣ Exit\n"
            "+ + + + + + + + + + + + + + + + + + \n"
            "Type the number or name of the information you want to see.";
        break;

      case "5":
      case "coins":
        content =
            "💰 Coins \n"
            "+ + + + + + + + + + + + + + + + + + \n"
            "▶️ ${userProfile!['coins'] ?? 0} coins\n"
            "+ + + + + + + + + + + + + + + + + + \n"
            "➡️User Information Commands:\n"
            "1️⃣ View Full Name\n"
            "2️⃣ View Username\n"
            "3️⃣ View Email\n"
            "4️⃣ View Total Reviews\n"
            "5️⃣ View Coins\n"
            "6️⃣ View Role\n"
            "7️⃣ Exit\n"
            "+ + + + + + + + + + + + + + + + + + \n"
            "Type the number or name of the information you want to see.";
        break;

      case "6":
      case "role":
        content =
            "🎭 Role\n"
            "+ + + + + + + + + + + + + + + + + + \n"
            "▶️ ${userProfile!['role'] ?? 'Not set'}\n"
            "+ + + + + + + + + + + + + + + + + + \n"
            "➡️User Information Commands:\n"
            "1️⃣ View Full Name\n"
            "2️⃣ View Username\n"
            "3️⃣ View Email\n"
            "4️⃣ View Total Reviews\n"
            "5️⃣ View Coins\n"
            "6️⃣ View Role\n"
            "7️⃣ Exit\n"
            "+ + + + + + + + + + + + + + + + + + \n"
            "Type the number or name of the information you want to see.";
        break;

      case "7":
      case "exit":
        content =
            "💬 You can type commands like:\n"
            "+ + + + + + + + + + + + + + + + + + \n"
            "1️⃣ User Information \n"
            "2️⃣ Restaurants Recommendations \n"
            "3️⃣ Dashboard Overview \n"
            "+ + + + + + + + + + + + + + + + + + \n"
            "Type the number or name of the information you want to see.";
        shouldExit = true;
        break;

      default:
        content =
            "⚠️ Invalid option.\n"
            "+ + + + + + + + + + + + + + + + + + \n"
            "▶️ User Information Commands:\n"
            "1️⃣ View Full Name\n"
            "2️⃣ View Username\n"
            "3️⃣ View Email\n"
            "4️⃣ View Dashboard\n"
            "5️⃣ View Total Reviews\n"
            "6️⃣ View Coins\n"
            "7️⃣ View Role\n"
            "8️⃣ Exit\n"
            "+ + + + + + + + + + + + + + + + + + \n"
            "Type the number or name of the information you want to see.";
    }

    // อัพเดท state และเพิ่มข้อความ
    setState(() {
      _messages.add({
        "role": "bot",
        "content": content,
        "timestamp": DateTime.now().toString(),
        "shouldAnimate": true,
      });

      if (shouldExit) {
        awaitingUserChoice = false;
      }

      _isLoading = false;
      _isBotTyping = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
  }

  Future<void> _handleRestaurantChoice(String option) async {
    setState(() => _isLoading = true);
    await Future.delayed(Duration(milliseconds: 400));

    List<String> emojis = [
      "1️⃣",
      "2️⃣",
      "3️⃣",
      "4️⃣",
      "5️⃣",
      "6️⃣",
      "7️⃣",
      "8️⃣",
      "9️⃣",
      "🔟",
      "1️⃣1️⃣ ",
      "⓬",
      "⓭",
      "⓮",
      "⓯",
      "⓰",
      "⓱",
      "⓲",
      "⓳",
      "⓴",
    ];

    String content = '';
    final opt = option.trim().toLowerCase();

    // ------------------ Service Type Selection ------------------
    if (awaitingServiceTypeChoice) {
      List<String> serviceTypes = ["Delivery", "Dine-in", "All"];

      String? chosenServiceType;
      int? index;

      if (emojis.contains(opt)) {
        index = emojis.indexOf(opt);
      } else if (int.tryParse(opt) != null) {
        index = int.parse(opt) - 1;
      } else {
        // ค้นหาจากชื่อ service type
        for (var type in serviceTypes) {
          if (type.toLowerCase().contains(opt)) {
            chosenServiceType = type;
            break;
          }
        }
      }

      if (index != null && index >= 0 && index < serviceTypes.length) {
        chosenServiceType = serviceTypes[index];
      }

      if (chosenServiceType != null) {
        selectedServiceType = chosenServiceType;

        final locations = await fetchLocations();
        List<String> locationOptions = ["All", ...locations];

        content =
            "📍 Please Choose Locations for\n" +
            "+ + + + + + + + + + + + + + + + + + \n" +
            "$chosenServiceType service:\n" +
            "+ + + + + + + + + + + + + + + + + + \n" +
            locationOptions
                .asMap()
                .entries
                .map((e) => "${emojis[e.key]} ${e.value}")
                .join("\n") +
            "\n+ + + + + + + + + + + + + + + + + + \n"
                "Type the number or name of the location.";

        awaitingServiceTypeChoice = false;
        awaitingServiceTypeLocationChoice = true;
      } else {
        content =
            "⚠️ Invalid service type.\n" +
            "+ + + + + + + + + + + + + + + + + + \n" +
            "Please choose a valid option:\n" +
            serviceTypes
                .asMap()
                .entries
                .map((e) => "${emojis[e.key]} ${e.value}")
                .join("\n") +
            "\n+ + + + + + + + + + + + + + + + + + \n" +
            "Type the number or name of the service type.";
      }
    }
    // ------------------ Service Type Location Selection ------------------
    else if (awaitingServiceTypeLocationChoice) {
      final locations = await fetchLocations();
      List<String> locationOptions = ["All", ...locations];
      String? chosenLocation;
      int? index;

      if (emojis.contains(opt)) {
        index = emojis.indexOf(opt);
      } else if (int.tryParse(opt) != null) {
        index = int.parse(opt) - 1;
      } else {
        // ค้นหาจากชื่อ location
        for (var location in locationOptions) {
          if (location.toLowerCase().contains(opt)) {
            chosenLocation = location;
            break;
          }
        }
      }

      if (index != null && index >= 0 && index < locationOptions.length) {
        chosenLocation = locationOptions[index];
      }

      if (chosenLocation != null) {
        // เรียก API เพื่อดึงข้อมูลร้านอาหารตาม service type และ location
        final restaurants = await fetchRestaurantsByServiceTypeAndLocation(
          serviceType: selectedServiceType,
          location: chosenLocation,
        );

        if (restaurants.isNotEmpty) {
          content =
              "🍽 Restaurants Found:\n"
              "+ + + + + + + + + + + + + + + + + + \n"
              "Service Type: ${selectedServiceType ?? 'All'}\n"
              "Location: ${chosenLocation ?? 'All'}\n"
              "+ + + + + + + + + + + + + + + + + + \n";

          int index = 1;
          for (var r in restaurants) {
            String numberIcon = "${index}️⃣";
            content += "━━━━━━━━━━━━━━━━━━━━\n";
            content += "$numberIcon ${r['restaurant_name']}\n";
            content += "Location: ${r['location']}\n";
            content += "Categories Product: ${r['category']}\n";
            content += "Service: ${r['service_type']}\n";
            // content += "Type: ${r['restaurant_type']}\n";
            content += "Cuisine Nation: ${r['cuisine_by_nation']}\n";
            content += "Diet: ${r['diet_type']}\n";
            content +=
                "Rating: ${r['rating_overall_avg'] != null ? double.tryParse(r['rating_overall_avg'].toString())?.toStringAsFixed(1) ?? 'N/A' : 'N/A'}\n";
            content += "Hours: ${r['operating_hours'] ?? 'Not specified'}\n";
            content += "Phone: ${r['phone_number'] ?? 'Not provided'}\n";
            index++;
          }
          content += "━━━━━━━━━━━━━━━━━━━━\n";
        } else {
          content =
              "⚠️ No restaurants found for $selectedServiceType service at ${chosenLocation ?? 'all locations'}.\n";
        }

        // รีเซ็ต state หลังจากแสดงผล
        content +=
            "\n💬 You can type commands like:\n"
            "1️⃣ Category\n2️⃣ Cuisine by Nation\n3️⃣ Diet Type\n"
            "4️⃣ Restaurant Type\n5️⃣ Service Type\n6️⃣ Exit\n"
            "+ + + + + + + + + + + + + + + + + + \n"
            "Type the number or name of the information you want to see.";

        awaitingServiceTypeLocationChoice = false;
        selectedServiceType = null;
      } else {
        content =
            "⚠️ Invalid location.\n" +
            "+ + + + + + + + + + + + + + + + + + \n" +
            "Please choose a valid option:\n" +
            locationOptions
                .asMap()
                .entries
                .map((e) => "${emojis[e.key]} ${e.value}")
                .join("\n") +
            "\n+ + + + + + + + + + + + + + + + + + \n" +
            "Type the number or name of the location.";
      }
    }
    // ------------------ Restaurant Type Selection ------------------
    else if (awaitingRestaurantTypeChoice) {
      List<String> restaurantTypes = [
        "Cafeteria",
        "Mini-Mart",
        "Cafe",
        "Restaurant",
      ];

      String? chosenRestaurantType;
      int? index;

      if (emojis.contains(opt)) {
        index = emojis.indexOf(opt);
      } else if (int.tryParse(opt) != null) {
        index = int.parse(opt) - 1;
      } else {
        // ค้นหาจากชื่อ restaurant type
        for (var type in restaurantTypes) {
          if (type.toLowerCase().contains(opt)) {
            chosenRestaurantType = type;
            break;
          }
        }
      }

      if (index != null && index >= 0 && index < restaurantTypes.length) {
        chosenRestaurantType = restaurantTypes[index];
      }

      if (chosenRestaurantType != null) {
        selectedRestaurantType = chosenRestaurantType;

        final locations = await fetchLocations();
        List<String> locationOptions = ["All", ...locations];

        content =
            "📍 Please Choose Locations for \n" +
            "+ + + + + + + + + + + + + + + + + + \n" +
            "$chosenRestaurantType:\n" +
            "+ + + + + + + + + + + + + + + + + + \n" +
            locationOptions
                .asMap()
                .entries
                .map((e) => "${emojis[e.key]} ${e.value}")
                .join("\n") +
            "\n+ + + + + + + + + + + + + + + + + + \n"
                "Type the number or name of the location.";

        awaitingRestaurantTypeChoice = false;
        awaitingRestaurantTypeLocationChoice = true;
      } else {
        content =
            "⚠️ Invalid restaurant type.\n" +
            "+ + + + + + + + + + + + + + + + + + \n" +
            "Please choose a valid option:\n" +
            restaurantTypes
                .asMap()
                .entries
                .map((e) => "${emojis[e.key]} ${e.value}")
                .join("\n") +
            "\n+ + + + + + + + + + + + + + + + + + \n" +
            "Type the number or name of the restaurant type.";
      }
    }
    // ------------------ Restaurant Type Location Selection ------------------
    else if (awaitingRestaurantTypeLocationChoice) {
      final locations = await fetchLocations();
      List<String> locationOptions = ["All", ...locations];
      String? chosenLocation;
      int? index;

      if (emojis.contains(opt)) {
        index = emojis.indexOf(opt);
      } else if (int.tryParse(opt) != null) {
        index = int.parse(opt) - 1;
      } else {
        // ค้นหาจากชื่อ location
        for (var location in locationOptions) {
          if (location.toLowerCase().contains(opt)) {
            chosenLocation = location;
            break;
          }
        }
      }

      if (index != null && index >= 0 && index < locationOptions.length) {
        chosenLocation = locationOptions[index];
      }

      if (chosenLocation != null) {
        // เรียก API เพื่อดึงข้อมูลร้านอาหารตาม restaurant type และ location
        final restaurants = await fetchRestaurantsByRestaurantTypeAndLocation(
          restaurantType: selectedRestaurantType,
          location: chosenLocation == "All" ? null : chosenLocation,
        );

        if (restaurants.isNotEmpty) {
          content =
              "🍽 Restaurants Found:\n"
              "+ + + + + + + + + + + + + + + + + + \n"
              "Restaurant Type: ${selectedRestaurantType ?? 'All'}\n"
              "Location: ${chosenLocation ?? 'All'}\n"
              "+ + + + + + + + + + + + + + + + + + \n";

          int index = 1;
          for (var r in restaurants) {
            String numberIcon = "${index}️⃣";
            content += "━━━━━━━━━━━━━━━━━━━━\n";
            content += "$numberIcon ${r['restaurant_name']}\n";
            content += "Location: ${r['location']}\n";
            content += "Category Product: ${r['category']}\n";
            content += "Restaurant Type: ${r['restaurant_type']}\n";
            content += "Cuisine Nation: ${r['cuisine_by_nation']}\n";
            content += "Diet: ${r['diet_type']}\n";
            content +=
                "Rating: ${r['rating_overall_avg'] != null ? double.tryParse(r['rating_overall_avg'].toString())?.toStringAsFixed(1) ?? 'N/A' : 'N/A'}\n";
            content += "Hours: ${r['operating_hours'] ?? 'Not specified'}\n";
            content += "Phone: ${r['phone_number'] ?? 'Not provided'}\n";
            index++;
          }
          content += "━━━━━━━━━━━━━━━━━━━━\n";
        } else {
          content =
              "⚠️ No restaurants found for" +
              "\n+ + + + + + + + + + + + + + + + + + \n" +
              "$selectedRestaurantType at ${chosenLocation ?? 'all locations'}.\n" +
              "\n+ + + + + + + + + + + + + + + + + + \n";
        }

        // รีเซ็ต state หลังจากแสดงผล
        content +=
            "\n💬 You can type commands like:\n"
            "1️⃣ Category\n2️⃣ Cuisine by Nation\n3️⃣ Diet Type\n"
            "4️⃣ Restaurant Type\n5️⃣ Service Type\n6️⃣ Exit\n"
            "+ + + + + + + + + + + + + + + + + + \n"
            "Type the number or name of the information you want to see.";

        awaitingRestaurantTypeLocationChoice = false;
        selectedRestaurantType = null;
      } else {
        content =
            "⚠️ Invalid location.\n" +
            "+ + + + + + + + + + + + + + + + + + \n" +
            "Please choose a valid option:\n" +
            locationOptions
                .asMap()
                .entries
                .map((e) => "${emojis[e.key]} ${e.value}")
                .join("\n") +
            "\n+ + + + + + + + + + + + + + + + + + \n" +
            "Type the number or name of the location.";
      }
    }
    // ------------------ Diet Type Selection ------------------
    else if (awaitingDietTypeChoice) {
      List<String> dietTypes = ["HALAL", "VEGETARIAN", "GENERAL"];

      String? chosenDietType;
      int? index;

      if (emojis.contains(opt)) {
        index = emojis.indexOf(opt);
      } else if (int.tryParse(opt) != null) {
        index = int.parse(opt) - 1;
      } else {
        // ค้นหาจากชื่อ diet type
        for (var diet in dietTypes) {
          if (diet.toLowerCase().contains(opt)) {
            chosenDietType = diet;
            break;
          }
        }
      }

      if (index != null && index >= 0 && index < dietTypes.length) {
        chosenDietType = dietTypes[index];
      }

      if (chosenDietType != null) {
        selectedDietType = chosenDietType;

        final locations = await fetchLocations();
        List<String> locationOptions = ["All", ...locations];

        content =
            "📍 Please Choose Locations for" +
            "\n + + + + + + + + + + + + + + + + + + \n" +
            "$chosenDietType diet:\n"
                " + + + + + + + + + + + + + + + + + + \n" +
            locationOptions
                .asMap()
                .entries
                .map((e) => "${emojis[e.key]} ${e.value}")
                .join("\n") +
            "\n+ + + + + + + + + + + + + + + + + + \n"
                "Type the number or name of the location.";

        awaitingDietTypeChoice = false;
        awaitingDietLocationChoice = true;
      } else {
        content =
            "⚠️ Invalid diet type.\n" +
            "+ + + + + + + + + + + + + + + + + + \n" +
            "Please choose a valid option:\n" +
            dietTypes
                .asMap()
                .entries
                .map((e) => "${emojis[e.key]} ${e.value}")
                .join("\n") +
            "\n+ + + + + + + + + + + + + + + + + + \n" +
            "Type the number or name of the diet type.";
      }
    }
    // ------------------ Diet Location Selection ------------------
    else if (awaitingDietLocationChoice) {
      final locations = await fetchLocations();
      List<String> locationOptions = ["All", ...locations];
      String? chosenLocation;
      int? index;

      if (emojis.contains(opt)) {
        index = emojis.indexOf(opt);
      } else if (int.tryParse(opt) != null) {
        index = int.parse(opt) - 1;
      } else {
        // ค้นหาจากชื่อ location
        for (var location in locationOptions) {
          if (location.toLowerCase().contains(opt)) {
            chosenLocation = location;
            break;
          }
        }
      }

      if (index != null && index >= 0 && index < locationOptions.length) {
        chosenLocation = locationOptions[index];
      }

      if (chosenLocation != null) {
        // เรียก API เพื่อดึงข้อมูลร้านอาหารตาม diet type และ location
        final restaurants = await fetchRestaurantsByDietAndLocation(
          dietType: selectedDietType,
          location: chosenLocation == "All" ? null : chosenLocation,
        );

        if (restaurants.isNotEmpty) {
          content =
              "🍽 Restaurants Found:\n"
              "+ + + + + + + + + + + + + + + + + + \n"
              "Diet Type: ${selectedDietType ?? 'All'}\n"
              "Location: ${chosenLocation ?? 'All'}\n"
              "+ + + + + + + + + + + + + + + + + + \n";

          int index = 1;
          for (var r in restaurants) {
            String numberIcon = "${index}️⃣";
            content += "━━━━━━━━━━━━━━━━━━━━\n";
            content += "$numberIcon ${r['restaurant_name']}\n";
            content += "Location: ${r['location']}\n";
            content += "Category: ${r['category']}\n";
            content += "Diet Type: ${r['diet_type']}\n";
            content += "Cuisine: ${r['cuisine_by_nation']}\n";
            content +=
                "Rating: ${r['rating_overall_avg'] != null ? double.tryParse(r['rating_overall_avg'].toString())?.toStringAsFixed(1) ?? 'N/A' : 'N/A'}\n";
            content += "Hours: ${r['operating_hours'] ?? 'Not specified'}\n";
            content += "Phone: ${r['phone_number'] ?? 'Not provided'}\n";
            index++;
          }
          content += "+ + + + + + + + + + + + + + + + + + \n";
        } else {
          content =
              "⚠️ No restaurants found for " +
              "\n+ + + + + + + + + + + + + + + + + + \n" +
              "  $selectedDietType diet at ${chosenLocation ?? 'all locations'}.\n" +
              "+ + + + + + + + + + + + + + + + + + \n";
        }

        // รีเซ็ต state หลังจากแสดงผล
        content +=
            "\n💬 You can type commands like:\n"
            "1️⃣ Category\n2️⃣ Cuisine by Nation\n3️⃣ Diet Type\n"
            "4️⃣ Restaurant Type\n5️⃣ Service Type\n6️⃣ Exit\n"
            "+ + + + + + + + + + + + + + + + + + \n"
            "Type the number or name of the information you want to see.";

        awaitingDietLocationChoice = false;
        selectedDietType = null;
      } else {
        content =
            "⚠️ Invalid location.\n" +
            "+ + + + + + + + + + + + + + + + + + \n" +
            "Please choose a valid option:\n" +
            locationOptions
                .asMap()
                .entries
                .map((e) => "${emojis[e.key]} ${e.value}")
                .join("\n") +
            "\n+ + + + + + + + + + + + + + + + + + \n" +
            "Type the number or name of the location.";
      }
    }
    // ------------------ Cuisine Selection ------------------
    else if (awaitingCuisineChoice) {
      List<String> cuisines = [
        "THAI",
        "CHINESE",
        "JAPANESE",
        "KOREAN",
        "INDIAN",
        "ITALIAN",
        "FRENCH",
        "MEXICAN",
        "AMERICAN",
        "VIETNAMESE",
        "OTHER",
      ];

      String? chosenCuisine;
      int? index;

      if (emojis.contains(opt)) {
        index = emojis.indexOf(opt);
      } else if (int.tryParse(opt) != null) {
        index = int.parse(opt) - 1;
      } else {
        // ค้นหาจากชื่อ cuisine
        for (var cuisine in cuisines) {
          if (cuisine.toLowerCase().contains(opt)) {
            chosenCuisine = cuisine;
            break;
          }
        }
      }

      if (index != null && index >= 0 && index < cuisines.length) {
        chosenCuisine = cuisines[index];
      }

      if (chosenCuisine != null) {
        selectedCuisine = chosenCuisine;

        if (chosenCuisine == "THAI") {
          // ต้องเลือก Region ต่อสำหรับอาหารไทย
          List<String> regions = [
            "NORTH",
            "CENTRAL",
            "NORTHEAST",
            "SOUTH",
            "EAST",
            "WEST",
          ];
          content =
              "🌏 You chose THAI cuisine.\n"
                  "Please choose the region:\n"
                  "+ + + + + + + + + + + + + + + + + + \n" +
              regions
                  .asMap()
                  .entries
                  .map((e) => "${emojis[e.key]} ${e.value}")
                  .join("\n") +
              "\n+ + + + + + + + + + + + + + + + + + \n"
                  "Type the number or name of the region.";
          awaitingCuisineChoice = false;
          awaitingRegionChoice = true;
        } else {
          // อาหารประเทศอื่นๆ ข้ามการเลือก region
          final locations = await fetchLocations();
          List<String> locationOptions = ["All", ...locations];

          content =
              "📍 Please Choose Locations for " +
              "\n + + + + + + + + + + + + + + + + + + \n" +
              "$chosenCuisine cuisine:\n"
                  "+ + + + + + + + + + + + + + + + + + \n" +
              locationOptions
                  .asMap()
                  .entries
                  .map((e) => "${emojis[e.key]} ${e.value}")
                  .join("\n") +
              "\n+ + + + + + + + + + + + + + + + + + \n"
                  "Type the number or name of the location.";

          awaitingCuisineChoice = false;
          awaitingCuisineLocationChoice = true;
        }
      } else {
        content =
            "⚠️ Invalid cuisine.\n" +
            "+ + + + + + + + + + + + + + + + + + \n" +
            "💬 You can type commands like:\n" +
            cuisines
                .asMap()
                .entries
                .map((e) => "${emojis[e.key]} ${e.value}")
                .join("\n") +
            "\n+ + + + + + + + + + + + + + + + + + \n" +
            "Type the number or name of the location.";
      }
    }
    // ------------------ Region Selection (เฉพาะ THAI) ------------------
    else if (awaitingRegionChoice) {
      List<String> regions = [
        "NORTH",
        "CENTRAL",
        "NORTHEAST",
        "SOUTH",
        "EAST",
        "WEST",
      ];

      String? chosenRegion;
      int? index;

      if (emojis.contains(opt)) {
        index = emojis.indexOf(opt);
      } else if (int.tryParse(opt) != null) {
        index = int.parse(opt) - 1;
      } else {
        // ค้นหาจากชื่อ region
        for (var region in regions) {
          if (region.toLowerCase().contains(opt)) {
            chosenRegion = region;
            break;
          }
        }
      }

      if (index != null && index >= 0 && index < regions.length) {
        chosenRegion = regions[index];
      }

      if (chosenRegion != null) {
        selectedRegion = chosenRegion;

        final locations = await fetchLocations();
        List<String> locationOptions = ["All", ...locations];

        content =
            "📍 Please Choose Locations for \n " +
            " + + + + + + + + + + + + + + + + + + \n" +
            "  Thai ($chosenRegion) cuisine:\n"
                "+ + + + + + + + + + + + + + + + + + \n" +
            locationOptions
                .asMap()
                .entries
                .map((e) => "${emojis[e.key]} ${e.value}")
                .join("\n") +
            "\n+ + + + + + + + + + + + + + + + + + \n"
                "Type the number or name of the location.";

        awaitingRegionChoice = false;
        awaitingCuisineLocationChoice = true;
      } else {
        content =
            "⚠️ Invalid region. Please choose a valid option:\n\n" +
            regions
                .asMap()
                .entries
                .map((e) => "${emojis[e.key]} ${e.value}")
                .join("\n");
      }
    }
    // ------------------ Cuisine Location Selection ------------------
    else if (awaitingCuisineLocationChoice) {
      final locations = await fetchLocations();
      List<String> locationOptions = ["All", ...locations];
      String? chosenLocation;
      int? index;

      if (emojis.contains(opt)) {
        index = emojis.indexOf(opt);
      } else if (int.tryParse(opt) != null) {
        index = int.parse(opt) - 1;
      } else {
        // ค้นหาจากชื่อ location
        for (var location in locationOptions) {
          if (location.toLowerCase().contains(opt)) {
            chosenLocation = location;
            break;
          }
        }
      }

      if (index != null && index >= 0 && index < locationOptions.length) {
        chosenLocation = locationOptions[index];
      }

      if (chosenLocation != null) {
        // เรียก API เพื่อดึงข้อมูลร้านอาหารตาม cuisine, region (ถ้ามี) และ location
        final restaurants = await fetchRestaurantsByCuisineAndLocation(
          cuisine: selectedCuisine,
          region: selectedRegion,
          location: chosenLocation == "All" ? null : chosenLocation,
        );

        if (restaurants.isNotEmpty) {
          content =
              "🍽 Restaurants Found:\n"
              "+ + + + + + + + + + + + + + + + + + \n"
              "Cuisine: ${selectedCuisine ?? 'All'}\n"
              "${selectedRegion != null ? 'Region: $selectedRegion\n' : ''}"
              "Location: ${chosenLocation ?? 'All'}\n"
              "+ + + + + + + + + + + + + + + + + + \n";

          int index = 1;
          for (var r in restaurants) {
            String numberIcon = "${index}️⃣";
            content += "━━━━━━━━━━━━━━━━━━━━\n";
            content += "$numberIcon ${r['restaurant_name']}\n";
            content += "Location: ${r['location']}\n";
            content += "Category: ${r['category']}\n";
            content += "Cuisine: ${r['cuisine_by_nation']}\n";
            if (r['region'] != null) content += "Region: ${r['region']}\n";
            content +=
                "Rating: ${r['rating_overall_avg'] != null ? double.tryParse(r['rating_overall_avg'].toString())?.toStringAsFixed(1) ?? 'N/A' : 'N/A'}\n";
            content += "Hours: ${r['operating_hours'] ?? 'Not specified'}\n";
            content += "Phone: ${r['phone_number'] ?? 'Not provided'}\n";
            index++;
          }
          content += " + + + + + + + + + + + + + + + + + + ";
        } else {
          content += "⚠️ No restaurants found for the selected criteria.\n";
          content += "+ + + + + + + + + + + + + + + + + + \n";
        }

        // รีเซ็ต state หลังจากแสดงผล
        content +=
            "💬 You can type commands like:\n"
            "1️⃣ Category\n2️⃣ Cuisine by Nation\n3️⃣ Diet Type\n"
            "4️⃣ Restaurant Type\n5️⃣ Service Type\n6️⃣ Exit\n"
            "Type the number or name of the information you want to see."
            "\n + + + + + + + + + + + + + + + + + + \n";
        awaitingCuisineLocationChoice = false;
        selectedCuisine = null;
        selectedRegion = null;
        awaitingRestaurantChoice = true; // ออกจากโหมด restaurant
      } else {
        content =
            "⚠️ Invalid location."
                "\n+ + + + + + + + + + + + + + + + + + \n"
                "Please choose a valid option:\n" +
            locationOptions
                .asMap()
                .entries
                .map((e) => "${emojis[e.key]} ${e.value}")
                .join("\n") +
            "\n+ + + + + + + + + + + + + + + + + + \n"
                "Type the number or name of the information you want to see.";
      }
    }
    // ------------------ Category Selection ------------------
    else if (awaitingCategoryChoice) {
      final categories = await fetchCategories();
      List<String> categoryOptions = ["All", ...categories];

      String? chosenCategory;
      int? index;

      if (emojis.contains(opt)) {
        index = emojis.indexOf(opt);
      } else if (int.tryParse(opt) != null) {
        index = int.parse(opt) - 1;
      } else {
        for (var category in categoryOptions) {
          if (category.toLowerCase().contains(opt)) {
            chosenCategory = category;
            break;
          }
        }
      }

      if (index != null && index >= 0 && index < categoryOptions.length) {
        chosenCategory = categoryOptions[index];
      }

      if (chosenCategory != null) {
        selectedCategory = chosenCategory == "All" ? null : chosenCategory;

        final locations = await fetchLocations();
        List<String> locationOptions = ["All", ...locations];
        content =
            "📍 Please Choose Locations:\n"
                "+ + + + + + + + + + + + + + + + + + \n" +
            locationOptions
                .asMap()
                .entries
                .map((e) => "${emojis[e.key]} ${e.value}")
                .join("\n") +
            "\n+ + + + + + + + + + + + + + + + + + \n"
                "Type the number or name of the location.";
        awaitingCategoryChoice = false;
        awaitingLocationChoice = true;
      } else {
        content =
            "⚠️ Invalid category. Please choose a valid option:\n\n" +
            categoryOptions
                .asMap()
                .entries
                .map((e) => "${emojis[e.key]} ${e.value}")
                .join("\n");
      }
    }
    // ------------------ Location Selection (สำหรับ Category) ------------------
    else if (awaitingLocationChoice) {
      final locations = await fetchLocations();
      List<String> locationOptions = ["All", ...locations];
      String? chosenLocation;
      int? index;

      if (emojis.contains(opt)) {
        index = emojis.indexOf(opt);
      } else if (int.tryParse(opt) != null) {
        index = int.parse(opt) - 1;
      } else {
        for (var location in locationOptions) {
          if (location.toLowerCase().contains(opt)) {
            chosenLocation = location;
            break;
          }
        }
      }

      if (index != null && index >= 0 && index < locationOptions.length) {
        chosenLocation = locationOptions[index];
      }

      if (chosenLocation != null) {
        final restaurants = await fetchRestaurants2(
          selectedCategory,
          chosenLocation == "All" ? null : chosenLocation,
        );

        if (restaurants.isNotEmpty) {
          content =
              "🍽 Total Restaurants:\n"
              "+ + + + + + + + + + + + + + + + + + \n"
              "Location: ${chosenLocation ?? 'All Locations'}\n"
              "Category: ${selectedCategory ?? 'All Categories'}\n"
              "+ + + + + + + + + + + + + + + + + + \n";

          int index = 1;
          for (var r in restaurants) {
            String numberIcon = "${index}️⃣";
            content += "━━━━━━━━━━━━━━━━━━━━\n";
            content += "$numberIcon ${r['restaurant_name']}\n";
            content += "Location: ${r['location']}\n";
            content +=
                "Rating: ${r['rating_overall_avg'] != null ? double.tryParse(r['rating_overall_avg'].toString())?.toStringAsFixed(1) ?? 'N/A' : 'N/A'}\n";
            content += "Hours: ${r['operating_hours'] ?? 'Not specified'}\n";
            content += "Phone: ${r['phone_number'] ?? 'Not provided'}\n";
            index++;
          }
          content += "\n + + + + + + + + + + + + + + + + + + ";
        } else {
          content += "⚠️ No restaurants found.\n";
          content += " + + + + + + + + + + + + + + + + + +\n ";
        }

        content +=
            "💬 You can type commands like:\n"
            "1️⃣ Category\n2️⃣ Cuisine by Nation\n3️⃣ Diet Type\n"
            "4️⃣ Restaurant Type\n5️⃣ Service Type\n6️⃣ Exit\n"
            " + + + + + + + + + + + + + + + + + +\n "
            "Type the number or name of the information you want to see.";

        awaitingLocationChoice = false;
        selectedCategory = null;
        awaitingRestaurantChoice = true;
      } else {
        content =
            "⚠️ Invalid location. Please choose a valid option:\n\n" +
            locationOptions
                .asMap()
                .entries
                .map((e) => "${emojis[e.key]} ${e.value}")
                .join("\n");
      }
    }
    // ------------------ Menu Options หลัก ------------------
    else if (RegExp(r'^1$').hasMatch(opt) || opt.contains('category')) {
      final categories = await fetchCategories();
      content =
          "📂 Please choose Categories:\n"
              "+ + + + + + + + + + + + + + + + + + \n" +
          ["All", ...categories]
              .asMap()
              .entries
              .map((e) => "${emojis[e.key]} ${e.value}")
              .join("\n") +
          "\n+ + + + + + + + + + + + + + + + + + \n"
              "Type the number or name of the category.";
      awaitingCategoryChoice = true;
    } else if (RegExp(r'^2$').hasMatch(opt) || opt.contains('cuisine')) {
      List<String> cuisines = [
        "THAI",
        "CHINESE",
        "JAPANESE",
        "KOREAN",
        "INDIAN",
        "ITALIAN",
        "FRENCH",
        "MEXICAN",
        "AMERICAN",
        "VIETNAMESE",
        "OTHER",
      ];
      content =
          "🌏 Please choose Cuisine Nation:\n"
              "+ + + + + + + + + + + + + + + + + + \n" +
          cuisines
              .asMap()
              .entries
              .map((e) => "${emojis[e.key]} ${e.value}")
              .join("\n") +
          "\n+ + + + + + + + + + + + + + + + + + \n"
              "Type the number or name of the cuisine.";
      awaitingCuisineChoice = true;
    } else if (RegExp(r'^3$').hasMatch(opt) || opt.contains('diet')) {
      List<String> dietTypes = ["HALAL", "VEGETARIAN", "GENERAL"];
      content =
          "🥗 Please choose Diet Type:\n"
              "+ + + + + + + + + + + + + + + + + + \n" +
          dietTypes
              .asMap()
              .entries
              .map((e) => "${emojis[e.key]} ${e.value}")
              .join("\n") +
          "\n+ + + + + + + + + + + + + + + + + + \n"
              "Type the number or name of the diet type.";
      awaitingDietTypeChoice = true;
    } else if (RegExp(r'^4$').hasMatch(opt) ||
        opt.contains('restaurant type')) {
      List<String> restaurantTypes = [
        "Cafeteria",
        "Mini-Mart",
        "Cafe",
        "Restaurant",
      ];
      content =
          "🏢Choose Restaurant Type:\n"
              "+ + + + + + + + + + + + + + + + + + \n" +
          restaurantTypes
              .asMap()
              .entries
              .map((e) => "${emojis[e.key]} ${e.value}")
              .join("\n") +
          "\n+ + + + + + + + + + + + + + + + + + \n"
              "Type the number or name of the restaurant type.";
      awaitingRestaurantTypeChoice = true;
    } else if (RegExp(r'^5$').hasMatch(opt) || opt.contains('service')) {
      List<String> serviceTypes = ["Delivery", "Dine-in", "All"];
      content =
          "🛎 Please choose Service Type:\n"
              "+ + + + + + + + + + + + + + + + + + \n" +
          serviceTypes
              .asMap()
              .entries
              .map((e) => "${emojis[e.key]} ${e.value}")
              .join("\n") +
          "\n+ + + + + + + + + + + + + + + + + + \n"
              "Type the number or name of the service type.";
      awaitingServiceTypeChoice = true;
    } else if (RegExp(r'^6$').hasMatch(opt) || opt.contains('exit')) {
      content =
          " + + + + + + + + + + + + + + + + + + \n"
          "You can type commands like:\n"
          "1️⃣ User Information\n"
          "2️⃣ Restaurant Recommendetion\n"
          "3️⃣ Dashboard Overview\n"
          " + + + + + + + + + + + + + + + + + +  \n"
          "   For other questions outside your account or the app, please use the Atlas model.";
      awaitingRestaurantChoice = false;
    } else {
      content =
          "⚠️ Please select a valid option.\n"
          "+ + + + + + + + + + + + + + + + + + \n"
          "💬 You can type commands like:\n"
          "1️⃣ Category\n2️⃣ Cuisine by Nation\n3️⃣ Diet Type\n"
          "4️⃣ Restaurant Type\n5️⃣ Service Type\n6️⃣ Exit\n"
          "+ + + + + + + + + + + + + + + + + + \n"
          "Type the number or name of the information you want to see.";
    }

    setState(() {
      _messages.add({
        "role": "bot",
        "content": content,
        "timestamp": DateTime.now().toString(),
        "shouldAnimate": true,
      });
      _isLoading = false;
      _isBotTyping = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
  }

  // เพิ่มฟังก์ชัน API สำหรับดึงข้อมูลตาม Restaurant Type
  Future<List<dynamic>> fetchRestaurantsByRestaurantTypeAndLocation({
    required String? restaurantType,
    required String? location,
  }) async {
    try {
      String url =
          "http://172.22.173.39:8080/restaurants/restaurant_type/search?";

      if (restaurantType != null && restaurantType != "All") {
        url += "restaurant_type=$restaurantType&";
      }
      if (location != null && location != "All") {
        url += "location=$location&";
      }

      if (url.endsWith('&')) {
        url = url.substring(0, url.length - 1);
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load restaurants: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching restaurants by restaurant type: $e');
      return [];
    }
  }

  Future<List<dynamic>> fetchRestaurantsByDietAndLocation({
    required String? dietType,
    required String? location,
  }) async {
    try {
      String url = "http://172.22.173.39:8080/restaurants/diet-types/search?";

      if (dietType != null && dietType != "All") {
        url += "diet=$dietType&";
      }
      if (location != null && location != "All") {
        url += "location=$location&";
      }

      if (url.endsWith('&')) {
        url = url.substring(0, url.length - 1);
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load restaurants: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching restaurants by diet: $e');
      return [];
    }
  }

  Future<List<dynamic>> fetchRestaurantsByServiceTypeAndLocation({
    required String? serviceType,
    required String? location,
  }) async {
    try {
      String url = "http://172.22.173.39:8080/restaurants/service-type/search?";

      if (serviceType != null) {
        url += "servicetype=$serviceType&";
      }
      if (location != null && location != "All") {
        url += "location=$location&";
      }

      if (url.endsWith('&')) {
        url = url.substring(0, url.length - 1);
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load restaurants: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching restaurants by diet: $e');
      return [];
    }
  }

  // ฟังก์ชันสำหรับดึงข้อมูลร้านอาหารตาม cuisine, region และ location
  Future<List<dynamic>> fetchRestaurantsByCuisineAndLocation({
    required String? cuisine,
    required String? region,
    required String? location,
  }) async {
    try {
      String url = "http://172.22.173.39:8080/restaurants/cuisine/search?";

      if (cuisine != null && cuisine != "All") {
        url += "cuisine=$cuisine&";
      }
      if (region != null) {
        url += "region=$region&";
      }
      if (location != null && location != "All") {
        url += "location=$location&";
      }

      // ลบ & สุดท้ายถ้ามี
      if (url.endsWith('&')) {
        url = url.substring(0, url.length - 1);
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load restaurants: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching restaurants: $e');
      return [];
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
                            builder: (context) => ProfilePageUser(),
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
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.only(bottom: 8, top: 16),
                  child: Column(
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
                        final shouldAnimate =
                            (msg['shouldAnimate'] ?? false)
                                as bool; // ดึงค่า shouldAnimate

                        return ChatBubble(
                          message: content,
                          isUser: isUser,
                          onTextUpdate: scrollToBottom,
                          onTypingComplete: () {
                            // ✅ รีเซ็ตสถานะการพิมพ์เมื่อพิมพ์เสร็จ
                            setState(() {
                              _isBotTyping = false;
                            });
                          }, // เรียก scrollToBottom เมื่อข้อความอัพเดต
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
                          shouldAnimate:
                              shouldAnimate, // ส่งค่าไปยัง ChatBubble
                        );
                      }).toList(),

                      // แสดงตัวบ่งชี้การพิมพ์หากกำลังโหลด
                      if (_isLoading)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: TypingIndicator(),
                        ),
                    ],
                  ),
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
            isBotTyping: _isBotTyping, // ส่งค่าไป
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
              MaterialPageRoute(builder: (context) => userChatbotScreen()),
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
          MaterialPageRoute(builder: (context) => RestaurantListPageUser()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LeaderboardPageUser()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ThreadsUserPage()),
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

String _formatTime(String timestamp) {
  try {
    final dateTime = DateTime.parse(timestamp);
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  } catch (e) {
    return '';
  }
}

class ChatBubble extends StatefulWidget {
  final String message;
  final bool isUser;
  final bool isError;
  final String timestamp;
  final int? userId;
  final bool showModelSelector; // Add this
  final Function(bool) onToggleModelSelector; // Add this
  final String current_model;
  final bool shouldAnimate; // เพิ่มพารามิเตอร์นี้
  final VoidCallback? onTextUpdate; // เพิ่ม callback ใหม่
  final VoidCallback? onTypingComplete; // เพิ่ม callback ใหม่

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
    this.onTextUpdate,
    this.onTypingComplete, // เพิ่มพารามิเตอร์นี้
    this.shouldAnimate = false, // ค่าเริ่มต้นเป็น false
  }) : super(key: key);

  _ChatBubbleState createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _typingComplete = false;

  @override
  void initState() {
    super.initState();
    _typingComplete = !widget.shouldAnimate;
  }

  void _handleTypingComplete() {
    setState(() {
      _typingComplete = true;
    });

    // ✅ แจ้งไปยัง parent ว่าพิมพ์เสร็จ
    if (widget.onTypingComplete != null) {
      widget.onTypingComplete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Column(
        crossAxisAlignment: widget.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                mainAxisAlignment: widget.isUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!widget.isUser && !widget.isError)
                    GestureDetector(
                      onTap: () {
                        widget.onToggleModelSelector(!widget.showModelSelector);
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

                  Flexible(
                    child: Column(
                      crossAxisAlignment: widget.isUser
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
                            color: widget.isError
                                ? Colors.red[100]?.withOpacity(0.9)
                                : widget.isUser
                                ? Color(0xFF4A5568)
                                : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                              bottomLeft: widget.isUser
                                  ? Radius.circular(20)
                                  : Radius.circular(8),
                              bottomRight: widget.isUser
                                  ? Radius.circular(8)
                                  : Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  widget.isUser ? 0.3 : 0.1,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                                spreadRadius: 0.5,
                              ),
                            ],
                            border: widget.isUser
                                ? null
                                : Border.all(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                          ),
                          child:
                              widget.isUser ||
                                  _typingComplete ||
                                  !widget.shouldAnimate
                              ? Text(
                                  widget.message,
                                  style: TextStyle(
                                    color: widget.isError
                                        ? Colors.red[900]
                                        : widget.isUser
                                        ? Colors.white
                                        : Color(0xFF2D3748),
                                    fontSize: 14,
                                    height: 1.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                )
                              : TypewriterText(
                                  text: widget.message,
                                  style: TextStyle(
                                    color: widget.isError
                                        ? Colors.red[900]
                                        : widget.isUser
                                        ? Colors.white
                                        : Color(0xFF2D3748),
                                    fontSize: 14,
                                    height: 1.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  onComplete: _handleTypingComplete,

                                  onTextUpdate:
                                      widget.onTextUpdate, // ส่ง callback ไป
                                  onTypingComplete: () {
                                    // แจ้งไปยัง parent ว่าพิมพ์เสร็จ
                                    if (widget.onTypingComplete != null) {
                                      widget.onTypingComplete!();
                                    }
                                  },
                                  typingSpeed:
                                      20, // ตั้งค่าให้ช้าลง (ค่ามาก = ช้าลง)
                                ),
                        ),

                        Padding(
                          padding: EdgeInsets.only(
                            top: 6,
                            right: widget.isUser ? 8 : 0,
                            left: widget.isUser ? 0 : 8,
                          ),
                          child: Text(
                            _formatTime(widget.timestamp),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (widget.isUser) SizedBox(width: 10),

                  if (widget.isUser && !widget.isError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 6),
                      child: FutureBuilder<String?>(
                        future: widget.userId != null
                            ? fetchProfilePicture(widget.userId!)
                            : Future.value(null),
                        builder: (context, snapshot) {
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
  final bool isBotTyping; // เพิ่มพารามิเตอร์นี้

  MessageInputField({
    Key? key,
    required this.controller,
    required this.onSend,
    required this.isLoading,
    required this.isBotTyping, // รับค่า isBotTyping
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
                      onSubmitted: (_) {
                        // ตรวจสอบว่า AI กำลังพิมพ์หรือไม่
                        if (!isBotTyping && !isLoading) {
                          onSend();
                        }
                      },
                      style: TextStyle(fontSize: 16),
                      // ปิดกั้นการพิมพ์ขณะ AI กำลังทำงาน
                      enabled: !isBotTyping && !isLoading,
                    ),
                  ),

                  // แสดงตัวบ่งชี้ตามสถานะ
                  if (isLoading)
                    Padding(
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
                  else if (isBotTyping)
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color:
                              Colors.grey[400], // สีเทาเพื่อแสดงว่าถูกปิดกั้น
                        ),
                      ),
                    )
                  else
                    IconButton(
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

// เพิ่มคลาส TypewriterText สำหรับแสดงข้อความทีละตัวอักษร
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final VoidCallback onComplete;
  final VoidCallback? onTypingComplete; // เพิ่ม callback ใหม่
  final VoidCallback? onTextUpdate; // เพิ่มพารามิเตอร์นี้
  final int typingSpeed; // เพิ่มพารามิเตอร์ความเร็ว

  const TypewriterText({
    Key? key,
    required this.text,
    required this.style,
    required this.onComplete,
    this.onTypingComplete, // เพิ่มพารามิเตอร์นี้
    this.onTextUpdate,
    this.typingSpeed = 20, // ค่าเริ่มต้น 50 milliseconds ต่อตัวอักษร (ช้าลง)
  }) : super(key: key);

  @override
  _TypewriterTextState createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _controller;
  String _displayText = '';
  int _currentIndex = 0;

  bool get wantKeepAlive => true; // ต้องการรักษาสถานะ
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(
        milliseconds: widget.typingSpeed,
      ), // ความเร็วในการพิมพ์
      vsync: this,
    )..addListener(_updateText);

    _startTyping();
  }

  void _updateText() {
    if (_currentIndex < widget.text.length) {
      // ใช้เทคนิค batch update
      _displayText += widget.text[_currentIndex];
      _currentIndex++;

      // อัพเดท UI ทุก 3 ตัวอักษร (ลด frequency)
      if (_currentIndex % 1 == 0 || _currentIndex >= widget.text.length) {
        setState(() {});
      }

      if (widget.onTextUpdate != null && _currentIndex % 5 == 0) {
        widget.onTextUpdate!(); // ลดความถี่ของการ scroll
      }
    } else {
      _controller.stop();
      widget.onComplete();
      if (widget.onTypingComplete != null) {
        widget.onTypingComplete!();
      }
    }
  }

  void _startTyping() {
    _controller.repeat();
  }

  // void _updateText() {
  //   if (_currentIndex < widget.text.length) {
  //     setState(() {
  //       _displayText += widget.text[_currentIndex];
  //       _currentIndex++;
  //     });
  //   } else {
  //     _controller.stop();
  //     widget.onComplete();
  //   }
  // }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayText, style: widget.style);
  }
}
