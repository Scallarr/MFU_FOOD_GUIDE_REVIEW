class Restaurant {
  final int id;
  final String name;
  final String location;
  final String operatingHours;
  final String phoneNumber;
  final String photoUrl;
  final String category;
  // final int totalLikes;
  final double ratingOverall;
  final double ratingHygiene;
  final double ratingFlavor;
  final double ratingService;
  final List<Review> reviews;
  final List<Menu> menus;

  Restaurant({
    required this.id,
    required this.name,
    required this.location,
    required this.operatingHours,
    required this.phoneNumber,
    required this.photoUrl,
    required this.category,
    // required this.totalLikes,
    required this.ratingOverall,
    required this.ratingHygiene,
    required this.ratingFlavor,
    required this.ratingService,
    required this.reviews,
    required this.menus,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['Restaurant_ID'],
      name: json['restaurant_name'],
      location: json['location'],
      operatingHours: json['operating_hours'],
      phoneNumber: json['phone_number'],
      photoUrl: json['photos'],
      category: json['category'],
      ratingOverall: double.parse(json['rating_overall_avg']),
      ratingHygiene: double.parse(json['rating_hygiene_avg']),
      ratingFlavor: double.parse(json['rating_flavor_avg']),
      ratingService: double.parse(json['rating_service_avg']),
      reviews: (json['reviews'] as List)
          .map((e) => Review.fromJson(e))
          .toList(),
      menus: (json['menus'] as List).map((e) => Menu.fromJson(e)).toList(),
    );
  }
}

class Review {
  final int id;
  final double ratingOverall;
  final String comment;
  final String username;
  final String pictureUrl;
  final int totalLikes;
  final String createdAt;

  Review({
    required this.id,
    required this.ratingOverall,
    required this.comment,
    required this.username,
    required this.pictureUrl,
    required this.totalLikes,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['Review_ID'],
      ratingOverall: double.parse(json['rating_overall'].toString()),
      comment: json['comment'],
      username: json['username'] ?? 'Anonymous',
      pictureUrl:
          json['picture_url'] ??
          'https://www.gravatar.com/avatar/placeholder?d=mp',
      totalLikes: json['total_likes'] ?? 0,
      createdAt: json['created_at'] ?? '',
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
