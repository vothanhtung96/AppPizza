import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pizza_app_vs_010/models/promo_model.dart';
import 'package:pizza_app_vs_010/service/shared_pref.dart';

class LoyaltyPage extends StatefulWidget {
  const LoyaltyPage({super.key});

  @override
  State<LoyaltyPage> createState() => _LoyaltyPageState();
}

class _LoyaltyPageState extends State<LoyaltyPage> {
  bool isLoading = false;
  String? errorMessage;
  String? userId;
  int userPoints = 0;
  List<PromoModel> promos = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPromos();
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    try {
      userId = await SharedPreferenceHelper().getUserId();
      if (userId == null) {
        setState(() {
          errorMessage = 'Vui lòng đăng nhập để xem điểm thưởng!';
          isLoading = false;
        });
        return;
      }
      await _syncLoyaltyPoints();
      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi khi tải thông tin người dùng: $e';
        isLoading = false;
      });
      print('❌ Error loading user data: $e');
    }
  }

  Future<void> _syncLoyaltyPoints() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        int firestorePoints =
            (userDoc.data()?['loyaltyPoints'] as num?)?.toInt() ?? 0;
        await SharedPreferenceHelper().saveUserLoyaltyPoints(firestorePoints);
        setState(() {
          userPoints = firestorePoints;
        });
        print('✅ Synced loyalty points: $userPoints');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi khi đồng bộ điểm thưởng: $e';
      });
      print('❌ Error syncing loyalty points: $e');
    }
  }

  Future<void> _loadPromos() async {
    try {
      print('📥 Loading promotions from Firestore...');
      final snapshot = await FirebaseFirestore.instance
          .collection('promotions')
          .where('isActive', isEqualTo: true)
          .get();
      final loadedPromos = snapshot.docs.map((doc) {
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
      setState(() {
        promos = loadedPromos.where((promo) => promo.isValid()).toList();
        promos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
      print('✅ Loaded ${promos.length} valid promos');
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi khi tải mã khuyến mãi: $e';
      });
      print('❌ Error loading promos: $e');
    }
  }

  Widget _buildPromoList() {
    if (promos.isEmpty) {
      return const Text(
        'Chưa có điểm thưởng nào.',
        style: TextStyle(color: Colors.grey, fontSize: 14),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: promos.length,
      itemBuilder: (context, index) {
        final promo = promos[index];
        final userRedeemedCount = promo.userRedemptions != null && userId != null
            ? (promo.userRedemptions![userId!] ?? 0)
            : 0;
        final canRedeem =
            userPoints >= (int.tryParse(promo.pointsRequired ?? '0') ?? 0) &&
            (promo.maxUses == null || userRedeemedCount < promo.maxUses!);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            // Ẩn mã, chỉ hiện tên điểm thưởng
            title: Text(
              promo.name ?? 'Điểm thưởng',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (promo.description != null && promo.description!.isNotEmpty)
                  Text('Mô tả: ${promo.description}'),
                Text('Phần trăm khuyến mãi: ${promo.discountPercent?.toStringAsFixed(2) ?? '0'}%'),
                // Text('Điểm yêu cầu: promo.pointsRequired ?? '0'}'), // Đã ẩn trường này
                Text('Đơn hàng tối thiểu: ${promo.minOrderAmount?.toStringAsFixed(2) ?? '0'}'),
                Text('Số lần sử dụng tối đa: ${promo.maxUses ?? '∞'}'),
                Text('Bạn đã đổi: $userRedeemedCount lần'),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: canRedeem
                  ? () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Xác nhận đổi điểm thưởng'),
                          content: const Text('Bạn muốn đổi điểm thưởng này?'),
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
                        await _redeemPromo(promo, userRedeemedCount);
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canRedeem ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: const Text('Đổi'),
            ),
          ),
        );
      },
    );
  }

  Future<void> _redeemPromo(PromoModel promo, int userRedeemedCount) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Vui lòng đăng nhập để đổi mã!'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final pointsRequired = int.tryParse(promo.pointsRequired ?? '0') ?? 0;
      if (userPoints < pointsRequired) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Bạn không đủ điểm để đổi mã này!'),
          ),
        );
        setState(() => isLoading = false);
        return;
      }

      // Kiểm tra số lần đã đổi
      if (promo.maxUses != null && userRedeemedCount >= promo.maxUses!) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Bạn đã đổi tối đa số lần cho phép!'),
          ),
        );
        setState(() => isLoading = false);
        return;
      }

      // Update Firestore: tăng số lần đổi của user
      await FirebaseFirestore.instance
          .collection('promotions')
          .doc(promo.id)
          .update({
            'userRedemptions.$userId': userRedeemedCount + 1,
            'usedCount': FieldValue.increment(1),
          });

      // Trừ điểm
      final newPoints = userPoints - pointsRequired;
      await FirebaseFirestore.instance.collection('Users').doc(userId).update({
        'loyaltyPoints': newPoints,
      });
      await SharedPreferenceHelper().saveUserLoyaltyPoints(newPoints);

      // Update local state
      setState(() {
        userPoints = newPoints;
        promos = promos.map((p) {
          if (p.id == promo.id) {
            final updatedRedemptions = Map<String, int>.from(p.userRedemptions ?? {});
            updatedRedemptions[userId!] = userRedeemedCount + 1;
            return PromoModel.fromMap({
              ...p.toMap(),
              'userRedemptions': updatedRedemptions,
              'usedCount': (p.usedCount ?? 0) + 1,
            }, p.id!);
          }
          return p;
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text('Đổi mã ${promo.code} thành công!'),
        ),
      );
      print('✅ Redeemed promo ${promo.code}, new points: $newPoints');
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi khi đổi mã: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Lỗi khi đổi mã: $e'),
        ),
      );
      print('❌ Error redeeming promo: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đổi điểm thưởng'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
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
                      _loadPromos();
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
                await _loadPromos();
                setState(() {});
              },
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isTablet ? 24 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Số điểm hiện tại: $userPoints điểm',
                      style: TextStyle(
                        fontSize: isTablet ? 24 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mã khuyến mãi có sẵn',
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
}
