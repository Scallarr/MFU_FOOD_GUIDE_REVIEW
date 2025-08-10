// lib/models/restaurant.dart
class Restaurants {
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

  Restaurants({
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

  factory Restaurants.fromJson(Map<String, dynamic> json) {
    return Restaurants(
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

class Review {
  final int id;
  final double ratingOverall;
  final String comment;
  final String username;
  final String email;
  final String pictureUrl;
  final int totalLikes;
  final String createdAt;
  final bool isLiked;
  Review({
    required this.id,
    required this.ratingOverall,
    required this.comment,
    required this.username,
    required this.email,
    required this.pictureUrl,
    required this.totalLikes,
    required this.createdAt,
    required this.isLiked,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['Review_ID'],
      ratingOverall: double.parse(json['rating_overall'].toString()),
      comment: json['comment'],
      username: json['username'] ?? 'Anonymous',
      email: json['email'],
      pictureUrl:
          json['picture_url'] ??
          'https://www.gravatar.com/avatar/placeholder?d=mp',
      totalLikes: json['total_likes'] ?? 0,
      createdAt: json['created_at'] ?? '',
      isLiked: json['isLiked'] ?? false,
    );
  }
}

class Menu {
  final int id;
  final String nameTH;
  final String nameEN;
  final String price;
  final String imageUrl;

  Menu({
    required this.id,
    required this.nameTH,
    required this.nameEN,
    required this.price,
    required this.imageUrl,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      id: json['Menu_ID'],
      nameTH: json['menu_thai_name'],
      nameEN: json['menu_english_name'],
      price: json['price'],
      imageUrl: json['menu_img'],
    );
  }
}
