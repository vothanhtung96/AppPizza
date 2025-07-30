import 'package:cloud_firestore/cloud_firestore.dart';

class PromoModel {
  final String? id;
  final String code;
  final String? name;
  final String? description;
  final double? discountPercent;
  final double? minOrderAmount;
  final double? maxDiscount;
  final int? maxUses;
  final String? pointsRequired;
  final int? usedCount;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final List<String> applicableUsers;
  final DateTime createdAt;
  final String? createdBy;
  final Map<String, int>? userRedemptions;

  PromoModel({
    this.id,
    required this.code,
    this.name,
    this.description,
    this.discountPercent,
    this.minOrderAmount,
    this.maxDiscount,
    this.maxUses,
    this.usedCount,
    this.startDate,
    this.endDate,
    this.pointsRequired,
    required this.isActive,
    required this.applicableUsers,
    required this.createdAt,
    this.createdBy,
    this.userRedemptions,
  });

  factory PromoModel.fromMap(Map<String, dynamic> map, String id) {
    return PromoModel(
      id: id,
      code: map['code']?.toString() ?? 'ERROR',
      name: map['name']?.toString(),
      description: map['description']?.toString(),
      discountPercent: (map['discountPercent'] as num?)?.toDouble(),
      minOrderAmount: map['minOrderAmount']?.toDouble(),
      maxDiscount: map['maxDiscount']?.toDouble(),
      maxUses: map['maxUses'] != null
          ? int.tryParse(map['maxUses'].toString())
          : null,
      usedCount: map['usedCount'] != null
          ? int.tryParse(map['usedCount'].toString())
          : 0,
      startDate: map['startDate'] != null
          ? (map['startDate'] as Timestamp).toDate()
          : null,
      endDate: map['endDate'] != null
          ? (map['endDate'] as Timestamp).toDate()
          : null,
      isActive: map['isActive'] == true,
      applicableUsers: List<String>.from(map['applicableUsers'] ?? []),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: map['createdBy']?.toString(),
      userRedemptions: (map['userRedemptions'] as Map?)?.map((k, v) => MapEntry(k as String, (v as num).toInt())),
      pointsRequired: map['pointsRequired']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'description': description,
      'discountPercent': discountPercent,
      'minOrderAmount': minOrderAmount,
      'maxDiscount': maxDiscount,
      'maxUses': maxUses,
      'usedCount': usedCount,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'applicableUsers': applicableUsers,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'userRedemptions': userRedemptions,
      'pointsRequired': pointsRequired,
    };
  }

  bool isValid() {
    final now = DateTime.now();
    return isActive &&
        (startDate == null ||
            startDate!.isBefore(now) ||
            startDate!.isAtSameMomentAs(now)) &&
        (endDate == null || endDate!.isAfter(now)) &&
        (maxUses == null || usedCount == null || usedCount! < maxUses!);
  }

  bool isApplicableForUser(String userId) {
    return isValid() &&
        (applicableUsers.isEmpty || applicableUsers.contains(userId));
  }

  double calculateDiscount(double orderAmount) {
    if (!isActive || orderAmount < (minOrderAmount ?? 0)) {
      return 0.0;
    }

    double discount = 0.0;

    if (discountPercent != null && discountPercent! > 0) {
      discount = orderAmount * (discountPercent! / 100);
      if (maxDiscount != null && maxDiscount! > 0) {
        discount = discount > maxDiscount! ? maxDiscount! : discount;
      }
    } else if (discountPercent != null && discountPercent! > 0) {
      discount = orderAmount * (discountPercent! / 100);
    }

    return discount;
  }
}
