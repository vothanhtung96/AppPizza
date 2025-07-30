import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pizza_app_vs_010/pages/details.dart';
import 'package:pizza_app_vs_010/service/database.dart';
import 'package:pizza_app_vs_010/service/shared_pref.dart';
import 'package:pizza_app_vs_010/widgets/theme_toggle.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String userName = "";
  String selectedCategory = "";
  List<QueryDocumentSnapshot> allFoodItems = [];
  List<QueryDocumentSnapshot> allCategories = [];
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  List<String> searchSuggestions = [];
  bool showSuggestions = false;

  // Price filter variables
  RangeValues _priceRange = RangeValues(0, 1000);
  double _minPrice = 0;
  double _maxPrice = 1000;
  bool _showPriceFilter = false;

  // Sort variables
  String _sortOption =
      'none'; // none, name_asc, name_desc, price_asc, price_desc

  final Map<String, IconData> _availableIcons = {
    'pizza': FontAwesomeIcons.pizzaSlice,
    'hamburger': FontAwesomeIcons.burger,
    'salad': FontAwesomeIcons.leaf,
    'icecream': FontAwesomeIcons.iceCream,
    'coffee': FontAwesomeIcons.mugHot,
    'drink': FontAwesomeIcons.wineGlass,
    'dessert': FontAwesomeIcons.cakeCandles,
    'soup': FontAwesomeIcons.bowlFood,
    'sushi': FontAwesomeIcons.fish,
    'chicken': FontAwesomeIcons.drumstickBite,
    'vegetarian': FontAwesomeIcons.carrot,
    'fastfood': FontAwesomeIcons.utensils,
    'healthy': FontAwesomeIcons.appleWhole,
    'spicy': FontAwesomeIcons.pepperHot,
    'seafood': FontAwesomeIcons.shrimp,
    'bread': FontAwesomeIcons.breadSlice,
    'pasta': FontAwesomeIcons.utensils,
    'steak': FontAwesomeIcons.drumstickBite,
    'fish': FontAwesomeIcons.fish,
    'shrimp': FontAwesomeIcons.shrimp,
    'lobster': FontAwesomeIcons.shrimp,
    'crab': FontAwesomeIcons.shrimp,
    'mussels': FontAwesomeIcons.shrimp,
    'oysters': FontAwesomeIcons.shrimp,
    'clams': FontAwesomeIcons.shrimp,
    'scallops': FontAwesomeIcons.shrimp,
    'calamari': FontAwesomeIcons.shrimp,
    'octopus': FontAwesomeIcons.shrimp,
    'squid': FontAwesomeIcons.shrimp,
    'anchovies': FontAwesomeIcons.shrimp,
    'sardines': FontAwesomeIcons.shrimp,
    'tuna': FontAwesomeIcons.fish,
    'salmon': FontAwesomeIcons.fish,
    'cod': FontAwesomeIcons.fish,
    'halibut': FontAwesomeIcons.fish,
    'mackerel': FontAwesomeIcons.fish,
    'trout': FontAwesomeIcons.fish,
    'bass': FontAwesomeIcons.fish,
    'perch': FontAwesomeIcons.fish,
    'walleye': FontAwesomeIcons.fish,
    'pike': FontAwesomeIcons.fish,
    'musky': FontAwesomeIcons.fish,
    'sturgeon': FontAwesomeIcons.fish,
    'catfish': FontAwesomeIcons.fish,
    'bluegill': FontAwesomeIcons.fish,
    'sunfish': FontAwesomeIcons.fish,
    'crappie': FontAwesomeIcons.fish,
    'whitefish': FontAwesomeIcons.fish,
    'herring': FontAwesomeIcons.fish,
    'mahi': FontAwesomeIcons.fish,
    'swordfish': FontAwesomeIcons.fish,
    'marlin': FontAwesomeIcons.fish,
    'sailfish': FontAwesomeIcons.fish,
    'wahoo': FontAwesomeIcons.fish,
    'dorado': FontAwesomeIcons.fish,
    'amberjack': FontAwesomeIcons.fish,
    'cobia': FontAwesomeIcons.fish,
    'grouper': FontAwesomeIcons.fish,
    'snapper': FontAwesomeIcons.fish,
    'redfish': FontAwesomeIcons.fish,
    'blackfish': FontAwesomeIcons.fish,
    'tautog': FontAwesomeIcons.fish,
    'flounder': FontAwesomeIcons.fish,
    'fluke': FontAwesomeIcons.fish,
    'sole': FontAwesomeIcons.fish,
    'dab': FontAwesomeIcons.fish,
    'plaice': FontAwesomeIcons.fish,
    'turbot': FontAwesomeIcons.fish,
    'brill': FontAwesomeIcons.fish,
    'megrim': FontAwesomeIcons.fish,
    'witch': FontAwesomeIcons.fish,
    'lemon': FontAwesomeIcons.fish,
    'dover': FontAwesomeIcons.fish,
    'petrale': FontAwesomeIcons.fish,
    'english': FontAwesomeIcons.fish,
    'channel': FontAwesomeIcons.fish,
    'blue': FontAwesomeIcons.fish,
    'flathead': FontAwesomeIcons.fish,
    'bullhead': FontAwesomeIcons.fish,
    'madtom': FontAwesomeIcons.fish,
    'stonecat': FontAwesomeIcons.fish,
    'margined': FontAwesomeIcons.fish,
    'tadpole': FontAwesomeIcons.fish,
    'speckled': FontAwesomeIcons.fish,
    'brown': FontAwesomeIcons.fish,
    'yellow': FontAwesomeIcons.fish,
    'black': FontAwesomeIcons.fish,
    'white': FontAwesomeIcons.fish,
  };

  @override
  void initState() {
    super.initState();
    getUserName();
    selectedCategory = "";
  }

  getUserName() async {
    userName = await SharedPreferenceHelper().getUserName() ?? "User";
    setState(() {});
  }

  void _updatePriceRange(List<QueryDocumentSnapshot> foodItems) {
    if (foodItems.isEmpty) return;

    double minPrice = double.infinity;
    double maxPrice = 0;

    for (var doc in foodItems) {
      var data = doc.data() as Map<String, dynamic>;
      double price = 0;
      try {
        var priceValue = data['Price'];
        if (priceValue is int) {
          price = priceValue.toDouble();
        } else if (priceValue is double) {
          price = priceValue;
        } else if (priceValue is String) {
          price = double.tryParse(priceValue) ?? 0;
        }
      } catch (e) {
        continue;
      }

      if (price > 0) {
        if (price < minPrice) minPrice = price;
        if (price > maxPrice) maxPrice = price;
      }
    }

    if (minPrice != double.infinity && maxPrice > 0) {
      _minPrice = minPrice;
      _maxPrice = maxPrice;
      if (_priceRange.start == 0 && _priceRange.end == 1000) {
        _priceRange = RangeValues(minPrice, maxPrice);
      }
    }
  }

  void _onSearchChanged(String value) {
    print('🔍 Search term changed: $value');
    _updateSearchSuggestions(value);
  }

  void _updateSearchSuggestions(String value) {
    if (value.isEmpty) {
      if (mounted) {
        setState(() {
          showSuggestions = false;
          searchSuggestions.clear();
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        showSuggestions = true;
        searchSuggestions = allFoodItems
            .map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return data['Name'] ?? '';
            })
            .where((name) => name.toLowerCase().contains(value.toLowerCase()))
            .take(5)
            .cast<String>()
            .toList();
        print('📋 Search suggestions: $searchSuggestions');
      });
    }
  }

  void selectSuggestion(String suggestion) {
    searchController.text = suggestion;
    if (mounted) {
      setState(() {
        showSuggestions = false;
      });
    }
    searchFocusNode.unfocus();
  }

  void _onCategorySelected(String categoryName) {
    print('🎯 Category selected: $categoryName');
    if (mounted) {
      setState(() {
        selectedCategory = categoryName;
      });
    }
  }

  void _onSortSelected(String sortOption) {
    setState(() {
      _sortOption = sortOption;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isTablet = screenWidth > 600;
    bool isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey[50]!],
          ),
        ),
        margin: EdgeInsets.only(top: 50.0, left: 20.0, right: 20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black.withOpacity(0.1),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Order your favourite food!",
                      style: TextStyle(
                        fontSize: isTablet ? 16.0 : 14.0,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 12),
                ThemeToggle(),
              ],
            ),
            SizedBox(height: isTablet ? 30.0 : 25.0),
            Row(
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
                          FontAwesomeIcons.magnifyingGlass,
                          color: Colors.grey[600],
                          size: isTablet ? 20 : 18,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  width: isTablet ? 54 : 48,
                  height: isTablet ? 54 : 48,
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
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    FontAwesomeIcons.magnifyingGlass,
                    color: Colors.white,
                    size: isTablet ? 20 : 18,
                  ),
                ),
              ],
            ),
            if (showSuggestions && searchSuggestions.isNotEmpty)
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    margin: EdgeInsets.only(top: 5),
                    constraints: BoxConstraints(
                      maxHeight: 200, // Giới hạn chiều cao danh sách gợi ý
                      maxWidth: constraints.maxWidth, // Giới hạn chiều rộng
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: searchSuggestions
                            .map(
                              (suggestion) => ListTile(
                                title: Text(
                                  suggestion,
                                  style: TextStyle(
                                    fontSize: isTablet ? 16 : 14,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                onTap: () => selectSuggestion(suggestion),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  );
                },
              ),
            SizedBox(height: isTablet ? 25.0 : 20.0),
            Container(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Categories')
                    .snapshots(),
                builder: (context, categorySnapshot) {
                  if (categorySnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (categorySnapshot.hasError) {
                    print(
                      '❌ Error loading categories: ${categorySnapshot.error}',
                    );
                    return Center(
                      child: Text(
                        'Error loading categories: ${categorySnapshot.error}',
                      ),
                    );
                  }
                  if (!categorySnapshot.hasData ||
                      categorySnapshot.data!.docs.isEmpty) {
                    print('📭 No categories found in database');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            FontAwesomeIcons.folderOpen,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Chưa có danh mục nào',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  allCategories = categorySnapshot.data!.docs;
                  print(
                    '📋 Found ${allCategories.length} categories in database',
                  );
                  for (var doc in allCategories) {
                    var categoryData = doc.data() as Map<String, dynamic>;
                    print('📝 Category ID: ${doc.id}');
                    print('   - Name: ${categoryData['Name']}');
                    print('   - name: ${categoryData['name']}');
                    print(
                      '   - Image: ${categoryData['Image']?.substring(0, 50)}...',
                    );
                    print(
                      '   - iconImage: ${categoryData['iconImage']?.substring(0, 50)}...',
                    );
                  }
                  Map<String, QueryDocumentSnapshot> uniqueCategories = {};
                  for (var doc in allCategories) {
                    var categoryData = doc.data() as Map<String, dynamic>;
                    String categoryName =
                        categoryData['Name'] ?? categoryData['name'] ?? '';
                    if (categoryName.isNotEmpty &&
                        !uniqueCategories.containsKey(categoryName)) {
                      uniqueCategories[categoryName] = doc;
                      print('✅ Added category: $categoryName');
                    }
                  }
                  print('🎯 Unique categories: ${uniqueCategories.length}');
                  if (uniqueCategories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            FontAwesomeIcons.exclamationTriangle,
                            size: 64,
                            color: Colors.orange[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Không tìm thấy danh mục hợp lệ',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Vui lòng kiểm tra dữ liệu trong database',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  List<QueryDocumentSnapshot> sortedCategories =
                      uniqueCategories.values.toList();
                  sortedCategories.sort((a, b) {
                    var dataA = a.data() as Map<String, dynamic>;
                    var dataB = b.data() as Map<String, dynamic>;
                    String nameA = dataA['Name'] ?? dataA['name'] ?? '';
                    String nameB = dataB['Name'] ?? dataB['name'] ?? '';
                    if (nameA.toLowerCase() == 'pizza') return -1;
                    if (nameB.toLowerCase() == 'pizza') return 1;
                    return nameA.compareTo(nameB);
                  });
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        SizedBox(width: 8),
                        ...sortedCategories.map((categoryDoc) {
                          var categoryData =
                              categoryDoc.data() as Map<String, dynamic>;
                          String categoryName =
                              categoryData['Name'] ??
                              categoryData['name'] ??
                              '';
                          String iconName = categoryData['icon'] ?? 'pizza';
                          bool isSelected = selectedCategory == categoryName;
                          print(
                            '🎨 Building category button: $categoryName (selected: $isSelected)',
                          );
                          return Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: _buildCategoryButton(
                              categoryName,
                              isSelected,
                              _getIconData(iconName),
                              isTablet,
                              iconImage:
                                  categoryData['iconImage'] ??
                                  categoryData['Image'],
                            ),
                          );
                        }),
                        SizedBox(width: 8),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: isTablet ? 25.0 : 20.0),
            // Sort Options
            Container(
              padding: EdgeInsets.all(16),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sắp xếp theo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  DropdownButton<String>(
                    value: _sortOption,
                    items: [
                      DropdownMenuItem(value: 'none', child: Text('Mặc định')),
                      DropdownMenuItem(
                        value: 'name_asc',
                        child: Text('Tên A-Z'),
                      ),
                      DropdownMenuItem(
                        value: 'name_desc',
                        child: Text('Tên Z-A'),
                      ),
                      DropdownMenuItem(
                        value: 'price_asc',
                        child: Text('Giá thấp-cao'),
                      ),
                      DropdownMenuItem(
                        value: 'price_desc',
                        child: Text('Giá cao-thấp'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _onSortSelected(value);
                      }
                    },
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                    dropdownColor: Colors.white,
                    icon: Icon(Icons.sort, color: Colors.orange[600]),
                  ),
                ],
              ),
            ),
            SizedBox(height: isTablet ? 25.0 : 20.0),
            Container(
              padding: EdgeInsets.all(16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lọc theo giá',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '\$${_priceRange.start.round()} - \$${_priceRange.end.round()}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[600],
                            ),
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              _showPriceFilter
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Colors.orange[600],
                            ),
                            onPressed: () {
                              setState(() {
                                _showPriceFilter = !_showPriceFilter;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_showPriceFilter) ...[
                    SizedBox(height: 16),
                    RangeSlider(
                      values: _priceRange,
                      min: _minPrice,
                      max: _maxPrice,
                      divisions: 100,
                      activeColor: Colors.orange[600],
                      inactiveColor: Colors.grey[300],
                      labels: RangeLabels(
                        '\$${_priceRange.start.round()}',
                        '\$${_priceRange.end.round()}',
                      ),
                      onChanged: (RangeValues values) {
                        setState(() {
                          _priceRange = values;
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${_priceRange.start.round()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '\$${_priceRange.end.round()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _priceRange = RangeValues(_minPrice, _maxPrice);
                              });
                            },
                            icon: Icon(Icons.refresh, size: 16),
                            label: Text('Đặt lại'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black87,
                              padding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _showPriceFilter = false;
                              });
                            },
                            icon: Icon(Icons.check, size: 16),
                            label: Text('Áp dụng'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: isTablet ? 25.0 : 20.0),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: DatabaseMethods().getFoodItems(selectedCategory),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    print('❌ Error loading food items: ${snapshot.error}');
                    String errorMessage = snapshot.error.toString();
                    if (errorMessage.contains('failed-precondition') ||
                        errorMessage.contains('index')) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              FontAwesomeIcons.exclamationTriangle,
                              size: 64,
                              color: Colors.orange[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Đang xây dựng index...',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Vui lòng thử lại sau vài phút',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {});
                              },
                              child: Text('Thử lại'),
                            ),
                          ],
                        ),
                      );
                    }
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            FontAwesomeIcons.exclamationTriangle,
                            size: 64,
                            color: Colors.red[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Lỗi tải dữ liệu',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  allFoodItems = snapshot.data!.docs;
                  print('🍕 Found ${allFoodItems.length} total food items');
                  _updatePriceRange(allFoodItems);
                  List<QueryDocumentSnapshot> filteredItems = DatabaseMethods()
                      .filterFoodItemsByCategory(
                        allFoodItems,
                        selectedCategory,
                      );
                  print(
                    '🍕 Filtered to ${filteredItems.length} items for category: $selectedCategory',
                  );
                  List<QueryDocumentSnapshot> priceFilteredItems = filteredItems
                      .where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        double price = 0;
                        try {
                          var priceValue = data['Price'];
                          if (priceValue is int) {
                            price = priceValue.toDouble();
                          } else if (priceValue is double) {
                            price = priceValue;
                          } else if (priceValue is String) {
                            price = double.tryParse(priceValue) ?? 0;
                          }
                        } catch (e) {
                          print(
                            '❌ Error parsing price for ${data['Name']}: $e',
                          );
                          price = 0;
                        }
                        return price >= _priceRange.start &&
                            price <= _priceRange.end;
                      })
                      .toList();
                  print(
                    '💰 Price filtered to ${priceFilteredItems.length} items (range: \$${_priceRange.start.round()} - \$${_priceRange.end.round()})',
                  );
                  for (var doc in priceFilteredItems) {
                    var foodData = doc.data() as Map<String, dynamic>;
                    print(
                      '🍽️ Food item: ${foodData['Name']} - Category: ${foodData['Category']} - Price: ${foodData['Price']}',
                    );
                  }
                  if (priceFilteredItems.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            FontAwesomeIcons.moneyBill,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Không có sản phẩm trong khoảng giá này',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Thử điều chỉnh khoảng giá hoặc chọn danh mục khác',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  String searchTerm = searchController.text.toLowerCase();
                  List<QueryDocumentSnapshot> currentFilteredItems =
                      priceFilteredItems.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        String itemName = (data['Name'] ?? '').toLowerCase();
                        String itemCategory = data['Category'] ?? 'Hamburger';
                        bool matchesSearch =
                            searchTerm.isEmpty || itemName.contains(searchTerm);
                        bool matchesCategory =
                            selectedCategory.isEmpty ||
                            itemCategory == selectedCategory;
                        return matchesSearch && matchesCategory;
                      }).toList();
                  // Apply sorting
                  currentFilteredItems.sort((a, b) {
                    var dataA = a.data() as Map<String, dynamic>;
                    var dataB = b.data() as Map<String, dynamic>;
                    String nameA = dataA['Name'] ?? '';
                    String nameB = dataB['Name'] ?? '';
                    double priceA = 0;
                    double priceB = 0;
                    try {
                      var priceValueA = dataA['Price'];
                      var priceValueB = dataB['Price'];
                      priceA = (priceValueA is int
                          ? priceValueA.toDouble()
                          : priceValueA is double
                          ? priceValueA
                          : double.tryParse(priceValueA.toString()) ?? 0);
                      priceB = (priceValueB is int
                          ? priceValueB.toDouble()
                          : priceValueB is double
                          ? priceValueB
                          : double.tryParse(priceValueB.toString()) ?? 0);
                    } catch (e) {
                      print('❌ Error parsing prices for sorting: $e');
                    }
                    switch (_sortOption) {
                      case 'name_asc':
                        return nameA.compareTo(nameB);
                      case 'name_desc':
                        return nameB.compareTo(nameA);
                      case 'price_asc':
                        return priceA.compareTo(priceB);
                      case 'price_desc':
                        return priceB.compareTo(priceA);
                      default:
                        return 0;
                    }
                  });
                  return GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: currentFilteredItems.length,
                    itemBuilder: (context, index) {
                      var foodData =
                          currentFilteredItems[index].data()
                              as Map<String, dynamic>;
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
        _onCategorySelected(text);
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
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
                        child: iconImage.startsWith('data:image')
                            ? Image.memory(
                                base64Decode(iconImage.split(',')[1]),
                                fit: BoxFit.cover,
                                color: isSelected ? Colors.white : null,
                                colorBlendMode: isSelected
                                    ? BlendMode.srcIn
                                    : null,
                              )
                            : Image.network(
                                iconImage,
                                fit: BoxFit.cover,
                                color: isSelected ? Colors.white : null,
                                colorBlendMode: isSelected
                                    ? BlendMode.srcIn
                                    : null,
                                errorBuilder: (context, error, stackTrace) {
                                  return _getCategoryIcon(
                                    text,
                                    isSelected,
                                    isTablet,
                                  );
                                },
                              ),
                      ),
                    )
                  : _getCategoryIcon(text, isSelected, isTablet),
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
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCategoryIcon(String categoryName, bool isSelected, bool isTablet) {
    Map<String, String> categoryIconMap = {
      'Pizza': 'images/Pizza_icon.png',
      'Hamburger': 'images/burger_icon.png',
      'Salad': 'images/salad_icon.png',
      'Ice Cream': 'images/ice-cream_Icon.png',
    };
    String? iconPath = categoryIconMap[categoryName];
    if (iconPath != null) {
      return SizedBox(
        width: isTablet ? 24 : 20,
        height: isTablet ? 24 : 20,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            iconPath,
            fit: BoxFit.cover,
            color: isSelected ? Colors.white : null,
            colorBlendMode: isSelected ? BlendMode.srcIn : null,
          ),
        ),
      );
    } else {
      return FaIcon(
        _getIconData(categoryName.toLowerCase()),
        size: isTablet ? 20 : 16,
        color: isSelected ? Colors.white : Colors.grey[700],
      );
    }
  }

  Widget _buildFoodItem(
    Map<String, dynamic> foodData,
    bool isTablet,
    bool isDesktop,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Details(
              id: foodData['id'] ?? '',
              image: foodData['Image'] ?? '',
              name: foodData['Name'] ?? '',
              detail: foodData['Detail'] ?? '',
              price: (foodData['Price'] ?? 0).toString(),
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
                      _buildProductImage(foodData['Image'] ?? '', isTablet),
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
                            "\$ ${(foodData['Price'] ?? 0).toString()}",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
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
      ),
    );
  }

  IconData _getIconData(String iconName) {
    return _availableIcons[iconName] ?? FontAwesomeIcons.layerGroup;
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
}
