import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pizza_app_vs_010/models/review_model.dart';
import 'package:pizza_app_vs_010/widgets/rating_stars.dart';

class ReviewManagement extends StatefulWidget {
  const ReviewManagement({super.key});

  @override
  State<ReviewManagement> createState() => _ReviewManagementState();
}

class _ReviewManagementState extends State<ReviewManagement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _deleteReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa đánh giá thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra khi xóa đánh giá: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
            print(
              '🔧 Fixing rating: ${data['rating']} -> ${updates['rating']}',
            );
          } catch (e) {
            print('❌ Cannot parse rating: ${data['rating']}');
          }
        }

        // Fix productPrice format
        if (data['productPrice'] is String) {
          try {
            updates['productPrice'] = double.parse(data['productPrice']);
            needsUpdate = true;
            print(
              '🔧 Fixing productPrice: ${data['productPrice']} -> ${updates['productPrice']}',
            );
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
        SnackBar(
          content: Text('Đã cập nhật $updatedCount reviews'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error cleaning up reviews: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi khi cleanup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(
    String reviewId,
    String userName,
    String productName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Xóa đánh giá'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc muốn xóa đánh giá này?'),
            SizedBox(height: 8),
            Text(
              'Người dùng: $userName',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Sản phẩm: $productName',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteReview(reviewId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý đánh giá'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _cleanupOldReviews,
            icon: Icon(Icons.cleaning_services),
            tooltip: 'Cleanup dữ liệu cũ',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('reviews')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('❌ ReviewManagement - Error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  SizedBox(height: 16),
                  Text(
                    'Có lỗi xảy ra khi tải đánh giá',
                    style: TextStyle(fontSize: 18, color: Colors.red[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final reviews = snapshot.data?.docs ?? [];

          if (reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có đánh giá nào',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              try {
                final reviewData =
                    reviews[index].data() as Map<String, dynamic>;
                final review = ReviewModel.fromMap(
                  reviewData,
                  reviews[index].id,
                );

                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header với thông tin người dùng và sản phẩm
                        Row(
                          children: [
                            // Avatar người dùng
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: review.userImage.isNotEmpty
                                  ? NetworkImage(review.userImage)
                                  : null,
                              child: review.userImage.isEmpty
                                  ? Icon(Icons.person, color: Colors.grey[600])
                                  : null,
                            ),
                            SizedBox(width: 12),
                            // Thông tin người dùng và sản phẩm
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review.userName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    review.productName,
                                    style: TextStyle(
                                      color: Colors.blue[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Danh mục: ${review.productCategory}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Nút xóa
                            IconButton(
                              onPressed: () => _showDeleteConfirmation(
                                review.id,
                                review.userName,
                                review.productName,
                              ),
                              icon: Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Xóa đánh giá',
                            ),
                          ],
                        ),

                        SizedBox(height: 12),

                        // Rating và ngày đánh giá
                        Row(
                          children: [
                            RatingStars(rating: review.rating, size: 16),
                            SizedBox(width: 8),
                            Text(
                              '${review.rating.toStringAsFixed(1)}/5.0',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[600],
                              ),
                            ),
                            Spacer(),
                            Text(
                              DateFormat(
                                'dd/MM/yyyy HH:mm',
                              ).format(review.createdAt),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 12),

                        // Nội dung đánh giá
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            review.comment,
                            style: TextStyle(fontSize: 14, height: 1.4),
                          ),
                        ),

                        // Thông tin sản phẩm
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.grey[200],
                                ),
                                child: review.productImage.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          review.productImage,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.fastfood,
                                                  color: Colors.grey[600],
                                                  size: 20,
                                                );
                                              },
                                        ),
                                      )
                                    : Icon(
                                        Icons.fastfood,
                                        color: Colors.grey[600],
                                        size: 20,
                                      ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Giá: \$${review.productPrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[600],
                                      ),
                                    ),
                                    Text(
                                      'ID: ${review.productId}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } catch (e) {
                print('❌ Error parsing review at index $index: $e');
                print('❌ Review data: ${reviews[index].data()}');

                // Return error card instead of crashing
                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  color: Colors.red[50],
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[600]),
                            SizedBox(width: 8),
                            Text(
                              'Lỗi dữ liệu đánh giá',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[600],
                              ),
                            ),
                            Spacer(),
                            IconButton(
                              onPressed: () => _showDeleteConfirmation(
                                reviews[index].id,
                                'Unknown User',
                                'Unknown Product',
                              ),
                              icon: Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Xóa đánh giá lỗi',
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Không thể hiển thị đánh giá này do lỗi dữ liệu.',
                          style: TextStyle(color: Colors.red[600]),
                        ),
                        Text(
                          'Lỗi: $e',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
