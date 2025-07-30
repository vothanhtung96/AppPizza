class ReviewModel {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String userImage;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final List<String> images;
  
  // Thông tin sản phẩm từ FoodItems
  final String productName;
  final String productImage;
  final double productPrice;
  final String productCategory;

  ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.images = const [],
    required this.productName,
    required this.productImage,
    required this.productPrice,
    required this.productCategory,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'images': images,
      'productName': productName,
      'productImage': productImage,
      'productPrice': productPrice,
      'productCategory': productCategory,
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ReviewModel(
      id: documentId,
      productId: map['productId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userImage: map['userImage'] ?? '',
      rating: _parseDouble(map['rating']),
      comment: map['comment'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      images: List<String>.from(map['images'] ?? []),
      productName: map['productName'] ?? '',
      productImage: map['productImage'] ?? '',
      productPrice: _parseDouble(map['productPrice']),
      productCategory: map['productCategory'] ?? '',
    );
  }

  // Helper method để parse double an toàn
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('❌ Error parsing double from string "$value": $e');
        return 0.0;
      }
    }
    print('❌ Unknown type for double parsing: ${value.runtimeType}');
    return 0.0;
  }
} 