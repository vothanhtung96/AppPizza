import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pizza_app_vs_010/service/shared_pref.dart';
import 'package:pizza_app_vs_010/services/order_service.dart';
import 'package:pizza_app_vs_010/services/reorder_service.dart';
import 'package:pizza_app_vs_010/widgets/reorder_dialog.dart';

class OrderStatusPage extends StatefulWidget {
  const OrderStatusPage({super.key});

  @override
  _OrderStatusPageState createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  bool isCancelling = false;
  bool isReordering = false;
  String? userId;
  final ReorderService _reorderService = ReorderService();

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    setState(() {
      isLoading = true;
    });

    try {
      userId = await SharedPreferenceHelper().getUserId();
      if (userId != null) {
        orders = await OrderService().getUserOrders();
      }
    } catch (e) {
      print('Error loading orders: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Lịch sử đơn hàng',
          style: TextStyle(
            fontSize: isTablet ? 24.0 : 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: loadOrders)],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FontAwesomeIcons.receipt, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có đơn hàng nào',
                    style: TextStyle(
                      fontSize: isTablet ? 20.0 : 18.0,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hãy đặt hàng để xem lịch sử',
                    style: TextStyle(
                      fontSize: isTablet ? 16.0 : 14.0,
                      color: Colors.grey[500],
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: Text('Mua sắm ngay'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: loadOrders,
              child: ListView.builder(
                padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  var order = orders[index];
                  return _buildOrderCard(order, isTablet);
                },
              ),
            ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, bool isTablet) {
    String orderId = order['id'] ?? '';
    String status = order['status'] ?? '';
    double total = (order['total'] ?? 0.0).toDouble();
    String deliveryAddress = order['deliveryAddress'] ?? '';

    // Parse createdAt - could be Timestamp or string
    DateTime? createdAt;
    var createdAtData = order['createdAt'];
    if (createdAtData != null) {
      if (createdAtData is String) {
        try {
          createdAt = DateTime.parse(createdAtData);
        } catch (e) {
          print('Error parsing createdAt string: $e');
        }
      } else {
        try {
          createdAt = createdAtData.toDate();
        } catch (e) {
          print('Error converting createdAt: $e');
        }
      }
    }

    List<dynamic> items = order['items'] ?? [];
    List<dynamic> statusHistory = order['statusHistory'] ?? [];

    print('📋 Building order card for: $orderId, status: $status');

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 20.0 : 16.0),
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
        children: [
          // Order Header
          Container(
            padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
            decoration: BoxDecoration(
              color: Color(
                OrderService.getStatusColor(status),
              ).withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đơn hàng #${orderId.substring(0, 8)}',
                        style: TextStyle(
                          fontSize: isTablet ? 18.0 : 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        createdAt != null
                            ? '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}'
                            : 'Không xác định',
                        style: TextStyle(
                          fontSize: isTablet ? 14.0 : 12.0,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(OrderService.getStatusColor(status)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    OrderService.getStatusDisplayText(status),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 14.0 : 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Order Items
          Container(
            padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sản phẩm (${items.length}):',
                  style: TextStyle(
                    fontSize: isTablet ? 16.0 : 14.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                ...items.map<Widget>((item) {
                  String name = item['foodName'] ?? item['name'] ?? '';
                  int quantity = item['quantity'] ?? 1;
                  double price = (item['price'] ?? 0.0).toDouble();

                  return Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$name x$quantity',
                            style: TextStyle(fontSize: isTablet ? 14.0 : 12.0),
                          ),
                        ),
                        Text(
                          '\$${(price * quantity).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 12.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                Divider(height: 24),

                // Order Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tổng cộng:',
                      style: TextStyle(
                        fontSize: isTablet ? 16.0 : 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: isTablet ? 16.0 : 14.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Delivery Address
                if (deliveryAddress.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          deliveryAddress,
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 12.0,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                ],

                // Status History
                if (statusHistory.isNotEmpty) ...[
                  Text(
                    'Lịch sử trạng thái:',
                    style: TextStyle(
                      fontSize: isTablet ? 16.0 : 14.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  ...statusHistory.map<Widget>((statusItem) {
                    String statusText = statusItem['status'] ?? '';
                    String note = statusItem['note'] ?? '';
                    DateTime? timestamp;

                    // Parse timestamp - could be string ISO8601 or Timestamp
                    var timestampData = statusItem['timestamp'];
                    if (timestampData != null) {
                      if (timestampData is String) {
                        try {
                          timestamp = DateTime.parse(timestampData);
                        } catch (e) {
                          print('Error parsing timestamp string: $e');
                        }
                      } else if (timestampData is DateTime) {
                        timestamp = timestampData;
                      } else {
                        // Try to convert to DateTime if it's a Timestamp
                        try {
                          timestamp = timestampData.toDate();
                        } catch (e) {
                          print('Error converting timestamp: $e');
                        }
                      }
                    }

                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Color(
                                OrderService.getStatusColor(statusText),
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  OrderService.getStatusDisplayText(statusText),
                                  style: TextStyle(
                                    fontSize: isTablet ? 14.0 : 12.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (note.isNotEmpty) ...[
                                  SizedBox(height: 2),
                                  Text(
                                    note,
                                    style: TextStyle(
                                      fontSize: isTablet ? 12.0 : 10.0,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                                if (timestamp != null) ...[
                                  SizedBox(height: 2),
                                  Text(
                                    '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: isTablet ? 12.0 : 10.0,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),

          // Action buttons
          Container(
            padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Cancel button (for pending orders)
                if (status == 'pending')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isCancelling
                          ? null
                          : () => _cancelOrder(orderId),
                      icon: isCancelling
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Icon(Icons.cancel, size: 16),
                      label: Text(
                        isCancelling ? 'Đang hủy...' : 'Hủy đơn hàng',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 16 : 12,
                        ),
                      ),
                    ),
                  ),

                // Reorder button (for completed/delivered/cancelled orders)
                if (_reorderService.canReorder(status))
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isReordering
                          ? null
                          : () => _showReorderDialog(orderId),
                      icon: isReordering
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Icon(Icons.refresh, size: 16),
                      label: Text(isReordering ? 'Đang xử lý...' : 'Mua lại'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 16 : 12,
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

  void _showCancelDialog(String orderId) {
    print('🔄 Show cancel dialog for order: $orderId');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Hủy đơn hàng'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc muốn hủy đơn hàng này?'),
            SizedBox(height: 8),
            Text(
              'Mã đơn hàng: ${orderId.substring(0, 8)}...',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '• Đơn hàng sẽ được hủy vĩnh viễn\n• Nếu đã thanh toán bằng ví, tiền sẽ được hoàn lại\n• Không thể khôi phục sau khi hủy',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Không hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelOrder(orderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Hủy đơn hàng'),
          ),
        ],
      ),
    );
  }

  void _showReorderDialog(String orderId) {
    // Tìm order data từ danh sách orders
    final orderData = orders.firstWhere(
      (order) => order['id'] == orderId,
      orElse: () => {},
    );

    if (orderData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tìm thấy thông tin đơn hàng')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ReorderDialog(
        orderId: orderId,
        orderData: orderData,
        onReorderComplete: () {
          // Có thể thêm logic refresh nếu cần
        },
      ),
    );
  }

  Future<void> _cancelOrder(String orderId) async {
    setState(() {
      isCancelling = true;
    });

    try {
      bool success = await OrderService().cancelOrder(orderId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã hủy đơn hàng thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        await loadOrders(); // Reload orders
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra khi hủy đơn hàng'),
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
    } finally {
      setState(() {
        isCancelling = false;
      });
    }
  }

  Future<void> _reorderItems(String orderId) async {
    setState(() {
      isReordering = true;
    });

    try {
      bool success = await _reorderService.reorderItems(orderId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã thêm sản phẩm vào giỏ hàng! Chuyển đến giỏ hàng để thanh toán.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Xem giỏ hàng',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, '/order');
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra khi mua lại đơn hàng'),
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
    } finally {
      setState(() {
        isReordering = false;
      });
    }
  }
}
