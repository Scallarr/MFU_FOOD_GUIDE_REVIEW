import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<dynamic> topUsers = [];
  List<dynamic> topRestaurants = [];

  @override
  void initState() {
    super.initState();
    fetchLeaderboard();
  }

  Future<void> fetchLeaderboard() async {
    final response = await http.get(
      Uri.parse('https://mfu-food-guide-review.onrender.com/leaderboard'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        topUsers = data['topUsers'];
        topRestaurants = data['topRestaurants'];
      });
    } else {
      print('Failed to load leaderboard');
    }
  }

  Widget buildUserCard(Map<String, dynamic> user, int rank) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage(user['profile_image_url']),
        ),
        title: Text('${user['username']} (Rank ${rank + 1})'),
        subtitle: Text(
          'Likes: ${user['total_likes']} | Reviews: ${user['total_reviews']}',
        ),
        trailing: Icon(Icons.star, color: Colors.amber),
      ),
    );
  }

  Widget buildRestaurantCard(Map<String, dynamic> restaurant, int rank) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            restaurant['restaurant_image_url'],
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        title: Text('${restaurant['restaurant_name']} (Rank ${rank + 1})'),
        subtitle: Text(
          'Rating: ${restaurant['overall_rating']} | Reviews: ${restaurant['total_reviews']}',
        ),
        trailing: Icon(Icons.restaurant, color: Colors.green),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Text(
              '🏆 Top Users',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ...topUsers.asMap().entries.map(
              (entry) => buildUserCard(entry.value, entry.key),
            ),
            const Divider(thickness: 2),
            const Text(
              '🍽️ Top Restaurants',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ...topRestaurants.asMap().entries.map(
              (entry) => buildRestaurantCard(entry.value, entry.key),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
