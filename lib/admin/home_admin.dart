import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pizza_app_vs_010/admin/category_management.dart';
import 'package:pizza_app_vs_010/admin/food_management.dart';
import 'package:pizza_app_vs_010/admin/loyalty_management.dart';
import 'package:pizza_app_vs_010/admin/order_management.dart';
import 'package:pizza_app_vs_010/admin/promo_management.dart';
import 'package:pizza_app_vs_010/admin/review_management.dart';
import 'package:pizza_app_vs_010/admin/user_management.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    bool isTablet = screenWidth > 600;
    bool isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Bảng điều khiển Admin',
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.signOutAlt),
            onPressed: () {
              // Thêm chức năng đăng xuất ở đây
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(
            isTablet ? 24.0 : 16.0,
          ), // Giảm margin cho màn hình nhỏ
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Giới hạn kích thước cột
            children: [
              // Welcome Banner
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isTablet ? 20 : 16), // Giảm padding
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[400]!, Colors.orange[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isTablet ? 16 : 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                      ),
                      child: Icon(
                        FontAwesomeIcons.userShield,
                        size: isTablet ? 32 : 24, // Giảm kích thước biểu tượng
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: isTablet ? 20 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chào mừng Admin!',
                            style: TextStyle(
                              fontSize: isTablet ? 24 : 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Quản lý hệ thống FoodGo',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isTablet ? 24 : 16), // Giảm khoảng cách
              // Tiêu đề Quản lý hệ thống
              Text(
                'Quản lý hệ thống',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: isTablet ? 16 : 12),

              // Danh sách thẻ quản lý
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildVerticalCard(
                    icon: FontAwesomeIcons.layerGroup,
                    title: 'Quản lý danh mục',
                    subtitle: 'Thêm, sửa danh mục',
                    gradient: LinearGradient(
                      colors: [Colors.purple[400]!, Colors.purple[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CategoryManagement(),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  _buildVerticalCard(
                    icon: FontAwesomeIcons.utensils,
                    title: 'Quản lý sản phẩm',
                    subtitle: 'Thêm, sửa sản phẩm',
                    gradient: LinearGradient(
                      colors: [Colors.orange[400]!, Colors.orange[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FoodManagement(),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  _buildVerticalCard(
                    icon: FontAwesomeIcons.receipt,
                    title: 'Quản lý đơn hàng',
                    subtitle: 'Xem và xử lý đơn hàng',
                    gradient: LinearGradient(
                      colors: [Colors.blue[400]!, Colors.blue[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrderManagement(),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  _buildVerticalCard(
                    icon: FontAwesomeIcons.users,
                    title: 'Quản lý người dùng',
                    subtitle: 'Xem thông tin người dùng',
                    gradient: LinearGradient(
                      colors: [Colors.green[400]!, Colors.green[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserManagement(),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  _buildVerticalCard(
                    icon: FontAwesomeIcons.ticket,
                    title: 'Quản lý khuyến mãi',
                    subtitle: 'Tạo và quản lý mã khuyến mãi',
                    gradient: LinearGradient(
                      colors: [Colors.orange[400]!, Colors.orange[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PromoManagement(),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  _buildVerticalCard(
                    icon: FontAwesomeIcons.comments,
                    title: 'Quản lý đánh giá',
                    subtitle: 'Xem và quản lý đánh giá sản phẩm',
                    gradient: LinearGradient(
                      colors: [Colors.purple[400]!, Colors.purple[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReviewManagement(),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  _buildVerticalCard(
                    icon: FontAwesomeIcons.star,
                    title: 'Quản lý khách hàng thân thiết',
                    subtitle: 'Cấu hình chương trình khách hàng thân thiết',
                    gradient: LinearGradient(
                      colors: [Colors.amber[400]!, Colors.amber[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoyaltyManagement(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isTablet = screenWidth > 600;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isTablet ? 16 : 12), // Giảm padding
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 12 : 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
              ),
              child: Icon(
                icon,
                size: isTablet ? 24 : 20, // Giảm kích thước biểu tượng
                color: Colors.white,
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              FontAwesomeIcons.arrowRight,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
