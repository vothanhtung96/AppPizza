import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pizza_app_vs_010/models/promo_model.dart';
import 'package:pizza_app_vs_010/service/shared_pref.dart';
import 'package:pizza_app_vs_010/services/notification_service.dart';

class LoyaltyManagement extends StatefulWidget {
  const LoyaltyManagement({super.key});

  @override
  State<LoyaltyManagement> createState() => _LoyaltyManagementState();
}

class _LoyaltyManagementState extends State<LoyaltyManagement> {
  bool isLoading = false;
  String? errorMessage;
  String? userId;
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountPercentController = TextEditingController();
  final _pointsRequiredController = TextEditingController();
  final _minOrderAmountController = TextEditingController();
  final _maxUsesController = TextEditingController();
  bool _isActive = true;
  String? _editingPromoId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    try {
      userId = await SharedPreferenceHelper().getUserId();
      if (userId == null) {
        setState(() {
          errorMessage = 'Vui lòng đăng nhập để quản lý mã khuyến mãi!';
          isLoading = false;
        });
        return;
      }
      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi khi tải thông tin người dùng: $e';
        isLoading = false;
      });
      print('❌ Error loading user data: $e');
    }
  }

  Future<List<PromoModel>> _loadPromos() async {
    try {
      print('📥 Loading promotions from Firestore...');
      final snapshot = await FirebaseFirestore.instance
          .collection('promotions')
          .get();
      final promos = snapshot.docs.map((doc) {
        try {
          return PromoModel.fromMap(doc.data(), doc.id);
        } catch (e) {
          print('❌ Error parsing promo ${doc.id}: $e');
          return PromoModel(
            id: doc.id,
            code: 'ERROR',
            name: 'Mã không hợp lệ',
            isActive: false,
            applicableUsers: [],
            createdAt: DateTime.now(),
          );
        }
      }).toList();
      promos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      print('✅ Loaded ${promos.length} promos');
      return promos;
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi khi tải mã khuyến mãi: $e';
      });
      print('❌ Error loading promos: $e');
      return [];
    }
  }

  Future<void> _savePromo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final discountPercent = _discountPercentController.text.trim();
      final percent = double.tryParse(discountPercent);
      if (percent == null || percent <= 0 || percent > 100) {
        setState(() {
          errorMessage = 'Phần trăm khuyến mãi phải lớn hơn 0 và nhỏ hơn hoặc bằng 100!';
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Phần trăm khuyến mãi phải lớn hơn 0 và nhỏ hơn hoặc bằng 100!'),
          ),
        );
        return;
      }

      final pointsRequired = _pointsRequiredController.text.trim();
      final points = int.tryParse(pointsRequired);
      if (points == null || points <= 0) {
        setState(() {
          errorMessage = 'Điểm yêu cầu phải là số dương!';
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Điểm yêu cầu phải là số dương!'),
          ),
        );
        return;
      }

      final code = _codeController.text.trim().toUpperCase();
      if (_editingPromoId == null) {
        final existingPromo = await FirebaseFirestore.instance
            .collection('promotions')
            .where('code', isEqualTo: code)
            .get();
        if (existingPromo.docs.isNotEmpty) {
          setState(() {
            errorMessage = 'Mã khuyến mãi đã tồn tại!';
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              content: Text('Mã khuyến mãi đã tồn tại!'),
            ),
          );
          return;
        }
      }

      // Preserve existing data for editing
      int usedCount = 0;
      Timestamp createdAt = Timestamp.now();
      List<String> applicableUsers = [];
      if (_editingPromoId != null) {
        final promoDoc = await FirebaseFirestore.instance
            .collection('promotions')
            .doc(_editingPromoId)
            .get();
        if (promoDoc.exists) {
          usedCount = promoDoc.data()?['usedCount']?.toInt() ?? 0;
          createdAt = promoDoc.data()?['createdAt'] ?? Timestamp.now();
          applicableUsers = List<String>.from(
            promoDoc.data()?['applicableUsers'] ?? [],
          );
        }
      }

      final promoData = {
        'code': code,
        'name': _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'discountPercent': percent,
        'minOrderAmount':
            double.tryParse(_minOrderAmountController.text) ?? 0.0,
        'maxUses': int.tryParse(_maxUsesController.text) ?? 0,
        'usedCount': usedCount,
        'pointsRequired': points.toString(), // Store as string for consistency
        'isActive': _isActive,
        'applicableUsers': applicableUsers,
        'createdAt': createdAt,
        'createdBy': userId,
        'startDate': Timestamp.now(),
        'endDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
      };

      if (_editingPromoId == null) {
        await FirebaseFirestore.instance
            .collection('promotions')
            .add(promoData);
        await NotificationService.sendPromotionNotificationToAllUsers(
          promoTitle: _nameController.text.trim(),
          promoDescription: _descriptionController.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Thêm mã khuyến mãi thành công!'),
          ),
        );
      } else {
        await FirebaseFirestore.instance
            .collection('promotions')
            .doc(_editingPromoId)
            .set(promoData, SetOptions(merge: true));
        await NotificationService.sendPromotionNotificationToAllUsers(
          promoTitle: _nameController.text.trim(),
          promoDescription: _descriptionController.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Cập nhật mã khuyến mãi thành công!'),
          ),
        );
      }

      _clearForm();
      setState(() {}); // Refresh promo list
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi khi lưu mã khuyến mãi: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Lỗi khi lưu mã khuyến mãi: $e'),
        ),
      );
      print('❌ Error saving promo: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _togglePromoStatus(String promoId, bool currentStatus) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('promotions')
          .doc(promoId)
          .update({'isActive': !currentStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            !currentStatus
                ? 'Kích hoạt mã thành công!'
                : 'Hủy kích hoạt mã thành công!',
          ),
        ),
      );
      setState(() {}); // Refresh promo list
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi khi thay đổi trạng thái: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Lỗi khi thay đổi trạng thái: $e'),
        ),
      );
      print('❌ Error toggling promo status: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deletePromo(String promoId, String code) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('promotions')
          .doc(promoId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text('Đã xóa mã $code thành công!'),
        ),
      );
      setState(() {}); // Refresh promo list
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi khi xóa mã: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Lỗi khi xóa mã: $e'),
        ),
      );
      print('❌ Error deleting promo: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _editPromo(PromoModel promo) {
    setState(() {
      _editingPromoId = promo.id;
      _codeController.text = promo.code;
      _nameController.text = promo.name ?? '';
      _descriptionController.text = promo.description ?? '';
      _discountPercentController.text = promo.discountPercent?.toString() ?? '';
      _pointsRequiredController.text = promo.pointsRequired ?? '';
      _minOrderAmountController.text = promo.minOrderAmount?.toString() ?? '';
      _maxUsesController.text = promo.maxUses?.toString() ?? '';
      _isActive = promo.isActive;
    });
  }

  void _clearForm() {
    setState(() {
      _editingPromoId = null;
      _codeController.clear();
      _nameController.clear();
      _descriptionController.clear();
      _discountPercentController.clear();
      _pointsRequiredController.clear();
      _minOrderAmountController.clear();
      _maxUsesController.clear();
      _isActive = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý mã khuyến mãi'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
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
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage!,
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      color: Colors.red[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        errorMessage = null;
                        isLoading = true;
                      });
                      _loadUserData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await _loadUserData();
                setState(() {});
              },
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isTablet ? 24 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thêm/Sửa mã khuyến mãi',
                      style: TextStyle(
                        fontSize: isTablet ? 28 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPromoForm(),
                    const SizedBox(height: 24),
                    Text(
                      'Danh sách mã khuyến mãi',
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPromoList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPromoForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Mã khuyến mãi',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mã khuyến mãi';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên khuyến mãi (Tùy chọn)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => null, // Optional field
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả (Tùy chọn)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => null, // Optional field
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _discountPercentController,
                decoration: const InputDecoration(
                  labelText: 'Phần trăm khuyến mãi (%)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập phần trăm khuyến mãi';
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0 || parsed > 100) {
                    return 'Phần trăm phải lớn hơn 0 và nhỏ hơn hoặc bằng 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pointsRequiredController,
                decoration: const InputDecoration(
                  labelText: 'Điểm yêu cầu',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số điểm yêu cầu';
                  }
                  final parsed = int.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Điểm yêu cầu phải là số dương';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _minOrderAmountController,
                decoration: const InputDecoration(
                  labelText: 'Đơn hàng tối thiểu (\$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số tiền tối thiểu';
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Số tiền tối thiểu phải là số dương';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxUsesController,
                decoration: const InputDecoration(
                  labelText: 'Số lần sử dụng tối đa',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số lần sử dụng tối đa';
                  }
                  final parsed = int.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Số lần sử dụng phải là số dương';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Kích hoạt'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Xác nhận'),
                            content: Text(
                              _editingPromoId != null
                                  ? 'Bạn muốn cập nhật mã khuyến mãi này?'
                                  : 'Bạn muốn thêm mã khuyến mãi này?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Hủy'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('Đồng ý'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _savePromo();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        _editingPromoId != null ? 'Cập nhật' : 'Thêm',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _clearForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoList() {
    return FutureBuilder<List<PromoModel>>(
      future: _loadPromos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print('❌ Error in FutureBuilder: ${snapshot.error}');
          return Text(
            'Lỗi: ${snapshot.error}',
            style: TextStyle(color: Colors.red[600]),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text(
            'Chưa có mã khuyến mãi nào.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          );
        }

        final promos = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: promos.length,
          itemBuilder: (context, index) {
            final promo = promos[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(
                  '${promo.code} - ${promo.name ?? 'Không có tên'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Giảm: ${promo.discountPercent?.toStringAsFixed(2) ?? '0'}% | '
                  'Điểm: ${promo.pointsRequired ?? '0'} | '
                  'Tối thiểu: ${promo.minOrderAmount?.toStringAsFixed(2) ?? '0'}\$ | '
                  'Lượt dùng: ${promo.usedCount ?? 0}/${promo.maxUses ?? '∞'} | '
                  'Hết hạn: ${promo.endDate != null ? promo.endDate!.toString().substring(0, 10) : 'Không xác định'}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editPromo(promo),
                      tooltip: 'Chỉnh sửa',
                    ),
                    IconButton(
                      icon: Icon(
                        promo.isActive ? Icons.toggle_on : Icons.toggle_off,
                        color: promo.isActive ? Colors.green : Colors.grey,
                      ),
                      onPressed: () =>
                          _togglePromoStatus(promo.id!, promo.isActive),
                      tooltip: promo.isActive ? 'Hủy kích hoạt' : 'Kích hoạt',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deletePromo(promo.id!, promo.code),
                      tooltip: 'Xóa',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
