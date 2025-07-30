import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pizza_app_vs_010/service/shared_pref.dart';

class MigrationService {
  static final MigrationService _instance = MigrationService._internal();
  factory MigrationService() => _instance;
  MigrationService._internal();

  // Migrate cart data from subcollection to new structure
  Future<bool> migrateCartData() async {
    try {
      String? userId = await SharedPreferenceHelper().getUserId();
      if (userId == null) {
        print('User not logged in for migration');
        return false;
      }

      // Get old cart data from subcollection
      var oldCartSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Cart')
          .get();

      if (oldCartSnapshot.docs.isEmpty) {
        print('No old cart data to migrate');
        return true;
      }

      // Create new cart
      var newCartRef = await FirebaseFirestore.instance.collection('cart').add({
        'userId': userId,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Migrate cart items
      for (var oldCartDoc in oldCartSnapshot.docs) {
        var oldData = oldCartDoc.data();

        // Create new cart item
        await FirebaseFirestore.instance.collection('cartItems').add({
          'cartId': newCartRef.id,
          'productId': oldData['id'] ?? '',
          'productName': oldData['name'] ?? oldData['Name'] ?? '',
          'productImage': oldData['image'] ?? oldData['Image'] ?? '',
          'quantity': oldData['quantity'] ?? 1,
          'price': oldData['price'] ?? 0.0,
          'note': '',
          'createdAt': oldData['addedAt'] ?? FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Delete old cart data
      for (var doc in oldCartSnapshot.docs) {
        await doc.reference.delete();
      }

      print('Cart migration completed successfully');
      return true;
    } catch (e) {
      print('Error migrating cart data: $e');
      return false;
    }
  }

  // Migrate orders from old structure to new structure
  Future<bool> migrateOrdersData() async {
    try {
      String? userId = await SharedPreferenceHelper().getUserId();
      if (userId == null) {
        print('User not logged in for migration');
        return false;
      }

      // Get old orders
      var oldOrdersSnapshot = await FirebaseFirestore.instance
          .collection('Orders')
          .where('UserID', isEqualTo: userId)
          .get();

      if (oldOrdersSnapshot.docs.isEmpty) {
        print('No old orders to migrate');
        return true;
      }

      // Migrate each order
      for (var oldOrderDoc in oldOrdersSnapshot.docs) {
        var oldData = oldOrderDoc.data();

        // Create new order
        await FirebaseFirestore.instance.collection('orders').add({
          'userId': oldData['UserID'] ?? userId,
          'cartId': '', // No cart ID for old orders
          'userName': oldData['userName'] ?? '',
          'userEmail': '',
          'userPhone': '',
          'deliveryAddress': oldData['userAddress'] ?? '',
          'items': oldData['items'] ?? [],
          'subtotal': oldData['subtotal'] ?? 0.0,
          'shippingFee': oldData['shippingFee'] ?? 0.0,
          'discount': oldData['discount'] ?? 0.0,
          'discountCode': oldData['discountCode'] ?? '',
          'total': oldData['total'] ?? 0.0,
          'paymentMethod': oldData['paymentMethod'] ?? 'cod',
          'status': _mapOldStatusToNew(oldData['status'] ?? 'pending'),
          'statusHistory': [
            {
              'status': _mapOldStatusToNew(oldData['status'] ?? 'pending'),
              'timestamp': oldData['orderDate'] ?? FieldValue.serverTimestamp(),
              'note': 'Migrated from old order structure',
            },
          ],
          'estimatedDeliveryTime': _calculateEstimatedDeliveryTime(),
          'createdAt': oldData['orderDate'] ?? FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      print('Orders migration completed successfully');
      return true;
    } catch (e) {
      print('Error migrating orders data: $e');
      return false;
    }
  }

  // Map old order status to new status
  String _mapOldStatusToNew(String oldStatus) {
    switch (oldStatus.toLowerCase()) {
      case 'pending':
        return 'pending';
      case 'confirmed':
        return 'confirmed';
      case 'preparing':
        return 'preparing';
      case 'delivering':
        return 'delivering';
      case 'completed':
        return 'delivered';
      case 'cancelled':
        return 'cancelled';
      default:
        return 'pending';
    }
  }

  // Calculate estimated delivery time
  DateTime _calculateEstimatedDeliveryTime() {
    return DateTime.now().add(Duration(minutes: 45));
  }

  // Check if migration is needed
  Future<bool> isMigrationNeeded() async {
    try {
      String? userId = await SharedPreferenceHelper().getUserId();
      if (userId == null) return false;

      // Check for old cart data
      var oldCartSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Cart')
          .limit(1)
          .get();

      // Check for old orders
      var oldOrdersSnapshot = await FirebaseFirestore.instance
          .collection('Orders')
          .where('UserID', isEqualTo: userId)
          .limit(1)
          .get();

      return oldCartSnapshot.docs.isNotEmpty ||
          oldOrdersSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking migration status: $e');
      return false;
    }
  }

  // Run full migration
  Future<bool> runFullMigration() async {
    try {
      print('Starting full migration...');

      bool cartMigration = await migrateCartData();
      bool ordersMigration = await migrateOrdersData();

      if (cartMigration && ordersMigration) {
        print('Full migration completed successfully');
        return true;
      } else {
        print('Migration failed');
        return false;
      }
    } catch (e) {
      print('Error during full migration: $e');
      return false;
    }
  }

  // Clean up old data (use with caution)
  Future<bool> cleanupOldData() async {
    try {
      String? userId = await SharedPreferenceHelper().getUserId();
      if (userId == null) return false;

      // Delete old cart subcollection
      var oldCartSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Cart')
          .get();

      for (var doc in oldCartSnapshot.docs) {
        await doc.reference.delete();
      }

      // Note: Don't delete old orders automatically
      // They should be kept for historical purposes

      print('Old data cleanup completed');
      return true;
    } catch (e) {
      print('Error during cleanup: $e');
      return false;
    }
  }
}
