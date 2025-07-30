import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pizza_app_vs_010/service/shared_pref.dart';
import 'package:pizza_app_vs_010/services/cart_provider.dart';
import 'package:pizza_app_vs_010/services/cart_service.dart';
import 'package:pizza_app_vs_010/services/order_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Order extends StatefulWidget {
  const Order({super.key});

  @override
  _OrderState createState() => _OrderState();
}

class _OrderState extends State<Order> {
  double discount = 0.0;
  double shippingFee = 5.0; // Fixed shipping fee
  double total = 0.0;
  String? userId;
  String? userName;
  String? userEmail;
  String? userAddress;
  double userWallet = 0.0;

  // Payment form controllers
  TextEditingController cardNumberController = TextEditingController();
  TextEditingController expiryController = TextEditingController();
  TextEditingController cvcController = TextEditingController();
  TextEditingController zipController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController discountCodeController = TextEditingController();

  bool isCheckoutMode = false;
  bool isProcessingPayment = false;
  String? appliedDiscountCode;
  double discountPercentage = 0.0;

  // Available discount codes
  final Map<String, double> discountCodes = {
    'SAVE10': 0.10, // 10% off
    'SAVE20': 0.20, // 20% off
    'SAVE30': 0.30, // 30% off
    'WELCOME': 0.15, // 15% off for new users
  };

  @override
  void initState() {
    super.initState();
    getthesharedpref();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadCart();
    });
  }

  @override
  void dispose() {
    cardNumberController.dispose();
    expiryController.dispose();
    cvcController.dispose();
    zipController.dispose();
    addressController.dispose();
    discountCodeController.dispose();
    super.dispose();
  }

  void getthesharedpref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = await SharedPreferenceHelper().getUserId();
    userName = prefs.getString('Name') ?? 'Khách hàng';
    userEmail = prefs.getString('Email') ?? '';
    userAddress = prefs.getString('Address') ?? '';
    userWallet = double.parse(prefs.getString('Wallet') ?? '0.0');
    if (userAddress != null && userAddress!.isNotEmpty) {
      addressController.text = userAddress!;
    }

    setState(() {});
  }

  void _calculateTotal() {
    discount = context.read<CartProvider>().subtotal * discountPercentage;
    total = context.read<CartProvider>().subtotal - discount + shippingFee;
  }

  void applyDiscountCode() {
    String code = discountCodeController.text.trim().toUpperCase();
    if (discountCodes.containsKey(code)) {
      setState(() {
        appliedDiscountCode = code;
        discountPercentage = discountCodes[code]!;
        _calculateTotal();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mã giảm giá $code đã được áp dụng!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mã giảm giá không hợp lệ!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void processOrder() async {
    if (userId == null || context.read<CartProvider>().cartItems.isEmpty) {
      return;
    }

    setState(() {
      isProcessingPayment = true;
    });

    try {
      // Get current cart ID
      String? cartId = await CartService().getCurrentCartId();
      if (cartId == null) {
        throw Exception('Không thể lấy thông tin giỏ hàng');
      }

      // Create order using OrderService
      String? orderId = await OrderService().createOrder(
        cartId: cartId,
        cartItems: context.read<CartProvider>().cartItems,
        subtotal: context.read<CartProvider>().subtotal,
        shippingFee: shippingFee,
        total: total,
        deliveryAddress: addressController.text,
        discountCode: appliedDiscountCode,
        discount: discount,
        paymentMethod: 'cod',
      );

      if (orderId != null) {
        // Clear cart after successful order
        await context.read<CartProvider>().clearCart();

        setState(() {
          isProcessingPayment = false;
          isCheckoutMode = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đặt hàng thành công! Mã đơn hàng: #${orderId.substring(0, 8)}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to order status page
        Navigator.pushReplacementNamed(context, '/order_status');
      } else {
        throw Exception('Không thể tạo đơn hàng');
      }
    } catch (e) {
      setState(() {
        isProcessingPayment = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = MediaQuery.of(context).size.width > 600;

    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        _calculateTotal();

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(
              isCheckoutMode ? 'Thanh toán' : 'Giỏ hàng',
              style: TextStyle(
                fontSize: isTablet ? 24.0 : 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
            actions: [
              if (!isCheckoutMode && cartProvider.cartItems.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.delete_sweep),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Xóa giỏ hàng'),
                        content: Text(
                          'Bạn có chắc muốn xóa tất cả sản phẩm trong giỏ hàng?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              cartProvider.clearCart();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: Text('Xóa'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              // Cart Items
              Expanded(child: _buildCartContent(cartProvider, isTablet)),

              // Checkout Section
              if (cartProvider.cartItems.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Order Summary
                      if (!isCheckoutMode) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tổng tiền hàng:',
                              style: TextStyle(
                                fontSize: isTablet ? 18.0 : 16.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '\$${cartProvider.subtotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: isTablet ? 18.0 : 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Phí vận chuyển:',
                              style: TextStyle(
                                fontSize: isTablet ? 18.0 : 16.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '\$${shippingFee.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: isTablet ? 18.0 : 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (discount > 0) ...[
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Giảm giá:',
                                style: TextStyle(
                                  fontSize: isTablet ? 18.0 : 16.0,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                '-\$${discount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: isTablet ? 18.0 : 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                        Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tổng cộng:',
                              style: TextStyle(
                                fontSize: isTablet ? 20.0 : 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${total.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: isTablet ? 20.0 : 18.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        // Checkout Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/checkout');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Thanh toán',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Checkout Form
                        _buildCheckoutForm(isTablet),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Build cart content based on state
  Widget _buildCartContent(CartProvider cartProvider, bool isTablet) {
    // Show loading state
    if (cartProvider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            SizedBox(height: 16),
            Text(
              'Đang tải giỏ hàng...',
              style: TextStyle(
                fontSize: isTablet ? 16.0 : 14.0,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Show error state
    if (cartProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: isTablet ? 80 : 64,
              color: Colors.red[400],
            ),
            SizedBox(height: 16),
            Text(
              'Có lỗi xảy ra',
              style: TextStyle(
                fontSize: isTablet ? 20.0 : 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                cartProvider.error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTablet ? 14.0 : 12.0,
                  color: Colors.grey[600],
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => cartProvider.refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    // Show empty cart
    if (cartProvider.cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.shoppingCart,
              size: isTablet ? 120 : 100,
              color: Colors.grey[400],
            ),
            SizedBox(height: 24),
            Text(
              'Giỏ hàng trống',
              style: TextStyle(
                fontSize: isTablet ? 24.0 : 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Hãy thêm sản phẩm vào giỏ hàng',
              style: TextStyle(
                fontSize: isTablet ? 16.0 : 14.0,
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text('Mua sắm ngay'),
            ),
          ],
        ),
      );
    }

    // Show cart items
    return ListView.builder(
      padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
      itemCount: cartProvider.cartItems.length,
      itemBuilder: (context, index) {
        var item = cartProvider.cartItems[index];
        return _buildCartItem(item, isTablet, cartProvider);
      },
    );
  }

  Widget _buildCartItem(
    Map<String, dynamic> item,
    bool isTablet,
    CartProvider cartProvider,
  ) {
    String itemId = item['id'] ?? '';
    String name = item['productName'] ?? item['name'] ?? '';
    double price = (item['price'] ?? 0.0).toDouble();
    int quantity = (item['quantity'] ?? 1).toInt();
    String image = item['productImage'] ?? item['image'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 16.0 : 12.0),
      padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
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
        children: [
          // Product Image
          Container(
            width: isTablet ? 100 : 80,
            height: isTablet ? 100 : 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildImageWidget(image, isTablet),
            ),
          ),

          SizedBox(width: isTablet ? 20.0 : 16.0),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: isTablet ? 18.0 : 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isTablet ? 16.0 : 14.0,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    // Quantity Controls
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => cartProvider.updateQuantity(
                              itemId,
                              quantity - 1,
                            ),
                            icon: Icon(Icons.remove, size: isTablet ? 20 : 18),
                            padding: EdgeInsets.all(8),
                            constraints: BoxConstraints(
                              minWidth: isTablet ? 40 : 36,
                              minHeight: isTablet ? 40 : 36,
                            ),
                          ),
                          SizedBox(
                            width: isTablet ? 50 : 40,
                            child: Text(
                              quantity.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isTablet ? 16.0 : 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => cartProvider.updateQuantity(
                              itemId,
                              quantity + 1,
                            ),
                            icon: Icon(Icons.add, size: isTablet ? 20 : 18),
                            padding: EdgeInsets.all(8),
                            constraints: BoxConstraints(
                              minWidth: isTablet ? 40 : 36,
                              minHeight: isTablet ? 40 : 36,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Spacer(),

                    // Remove Button
                    IconButton(
                      onPressed: () => cartProvider.removeItem(itemId),
                      icon: Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Xóa sản phẩm',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl, bool isTablet) {
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
      return _getDefaultImage(isTablet);
    }
  }

  Widget _getDefaultImage(bool isTablet) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.fastfood,
        size: isTablet ? 40 : 32,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildCheckoutForm(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông tin thanh toán',
          style: TextStyle(
            fontSize: isTablet ? 20.0 : 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20),

        // Discount Code
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: discountCodeController,
                decoration: InputDecoration(
                  labelText: 'Mã giảm giá',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            ElevatedButton(
              onPressed: applyDiscountCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('Áp dụng'),
            ),
          ],
        ),

        SizedBox(height: 20),

        // Address
        TextField(
          controller: addressController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Địa chỉ giao hàng',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        SizedBox(height: 20),

        // Payment Method (simplified)
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.credit_card, color: Colors.orange),
              SizedBox(width: 12),
              Text(
                'Thanh toán khi nhận hàng (COD)',
                style: TextStyle(
                  fontSize: isTablet ? 16.0 : 14.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 24),

        // Order Summary
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tổng tiền hàng:'),
                  Text(
                    '\$${context.read<CartProvider>().subtotal.toStringAsFixed(2)}',
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Phí vận chuyển:'),
                  Text('\$${shippingFee.toStringAsFixed(2)}'),
                ],
              ),
              if (discount > 0) ...[
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Giảm giá:', style: TextStyle(color: Colors.green)),
                    Text(
                      '-\$${discount.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ],
              Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tổng cộng:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 24),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    isCheckoutMode = false;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Quay lại'),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: isProcessingPayment ? null : processOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isProcessingPayment
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Đặt hàng'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
