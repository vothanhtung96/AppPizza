import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pizza_app_vs_010/services/cart_service.dart';
import 'package:pizza_app_vs_010/service/shared_pref.dart';

class ReorderService {
  static final ReorderService _instance = ReorderService._internal();
  factory ReorderService() => _instance;
  ReorderService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CartService _cartService = CartService();

  // Lấy thông tin chi tiết đơn hàng cũ
  Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (orderDoc.exists) {
        return orderDoc.data();
      }
      return null;
    } catch (e) {
      print('Error getting order details: $e');
      return null;
    }
  }

  // Thêm tất cả items từ đơn hàng cũ vào giỏ hàng
  Future<bool> reorderItems(String orderId) async {
    try {
      final orderData = await getOrderDetails(orderId);
      if (orderData == null) {
        print('❌ Order not found: $orderId');
        return false;
      }

      final userId = await SharedPreferenceHelper().getUserId();
      if (userId == null) {
        print('❌ User not logged in');
        return false;
      }

      final items = orderData['items'] as List<dynamic>? ?? [];
      if (items.isEmpty) {
        print('❌ No items in order');
        return false;
      }

      print('🔄 Reordering ${items.length} items from order: $orderId');

      // Clear current cart first
      await _cartService.clearCart();

      // Add each item to cart
      for (var item in items) {
        final foodData = {
          'id': item['productId'] ?? '',
          'Name': item['productName'] ?? '',
          'Price': item['price'] ?? 0,
          'Image': item['productImage'] ?? '',
          'Detail': item['productDetail'] ?? '',
          'Category': item['category'] ?? 'General',
        };

        final quantity = item['quantity'] ?? 1;

        // Add to cart with quantity
        await _cartService.addToCartWithQuantity(foodData, quantity);

        print('✅ Added ${item['productName']} x$quantity to cart');
      }

      print('✅ Reorder completed successfully');
      return true;
    } catch (e) {
      print('❌ Error during reorder: $e');
      return false;
    }
  }

  // Thêm từng sản phẩm riêng lẻ vào giỏ hàng
  Future<bool> reorderSingleItem(Map<String, dynamic> item) async {
    try {
      final userId = await SharedPreferenceHelper().getUserId();
      if (userId == null) {
        print('❌ User not logged in');
        return false;
      }

      final foodData = {
        'id': item['productId'] ?? '',
        'Name': item['productName'] ?? '',
        'Price': item['price'] ?? 0,
        'Image': item['productImage'] ?? '',
        'Detail': item['productDetail'] ?? '',
        'Category': item['category'] ?? 'General',
      };

      final quantity = item['quantity'] ?? 1;

      // Add to cart with quantity
      await _cartService.addToCartWithQuantity(foodData, quantity);

      print('✅ Added single item ${item['productName']} x$quantity to cart');
      return true;
    } catch (e) {
      print('❌ Error adding single item: $e');
      return false;
    }
  }

  // Lấy danh sách sản phẩm từ đơn hàng
  List<Map<String, dynamic>> getOrderItems(Map<String, dynamic> orderData) {
    try {
      final items = orderData['items'] as List<dynamic>? ?? [];
      return items.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('Error getting order items: $e');
      return [];
    }
  }

  // Kiểm tra xem đơn hàng có thể mua lại không
  bool canReorder(String status) {
    // Cho phép mua lại đơn hàng đã hoàn thành, đã giao hàng hoặc đã hủy
    return status == 'completed' ||
        status == 'delivered' ||
        status == 'cancelled';
  }

  // Lấy thông tin địa chỉ giao hàng từ đơn hàng cũ
  Map<String, dynamic>? getDeliveryAddress(Map<String, dynamic> orderData) {
    try {
      final deliveryAddress = orderData['deliveryAddress'];
      if (deliveryAddress != null) {
        return {
          'city': deliveryAddress['city'] ?? '',
          'district': deliveryAddress['district'] ?? '',
          'ward': deliveryAddress['ward'] ?? '',
          'street': deliveryAddress['street'] ?? '',
          'fullAddress': deliveryAddress['fullAddress'] ?? '',
        };
      }
      return null;
    } catch (e) {
      print('Error getting delivery address: $e');
      return null;
    }
  }

  // Lấy thông tin thanh toán từ đơn hàng cũ
  Map<String, dynamic>? getPaymentInfo(Map<String, dynamic> orderData) {
    try {
      return {
        'paymentMethod': orderData['paymentMethod'] ?? 'cod',
        'promoCode': orderData['promoCode'] ?? '',
        'discountAmount': orderData['discountAmount'] ?? 0.0,
      };
    } catch (e) {
      print('Error getting payment info: $e');
      return null;
    }
  }
}
