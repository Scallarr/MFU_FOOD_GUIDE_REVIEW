import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/Dashboard.dart';
import 'package:myapp/leaderboard.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/threads.dart';

// Model ร้านอาหาร
class Restaurant {
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

  Restaurant({
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
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
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
    );
  }
}

class RestaurantListPage extends StatefulWidget {
  @override
  _RestaurantListPageState createState() => _RestaurantListPageState();
}

class _RestaurantListPageState extends State<RestaurantListPage> {
  late Future<List<Restaurant>> futureRestaurants;
  List<Restaurant> allRestaurants = [];
  String searchQuery = '';
  String sortBy = ''; // 'rating' (location และ category จะใช้ filter แยก)
  bool ratingAscending = false; // false = มากไปน้อย, true = น้อยไปมาก
  String? filterLocation; // ตัวกรอง location
  String? filterCategory; // ตัวกรองประเภทอาหาร
  String? profileImageUrl;
  int? userId;

  // สถานที่ให้เลือกกรอง
  final List<String> locationOptions = [
    'D1',
    'E1',
    'E2',
    'C5',
    'S2',
    'M-SQUARE',
    'LAMDUAN',
  ];

  // ประเภทอาหารให้เลือกกรอง
  final List<String> categoryOptions = ['Main_dish', 'Snack', 'Drinks'];

  final double buttonHeight = 36;
  final double buttonWidth = 137; // กำหนดความกว้างปุ่มเท่ากัน
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    loadUserIdAndFetchProfile();
    futureRestaurants = fetchRestaurants();
    futureRestaurants.then((list) {
      setState(() {
        allRestaurants = list;
      });
    });
  }

  Future<void> loadUserIdAndFetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getInt('userId');

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
          profileImageUrl = data['picture_url'];
        });
      } else {
        print('Failed to load profile picture');
      }
    } catch (e) {
      print('Error fetching profile picture: $e');
    }
  }

  Future<List<Restaurant>> fetchRestaurants() async {
    final response = await http.get(
      Uri.parse('https://mfu-food-guide-review.onrender.com/restaurants'),
    );

    if (response.statusCode == 200) {
      List jsonList = json.decode(response.body);
      return jsonList.map((json) => Restaurant.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load restaurants');
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

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LeaderboardPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ThreadsPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MFU Food Guide'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: profileImageUrl == null
                ? CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    child: Icon(Icons.person, color: Colors.white),
                  )
                : CircleAvatar(
                    backgroundImage: NetworkImage(profileImageUrl!),
                    backgroundColor: Colors.grey[300],
                  ),
          ),
        ],
      ),
      body: FutureBuilder<List<Restaurant>>(
        future: futureRestaurants,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              allRestaurants.isEmpty) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError && allRestaurants.isEmpty) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (allRestaurants.isEmpty) {
            return Center(child: Text('No restaurants found'));
          } else {
            final restaurantsToShow = filteredAndSortedRestaurants;

            return Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search restaurants...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),

                // Row รวม dropdown และปุ่ม sort
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // ปุ่ม sort Rating (กดวน 3 ครั้ง)
                      SizedBox(
                        width: buttonWidth,
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
                              : Icon(
                                  Icons.star,
                                  size: 20,
                                  color: Colors.yellow,
                                ),
                          onTap: () {
                            setState(() {
                              if (sortBy != 'rating') {
                                sortBy = 'rating';
                                ratingAscending = false; // มากไปน้อย
                              } else {
                                if (!ratingAscending) {
                                  ratingAscending = true; // น้อยไปมาก
                                } else {
                                  sortBy = ''; // ยกเลิกการเลือก
                                }
                              }
                            });
                          },
                        ),
                      ),

                      SizedBox(width: 7),

                      // Dropdown Location
                      SizedBox(
                        width: buttonWidth,
                        child: Container(
                          height: buttonHeight,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
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
                                191,
                                98,
                                51,
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
                                            : const Color.fromARGB(
                                                255,
                                                0,
                                                0,
                                                0,
                                              ),
                                      ),
                                      SizedBox(width: 2),
                                      Text('All Location'),
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
                                              ? const Color.fromARGB(
                                                  255,
                                                  0,
                                                  0,
                                                  0,
                                                )
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
                                fontSize: 14,
                                color: filterLocation == null
                                    ? const Color.fromARGB(221, 3, 3, 3)
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 7),

                      // Dropdown Food Type (category)
                      SizedBox(
                        width: buttonWidth,
                        child: Container(
                          height: buttonHeight,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
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
                                191,
                                98,
                                51,
                              ),
                              items: [
                                DropdownMenuItem(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.restaurant_menu,
                                        size: 18,
                                        color: filterCategory == null
                                            ? const Color.fromARGB(
                                                136,
                                                209,
                                                0,
                                                0,
                                              )
                                            : Colors.white,
                                      ),
                                      SizedBox(width: 6),
                                      Text('All Types'),
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
                                          size: 18,
                                          color: filterCategory == null
                                              ? Colors.black54
                                              : Colors.white,
                                        ),
                                        SizedBox(width: 6),
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
                                fontSize: 14,
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

                Expanded(
                  child: restaurantsToShow.isEmpty
                      ? Center(child: Text('No restaurants found'))
                      : ListView.builder(
                          itemCount: restaurantsToShow.length,
                          itemBuilder: (context, index) {
                            final res = restaurantsToShow[index];
                            return Card(
                              margin: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child: Image.network(
                                      res.photoUrl,
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                height: 180,
                                                color: Colors.grey[300],
                                              ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                res.name,
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.star,
                                                    color:
                                                        Colors.green.shade700,
                                                    size: 18,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    res.ratingOverall
                                                        .toStringAsFixed(1),
                                                    style: TextStyle(
                                                      color:
                                                          Colors.green.shade900,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              color: Colors.redAccent,
                                              size: 20,
                                            ),
                                            SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                '${res.location}, MFU',
                                                style: TextStyle(fontSize: 14),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    _getCategoryIcon(
                                                      res.category,
                                                    ),
                                                    size: 18,
                                                    color: Colors.orange[800],
                                                  ),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    res.category.replaceAll(
                                                      '_',
                                                      ' ',
                                                    ),
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.orange[800],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            _buildRatingItem(
                                              'Hygiene',
                                              res.ratingHygiene,
                                            ),
                                            _buildRatingItem(
                                              'Flavor',
                                              res.ratingFlavor,
                                            ),
                                            _buildRatingItem(
                                              'Service',
                                              res.ratingService,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          }
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Leaderboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Threads'),
        ],
      ),
    );
  }
}

Widget _buildRatingItem(String label, double rating) {
  return Row(
    children: [
      Icon(Icons.star, color: Colors.amber, size: 18),
      SizedBox(width: 4),
      Text('$label: ', style: TextStyle(fontWeight: FontWeight.w500)),
      Text(rating.toStringAsFixed(1), style: TextStyle(color: Colors.black87)),
    ],
  );
}

IconData _getCategoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'main_dish':
      return Icons.restaurant;
    case 'snack':
      return Icons.fastfood;
    case 'drinks':
      return Icons.local_cafe;
    default:
      return Icons.category;
  }
}

class SortButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? icon;

  const SortButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: icon ?? const SizedBox.shrink(),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(36),
        backgroundColor: selected ? Colors.black : Colors.white,
        foregroundColor: selected ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
