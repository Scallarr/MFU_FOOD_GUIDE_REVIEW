import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myapp/home.dart';

class RestaurantDetailPage extends StatefulWidget {
  final int restaurantId; // รับ ID ของร้าน

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
        child: Column(
          children: [
            Image.network(restaurant!.photoUrl),
            SizedBox(height: 10),
            Text(restaurant!.location, style: TextStyle(fontSize: 16)),
            Text(restaurant!.operatingHours, style: TextStyle(fontSize: 14)),
            // เพิ่มได้เรื่อยๆ เช่น เบอร์โทร, คะแนน, หมวดอาหาร ฯลฯ
          ],
        ),
      ),
    );
  }
}
