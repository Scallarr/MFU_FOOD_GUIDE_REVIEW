import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'restaurant_model.dart'; // <-- import model ที่สร้างไว้

class RestaurantDetailPage extends StatefulWidget {
  final int restaurantId;

  const RestaurantDetailPage({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  Restaurant? restaurant;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRestaurant();
  }

  Future<void> fetchRestaurant() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://mfu-food-guide-review.onrender.com/restaurant/${widget.restaurantId}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          restaurant = Restaurant.fromJson(data);
          isLoading = false;
        });
      } else {
        print('Failed to load restaurant');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || restaurant == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Restaurant Details')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(restaurant!.name)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              restaurant!.photoUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  restaurant!.name,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Icon(Icons.favorite, color: Colors.red),
              ],
            ),
            Chip(label: Text(restaurant!.category)),
            Row(
              children: [
                Icon(Icons.location_on, size: 16),
                SizedBox(width: 5),
                Text(restaurant!.location),
              ],
            ),
            Row(
              children: [
                Icon(Icons.access_time, size: 16),
                SizedBox(width: 5),
                Text('Open ${restaurant!.operatingHours}'),
              ],
            ),
            Row(
              children: [
                Icon(Icons.phone, size: 16),
                SizedBox(width: 5),
                Text(restaurant!.phoneNumber),
              ],
            ),
            Divider(height: 30),
            Text(
              'Overall Rating',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Text(
                  '${restaurant!.ratingOverall}',
                  style: TextStyle(fontSize: 18),
                ),
                Icon(Icons.star, color: Colors.amber),
              ],
            ),
            _buildRatingRow('Hygiene', restaurant!.ratingHygiene),
            _buildRatingRow('Flavor', restaurant!.ratingFlavor),
            _buildRatingRow('Service', restaurant!.ratingService),
            Divider(height: 30),
            Text('Menu', style: TextStyle(fontWeight: FontWeight.bold)),
            ...restaurant!.menus.map(
              (menu) => ListTile(
                leading: Image.network(
                  menu.imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
                title: Text(menu.nameTH),
                subtitle: Text('Price: ${menu.price} Bath'),
                trailing: Icon(Icons.clear),
              ),
            ),
            Divider(height: 30),
            Text('Reviews', style: TextStyle(fontWeight: FontWeight.bold)),
            ...restaurant!.reviews.map(
              (review) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(review.pictureUrl),
                  ),
                  title: Row(
                    children: [
                      Text(review.username),
                      Spacer(),
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      Text('${review.ratingOverall}'),
                    ],
                  ),
                  subtitle: Text(review.comment),
                ),
              ),
            ),

            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: เขียนรีวิว
                },
                child: Text('Write a Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(String label, double value) {
    int rounded = value.round();
    return Row(
      children: [
        Text('$label: '),
        ...List.generate(
          5,
          (index) => Icon(
            index < rounded ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 20,
          ),
        ),
      ],
    );
  }
}
