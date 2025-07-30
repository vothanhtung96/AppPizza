import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pizza_app_vs_010/service/shared_pref.dart';
import 'package:pizza_app_vs_010/services/cart_service.dart';
import 'package:pizza_app_vs_010/services/notification_service.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  // Order status constants
  static const String STATUS_PENDING = 'pending';
  static const String STATUS_CONFIRMED = 'confirmed';
  static const String STATUS_PREPARING = 'preparing';
  static const String STATUS_DELIVERING = 'delivering';
  static const String STATUS_DELIVERED = 'delivered';
  static const String STATUS_CANCELLED = 'cancelled';
  static const String STATUS_PAID = 'paid';

  // Create new order
  Future<String?> createOrder({
    required String cartId,
    required List<Map<String, dynamic>> cartItems,
    required double subtotal,
    required double shippingFee,
    required double total,
    required String deliveryAddress,
    String? discountCode,
    double discount = 0.0,
    String paymentMethod = 'cod',
  }) async {
    try {
      String? userId = await SharedPreferenceHelper().getUserId();
      if (userId == null) {
        print('❌ User not logged in');
        throw Exception('User not logged in');
      }

      print('🔄 Creating order for user: $userId');
      print('📦 Cart items count: ${cartItems.length}');

      // Get user info
      var userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();

      var userData = userDoc.data() ?? {};
      print('👤 User data: ${userData['Name']}');

      // Create order document
      var orderData = {
        'userId': userId,
        'cartId': cartId,
        'userName': userData['Name'] ?? 'Khách hàng',
        'userEmail': userData['Email'] ?? '',
        'userPhone': userData['Phone'] ?? '',
        'deliveryAddress': deliveryAddress,
        'items': cartItems,
        'subtotal': subtotal,
        'shippingFee': shippingFee,
        'discount': discount,
        'discountCode': discountCode,
        'total': total,
        'paymentMethod': paymentMethod,
        'status': paymentMethod == 'wallet' ? STATUS_PAID : STATUS_PENDING,
        'statusHistory': [
          {
            'status': paymentMethod == 'wallet' ? STATUS_PAID : STATUS_PENDING,
            'timestamp': DateTime.now().toIso8601String(),
            'note': paymentMethod == 'wallet'
                ? 'Đơn hàng đã được thanh toán bằng ví'
                : 'Đơn hàng đã được tạo, chờ thanh toán COD',
          },
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'estimatedDeliveryTime': _calculateEstimatedDeliveryTime(),
      };

      print('📝 Creating order document...');
      DocumentReference orderRef = await FirebaseFirestore.instance
          .collection('orders')
          .add(orderData);

      print('✅ Order created successfully: ${orderRef.id}');

      // Mark cart as ordered
      print('🔄 Marking cart as ordered...');
      await CartService().markCartAsOrdered(cartId);
      print('✅ Cart marked as ordered');

      return orderRef.id;
    } catch (e) {
      print('❌ Error creating order: $e');
      return null;
    }
  }

  // Get user orders
  Future<List<Map<String, dynamic>>> getUserOrders() async {
    try {
      String? userId = await SharedPreferenceHelper().getUserId();
      if (userId == null) {
        print('❌ User not logged in for getUserOrders');
        return [];
      }

      print('🔄 Getting orders for user: $userId');

      // Retry logic for index building
      int maxRetries = 3;
      int retryCount = 0;

      while (retryCount < maxRetries) {
        try {
          print('📋 Attempt ${retryCount + 1}: Querying orders...');
          var ordersSnapshot = await FirebaseFirestore.instance
              .collection('orders')
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .get();

          List<Map<String, dynamic>> orders = [];
          for (var doc in ordersSnapshot.docs) {
            var data = doc.data();
            data['id'] = doc.id;
            orders.add(data);
          }

          print('✅ Found ${orders.length} orders');
          return orders;
        } catch (e) {
          retryCount++;
          print('⚠️ Attempt $retryCount failed for getUserOrders: $e');

          if (e.toString().contains('index') && retryCount < maxRetries) {
            print(
              '⏳ Index building in progress, waiting ${2 * retryCount} seconds...',
            );
            // Wait before retrying for index building
            await Future.delayed(Duration(seconds: 2 * retryCount));
            continue;
          } else {
            print('❌ Final error in getUserOrders: $e');
            // Return empty list instead of throwing
            return [];
          }
        }
      }

      print('⚠️ Max retries reached, returning empty list');
      return [];
    } catch (e) {
      print('❌ Error getting user orders: $e');
      return [];
    }
  }

  // Get order by ID
  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      var orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      if (orderDoc.exists) {
        var data = orderDoc.data()!;
        data['id'] = orderDoc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  // Update order status (for admin)
  Future<bool> updateOrderStatus(
    String orderId,
    String newStatus,
    String note,
  ) async {
    try {
      var orderRef = FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId);

      // Get current order
      var orderDoc = await orderRef.get();
      if (!orderDoc.exists) {
        return false;
      }

      var orderData = orderDoc.data()!;
      List<dynamic> statusHistory = List.from(orderData['statusHistory'] ?? []);

      // Add new status to history
      statusHistory.add({
        'status': newStatus,
        'timestamp': DateTime.now().toIso8601String(),
        'note': note,
      });

      // Update order
      await orderRef.update({
        'status': newStatus,
        'statusHistory': statusHistory,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Gửi thông báo trạng thái đơn hàng cho user
      String userId = orderData['userId'] ?? '';
      String orderNumber = orderId.substring(0, 8); // Lấy 8 ký tự đầu của orderId làm orderNumber
      
      if (userId.isNotEmpty) {
        await NotificationService.sendOrderStatusNotification(
          userId: userId,
          orderId: orderId,
          status: newStatus,
          orderNumber: orderNumber,
        );
      }

      return true;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  // Cancel order (for user)
  Future<bool> cancelOrder(String orderId) async {
    try {
      String? userId = await SharedPreferenceHelper().getUserId();
      if (userId == null) {
        print('❌ User not logged in for cancelOrder');
        return false;
      }

      print('🔄 Cancelling order: $orderId');

      // Get order to check if it belongs to user and can be cancelled
      var orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        print('❌ Order not found');
        return false;
      }

      var orderData = orderDoc.data()!;
      String orderUserId = orderData['userId'] ?? '';
      String currentStatus = orderData['status'] ?? '';

      // Check if order belongs to user
      if (orderUserId != userId) {
        print('❌ Order does not belong to user');
        return false;
      }

      // Check if order can be cancelled (only pending/paid orders)
      if (currentStatus != STATUS_PENDING && currentStatus != STATUS_PAID) {
        print('❌ Order cannot be cancelled in current status: $currentStatus');
        return false;
      }

      // Update order status to cancelled
      bool success = await updateOrderStatus(
        orderId,
        STATUS_CANCELLED,
        'Khách hàng đã hủy đơn hàng',
      );

      if (success) {
        print('✅ Order cancelled successfully');

        // If order was paid by wallet, refund the money
        if (currentStatus == STATUS_PAID) {
          double total = (orderData['total'] ?? 0.0).toDouble();
          String paymentMethod = orderData['paymentMethod'] ?? '';

          if (paymentMethod == 'wallet') {
            print('💰 Processing refund to wallet...');

            // Get current wallet balance
            var userDoc = await FirebaseFirestore.instance
                .collection('Users')
                .doc(userId)
                .get();

            var userData = userDoc.data() ?? {};
            double currentBalance =
                double.tryParse(userData['Wallet'] ?? '0') ?? 0.0;
            double newBalance = currentBalance + total;

            // Update wallet balance
            await SharedPreferenceHelper().saveUserWallet(
              newBalance.toString(),
            );
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(userId)
                .update({'Wallet': newBalance.toString()});

            print('✅ Refund processed: \$${total.toStringAsFixed(2)}');
          }
        }
      }

      return success;
    } catch (e) {
      print('❌ Error cancelling order: $e');
      return false;
    }
  }

  // Get all orders (for admin)
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      var ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> orders = [];
      for (var doc in ordersSnapshot.docs) {
        var data = doc.data();
        data['id'] = doc.id;
        orders.add(data);
      }

      return orders;
    } catch (e) {
      print('Error getting all orders: $e');
      return [];
    }
  }

  // Get orders by status (for admin)
  Future<List<Map<String, dynamic>>> getOrdersByStatus(String status) async {
    try {
      print('🔎 Truy vấn đơn hàng với status: $status');
      try {
        var ordersSnapshot = await FirebaseFirestore.instance
            .collection('orders')
            .where('status', isEqualTo: status)
            .orderBy('createdAt', descending: true)
            .get();

        List<Map<String, dynamic>> orders = [];
        for (var doc in ordersSnapshot.docs) {
          var data = doc.data();
          data['id'] = doc.id;
          orders.add(data);
          print('  - Đơn hàng: ${doc.id}, status: ${data['status']}');
        }
        print('==> Tổng số đơn hàng lấy được: ${orders.length}');
        return orders;
      } catch (e) {
        print('⚠️ Lỗi truy vấn where+orderBy (có thể do thiếu index): $e');
        print('🔄 Fallback: Lấy toàn bộ đơn hàng rồi lọc bằng code...');
        var allOrdersSnapshot = await FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .get();
        List<Map<String, dynamic>> orders = [];
        for (var doc in allOrdersSnapshot.docs) {
          var data = doc.data();
          data['id'] = doc.id;
          if ((data['status'] ?? '').toString().toLowerCase() == status.toLowerCase()) {
            orders.add(data);
            print('  - Đơn hàng: ${doc.id}, status: ${data['status']}');
          }
        }
        print('==> Tổng số đơn hàng lấy được (lọc bằng code): ${orders.length}');
        return orders;
      }
    } catch (e) {
      print('Error getting orders by status: $e');
      return [];
    }
  }

  // Get order statistics (for admin)
  Future<Map<String, dynamic>> getOrderStatistics() async {
    try {
      var ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .get();

      int totalOrders = ordersSnapshot.docs.length;
      double totalRevenue = 0.0;
      Map<String, int> statusCount = {};

      for (var doc in ordersSnapshot.docs) {
        var data = doc.data();
        totalRevenue += data['total'] ?? 0.0;

        String status = data['status'] ?? 'unknown';
        statusCount[status] = (statusCount[status] ?? 0) + 1;
      }

      return {
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'statusCount': statusCount,
      };
    } catch (e) {
      print('Error getting order statistics: $e');
      return {'totalOrders': 0, 'totalRevenue': 0.0, 'statusCount': {}};
    }
  }

  // Calculate estimated delivery time
  DateTime _calculateEstimatedDeliveryTime() {
    // Add 30-45 minutes for preparation and delivery
    return DateTime.now().add(Duration(minutes: 45));
  }

  // Get status display text
  static String getStatusDisplayText(String status) {
    switch (status) {
      case STATUS_PENDING:
        return 'Chờ xác nhận';
      case STATUS_PAID:
        return 'Đã thanh toán';
      case STATUS_CONFIRMED:
        return 'Đã xác nhận';
      case STATUS_PREPARING:
        return 'Đang chuẩn bị';
      case STATUS_DELIVERING:
        return 'Đang giao hàng';
      case STATUS_DELIVERED:
        return 'Đã giao hàng';
      case STATUS_CANCELLED:
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }

  // Get status color
  static int getStatusColor(String status) {
    switch (status) {
      case STATUS_PENDING:
        return 0xFFFFA500; // Orange
      case STATUS_PAID:
        return 0xFF4CAF50; // Green
      case STATUS_CONFIRMED:
        return 0xFF2196F3; // Blue
      case STATUS_PREPARING:
        return 0xFF9C27B0; // Purple
      case STATUS_DELIVERING:
        return 0xFF4CAF50; // Green
      case STATUS_DELIVERED:
        return 0xFF4CAF50; // Green
      case STATUS_CANCELLED:
        return 0xFFF44336; // Red
      default:
        return 0xFF9E9E9E; // Grey
    }
  }
}
