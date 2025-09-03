import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/Atlas-model.dart';
import 'package:myapp/admin/Admin-AddRestaurant.dart';
import 'package:myapp/admin/Admin-Dashboard.dart';
import 'package:myapp/admin/Admin-Leaderboard.dart';
import 'package:myapp/admin/Admin-Pending-all-Review.dart';
import 'package:myapp/admin/Admin-Pending_Review.dart';
import 'package:myapp/admin/Admin-Restaurant-Detail.dart';
import 'package:myapp/admin/Admin-Restaurant-History.dart';
import 'package:myapp/admin/Admin-Thread.dart';
import 'package:myapp/admin/Admin-profile-info.dart';
import 'package:myapp/dashboard.dart';
import 'package:myapp/Profileinfo.dart';
import 'package:myapp/leaderboard.dart';
import 'package:myapp/restaurantDetail.dart';
import 'package:myapp/admin/Admin-Edit-Restaurant.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/threads.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class Restaurant {
  final int id;
  final String name;
  final String location;
  final String operatingHours;
  final String phoneNumber;
  final String photoUrl;
  final double ratingOverall;
  final double ratingHygiene;
  final double ratingFlavor;
  final double ratingService;
  final String category;
  final int pendingReviewsCount;
  final int postedReviewsCount;

  Restaurant({
    required this.id,
    required this.name,
    required this.location,
    required this.operatingHours,
    required this.phoneNumber,
    required this.photoUrl,
    required this.ratingOverall,
    required this.ratingHygiene,
    required this.ratingFlavor,
    required this.ratingService,
    required this.category,
    required this.pendingReviewsCount,
    required this.postedReviewsCount,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['Restaurant_ID'],
      name: json['restaurant_name'],
      location: json['location'],
      operatingHours: json['operating_hours'],
      phoneNumber: json['phone_number'],
      photoUrl: json['photos'],
      ratingOverall: double.parse(json['rating_overall_avg'].toString()),
      ratingHygiene: double.parse(json['rating_hygiene_avg'].toString()),
      ratingFlavor: double.parse(json['rating_flavor_avg'].toString()),
      ratingService: double.parse(json['rating_service_avg'].toString()),
      category: json['category'],
      pendingReviewsCount: json['pending_reviews_count'] ?? 0,
      postedReviewsCount: json['posted_reviews_count'] ?? 0,
    );
  }
}

class RestaurantListPageAdmin extends StatefulWidget {
  @override
  _RestaurantListPageState createState() => _RestaurantListPageState();
  final bool reload;

  const RestaurantListPageAdmin({super.key, this.reload = false});
}

class _RestaurantListPageState extends State<RestaurantListPageAdmin> {
  late Future<List<Restaurant>> futureRestaurants;
  List<Restaurant> allRestaurants = [];
  String searchQuery = '';
  String sortBy = '';
  bool ratingAscending = false;
  String? filterLocation;
  String? filterCategory;
  String? profileImageUrl;
  int? userId;
  bool _isDeleting = false;

  final List<String> locationOptions = [
    'D1',
    'E1',
    'E2',
    'C5',
    'S2',
    'M-SQUARE',
    'LAMDUAN',
  ];

  final List<String> categoryOptions = ['Main_dish', 'Snack', 'Drinks'];

  final double buttonHeight = 36;
  final double buttonWidth = 137;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    loadUserIdAndFetchProfile();
    futureRestaurants = fetchRestaurants();
    futureRestaurants.then((list) {
      setState(() {
        allRestaurants = list;
        _precacheRestaurantImages();
      });
    });
  }

  void _precacheRestaurantImages() {
    for (var restaurant in allRestaurants) {
      try {
        precacheImage(
          CachedNetworkImageProvider(_validateImageUrl(restaurant.photoUrl)),
          context,
        );
      } catch (e) {
        debugPrint('Failed to precache image: ${restaurant.photoUrl}');
      }
    }
  }

  String _validateImageUrl(String url) {
    if (url.isEmpty) return 'https://via.placeholder.com/400';
    if (!url.startsWith('http')) return 'https://$url';
    return url;
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
          profileImageUrl = _validateImageUrl(data['picture_url']);
        });
      } else {
        debugPrint('Failed to load profile picture');
      }
    } catch (e) {
      debugPrint('Error fetching profile picture: $e');
    }
  }

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

  Future<void> _deleteRestaurant(int restaurantId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                'Delete Restaurant',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Are you sure you want to delete this restaurant?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(color: Colors.grey),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final response = await http.delete(
        Uri.parse(
          'https://mfu-food-guide-review.onrender.com/Delete/restaurants/$restaurantId',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restaurant deleted successfully!'),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
        _refreshRestaurantData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete restaurant: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  List<Restaurant> get filteredAndSortedRestaurants {
    List<Restaurant> filtered = allRestaurants.where((res) {
      final query = searchQuery.toLowerCase();
      final matchesSearch =
          res.name.toLowerCase().contains(query) ||
          res.location.toLowerCase().contains(query) ||
          res.category.toLowerCase().contains(query);

      final matchesLocation = filterLocation == null || filterLocation!.isEmpty
          ? true
          : res.location.toLowerCase() == filterLocation!.toLowerCase();

      final matchesCategory = filterCategory == null || filterCategory!.isEmpty
          ? true
          : res.category.toLowerCase() == filterCategory!.toLowerCase();

      return matchesSearch && matchesLocation && matchesCategory;
    }).toList();

    if (sortBy == 'rating') {
      filtered.sort(
        (a, b) => ratingAscending
            ? a.ratingOverall.compareTo(b.ratingOverall)
            : b.ratingOverall.compareTo(a.ratingOverall),
      );
    }

    return filtered;
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LeaderboardPageAdmin()),
        );
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
  Widget build(BuildContext context) {
    if (_isDeleting) {
      return Scaffold(
        backgroundColor: Colors.black.withOpacity(0.3),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final restaurantsToShow = filteredAndSortedRestaurants;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            toolbarHeight: 80,
            backgroundColor: const Color(0xFFCEBFA3),
            pinned: false,
            floating: true,
            snap: true,
            elevation: 6,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MFU FOOD GUIDE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
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
            ),
          ),

          // Search Bar
          // ในส่วนของ SliverPadding ที่มี Search Bar ให้เพิ่ม PopupMenuButton ด้านขวา
          SliverPadding(
            padding: const EdgeInsets.only(left: 10, right: 10, top: 14),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search restaurants...',
                        hintStyle: TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0).withOpacity(0.6),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Color(0xFF5D4037),
                        ),
                        filled: true,
                        fillColor: Color(0xFFF5F0E6),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color.fromARGB(255, 108, 76, 44),
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color.fromARGB(255, 122, 80, 38),
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color.fromARGB(255, 141, 71, 50),
                            width: 2.5,
                          ),
                        ),
                      ),
                      style: TextStyle(color: Color.fromARGB(255, 34, 31, 30)),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 4),
                  // เพิ่ม PopupMenuButton ตรงนี้
                  Container(
                    width: 30,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F0E6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border(),
                    ),
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Color(0xFF5D4037),
                        size: 30,
                      ),
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem(
                          value: 'approve',
                          child: Row(
                            children: [
                              Icon(Icons.reviews, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Approve Reviews'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'history',
                          child: Row(
                            children: [
                              Icon(Icons.history, color: Colors.green),
                              SizedBox(width: 8),
                              Text('My History'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (String value) {
                        if (value == 'approve') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RestaurantallPendingrewiewPage(),
                            ),
                          );
                        } else if (value == 'history') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RestaurantReviewHistoryPage(),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 4),
                ],
              ),
            ),
          ),

          // Filter Buttons
          SliverPadding(
            padding: const EdgeInsets.only(top: 15, left: 14),
            sliver: SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 105,
                      child: SortButton(
                        label: 'Rating',
                        selected: sortBy == 'rating',
                        icon: sortBy == 'rating'
                            ? Icon(
                                ratingAscending
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 20,
                                color: Colors.white,
                              )
                            : Icon(Icons.star, size: 20, color: Colors.yellow),
                        onTap: () {
                          setState(() {
                            if (sortBy != 'rating') {
                              sortBy = 'rating';
                              ratingAscending = false;
                            } else {
                              if (!ratingAscending) {
                                ratingAscending = true;
                              } else {
                                sortBy = '';
                              }
                            }
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 7),
                    SizedBox(
                      width: buttonWidth,
                      child: Container(
                        height: buttonHeight,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: filterLocation == null
                                ? const Color.fromARGB(255, 43, 43, 43)
                                : const Color.fromARGB(255, 248, 248, 248),
                            width: 1.0,
                          ),
                          color: filterLocation == null
                              ? Colors.white
                              : const Color.fromARGB(255, 0, 0, 0),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: filterLocation ?? '',
                            isExpanded: true,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: filterLocation == null
                                  ? Colors.black54
                                  : Colors.white,
                            ),
                            dropdownColor: const Color.fromARGB(
                              255,
                              203,
                              166,
                              136,
                            ),
                            items: [
                              DropdownMenuItem(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 19,
                                      color: filterLocation == null
                                          ? Colors.blue
                                          : const Color.fromARGB(255, 0, 0, 0),
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      'All location',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                value: '',
                              ),
                              ...locationOptions.map(
                                (loc) => DropdownMenuItem(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 20,
                                        color: filterLocation == null
                                            ? const Color.fromARGB(255, 0, 0, 0)
                                            : const Color.fromARGB(
                                                255,
                                                226,
                                                226,
                                                226,
                                              ),
                                      ),
                                      SizedBox(width: 3),
                                      Text(loc),
                                    ],
                                  ),
                                  value: loc,
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                filterLocation = value == '' ? null : value;
                              });
                            },
                            style: TextStyle(
                              fontSize: 12,
                              color: filterLocation == null
                                  ? const Color.fromARGB(221, 3, 3, 3)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 7),
                    SizedBox(
                      width: 125,
                      child: Container(
                        height: buttonHeight,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: filterCategory == null
                                ? const Color.fromARGB(255, 0, 0, 0)
                                : const Color.fromARGB(255, 248, 248, 248),
                            width: 1.0,
                          ),
                          color: filterCategory == null
                              ? Colors.white
                              : Colors.black,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: filterCategory ?? '',
                            isExpanded: true,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: filterCategory == null
                                  ? Colors.black54
                                  : Colors.white,
                            ),
                            dropdownColor: const Color.fromARGB(
                              255,
                              203,
                              166,
                              136,
                            ),
                            items: [
                              DropdownMenuItem(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.restaurant_menu,
                                      size: 17,
                                      color: filterCategory == null
                                          ? const Color.fromARGB(136, 209, 0, 0)
                                          : Colors.white,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'All Type',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                value: '',
                              ),
                              ...categoryOptions.map(
                                (cat) => DropdownMenuItem(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.restaurant_menu,
                                        size: 15,
                                        color: filterCategory == null
                                            ? const Color.fromARGB(137, 0, 0, 0)
                                            : Colors.white,
                                      ),
                                      SizedBox(width: 4),
                                      Text(cat.replaceAll('_', ' ')),
                                    ],
                                  ),
                                  value: cat,
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                filterCategory = value == '' ? null : value;
                              });
                            },
                            style: TextStyle(
                              fontSize: 11,
                              color: filterCategory == null
                                  ? const Color.fromARGB(221, 3, 3, 3)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Restaurant List
          _buildRestaurantListContent(),
        ],
      ),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 235, 188, 117),
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddRestaurantPage(userId: userId!),
            ),
          ).then((shouldRefresh) {
            if (shouldRefresh == true) {
              _refreshRestaurantData();
            }
          });
        },
      ),
    );
  }

  Widget _buildRestaurantListContent() {
    if (allRestaurants.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
      );
    }

    if (filteredAndSortedRestaurants.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            'No restaurants found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final res = filteredAndSortedRestaurants[index];
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          child: Material(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            clipBehavior: Clip.antiAlias,
            elevation: 14,
            child: InkWell(
              borderRadius: BorderRadius.circular(5),
              onTap: () async {
                try {
                  final shouldRefresh = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          RestaurantDetailAdminPage(restaurantId: res.id),
                    ),
                  );

                  if (shouldRefresh == true) {
                    _refreshRestaurantData();
                  }
                } catch (e) {
                  debugPrint('Navigation error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error during navigation')),
                  );
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  Stack(
                    children: [
                      // Hero Image with retryable cached network image
                      Container(
                        height: 230,
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: RetryableCachedImage(
                            imageUrl: res.photoUrl,
                            maxRetry: 3,
                          ),
                        ),
                      ),

                      // Dark overlay gradient
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.2),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Rating Badge
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 20,
                              ),
                              SizedBox(width: 6),
                              Text(
                                res.ratingOverall.toStringAsFixed(1),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Admin controls
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left side - Pending reviews or empty container
                            if (res.pendingReviewsCount > 0)
                              GestureDetector(
                                onTap: () async {
                                  final shouldRefresh = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PendingReviewsPage(
                                        restaurantId: res.id,
                                      ),
                                    ),
                                  );
                                  if (shouldRefresh) {
                                    _refreshRestaurantData();
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      255,
                                      224,
                                      50,
                                      50,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.hourglass_top_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        '${res.pendingReviewsCount} Pending',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Container(), // Empty container to maintain space
                            // Right side - Admin buttons
                            if (userId != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Edit button
                                  CircleAvatar(
                                    radius: 23,
                                    backgroundColor: Colors.white.withOpacity(
                                      0.9,
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.edit_rounded,
                                        size: 23,
                                        color: Colors.blue[700],
                                      ),
                                      onPressed: () =>
                                          _navigateToEditRestaurant(res),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                  SizedBox(width: 15),
                                  // Delete button
                                  CircleAvatar(
                                    radius: 23,
                                    backgroundColor: Colors.white.withOpacity(
                                      0.9,
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.delete_rounded,
                                        size: 23,
                                        color: Colors.red[700],
                                      ),
                                      onPressed: () =>
                                          _deleteRestaurant(res.id),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Content Section
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    res.name,
                                    style: TextStyle(
                                      fontSize: 22,
                                      color: Color(0xFF5D4037),
                                      fontWeight: FontWeight.w500,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_rounded,
                                        size: 16,
                                        color: Colors.red[400],
                                      ),
                                      SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${res.location}, MFU',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: const Color.fromARGB(
                                              255,
                                              100,
                                              98,
                                              98,
                                            ),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.verified_rounded,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Category Chip - Enhanced
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFF5F5F5),
                                    Color(0xFFE0E0E0),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: Color(0xFF9E9E9E),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.restaurant_menu_rounded,
                                    size: 18,
                                    color: Color(0xFF5D4037),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    res.category.replaceAll('_', ' '),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF3E2723),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Reviews Count - Enhanced
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF424242),
                                    Color(0xFF212121),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.reviews_rounded,
                                    size: 20,
                                    color: Color.fromARGB(255, 255, 254, 252),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    '${res.postedReviewsCount}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 2,
                                          offset: Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        // Rating Progress Bars
                        Column(
                          children: [
                            _buildRatingIndicator('Hygiene', res.ratingHygiene),
                            SizedBox(height: 8),
                            _buildRatingIndicator('Flavor', res.ratingFlavor),
                            SizedBox(height: 8),
                            _buildRatingIndicator('Service', res.ratingService),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }, childCount: filteredAndSortedRestaurants.length),
    );
  }

  Widget _buildRatingIndicator(String label, double rating) {
    final color = _getRatingColor(rating);
    final segments = 5;
    final segmentValue = rating / segments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            Text(
              rating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Row(
          children: List.generate(segments, (index) {
            final segmentWidth =
                (MediaQuery.of(context).size.width - 70) / segments;
            final segmentRating = (rating - index).clamp(0.0, 1.0);

            return Container(
              height: 12,
              width: segmentWidth,
              margin: EdgeInsets.only(right: index == segments - 1 ? 0 : 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(index == 0 ? 6 : 0),
                  right: Radius.circular(index == segments - 1 ? 6 : 0),
                ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: segmentWidth * segmentRating,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(index == 0 ? 6 : 0),
                      right: Radius.circular(index == segments - 1 ? 6 : 0),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green[800]!; // Excellent
    if (rating >= 4.0) return Colors.lightGreen[600]!; // Very Good
    if (rating >= 3.5) return Colors.lime[600]!; // Good
    if (rating >= 3.0) return Colors.amber[600]!; // Average
    if (rating >= 2.5) return Colors.orange[600]!; // Below Average
    if (rating >= 2.0) return Colors.deepOrange[600]!; // Poor
    return Colors.red[700]!; // Very Poor
  }

  void _navigateToEditRestaurant(Restaurant restaurant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRestaurant(
          userId: userId!,
          restaurantId: restaurant.id,
          currentData: restaurant,
        ),
      ),
    ).then((shouldRefresh) {
      if (shouldRefresh == true) {
        _refreshRestaurantData();
      }
    });
  }

  void _refreshRestaurantData() {
    setState(() {
      futureRestaurants = fetchRestaurants();
      futureRestaurants.then((list) {
        setState(() {
          allRestaurants = list;
          _precacheRestaurantImages();
        });
      });
    });
  }
}

class RetryableCachedImage extends StatefulWidget {
  final String imageUrl;
  final int maxRetry;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const RetryableCachedImage({
    required this.imageUrl,
    this.maxRetry = 3,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  });

  @override
  _RetryableCachedImageState createState() => _RetryableCachedImageState();
}

class _RetryableCachedImageState extends State<RetryableCachedImage> {
  int _retryCount = 0;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ?? _buildDefaultErrorWidget();
    }

    return CachedNetworkImage(
      imageUrl: _validateImageUrl(widget.imageUrl),
      width: widget.width,
      height: widget.height,
      fit: widget.fit ?? BoxFit.cover,
      cacheManager:
          RestaurantCacheManager.instance, // ใช้ Cache Manager ที่กำหนดเอง
      placeholder: (context, url) =>
          widget.placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, url, error) {
        if (_retryCount < widget.maxRetry) {
          Future.delayed(Duration(seconds: 1), () {
            _retryCount++;
            setState(() {});
          });
          return widget.placeholder ?? _buildDefaultPlaceholder();
        } else {
          _hasError = true;
          return widget.errorWidget ?? _buildDefaultErrorWidget();
        }
      },
      fadeInDuration: Duration(milliseconds: 300),
      fadeOutDuration: Duration(milliseconds: 300),
      httpHeaders: {'Cache-Control': 'max-age=31536000'}, // 1 ปีในหน่วยวินาที
    );
  }

  String _validateImageUrl(String url) {
    if (url.isEmpty) return 'https://via.placeholder.com/400';
    if (!url.startsWith('http')) return 'https://$url';
    return url;
  }

  Widget _buildDefaultPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        color: Colors.white,
        width: widget.width,
        height: widget.height,
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      color: Colors.grey[200],
      width: widget.width,
      height: widget.height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
            if (_retryCount < widget.maxRetry)
              TextButton(
                onPressed: () {
                  setState(() {
                    _retryCount++;
                    _hasError = false;
                  });
                },
                child: Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}

class SortButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? icon;
  final double fontSize;

  const SortButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.fontSize = 3,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: icon ?? const SizedBox.shrink(),
      label: Text(label, style: TextStyle(fontSize: 11)),
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(36),
        backgroundColor: selected ? Colors.black : Colors.white,
        foregroundColor: selected ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class RestaurantCacheManager {
  static const String key = 'restaurantImagesCache';
  static const Duration cacheDuration = Duration(days: 365); // 1 ปี
  static const int maxCacheObjects = 1000; // จำกัดจำนวนไฟล์สูงสุด

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: cacheDuration,
      maxNrOfCacheObjects: maxCacheObjects,
      repo: JsonCacheInfoRepository(databaseName: key),
    ),
  );
}
