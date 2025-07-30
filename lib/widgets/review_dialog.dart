import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pizza_app_vs_010/models/review_model.dart';
import 'package:pizza_app_vs_010/service/shared_pref.dart';
import 'package:pizza_app_vs_010/services/review_service.dart';
import 'package:pizza_app_vs_010/widgets/rating_stars.dart';

class ReviewDialog extends StatefulWidget {
  final String productId;
  final String productName;
  final ReviewModel? existingReview;
  final Function(ReviewModel) onSave;

  const ReviewDialog({
    super.key,
    required this.productId,
    required this.productName,
    this.existingReview,
    required this.onSave,
  });

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _commentController = TextEditingController();
  double _rating = 5.0;
  final List<File> _selectedImages = [];
  bool _isLoading = false;
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserImage;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    if (widget.existingReview != null) {
      _rating = widget.existingReview!.rating;
      _commentController.text = widget.existingReview!.comment;
    }
  }

  Future<void> _loadCurrentUser() async {
    print('🔍 ReviewDialog - Loading current user...');
    final userId = await SharedPreferenceHelper().getUserId();
    final userName = await SharedPreferenceHelper().getUserName();

    print(
      '🔍 ReviewDialog - User info loaded: userId=$userId, userName=$userName',
    );

    setState(() {
      _currentUserId = userId;
      _currentUserName = userName;
      _currentUserImage = ''; // Có thể lấy từ user profile sau
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];

    for (File imageFile in _selectedImages) {
      try {
        // Convert image to base64 for now (you can implement Firebase Storage upload later)
        List<int> imageBytes = await imageFile.readAsBytes();
        String base64Image = base64Encode(imageBytes);
        String mimeType = 'image/jpeg'; // You can detect this dynamically
        String dataUrl = 'data:$mimeType;base64,$base64Image';
        imageUrls.add(dataUrl);
      } catch (e) {
        print('Error uploading image: $e');
      }
    }

    return imageUrls;
  }

  Future<void> _saveReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Vui lòng nhập đánh giá của bạn')));
      return;
    }

    if (_currentUserId == null || _currentUserName == null) {
      print(
        '❌ ReviewDialog - User info is null: userId=$_currentUserId, userName=$_currentUserName',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể lấy thông tin người dùng, vui lòng thử lại'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<String> imageUrls = await _uploadImages();

      print('🔍 ReviewDialog - Creating review with:');
      print('  - productId: ${widget.productId}');
      print('  - userId: $_currentUserId');
      print('  - userName: $_currentUserName');
      print('  - rating: $_rating');
      print('  - comment: ${_commentController.text.trim()}');

      ReviewModel review = ReviewModel(
        id: widget.existingReview?.id ?? '',
        productId: widget.productId,
        userId: _currentUserId!,
        userName: _currentUserName!,
        userImage: _currentUserImage ?? '',
        rating: _rating,
        comment: _commentController.text.trim(),
        createdAt: widget.existingReview?.createdAt ?? DateTime.now(),
        images: imageUrls,
        productName: widget.productName,
        productImage: '', // Sẽ được lấy từ FoodItems trong ReviewService
        productPrice: 0, // Sẽ được lấy từ FoodItems trong ReviewService
        productCategory: '', // Sẽ được lấy từ FoodItems trong ReviewService
      );

      print('✅ ReviewDialog - Review model created successfully');
      widget.onSave(review);
      Navigator.of(context).pop();
    } catch (e) {
      print('❌ ReviewDialog - Error in _saveReview: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Có lỗi xảy ra: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.rate_review, color: Colors.blue[600], size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.existingReview != null
                              ? 'Sửa đánh giá'
                              : 'Thêm đánh giá',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        Text(
                          widget.productName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close),
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rating
                    Text(
                      'Đánh giá của bạn:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Center(
                      child: InteractiveRatingStars(
                        initialRating: _rating,
                        size: 32,
                        onRatingChanged: (rating) {
                          setState(() {
                            _rating = rating;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 20),

                    // Comment
                    Text(
                      'Nhận xét:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _commentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            'Chia sẻ trải nghiệm của bạn về sản phẩm này...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue[600]!),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Images
                    Text(
                      'Hình ảnh (tùy chọn):',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),

                    // Selected images
                    if (_selectedImages.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _selectedImages[index],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                    SizedBox(height: 8),

                    // Add image button
                    if (_selectedImages.length < 5)
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(Icons.add_photo_alternate),
                        label: Text('Thêm hình ảnh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.grey[700],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                      ),
                      child: Text('Hủy'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              widget.existingReview != null
                                  ? 'Cập nhật'
                                  : 'Gửi',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
