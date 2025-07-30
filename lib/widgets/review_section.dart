import 'package:flutter/material.dart';
import 'package:pizza_app_vs_010/models/review_model.dart';
import 'package:pizza_app_vs_010/service/shared_pref.dart';
import 'package:pizza_app_vs_010/services/review_service.dart';
import 'package:pizza_app_vs_010/widgets/rating_stars.dart';
import 'package:pizza_app_vs_010/widgets/review_dialog.dart';
import 'package:pizza_app_vs_010/widgets/review_item.dart';

class ReviewSection extends StatefulWidget {
  final String productId;
  final String productName;

  const ReviewSection({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  final ReviewService _reviewService = ReviewService();
  String? currentUserId;
  ReviewModel? userReview;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final userId = await SharedPreferenceHelper().getUserId();
    setState(() {
      currentUserId = userId;
    });

    if (userId != null) {
      _checkUserReview();
    }
  }

  Future<void> _checkUserReview() async {
    if (currentUserId == null) return;

    print(
      '🔍 ReviewSection - Checking user review for userId: $currentUserId, productId: ${widget.productId}',
    );

    final hasReviewed = await _reviewService.hasUserReviewed(
      widget.productId,
      currentUserId!,
    );
    print('🔍 ReviewSection - User has reviewed: $hasReviewed');

    if (hasReviewed) {
      // Get user's review
      _reviewService.getProductReviews(widget.productId).listen((reviews) {
        final userReview = reviews
            .where((r) => r.userId == currentUserId)
            .firstOrNull;
        print(
          '🔍 ReviewSection - Found user review: ${userReview != null ? "Yes" : "No"}',
        );
        setState(() {
          this.userReview = userReview;
        });
      });
    } else {
      setState(() {
        userReview = null;
      });
    }
  }

  Future<void> _refreshReviews() async {
    print('🔄 ReviewSection - Refreshing reviews...');
    await _checkUserReview();
    setState(() {
      // Force rebuild
    });
  }

  void _showReviewDialog() {
    print('🔍 ReviewSection - Opening review dialog for:');
    print('  - productId: ${widget.productId}');
    print('  - productName: ${widget.productName}');
    print('  - existingReview: ${userReview != null ? "Yes" : "No"}');

    showDialog(
      context: context,
      builder: (context) => ReviewDialog(
        productId: widget.productId,
        productName: widget.productName,
        existingReview: userReview,
        onSave: (ReviewModel review) async {
          print('🔍 ReviewSection - onSave called with review:');
          print('  - productId: ${review.productId}');
          print('  - userId: ${review.userId}');
          print('  - userName: ${review.userName}');

          try {
            bool success;
            if (userReview != null) {
              // Update existing review
              print('🔄 ReviewSection - Updating existing review');
              success = await _reviewService.updateReview(userReview!.id, {
                'rating': review.rating,
                'comment': review.comment,
                'images': review.images,
                'createdAt': DateTime.now().toIso8601String(),
              });
            } else {
              // Add new review
              print('➕ ReviewSection - Adding new review');
              success = await _reviewService.addReview(review);
            }

            print('✅ ReviewSection - Review operation result: $success');

            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    userReview != null
                        ? 'Đánh giá đã được cập nhật!'
                        : 'Đánh giá đã được thêm!',
                  ),
                  backgroundColor: Colors.green,
                ),
              );

              // Refresh user review check
              await _refreshReviews();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Có lỗi xảy ra khi lưu đánh giá'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } catch (e) {
            print('❌ ReviewSection - Error in onSave: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Có lỗi xảy ra: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận'),
        content: Text('Bạn có chắc chắn muốn xóa đánh giá này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _reviewService.deleteReview(reviewId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa đánh giá thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra khi xóa đánh giá'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
      '🏪 ReviewSection - ProductId: ${widget.productId}, ProductName: ${widget.productName}',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.rate_review, color: Colors.blue[600], size: 24),
              SizedBox(width: 8),
              Text(
                'Đánh giá sản phẩm',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // Rating summary
        StreamBuilder<double>(
          stream: _reviewService.getProductAverageRating(widget.productId),
          builder: (context, ratingSnapshot) {
            return StreamBuilder<int>(
              stream: _reviewService.getProductReviewCount(widget.productId),
              builder: (context, countSnapshot) {
                final averageRating = ratingSnapshot.data ?? 0.0;
                final reviewCount = countSnapshot.data ?? 0;

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Average rating
                      Column(
                        children: [
                          Text(
                            averageRating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                          RatingStars(
                            rating: averageRating,
                            size: 16,
                            showRating: false,
                          ),
                          SizedBox(height: 4),
                          Text(
                            '$reviewCount đánh giá',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 20),

                      // Rating distribution (optional)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phân bố đánh giá:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            // You can add rating distribution bars here
                            Text(
                              'Chưa có dữ liệu phân bố',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),

        SizedBox(height: 16),

        // Add review button
        if (currentUserId != null && userReview == null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton.icon(
              onPressed: () => _showReviewDialog(),
              icon: Icon(Icons.add),
              label: Text('Viết đánh giá'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 48),
              ),
            ),
          ),

        if (currentUserId != null && userReview != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue[600]),
                        SizedBox(width: 8),
                        Text(
                          'Đánh giá của bạn:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ReviewItem(
                      review: userReview!,
                      showActions: false,
                      onEdit: () => _showReviewDialog(),
                      onDelete: () => _deleteReview(userReview!.id),
                    ),
                  ],
                ),
              ),
            ),
          ),

        SizedBox(height: 16),

        // Reviews list
        StreamBuilder<List<ReviewModel>>(
          stream: _reviewService.getProductReviews(widget.productId),
          builder: (context, snapshot) {
            print('🔍 ReviewSection - ProductId: ${widget.productId}');
            print(
              '🔍 ReviewSection - Snapshot data: ${snapshot.data?.length ?? 0} reviews',
            );
            print(
              '🔍 ReviewSection - Connection state: ${snapshot.connectionState}',
            );

            if (snapshot.hasError) {
              print('❌ ReviewSection - Error: ${snapshot.error}');
              return Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Có lỗi xảy ra khi tải đánh giá: ${snapshot.error}',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final reviews = snapshot.data ?? [];
            print('🔍 ReviewSection - Reviews found: ${reviews.length}');
            for (var review in reviews) {
              print(
                '🔍 ReviewSection - Review: productId=${review.productId}, userName=${review.userName}, comment=${review.comment}',
              );
            }

            if (reviews.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Chưa có đánh giá nào',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Hãy là người đầu tiên đánh giá sản phẩm này!',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Tất cả đánh giá',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${reviews.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                ...reviews.map(
                  (review) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: ReviewItem(
                      review: review,
                      onEdit: review.userId == currentUserId
                          ? () => _showReviewDialog()
                          : null,
                      onDelete: review.userId == currentUserId
                          ? () => _deleteReview(review.id)
                          : null,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
