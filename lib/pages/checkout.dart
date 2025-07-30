import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:pizza_app_vs_010/models/address_model.dart';
import 'package:pizza_app_vs_010/models/promo_model.dart';
import 'package:pizza_app_vs_010/service/shared_pref.dart';
import 'package:pizza_app_vs_010/services/cart_provider.dart';
import 'package:pizza_app_vs_010/services/order_service.dart';
import 'package:provider/provider.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? userId;
  String? selectedCity;
  String? selectedDistrict;
  String? selectedWard;
  String? streetAddress;
  double shippingFee = 5.0;
  String? promoCode;
  PromoModel? appliedPromo;
  String paymentMethod = 'cod'; // 'cod' or 'wallet'
  double walletBalance = 0.0;
  int userPoints = 0; // Sử dụng int cho điểm
  bool isLoading = false;
  bool showAddressForm = false;
  List<Map<String, dynamic>> savedAddresses = [];
  String? selectedAddressId;

  TextEditingController promoController = TextEditingController();
  TextEditingController streetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    selectedCity = 'TP. Hồ Chí Minh';
    _registerDeviceToken();
  }

  Future<void> _registerDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && userId != null) {
        await FirebaseFirestore.instance.collection('Users').doc(userId).update(
          {
            'deviceTokens': FieldValue.arrayUnion([token]),
          },
        );
        print('📱 Device token registered for user: $userId');
      }
    } catch (e) {
      print('❌ Error registering device token: $e');
    }
  }

  Future<void> _loadUserData() async {
    userId = await SharedPreferenceHelper().getUserId();
    if (userId == null) {
      print('❌ User ID is null');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Không thể tải thông tin người dùng. Vui lòng đăng nhập lại.',
          ),
        ),
      );
      return;
    }
    walletBalance = double.parse(
      await SharedPreferenceHelper().getUserWallet() ?? '0',
    );
    userPoints = await SharedPreferenceHelper().getUserLoyaltyPoints() ?? 0;
    // Đồng bộ với Firestore
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        int firestorePoints =
            (userDoc.data()?['loyaltyPoints'] as num?)?.toInt() ?? 0;
        if (firestorePoints != userPoints) {
          await SharedPreferenceHelper().saveUserLoyaltyPoints(firestorePoints);
          userPoints = firestorePoints;
        }
      }
    } catch (e) {
      print('❌ Error syncing loyalty points from Firestore: $e');
    }
    await _loadSavedAddresses();
    setState(() {});
  }

  Future<void> _loadSavedAddresses() async {
    if (userId == null) return;
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('addresses')
          .get();
      savedAddresses = querySnapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
      if (savedAddresses.isNotEmpty) {
        final defaultAddress = savedAddresses.firstWhere(
          (address) => address['isDefault'] == true,
          orElse: () => savedAddresses.first,
        );
        selectedAddressId = defaultAddress['id'];
        _updateAddressFields(defaultAddress);
      } else {
        showAddressForm = true;
      }
      setState(() {});
    } catch (e) {
      print('❌ Error loading addresses: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Lỗi khi tải địa chỉ: $e'),
        ),
      );
    }
  }

  void _updateAddressFields(Map<String, dynamic> address) {
    setState(() {
      selectedCity = address['city'];
      selectedDistrict = address['district'];
      selectedWard = address['ward'];
      streetAddress = address['street'];
      streetController.text = streetAddress ?? '';
      _updateShippingFee();
    });
  }

  Future<void> _saveNewAddress() async {
    if (selectedCity == null ||
        selectedDistrict == null ||
        selectedWard == null ||
        streetController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Vui lòng nhập đầy đủ thông tin địa chỉ'),
        ),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });
      final newAddress = {
        'street': streetController.text.trim(),
        'ward': selectedWard,
        'district': selectedDistrict,
        'city': selectedCity,
        'isDefault': savedAddresses.isEmpty,
      };
      final docRef = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('addresses')
          .add(newAddress);
      await _loadSavedAddresses();
      setState(() {
        showAddressForm = false;
        selectedAddressId = docRef.id;
        _updateAddressFields({...newAddress, 'id': docRef.id});
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Đã lưu địa chỉ mới'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Lỗi khi lưu địa chỉ: $e'),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteAddress(String addressId) async {
    try {
      setState(() {
        isLoading = true;
      });
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId)
          .delete();
      await _loadSavedAddresses();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Đã xóa địa chỉ'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Lỗi khi xóa địa chỉ: $e'),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _setDefaultAddress(String addressId) async {
    try {
      setState(() {
        isLoading = true;
      });
      final batch = FirebaseFirestore.instance.batch();
      for (var address in savedAddresses) {
        batch.update(
          FirebaseFirestore.instance
              .collection('Users')
              .doc(userId)
              .collection('addresses')
              .doc(address['id']),
          {'isDefault': false},
        );
      }
      batch.update(
        FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .collection('addresses')
            .doc(addressId),
        {'isDefault': true},
      );
      await batch.commit();
      await _loadSavedAddresses();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Đã đặt địa chỉ làm mặc định'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Lỗi khi đặt địa chỉ mặc định: $e'),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _updateShippingFee() {
    if (selectedCity != null && selectedDistrict != null) {
      setState(() {
        shippingFee = AddressData.calculateShippingFee(
          selectedCity!,
          selectedDistrict!,
        );
      });
    }
  }

  Future<void> _applyPromoCode() async {
    if (promoController.text.trim().isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      var promoQuery = await FirebaseFirestore.instance
          .collection('promotions')
          .where('code', isEqualTo: promoController.text.trim().toUpperCase())
          .get();

      if (promoQuery.docs.isNotEmpty) {
        var promoDoc = promoQuery.docs.first;
        var promo = PromoModel.fromMap(promoDoc.data(), promoDoc.id);

        if (promo.isValid() && promo.isApplicableForUser(userId!)) {
          setState(() {
            appliedPromo = promo;
            promoCode = promo.code;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green,
              content: Text('Mã khuyến mãi đã được áp dụng!'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text('Mã khuyến mãi không hợp lệ hoặc đã hết hạn!'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Mã khuyến mãi không tồn tại!'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Có lỗi xảy ra: $e'),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _placeOrder() async {
    print('🔄 Starting order placement...');

    if (userId == null) {
      print('❌ User ID is null');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Không thể xác định người dùng. Vui lòng đăng nhập lại.',
          ),
        ),
      );
      return;
    }

    if (selectedCity != 'TP. Hồ Chí Minh') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Cửa hàng chỉ giao hàng tại TP. Hồ Chí Minh!'),
        ),
      );
      return;
    }

    if (selectedDistrict == null || selectedWard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Vui lòng chọn địa chỉ giao hàng đầy đủ!'),
        ),
      );
      return;
    }

    if (streetController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Vui lòng nhập đường/số nhà!'),
        ),
      );
      return;
    }

    if (paymentMethod == 'wallet' && walletBalance < _calculateTotal()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Số dư ví không đủ để thanh toán!'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      print('📦 Getting cart data...');
      final cartProvider = context.read<CartProvider>();
      final cartItems = cartProvider.cartItems;
      final subtotal = cartProvider.subtotal;
      final discount = appliedPromo?.calculateDiscount(subtotal) ?? 0.0;
      final total = _calculateTotal();

      // Tính điểm kiếm được
      int pointsEarned = (total / 10).floor() * 2;
      print(
        '🏆 Points earned: $pointsEarned (Total: \$${total.toStringAsFixed(2)})',
      );

      print('📊 Order summary:');
      print('   - Items: ${cartItems.length}');
      print('   - Subtotal: \$${subtotal.toStringAsFixed(2)}');
      print('   - Shipping: \$${shippingFee.toStringAsFixed(2)}');
      print('   - Discount: \$${discount.toStringAsFixed(2)}');
      print('   - Total: \$${total.toStringAsFixed(2)}');

      String fullAddress =
          '${streetController.text}, $selectedWard, $selectedDistrict, $selectedCity';
      print('📍 Delivery address: $fullAddress');

      String? cartId = await cartProvider.getCurrentCartId();
      if (cartId == null) {
        print('❌ Cannot get cart ID');
        throw Exception('Không thể lấy cart ID');
      }

      print('🛒 Cart ID: $cartId');
      print('💳 Payment method: $paymentMethod');

      String? orderId = await OrderService().createOrder(
        cartId: cartId,
        cartItems: cartItems,
        subtotal: subtotal,
        shippingFee: shippingFee,
        total: total,
        deliveryAddress: fullAddress,
        discountCode: promoCode,
        discount: discount,
        paymentMethod: paymentMethod,
      );

      if (orderId == null) {
        print('❌ Order creation failed');
        throw Exception('Không thể tạo đơn hàng');
      }

      print('✅ Order created successfully: $orderId');

      // Cập nhật điểm
      if (pointsEarned > 0) {
        int newPoints = userPoints + pointsEarned;
        print(
          '🏆 Updating loyalty points for user $userId: $userPoints + $pointsEarned = $newPoints',
        );
        await FirebaseFirestore.instance.collection('Users').doc(userId).set({
          'loyaltyPoints': newPoints,
        }, SetOptions(merge: true));
        await SharedPreferenceHelper().saveUserLoyaltyPoints(newPoints);
        setState(() {
          userPoints = newPoints;
        });
      }

      // Nếu thanh toán bằng ví, trừ tiền
      if (paymentMethod == 'wallet') {
        print('💰 Processing wallet payment...');
        double newBalance = walletBalance - total;
        await SharedPreferenceHelper().saveUserWallet(newBalance.toString());
        await FirebaseFirestore.instance.collection('Users').doc(userId).set({
          'Wallet': newBalance.toString(),
        }, SetOptions(merge: true));
        print('✅ Wallet updated: \$${newBalance.toStringAsFixed(2)}');
        setState(() {
          walletBalance = newBalance;
        });
      }

      print('🗑️ Clearing cart...');
      await cartProvider.clearCart();
      print('✅ Cart cleared');

      String successMessage = paymentMethod == 'wallet'
          ? 'Đặt hàng thành công! Đơn hàng đã được thanh toán. Mã đơn hàng: $orderId. Bạn đã nhận được $pointsEarned điểm.'
          : 'Đặt hàng thành công! Vui lòng chuẩn bị tiền để thanh toán khi nhận hàng. Mã đơn hàng: $orderId. Bạn đã nhận được $pointsEarned điểm.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(successMessage),
          duration: Duration(seconds: 4),
        ),
      );

      print('🎉 Order placement completed successfully');
      print(
        '📋 Order status: ${paymentMethod == 'wallet' ? 'PAID' : 'PENDING'}',
      );

      await Future.delayed(Duration(seconds: 2));
      Navigator.pushReplacementNamed(context, '/order_status');
    } catch (e) {
      print('❌ Error in _placeOrder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Có lỗi xảy ra: $e'),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  double _calculateTotal() {
    final cartProvider = context.read<CartProvider>();
    final subtotal = cartProvider.subtotal;
    final discount = appliedPromo?.calculateDiscount(subtotal) ?? 0.0;
    return subtotal + shippingFee - discount;
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final subtotal = cartProvider.subtotal;
    final discount = appliedPromo?.calculateDiscount(subtotal) ?? 0.0;
    final total = _calculateTotal();

    return Scaffold(
      appBar: AppBar(
        title: Text('Thông tin thanh toán'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPromoSection(),
                  SizedBox(height: 20),
                  _buildAddressSection(),
                  SizedBox(height: 20),
                  _buildPaymentSection(),
                  SizedBox(height: 20),
                  _buildOrderSummary(subtotal, discount, total),
                  SizedBox(height: 30),
                  _buildOrderButton(total),
                ],
              ),
            ),
    );
  }

  Widget _buildPromoSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mã khuyến mãi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: promoController,
                    decoration: InputDecoration(
                      hintText: 'Nhập mã khuyến mãi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _applyPromoCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Áp dụng'),
                ),
              ],
            ),
            if (appliedPromo != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đã áp dụng mã: ${appliedPromo!.code}',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          appliedPromo = null;
                          promoCode = null;
                          promoController.clear();
                        });
                      },
                      icon: Icon(Icons.close, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Địa chỉ giao hàng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (savedAddresses.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        showAddressForm = true;
                        selectedAddressId = null;
                        selectedCity = 'TP. Hồ Chí Minh';
                        selectedDistrict = null;
                        selectedWard = null;
                        streetController.clear();
                      });
                    },
                    child: const Text(
                      'Thêm địa chỉ mới',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cửa hàng chỉ giao hàng tại TP. Hồ Chí Minh\nQuận 1: \$5 | Các quận khác: \$3',
                      style: TextStyle(color: Colors.blue[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (savedAddresses.isNotEmpty && !showAddressForm)
              Column(
                children: savedAddresses.map((address) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedAddressId == address['id']
                            ? Colors.orange
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text(
                        '${address['street']}, ${address['ward']}, ${address['district']}, ${address['city']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: address['isDefault']
                          ? const Text(
                              'Mặc định',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!address['isDefault'])
                            IconButton(
                              icon: const Icon(
                                Icons.star_border,
                                color: Colors.blue,
                              ),
                              onPressed: () =>
                                  _setDefaultAddress(address['id']),
                              tooltip: 'Đặt làm mặc định',
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteAddress(address['id']),
                            tooltip: 'Xóa địa chỉ',
                          ),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          selectedAddressId = address['id'];
                          _updateAddressFields(address);
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            if (showAddressForm || savedAddresses.isEmpty) ...[
              DropdownButtonFormField<String>(
                value: selectedCity ?? 'TP. Hồ Chí Minh',
                decoration: const InputDecoration(
                  labelText: 'Thành phố',
                  border: OutlineInputBorder(),
                ),
                items: ['TP. Hồ Chí Minh'].map((city) {
                  return DropdownMenuItem(value: city, child: Text(city));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCity = value;
                    selectedDistrict = null;
                    selectedWard = null;
                    streetController.clear();
                  });
                  _updateShippingFee();
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedDistrict,
                decoration: const InputDecoration(
                  labelText: 'Quận/Huyện',
                  border: OutlineInputBorder(),
                ),
                items: selectedCity != null
                    ? AddressData.getDistricts(selectedCity!).map((district) {
                        return DropdownMenuItem(
                          value: district,
                          child: Text(district),
                        );
                      }).toList()
                    : [],
                onChanged: (value) {
                  setState(() {
                    selectedDistrict = value;
                    selectedWard = null;
                    streetController.clear();
                  });
                  _updateShippingFee();
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedWard,
                decoration: const InputDecoration(
                  labelText: 'Phường/Xã',
                  border: OutlineInputBorder(),
                ),
                items: (selectedCity != null && selectedDistrict != null)
                    ? AddressData.getWards(
                        selectedCity!,
                        selectedDistrict!,
                      ).map((ward) {
                        return DropdownMenuItem(value: ward, child: Text(ward));
                      }).toList()
                    : [],
                onChanged: (value) {
                  setState(() {
                    selectedWard = value;
                    streetController.clear();
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: streetController,
                decoration: const InputDecoration(
                  labelText: 'Đường/Số nhà',
                  border: OutlineInputBorder(),
                  hintText: 'Ví dụ: 123 Nguyễn Huệ, P. Bến Nghé',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveNewAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Lưu địa chỉ mới'),
                    ),
                  ),
                  if (savedAddresses.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            showAddressForm = false;
                            if (selectedAddressId != null) {
                              final address = savedAddresses.firstWhere(
                                (addr) => addr['id'] == selectedAddressId,
                              );
                              _updateAddressFields(address);
                            }
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Hủy'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
            if (selectedDistrict != null && !showAddressForm)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_shipping,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Phí vận chuyển: \$${shippingFee.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
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

  Widget _buildPaymentSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Phương thức thanh toán',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: paymentMethod == 'cod'
                      ? Colors.orange
                      : Colors.grey[300]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: RadioListTile<String>(
                value: 'cod',
                groupValue: paymentMethod,
                onChanged: (value) {
                  setState(() {
                    paymentMethod = value!;
                  });
                },
                title: Row(
                  children: [
                    Icon(Icons.money, color: Colors.orange, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Thanh toán khi nhận hàng (COD)',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: paymentMethod == 'wallet'
                      ? Colors.green
                      : Colors.grey[300]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: RadioListTile<String>(
                value: 'wallet',
                groupValue: paymentMethod,
                onChanged: (value) {
                  setState(() {
                    paymentMethod = value!;
                  });
                },
                title: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: Colors.green,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Thanh toán bằng ví (\$${walletBalance.toStringAsFixed(2)}) | Điểm: $userPoints',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(double subtotal, double discount, double total) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tóm tắt đơn hàng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tổng tiền hàng:'),
                Text('\$${subtotal.toStringAsFixed(2)}'),
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
                  Text('Giảm giá:'),
                  Text(
                    '-\$${discount.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ],
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Điểm thưởng hiện tại:'),
                Text('$userPoints điểm', style: TextStyle(color: Colors.blue)),
              ],
            ),
            Divider(),
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
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Bạn sẽ nhận được ${(total / 10).floor() * 2} điểm sau đơn hàng này',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderButton(double total) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text('Quay lại'),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text('Đặt hàng'),
          ),
        ),
      ],
    );
  }
}
