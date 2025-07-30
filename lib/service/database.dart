// Demo mode database service - Firebase Firestore temporarily disabled
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseMethods {
  Future addFoodItem(Map<String, dynamic> foodInfoData, String category) async {
    try {
      print("🔄 Adding food item to Firestore: ${foodInfoData['Name']}");

      // Add to Firestore
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('FoodItems')
          .add(foodInfoData);

      print("✅ Food item added successfully with ID: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      print("❌ Error adding food item: $e");
      rethrow;
    }
  }

  Stream<QuerySnapshot> getFoodItems(String category) {
    print("📋 Getting food items for category: $category");

    if (category.isEmpty || category == 'All') {
      print("📋 Getting ALL food items");
      return FirebaseFirestore.instance
          .collection('FoodItems')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      print("📋 Getting ALL food items (will filter client-side)");
      // Get all items and filter client-side to avoid index issues
      return FirebaseFirestore.instance.collection('FoodItems').snapshots();
    }
  }

  // Helper method to filter food items by category
  List<QueryDocumentSnapshot> filterFoodItemsByCategory(
    List<QueryDocumentSnapshot> allItems,
    String category,
  ) {
    if (category.isEmpty || category == 'All') {
      return allItems;
    }

    return allItems.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      String itemCategory = data['Category'] ?? '';
      return itemCategory.toLowerCase() == category.toLowerCase();
    }).toList();
  }

  Future addUserDetails(Map<String, dynamic> userInfoMap) async {
    try {
      print("🔄 Adding user details to Firestore");

      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .set(userInfoMap);
        print("✅ User details added successfully");
      } else {
        print("❌ No user logged in");
      }
    } catch (e) {
      print("❌ Error adding user details: $e");
      rethrow;
    }
  }

  Future addUserDetail(Map<String, dynamic> userInfoMap, String userId) async {
    try {
      print("🔄 Adding user detail to Firestore for user: $userId");

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .set(userInfoMap);
      print("✅ User detail added successfully");
    } catch (e) {
      print("❌ Error adding user detail: $e");
      rethrow;
    }
  }

  Future addOrderDetails(Map<String, dynamic> orderInfoMap) async {
    try {
      print("🔄 Adding order details to Firestore");

      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('Orders')
          .add(orderInfoMap);
      print("✅ Order details added successfully with ID: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      print("❌ Error adding order details: $e");
      rethrow;
    }
  }

  Future<Stream<dynamic>> getUserOrders() async {
    try {
      print("📋 Getting user orders from Firestore");

      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        return FirebaseFirestore.instance
            .collection('Orders')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots();
      } else {
        print("❌ No user logged in");
        return Stream.empty();
      }
    } catch (e) {
      print("❌ Error getting user orders: $e");
      return Stream.empty();
    }
  }

  Future updateUserWallet(double amount) async {
    try {
      print("💰 Updating user wallet: $amount");

      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance.collection('Users').doc(userId).update(
          {'Wallet': amount.toString()},
        );
        print("✅ User wallet updated successfully");
      } else {
        print("❌ No user logged in");
      }
    } catch (e) {
      print("❌ Error updating user wallet: $e");
      rethrow;
    }
  }

  Future<dynamic> getUserDetails() async {
    try {
      print("👤 Getting user details from Firestore");

      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .get();

        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;
          data['Id'] = userId;
          print("✅ User details retrieved successfully");
          return data;
        } else {
          print("❌ User document not found");
          return null;
        }
      } else {
        print("❌ No user logged in");
        return null;
      }
    } catch (e) {
      print("❌ Error getting user details: $e");
      return null;
    }
  }

  Future addFoodToCart(Map<String, dynamic> cartInfoData, String userId) async {
    try {
      print("🛒 Adding food to cart for user: $userId");

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Cart')
          .add(cartInfoData);
      print("✅ Food added to cart successfully");
    } catch (e) {
      print("❌ Error adding food to cart: $e");
      rethrow;
    }
  }

  Future<Stream<dynamic>> getCartItems(String userId) async {
    try {
      print("📋 Getting cart items for user: $userId");

      return FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Cart')
          .snapshots();
    } catch (e) {
      print("❌ Error getting cart items: $e");
      return Stream.empty();
    }
  }

  Future<Stream<dynamic>> getFoodCart(String userId) async {
    try {
      print("📋 Getting food cart for user: $userId");

      return FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Cart')
          .snapshots();
    } catch (e) {
      print("❌ Error getting food cart: $e");
      return Stream.empty();
    }
  }

  Future UpdateUserwallet(String userId, dynamic amount) async {
    try {
      print("💰 Updating user wallet: $userId, amount: $amount");

      await FirebaseFirestore.instance.collection('Users').doc(userId).update({
        'Wallet': amount.toString(),
      });
      print("✅ User wallet updated successfully");
    } catch (e) {
      print("❌ Error updating user wallet: $e");
      rethrow;
    }
  }

  Future deleteCartItem(String userId, String cartItemId) async {
    try {
      print("🗑️ Deleting cart item: $cartItemId for user: $userId");

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Cart')
          .doc(cartItemId)
          .delete();
      print("✅ Cart item deleted successfully");
    } catch (e) {
      print("❌ Error deleting cart item: $e");
      rethrow;
    }
  }
}
