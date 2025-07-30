import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pizza_app_vs_010/pages/details.dart';

class HomeFixed extends StatefulWidget {
  const HomeFixed({super.key});

  @override
  State<HomeFixed> createState() => _HomeFixedState();
}

class _HomeFixedState extends State<HomeFixed> {
  String selectedCategory = '';
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  List<QueryDocumentSnapshot> allFoodItems = [];
  List<QueryDocumentSnapshot> filteredFoodItems = [];
  String searchTerm = '';

  @override
  void initState() {
    super.initState();
    _loadFoodItems();
  }

  void _loadFoodItems() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('FoodItems')
          .get();

      setState(() {
        allFoodItems = snapshot.docs;
        filteredFoodItems = snapshot.docs;
      });
    } catch (e) {
      print('Error loading food items: $e');
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchTerm = value.toLowerCase();
      _filterItems();
    });
  }

  void _filterItems() {
    filteredFoodItems = allFoodItems.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      String itemName = (data['Name'] ?? '').toString().toLowerCase();
      String itemCategory = (data['Category'] ?? '').toString();

      bool matchesSearch = searchTerm.isEmpty || itemName.contains(searchTerm);
      bool matchesCategory =
          selectedCategory.isEmpty || itemCategory == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = MediaQuery.of(context).size.width > 600;
    bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App name and tagline
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "FoodGo",
                        style: TextStyle(
                          fontSize: isTablet ? 32.0 : 28.0,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Order your favourite food!",
                        style: TextStyle(
                          fontSize: isTablet ? 16.0 : 14.0,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Action buttons
                  Row(
                    children: [
                      // Order status icon
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/order_status');
                        },
                        child: Container(
                          width: isTablet ? 48 : 42,
                          height: isTablet ? 48 : 42,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red, Colors.red[700]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            FontAwesomeIcons.receipt,
                            color: Colors.white,
                            size: isTablet ? 24 : 20,
                          ),
                        ),
                      ),

                      SizedBox(width: 12),
                    ],
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 24.0 : 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 16.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: searchController,
                        focusNode: searchFocusNode,
                        onChanged: (value) {
                          _onSearchChanged(value);
                        },
                        decoration: InputDecoration(
                          hintText: "Search food item...",
                          hintStyle: TextStyle(
                            fontSize: isTablet ? 16.0 : 14.0,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          icon: Icon(
                            Icons.search,
                            color: Colors.grey[500],
                            size: isTablet ? 24 : 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: isTablet ? 30.0 : 25.0),

            // Categories
            SizedBox(
              height: isTablet ? 60 : 50,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Categories')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  var categories = snapshot.data!.docs;

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 24.0 : 20.0,
                    ),
                    itemCount: categories.length + 1, // +1 for "All" category
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // "All" category
                        return _buildCategoryButton(
                          "All",
                          selectedCategory.isEmpty,
                          FontAwesomeIcons.layerGroup,
                          isTablet,
                        );
                      }

                      var categoryData =
                          categories[index - 1].data() as Map<String, dynamic>;
                      String categoryName = categoryData['name'] ?? '';
                      String? iconImage = categoryData['icon'];

                      return _buildCategoryButton(
                        categoryName,
                        selectedCategory == categoryName,
                        FontAwesomeIcons.layerGroup,
                        isTablet,
                        iconImage: iconImage,
                      );
                    },
                  );
                },
              ),
            ),

            SizedBox(height: isTablet ? 30.0 : 25.0),

            // Food Items Grid
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('FoodItems')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  var items = snapshot.data!.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String itemName = (data['Name'] ?? '')
                        .toString()
                        .toLowerCase();
                    String itemCategory = (data['Category'] ?? '').toString();

                    bool matchesSearch =
                        searchTerm.isEmpty || itemName.contains(searchTerm);
                    bool matchesCategory =
                        selectedCategory.isEmpty ||
                        itemCategory == selectedCategory;

                    return matchesSearch && matchesCategory;
                  }).toList();

                  return GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      var foodData =
                          items[index].data() as Map<String, dynamic>;
                      return _buildFoodItem(foodData, isTablet, isDesktop);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(
    String text,
    bool isSelected,
    IconData icon,
    bool isTablet, {
    String? iconImage,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = text == "All" ? "" : text;
        });
        _filterItems();
      },
      child: Container(
        margin: EdgeInsets.only(right: 12),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 12 : 10,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Colors.red, Colors.red[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.red.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: isSelected ? 12 : 8,
              offset: Offset(0, isSelected ? 6 : 4),
            ),
          ],
          border: isSelected
              ? null
              : Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              child: iconImage != null
                  ? SizedBox(
                      width: isTablet ? 24 : 20,
                      height: isTablet ? 24 : 20,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.memory(
                          base64Decode(iconImage.split(',')[1]),
                          fit: BoxFit.cover,
                          color: isSelected ? Colors.white : null,
                          colorBlendMode: isSelected ? BlendMode.srcIn : null,
                        ),
                      ),
                    )
                  : FaIcon(
                      icon,
                      size: isTablet ? 20 : 16,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
            ),
            SizedBox(width: isTablet ? 8 : 6),
            Text(
              text,
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItem(
    Map<String, dynamic> foodData,
    bool isTablet,
    bool isDesktop,
  ) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image container
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
                    // Image
                    _buildProductImage(foodData['Image'] ?? '', isTablet),
                    // Price badge
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
                          "\$${foodData['Price'] ?? '0'}",
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

          // Content section - Fixed height
          Container(
            height: 80,
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name
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

                // Description
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

                // Arrow icon for navigation
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Details(
                            id: foodData['id'] ?? '',
                            name: foodData['Name'],
                            price: (foodData['Price'] ?? 0).toString(),
                            image: foodData['Image'],
                            detail: foodData['Detail'],
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
    );
  }

  Widget _buildProductImage(String imageUrl, bool isTablet) {
    if (imageUrl.startsWith('data:image')) {
      // Base64 image
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
      // Network image
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
      // Asset image
      return Image.asset(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _getDefaultImage(isTablet);
        },
      );
    }
  }

  Widget _getDefaultImage(bool isTablet) {
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
  }
}
