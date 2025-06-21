class RestaurantModel {
  final String name;
  final String photoUrl;
  final String location;
  final String category;
  final double ratingOverall;
  final double ratingHygiene;
  final double ratingFlavor;
  final double ratingService;

  RestaurantModel({
    required this.name,
    required this.photoUrl,
    required this.location,
    required this.category,
    required this.ratingOverall,
    required this.ratingHygiene,
    required this.ratingFlavor,
    required this.ratingService,
  });

  // Optional: for future use when fetching from backend
  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      name: json['name'],
      photoUrl: json['photo_url'],
      location: json['location'],
      category: json['category'],
      ratingOverall: (json['rating_overall'] ?? 0).toDouble(),
      ratingHygiene: (json['rating_hygiene'] ?? 0).toDouble(),
      ratingFlavor: (json['rating_flavor'] ?? 0).toDouble(),
      ratingService: (json['rating_service'] ?? 0).toDouble(),
    );
  }
}
