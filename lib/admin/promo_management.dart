import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pizza_app_vs_010/models/promo_model.dart';
import 'package:pizza_app_vs_010/services/notification_service.dart';

class PromoManagement extends StatefulWidget {
  const PromoManagement({super.key});

  @override
  State<PromoManagement> createState() => _PromoManagementState();
}

class _PromoManagementState extends State<PromoManagement> {
  List<PromoModel> promos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPromos();
  }

  Future<void> _loadPromos() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('promotions')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        promos = snapshot.docs.map((doc) {
          return PromoModel.fromMap(doc.data(), doc.id);
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading promos: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _createPromo() async {
    showDialog(
      context: context,
      builder: (context) => CreatePromoDialog(
        onPromoCreated: () {
          _loadPromos();
        },
      ),
    );
  }

  Future<void> _deletePromo(String promoId) async {
    try {
      await FirebaseFirestore.instance
          .collection('promotions')
          .doc(promoId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Đã xóa mã khuyến mãi'),
        ),
      );

      _loadPromos();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Có lỗi xảy ra: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý khuyến mãi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Thống kê
                _buildStats(),

                // Danh sách mã khuyến mãi
                Expanded(
                  child: promos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_offer,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Chưa có mã khuyến mãi nào',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: promos.length,
                          itemBuilder: (context, index) {
                            return _buildPromoCard(promos[index]);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPromo,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStats() {
    int activePromos = promos.where((p) => p.isValid()).length;
    int totalUses = promos.fold(0, (sum, p) => sum + (p.usedCount ?? 0));

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Mã đang hoạt động',
              activePromos.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Tổng lượt sử dụng',
              totalUses.toString(),
              Icons.people,
              Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCard(PromoModel promo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo.name ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mã: ${promo.code}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: promo.isValid() ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    promo.isValid() ? 'Hoạt động' : 'Hết hạn',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              promo.description ?? '',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.discount, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                Text(
                  promo.discountPercent != null && promo.discountPercent! > 0
                      ? 'Giảm ${promo.discountPercent}%'
                      : 'Không có khuyến mãi',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Điểm yêu cầu: ${promo.pointsRequired ?? '0'}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people, color: Colors.blue, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Đã sử dụng: ${promo.usedCount ?? 0}/${promo.maxUses ?? '∞'}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Từ ${promo.startDate?.toString().substring(0, 10) ?? 'N/A'} đến ${promo.endDate?.toString().substring(0, 10) ?? 'N/A'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                IconButton(
                  onPressed: () => _deletePromo(promo.id!),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CreatePromoDialog extends StatefulWidget {
  final VoidCallback onPromoCreated;

  const CreatePromoDialog({super.key, required this.onPromoCreated});

  @override
  State<CreatePromoDialog> createState() => _CreatePromoDialogState();
}

class _CreatePromoDialogState extends State<CreatePromoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _maxUsesController = TextEditingController();
  final _pointsRequiredController = TextEditingController();

  String discountType = 'percent'; // 'percent' or 'amount'
  double discountValue = 0.0;
  double maxDiscount = 0.0;
  DateTime? startDate;
  DateTime? endDate;
  bool sendToAllUsers = true;
  List<String> selectedUsers = [];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tạo mã khuyến mãi mới',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Mã khuyến mãi
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Mã khuyến mãi',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mã khuyến mãi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Tên khuyến mãi
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên khuyến mãi',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên khuyến mãi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Mô tả
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                // Loại giảm giá
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        value: 'percent',
                        groupValue: discountType,
                        onChanged: (value) {
                          setState(() {
                            discountType = value!;
                          });
                        },
                        title: const Text('Phần trăm'),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        value: 'amount',
                        groupValue: discountType,
                        onChanged: (value) {
                          setState(() {
                            discountType = value!;
                          });
                        },
                        title: const Text('Số tiền'),
                      ),
                    ),
                  ],
                ),

                // Giá trị giảm
                TextFormField(
                  decoration: InputDecoration(
                    labelText: discountType == 'percent'
                        ? 'Phần trăm giảm (%)'
                        : 'Số tiền giảm (\$)',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    discountValue = double.tryParse(value) ?? 0.0;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập giá trị giảm';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Giảm tối đa (chỉ cho phần trăm)
                if (discountType == 'percent')
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Giảm tối đa (\$)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      maxDiscount = double.tryParse(value) ?? 0.0;
                    },
                  ),
                const SizedBox(height: 12),

                // Điểm yêu cầu
                TextFormField(
                  controller: _pointsRequiredController,
                  decoration: const InputDecoration(
                    labelText: 'Điểm yêu cầu',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập điểm yêu cầu';
                    }
                    final points = int.tryParse(value);
                    if (points == null || points < 0) {
                      return 'Điểm yêu cầu phải là số không âm';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Đơn hàng tối thiểu
                TextFormField(
                  controller: _minOrderController,
                  decoration: const InputDecoration(
                    labelText: 'Đơn hàng tối thiểu (\$)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),

                // Số lần sử dụng tối đa
                TextFormField(
                  controller: _maxUsesController,
                  decoration: const InputDecoration(
                    labelText: 'Số lần sử dụng tối đa',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),

                // Ngày bắt đầu và kết thúc
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Từ ngày'),
                        subtitle: Text(
                          startDate?.toString().substring(0, 10) ?? 'Chọn ngày',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setState(() {
                              startDate = date;
                            });
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('Đến ngày'),
                        subtitle: Text(
                          endDate?.toString().substring(0, 10) ?? 'Chọn ngày',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(
                              const Duration(days: 30),
                            ),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setState(() {
                              endDate = date;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),

                // Gửi cho tất cả user
                CheckboxListTile(
                  title: const Text('Gửi cho tất cả người dùng'),
                  value: sendToAllUsers,
                  onChanged: (value) {
                    setState(() {
                      sendToAllUsers = value!;
                    });
                  },
                ),

                const SizedBox(height: 20),

                // Nút tạo
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _createPromo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Tạo mã'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createPromo() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Tạo promo model
      var promo = PromoModel(
        code: _codeController.text.trim().toUpperCase(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        discountPercent: discountType == 'percent' ? discountValue : null,
        minOrderAmount: double.tryParse(_minOrderController.text),
        maxUses: int.tryParse(_maxUsesController.text),
        isActive: true,
        applicableUsers: sendToAllUsers ? [] : selectedUsers,
        startDate: startDate ?? DateTime.now(),
        endDate: endDate ?? DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        createdBy: 'admin',
        pointsRequired: _pointsRequiredController.text.trim().isEmpty 
            ? null 
            : _pointsRequiredController.text.trim(),
      );

      // Lưu vào Firestore
      await FirebaseFirestore.instance
          .collection('promotions')
          .add(promo.toMap());

      // Gửi thông báo khuyến mãi cho tất cả user
      await NotificationService.sendPromotionNotificationToAllUsers(
        promoTitle: _nameController.text.trim(),
        promoDescription: _descriptionController.text.trim(),
      );

      // Gửi thông báo cho user (nếu gửi cho tất cả)
      if (sendToAllUsers) {
        await _sendNotificationToAllUsers(promo);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Đã tạo mã khuyến mãi thành công!'),
        ),
      );

      // Kiểm tra context có thể pop không trước khi gọi Navigator.pop
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      widget.onPromoCreated();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Có lỗi xảy ra: $e'),
        ),
      );
    }
  }

  Future<void> _sendNotificationToAllUsers(PromoModel promo) async {
    try {
      // Lấy tất cả user
      var usersSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .get();

      // Tạo thông báo cho từng user
      for (var userDoc in usersSnapshot.docs) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': userDoc.id,
          'title': 'Mã khuyến mãi mới!',
          'message': 'Bạn có mã khuyến mãi mới: ${promo.code} - ${promo.name}',
          'type': 'promo',
          'promoId': promo.id,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error sending notifications: $e');
    }
  }
}
