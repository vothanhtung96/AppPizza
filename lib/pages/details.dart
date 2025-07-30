import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pizza_app_vs_010/service/shared_pref.dart';
import 'package:pizza_app_vs_010/services/cart_provider.dart';
import 'package:pizza_app_vs_010/widgets/review_section.dart';
import 'package:provider/provider.dart';

class Details extends StatefulWidget {
  final String image, name, detail, price, id, category;
  const Details({
    super.key,
    required this.detail,
    required this.image,
    required this.name,
    required this.price,
    required this.id,
    this.category = 'General',
  });

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  int quantity = 1;
  String? id;
  String selectedSize = 'S'; // Default size is Small

  getthesharedpref() async {
    id = await SharedPreferenceHelper().getUserId();
    setState(() {});
  }

  ontheload() async {
    await getthesharedpref();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    print(
      '📱 Details page - ProductId: ${widget.id}, ProductName: ${widget.name}, Category: ${widget.category}',
    );
    // Log Firestore query for debugging
    FirebaseFirestore.instance
        .collection('FoodItems')
        .limit(20)
        .get()
        .then((snapshot) {
          print('🔍 Found ${snapshot.docs.length} items in FoodItems');
          for (var doc in snapshot.docs) {
            print('📄 Item: ${doc.data()}');
          }
        })
        .catchError((error) {
          print('❌ Firestore query error: $error');
        });
    ontheload();
  }

  double get adjustedPrice {
    try {
      String cleanPrice = widget.price.replaceAll(RegExp(r'[^\d.]'), '');
      if (cleanPrice.isEmpty) return 0.0;
      double basePrice = double.parse(cleanPrice);
      if (selectedSize == 'M') {
        return basePrice * 1.05; // Medium: +5%
      } else if (selectedSize == 'L') {
        return basePrice * 1.10; // Large: +10%
      }
      return basePrice; // Small: no change
    } catch (e) {
      print('Error parsing price: $e');
      return 0.0;
    }
  }

  int get totalPrice {
    return (quantity * adjustedPrice).round();
  }

  void _addToCart() async {
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng đăng nhập để thêm vào giỏ hàng')),
      );
      return;
    }

    try {
      Map<String, dynamic> foodData = {
        'id': widget.id,
        'Name': widget.name,
        'Price': adjustedPrice.toStringAsFixed(2),
        'Image': widget.image,
        'Detail': widget.detail,
        'Category': widget.category,
        'quantity': quantity,
        'size': selectedSize,
      };

      bool success = await context.read<CartProvider>().addToCartWithQuantity(
        foodData,
        quantity,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã thêm ${widget.name} (Kích thước: $selectedSize) vào giỏ hàng!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra khi thêm vào giỏ hàng'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildImageWidget(String imageUrl, bool isTablet) {
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
            ),
            child: Icon(
              Icons.fastfood,
              size: isTablet ? 120 : 100,
              color: Colors.grey[600],
            ),
          );
        },
      );
    } else if (imageUrl.startsWith('data:image')) {
      return Image.memory(
        base64Decode(imageUrl.split(',')[1]),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
            ),
            child: Icon(
              Icons.fastfood,
              size: isTablet ? 120 : 100,
              color: Colors.grey[600],
            ),
          );
        },
      );
    } else {
      return Image.asset(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }
  }

  Widget _buildProductImage(String imageUrl, bool isTablet) {
    if (imageUrl.startsWith('data:image')) {
      try {
        String base64String = imageUrl.split(',')[1];
        return Image.memory(
          base64Decode(base64String),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _getDefaultImage(isTablet);
          },
        );
      } catch (e) {
        return _getDefaultImage(isTablet);
      }
    } else if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _getDefaultImage(isTablet);
        },
      );
    } else {
      String assetPath = _getCategoryImagePath(imageUrl);
      return Image.asset(
        assetPath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _getDefaultImage(isTablet);
        },
      );
    }
  }

  String _getCategoryImagePath(String imageUrl) {
    if (imageUrl.contains('pizza')) {
      return 'images/pizza.png';
    } else if (imageUrl.contains('burger')) {
      return 'images/burger.png';
    } else if (imageUrl.contains('salad')) {
      return 'images/salad_icon.png';
    } else if (imageUrl.contains('ice-cream')) {
      return 'images/ice-cream.png';
    } else {
      return 'images/food.jpg';
    }
  }

  Widget _getDefaultImage(bool isTablet) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[300],
      child: Icon(
        FontAwesomeIcons.utensils,
        size: isTablet ? 60 : 50,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildFoodItem(
    Map<String, dynamic> foodData,
    bool isTablet,
    bool isDesktop,
  ) {
    print(
      '🔧 Building food item: ${foodData['Name']}, Image: ${foodData['Image']}',
    );
    return GestureDetector(
      onTap: () {
        print('🚀 Navigating to Details for: ${foodData['Name']}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Details(
              id: foodData['id'] ?? '',
              image: foodData['Image'] ?? 'https://via.placeholder.com/150',
              name: foodData['Name'] ?? '',
              detail: foodData['Detail'] ?? '',
              price: (foodData['Price'] ?? 0).toString(),
              category: foodData['Category'] ?? 'General',
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      _buildProductImage(
                        foodData['Image'] ?? 'https://via.placeholder.com/150',
                        isTablet,
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "\$${foodData['Price']?.toString() ?? '0'}",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              height: 80,
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    foodData['Name'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      foodData['Detail'] ?? '',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        print(
                          '🚀 Navigating to Details for: ${foodData['Name']}',
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Details(
                              id: foodData['id'] ?? '',
                              image:
                                  foodData['Image'] ??
                                  'https://via.placeholder.com/150',
                              name: foodData['Name'] ?? '',
                              detail: foodData['Detail'] ?? '',
                              price: (foodData['Price'] ?? 0).toString(),
                              category: foodData['Category'] ?? 'General',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.orange[600],
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 10,
                        ),
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

  @override
  Widget build(BuildContext context) {
    bool isTablet = MediaQuery.of(context).size.width > 600;
    bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Navigation Bar
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 30.0 : 20.0,
                  vertical: isTablet ? 20.0 : 15.0,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: isTablet ? 50 : 45,
                        height: isTablet ? 50 : 45,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(
                            isTablet ? 15 : 12,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: isTablet ? 24 : 20,
                        ),
                      ),
                    ),
                    Spacer(),
                  ],
                ),
              ),

              // Food Image
              Container(
                height: MediaQuery.of(context).size.height * 0.35,
                width: double.infinity,
                margin: EdgeInsets.symmetric(
                  horizontal: isTablet ? 30.0 : 20.0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
                  child: _buildImageWidget(widget.image, isTablet),
                ),
              ),

              // Product Information Section
              Container(
                padding: EdgeInsets.all(isTablet ? 30.0 : 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      widget.name,
                      style: TextStyle(
                        fontSize: isTablet ? 32.0 : 28.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    SizedBox(height: isTablet ? 15.0 : 10.0),

                    // Price
                    Text(
                      "\$${adjustedPrice.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: isTablet ? 28.0 : 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    SizedBox(height: isTablet ? 25.0 : 20.0),

                    // Size Selection
                    Text(
                      "Kích thước",
                      style: TextStyle(
                        fontSize: isTablet ? 20.0 : 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    SizedBox(height: isTablet ? 15.0 : 12.0),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildSizeButton('S', isTablet),
                        SizedBox(width: isTablet ? 20.0 : 15.0),
                        _buildSizeButton('M', isTablet),
                        SizedBox(width: isTablet ? 20.0 : 15.0),
                        _buildSizeButton('L', isTablet),
                      ],
                    ),

                    SizedBox(height: isTablet ? 25.0 : 20.0),

                    // Description Section
                    Text(
                      "Mô tả",
                      style: TextStyle(
                        fontSize: isTablet ? 20.0 : 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    SizedBox(height: isTablet ? 10.0 : 8.0),

                    Text(
                      widget.detail,
                      style: TextStyle(
                        fontSize: isTablet ? 16.0 : 14.0,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: isTablet ? 25.0 : 20.0),

                    // Quantity Section
                    Text(
                      "Số lượng",
                      style: TextStyle(
                        fontSize: isTablet ? 20.0 : 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    SizedBox(height: isTablet ? 15.0 : 12.0),

                    // Quantity Controls
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (quantity > 1) {
                              setState(() {
                                quantity--;
                              });
                            }
                          },
                          child: Container(
                            width: isTablet ? 50 : 45,
                            height: isTablet ? 50 : 45,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(
                                isTablet ? 12 : 10,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.remove,
                              color: Colors.white,
                              size: isTablet ? 24 : 20,
                            ),
                          ),
                        ),

                        SizedBox(width: isTablet ? 30.0 : 25.0),

                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 30.0 : 25.0,
                            vertical: isTablet ? 12.0 : 10.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(
                              isTablet ? 12 : 10,
                            ),
                          ),
                          child: Text(
                            quantity.toString(),
                            style: TextStyle(
                              fontSize: isTablet ? 24.0 : 20.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),

                        SizedBox(width: isTablet ? 30.0 : 25.0),

                        GestureDetector(
                          onTap: () {
                            setState(() {
                              quantity++;
                            });
                          },
                          child: Container(
                            width: isTablet ? 50 : 45,
                            height: isTablet ? 50 : 45,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(
                                isTablet ? 12 : 10,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: isTablet ? 24 : 20,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isTablet ? 25.0 : 20.0),

                    // Related Items Grid
                    Text(
                      "Gợi ý món ăn",
                      style: TextStyle(
                        fontSize: isTablet ? 20.0 : 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    SizedBox(height: isTablet ? 15.0 : 12.0),

                    SizedBox(
                      height: isTablet ? 320 : 280, // Adjusted height for grid
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('FoodItems')
                            .limit(20) // Limit to avoid excessive data
                            .snapshots(includeMetadataChanges: true),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            print('⏳ Waiting for Firestore data...');
                            return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            print(
                              '❌ Error loading related items: ${snapshot.error}',
                            );
                            return Center(
                              child: Text(
                                'Lỗi tải gợi ý món ăn: ${snapshot.error}',
                                style: TextStyle(
                                  fontSize: isTablet ? 16 : 14,
                                  color: Colors.red,
                                ),
                              ),
                            );
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            print('📭 No items found in FoodItems');
                            return Center(
                              child: Text(
                                'Chưa có món gợi ý',
                                style: TextStyle(
                                  fontSize: isTablet ? 16 : 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            );
                          }

                          // Filter out current item and shuffle
                          List<QueryDocumentSnapshot> relatedItems =
                              snapshot.data!.docs
                                  .where((doc) => doc.id != widget.id)
                                  .toList()
                                ..shuffle(Random()); // Randomize the list
                          relatedItems = relatedItems
                              .take(5)
                              .toList(); // Limit to 5 items
                          print(
                            '📋 Related items count: ${relatedItems.length}',
                          );

                          if (relatedItems.isEmpty) {
                            print('📭 No other items (current item excluded)');
                            return Center(
                              child: Text(
                                'Chưa có món gợi ý khác',
                                style: TextStyle(
                                  fontSize: isTablet ? 16 : 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            );
                          }

                          return GridView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.75,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                ),
                            itemCount: relatedItems.length,
                            itemBuilder: (context, index) {
                              try {
                                var foodData =
                                    relatedItems[index].data()
                                        as Map<String, dynamic>;
                                print(
                                  '🔧 Building grid item: ${foodData['Name']}',
                                );
                                return _buildFoodItem(
                                  foodData,
                                  isTablet,
                                  isDesktop,
                                );
                              } catch (e) {
                                print('❌ Error in grid itemBuilder: $e');
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        spreadRadius: 1,
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Error: $e',
                                      style: TextStyle(color: Colors.red),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Review Section
              ReviewSection(productId: widget.id, productName: widget.name),

              // Bottom Action Buttons
              Container(
                padding: EdgeInsets.all(isTablet ? 30.0 : 20.0),
                child: Row(
                  children: [
                    // Total Price Button
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: () {
                          // Show total price info
                        },
                        child: Container(
                          height: isTablet ? 60 : 50,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(
                              isTablet ? 15 : 12,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              "\$${totalPrice.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 20.0 : 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: isTablet ? 20.0 : 15.0),

                    // Order Now Button
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () async {
                          _addToCart();
                          Navigator.pushNamed(context, '/order');
                        },
                        child: Container(
                          height: isTablet ? 60 : 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange[600]!,
                                Colors.orange[700]!,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(
                              isTablet ? 15 : 12,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              "ĐẶT HÀNG NGAY",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 18.0 : 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSizeButton(String size, bool isTablet) {
    bool isSelected = selectedSize == size;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSize = size;
        });
      },
      child: Container(
        width: isTablet ? 50 : 45,
        height: isTablet ? 50 : 45,
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange[600] : Colors.white,
          borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
          border: Border.all(
            color: isSelected ? Colors.orange[600]! : Colors.grey[300]!,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            size,
            style: TextStyle(
              fontSize: isTablet ? 18.0 : 16.0,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
