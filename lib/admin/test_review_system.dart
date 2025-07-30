import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pizza_app_vs_010/models/review_model.dart';
import 'package:pizza_app_vs_010/services/review_service.dart';

class TestReviewSystem extends StatefulWidget {
  const TestReviewSystem({super.key});

  @override
  State<TestReviewSystem> createState() => _TestReviewSystemState();
}

class _TestReviewSystemState extends State<TestReviewSystem> {
  final ReviewService _reviewService = ReviewService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> products = [];
  List<ReviewModel> reviews = [];
  String? selectedProductId;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadReviews();
  }

  Future<void> _loadProducts() async {
    try {
      final snapshot = await _firestore.collection('FoodItems').limit(5).get();
      setState(() {
        products = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      });
      print('📦 Loaded ${products.length} products');
    } catch (e) {
      print('❌ Error loading products: $e');
    }
  }

  Future<void> _loadReviews() async {
    try {
      final snapshot = await _firestore.collection('reviews').limit(10).get();
      setState(() {
        reviews = snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
            .toList();
      });
      print('📝 Loaded ${reviews.length} reviews');
    } catch (e) {
      print('❌ Error loading reviews: $e');
    }
  }

  Future<void> _createTestReview() async {
    if (products.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không có sản phẩm để test')));
      return;
    }

    try {
      final product = products.first;
      final testReview = ReviewModel(
        id: '',
        productId: product['id'],
        userId: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
        userName: 'Test User',
        userImage: '',
        rating: 4.5,
        comment: 'Đây là đánh giá test được tạo lúc ${DateTime.now()}',
        createdAt: DateTime.now(),
        images: [],
        productName: product['Name'] ?? 'Test Product',
        productImage: product['Image'] ?? '',
        productPrice: (product['Price'] ?? 0).toDouble(),
        productCategory: product['Category'] ?? 'Test',
      );

      final success = await _reviewService.addReview(testReview);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã tạo review test thành công!')),
        );
        _loadReviews(); // Reload reviews
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Có lỗi khi tạo review test')));
      }
    } catch (e) {
      print('❌ Error creating test review: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Có lỗi: $e')));
    }
  }

  Future<void> _cleanupOldReviews() async {
    try {
      final snapshot = await _firestore.collection('reviews').get();
      int updatedCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        bool needsUpdate = false;
        Map<String, dynamic> updates = {};

        // Fix rating format
        if (data['rating'] is String) {
          try {
            updates['rating'] = double.parse(data['rating']);
            needsUpdate = true;
          } catch (e) {
            print('❌ Cannot parse rating: ${data['rating']}');
          }
        }

        // Fix productPrice format
        if (data['productPrice'] is String) {
          try {
            updates['productPrice'] = double.parse(data['productPrice']);
            needsUpdate = true;
          } catch (e) {
            print('❌ Cannot parse productPrice: ${data['productPrice']}');
          }
        }

        if (needsUpdate) {
          await _firestore.collection('reviews').doc(doc.id).update(updates);
          updatedCount++;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật $updatedCount reviews')),
      );
      _loadReviews();
    } catch (e) {
      print('❌ Error cleaning up reviews: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Có lỗi khi cleanup: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Review System'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Products Section
            Text(
              'Sản phẩm (FoodItems):',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ...products.map(
              (product) => Card(
                child: ListTile(
                  title: Text(product['Name'] ?? 'Unknown'),
                  subtitle: Text('ID: ${product['id']}'),
                  trailing: Text('\$${product['Price']}'),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Reviews Section
            Text(
              'Đánh giá (Reviews):',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ...reviews.map(
              (review) => Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sản phẩm: ${review.productName}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('ProductId: ${review.productId}'),
                      Text('User: ${review.userName}'),
                      Text('Rating: ${review.rating}/5'),
                      Text('Comment: ${review.comment}'),
                      Text('Created: ${review.createdAt}'),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Test Buttons
            ElevatedButton(
              onPressed: _loadProducts,
              child: Text('Reload Products'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadReviews,
              child: Text('Reload Reviews'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _createTestReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('Create Test Review'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _cleanupOldReviews,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('Cleanup Old Reviews'),
            ),
          ],
        ),
      ),
    );
  }
}
