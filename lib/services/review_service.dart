import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pizza_app_vs_010/models/review_model.dart';
import 'package:pizza_app_vs_010/service/shared_pref.dart';

class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy tất cả reviews của một sản phẩm
  Stream<List<ReviewModel>> getProductReviews(String productId) {
    print('🔍 ReviewService - Getting reviews for productId: $productId');
    return _firestore
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        // .orderBy('createdAt', descending: true) // Tạm thời bỏ để tránh index error
        .snapshots()
        .map((snapshot) {
          print(
            '📊 ReviewService - Found ${snapshot.docs.length} reviews for productId: $productId',
          );

          final reviews = snapshot.docs.map((doc) {
            final data = doc.data();
            print(
              '📝 ReviewService - Review data: productId=${data['productId']}, comment=${data['comment']}, userName=${data['userName']}',
            );
            return ReviewModel.fromMap(data, doc.id);
          }).toList();

          // Sort manually để tránh index error
          reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          print(
            '✅ ReviewService - Returning ${reviews.length} reviews for productId: $productId',
          );
          return reviews;
        })
        .handleError((error) {
          print('❌ ReviewService - Error in getProductReviews: $error');
          return <ReviewModel>[];
        });
  }

  // Lấy rating trung bình của sản phẩm
  Stream<double> getProductAverageRating(String productId) {
    return _firestore
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return 0.0;

          double totalRating = 0;
          for (var doc in snapshot.docs) {
            totalRating += (doc.data()['rating'] ?? 0).toDouble();
          }
          return totalRating / snapshot.docs.length;
        });
  }

  // Lấy số lượng reviews của sản phẩm
  Stream<int> getProductReviewCount(String productId) {
    return _firestore
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Lấy thông tin sản phẩm từ FoodItems
  Future<Map<String, dynamic>?> getProductInfo(String productId) async {
    try {
      final doc = await _firestore.collection('FoodItems').doc(productId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting product info: $e');
      return null;
    }
  }

  // Thêm review mới với thông tin sản phẩm
  Future<bool> addReview(ReviewModel review) async {
    try {
      print(
        '➕ ReviewService - Adding review for productId: ${review.productId}',
      );
      print('➕ ReviewService - Review userId: ${review.userId}');
      print('➕ ReviewService - Review userName: ${review.userName}');

      // Lấy thông tin sản phẩm từ FoodItems
      final productInfo = await getProductInfo(review.productId);
      if (productInfo == null) {
        print('❌ ReviewService - Product not found: ${review.productId}');
        return false;
      }

      print('✅ ReviewService - Product info found: ${productInfo['Name']}');

      // Tạo review data với thông tin sản phẩm
      final reviewData = {
        'productId': review.productId,
        'userId': review.userId,
        'userName': review.userName,
        'userImage': review.userImage,
        'rating': review.rating.toDouble(), // Đảm bảo là double
        'comment': review.comment,
        'createdAt': review.createdAt.toIso8601String(),
        'images': review.images,
        'productName': productInfo['Name'] ?? '',
        'productImage': productInfo['Image'] ?? '',
        'productPrice': (productInfo['Price'] ?? 0)
            .toDouble(), // Đảm bảo là double
        'productCategory': productInfo['Category'] ?? '',
      };

      print('📝 ReviewService - Review data to save: $reviewData');
      await _firestore.collection('reviews').add(reviewData);
      print('✅ ReviewService - Review added successfully');
      return true;
    } catch (e) {
      print('❌ ReviewService - Error adding review: $e');
      return false;
    }
  }

  // Kiểm tra xem user đã review sản phẩm này chưa
  Future<bool> hasUserReviewed(String productId, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .where('userId', isEqualTo: userId)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking user review: $e');
      return false;
    }
  }

  // Cập nhật review
  Future<bool> updateReview(
    String reviewId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update(updates);
      return true;
    } catch (e) {
      print('Error updating review: $e');
      return false;
    }
  }

  // Xóa review
  Future<bool> deleteReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).delete();
      return true;
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }

  // Lấy thông tin user hiện tại
  Future<Map<String, String>> getCurrentUserInfo() async {
    try {
      final userId = await SharedPreferenceHelper().getUserId();
      if (userId == null) return {};

      final userDoc = await _firestore.collection('Users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return {
          'userId': userId,
          'userName': userData['Name'] ?? userData['name'] ?? 'Unknown User',
          'userImage': userData['Image'] ?? userData['image'] ?? '',
        };
      }
      return {};
    } catch (e) {
      print('Error getting user info: $e');
      return {};
    }
  }
}
