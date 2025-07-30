import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pizza_app_vs_010/services/order_service.dart';

class OrderManagement extends StatefulWidget {
  const OrderManagement({super.key});

  @override
  _OrderManagementState createState() => _OrderManagementState();
}

class _OrderManagementState extends State<OrderManagement> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  String selectedStatus = 'all';

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
      if (selectedStatus == 'all') {
        orders = await OrderService().getAllOrders();
      } else {
        orders = await OrderService().getOrdersByStatus(selectedStatus);
      }
    } catch (e) {
      print('Error loading orders: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      String note = '';
      switch (newStatus) {
        case OrderService.STATUS_CONFIRMED:
          note = 'Admin đã xác nhận đơn hàng';
          break;
        case OrderService.STATUS_PREPARING:
          note = 'Đang chuẩn bị đơn hàng';
          break;
        case OrderService.STATUS_DELIVERING:
          note = 'Đang giao hàng';
          break;
        case OrderService.STATUS_DELIVERED:
          note = 'Đã giao hàng thành công';
          break;
        case OrderService.STATUS_CANCELLED:
          note = 'Đơn hàng đã bị hủy';
          break;
      }

      bool success = await OrderService().updateOrderStatus(
        orderId,
        newStatus,
        note,
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Cập nhật trạng thái thành công'),
          ),
        );
        loadOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Có lỗi xảy ra khi cập nhật'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Quản lý đơn hàng',
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
      body: Column(
        children: [
          // Filter section
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Text(
                  'Lọc theo trạng thái: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedStatus,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Chờ xác nhận'),
                      ),
                      DropdownMenuItem(
                        value: 'paid',
                        child: Text('Đã thanh toán'),
                      ),
                      DropdownMenuItem(
                        value: 'confirmed',
                        child: Text('Đã xác nhận'),
                      ),
                      DropdownMenuItem(
                        value: 'preparing',
                        child: Text('Đang chuẩn bị'),
                      ),
                      DropdownMenuItem(
                        value: 'delivering',
                        child: Text('Đang giao hàng'),
                      ),
                      DropdownMenuItem(
                        value: 'delivered',
                        child: Text('Đã giao hàng'),
                      ),
                      DropdownMenuItem(
                        value: 'cancelled',
                        child: Text('Đã hủy'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                      print('Lọc theo trạng thái: $selectedStatus');
                      loadOrders();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Orders list
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FontAwesomeIcons.receipt,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Không có đơn hàng nào',
                          style: TextStyle(
                            fontSize: isTablet ? 20.0 : 18.0,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      var order = orders[index];
                      return _buildOrderCard(order, isTablet);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, bool isTablet) {
    String status = order['status'] ?? 'unknown';
    String statusText = OrderService.getStatusDisplayText(status);
    int statusColor = OrderService.getStatusColor(status);

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đơn hàng #${order['id']?.substring(0, 8) ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: isTablet ? 18.0 : 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(statusColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(statusColor)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: Color(statusColor),
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 14.0 : 12.0,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            Text('Khách hàng: ${order['userName'] ?? 'N/A'}'),
            Text('SĐT: ${order['userPhone'] ?? 'N/A'}'),
            Text('Địa chỉ: ${order['deliveryAddress'] ?? 'N/A'}'),
            Text(
              'Phương thức: ${order['paymentMethod'] == 'wallet' ? 'Ví' : 'COD'}',
            ),
            Text('Tổng tiền: \$${(order['total'] ?? 0.0).toStringAsFixed(2)}'),

            SizedBox(height: 16),

            // Status update buttons
            if (status == OrderService.STATUS_PENDING ||
                status == OrderService.STATUS_PAID)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => updateOrderStatus(
                        order['id'],
                        OrderService.STATUS_CONFIRMED,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Xác nhận'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => updateOrderStatus(
                        order['id'],
                        OrderService.STATUS_CANCELLED,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Hủy'),
                    ),
                  ),
                ],
              ),

            if (status == OrderService.STATUS_CONFIRMED)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => updateOrderStatus(
                        order['id'],
                        OrderService.STATUS_PREPARING,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Chuẩn bị'),
                    ),
                  ),
                ],
              ),

            if (status == OrderService.STATUS_PREPARING)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => updateOrderStatus(
                        order['id'],
                        OrderService.STATUS_DELIVERING,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Giao hàng'),
                    ),
                  ),
                ],
              ),

            if (status == OrderService.STATUS_DELIVERING)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => updateOrderStatus(
                        order['id'],
                        OrderService.STATUS_DELIVERED,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Hoàn thành'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
