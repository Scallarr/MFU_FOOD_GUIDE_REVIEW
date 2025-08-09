// lib/models/restaurant.dart
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
    );
  }
}
