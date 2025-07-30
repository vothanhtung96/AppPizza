import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pizza_app_vs_010/service/shared_pref.dart';

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  // Cart status constants
  static const String CART_STATUS_ACTIVE = 'active';
  static const String CART_STATUS_ORDERED = 'ordered';
  static const String CART_STATUS_ABANDONED = 'abandoned';

  // Get or create user's active cart
  Future<String?> _getOrCreateCart() async {
    try {
      String? userId = await SharedPreferenceHelper().getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Check if user has active cart
      var cartQuery = await FirebaseFirestore.instance
          .collection('cart')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: CART_STATUS_ACTIVE)
          .limit(1)
          .get();

      if (cartQuery.docs.isNotEmpty) {
        return cartQuery.docs.first.id;
      } else {
        // Create new active cart
        var cartRef = await FirebaseFirestore.instance.collection('cart').add({
          'userId': userId,
          'status': CART_STATUS_ACTIVE,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return cartRef.id;
      }
    } catch (e) {
      print('Error getting or creating cart: $e');
      return null;
    }
  }

  // Add item to cart
  Future<bool> addToCart(Map<String, dynamic> foodData) async {
    try {
      String? cartId = await _getOrCreateCart();
      if (cartId == null) {
        return false;
      }

      // Check if item already exists in cart
      var existingItemQuery = await FirebaseFirestore.instance
          .collection('cartItems')
          .where('cartId', isEqualTo: cartId)
          .where('productId', isEqualTo: foodData['id'] ?? '')
          .get();

      if (existingItemQuery.docs.isNotEmpty) {
        // Update quantity if item exists
        var existingDoc = existingItemQuery.docs.first;
        int currentQuantity = existingDoc.data()['quantity'] ?? 1;
        await existingDoc.reference.update({
          'quantity': currentQuantity + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Add new item to cart
        var cartItem = {
          'cartId': cartId,
          'productId': foodData['id'] ?? '',
          'productName': foodData['Name'],
          'productImage': foodData['Image'],
          'quantity': 1,
          'price': double.parse((foodData['Price'] ?? 0).toString()),
          'note': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance.collection('cartItems').add(cartItem);
      }

      // Update cart timestamp
      await FirebaseFirestore.instance.collection('cart').doc(cartId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error adding to cart: $e');
      return false;
    }
  }

  // Add item to cart with specific quantity
  Future<bool> addToCartWithQuantity(
    Map<String, dynamic> foodData,
    int quantity,
  ) async {
    try {
      print('🛒 Adding to cart with quantity:');
      print('  - Product ID: ${foodData['id']}');
      print('  - Product Name: ${foodData['Name']}');
      print('  - Quantity: $quantity');
      print('  - Full foodData: $foodData');

      String? cartId = await _getOrCreateCart();
      if (cartId == null) {
        return false;
      }

      // Always add new item to cart (don't check for existing)
      print('➕ Adding new item with quantity: $quantity');
      print('📋 Food Data: $foodData');

      var cartItem = {
        'cartId': cartId,
        'productId': foodData['id'] ?? '',
        'productName': foodData['Name'],
        'productImage': foodData['Image'],
        'quantity': quantity,
        'price': double.parse((foodData['Price'] ?? 0).toString()),
        'note': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print('📦 Cart Item to save: $cartItem');

      await FirebaseFirestore.instance.collection('cartItems').add(cartItem);

      // Update cart timestamp
      await FirebaseFirestore.instance.collection('cart').doc(cartId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Successfully added to cart');
      return true;
    } catch (e) {
      print('❌ Error adding to cart with quantity: $e');
      return false;
    }
  }

  // Get cart items for current user
  Future<List<Map<String, dynamic>>> getCartItems() async {
    try {
      String? cartId = await _getOrCreateCart();
      if (cartId == null) {
        return [];
      }

      // Retry logic for index building
      int maxRetries = 3;
      int retryCount = 0;

      while (retryCount < maxRetries) {
        try {
          var cartItemsSnapshot = await FirebaseFirestore.instance
              .collection('cartItems')
              .where('cartId', isEqualTo: cartId)
              .orderBy('createdAt', descending: true)
              .get();

          List<Map<String, dynamic>> items = [];
          for (var doc in cartItemsSnapshot.docs) {
            var data = doc.data();
            data['id'] = doc.id;

            // Debug logging
            print('📦 Cart Item Data:');
            print('  - ID: ${data['id']}');
            print('  - Product Name: ${data['productName']}');
            print('  - Product Image: ${data['productImage']}');
            print('  - Price: ${data['price']}');
            print('  - Quantity: ${data['quantity']}');

            // Get options for this cart item
            try {
              var optionsSnapshot = await FirebaseFirestore.instance
                  .collection('cartItemOptions')
                  .where('cartItemId', isEqualTo: doc.id)
                  .get();

              data['options'] = optionsSnapshot.docs.map((optionDoc) {
                var optionData = optionDoc.data();
                optionData['id'] = optionDoc.id;
                return optionData;
              }).toList();
            } catch (e) {
              print('Error loading options for item ${doc.id}: $e');
              data['options'] = [];
            }

            items.add(data);
          }

          print('🛒 Total cart items: ${items.length}');
          return items;
        } catch (e) {
          retryCount++;
          print('Attempt $retryCount failed: $e');

          if (e.toString().contains('index') && retryCount < maxRetries) {
            // Wait before retrying for index building
            await Future.delayed(Duration(seconds: 2 * retryCount));
            continue;
          } else {
            rethrow;
          }
        }
      }

      return [];
    } catch (e) {
      print('Error getting cart items: $e');
      return [];
    }
  }

  // Update item quantity
  Future<bool> updateQuantity(String itemId, int newQuantity) async {
    try {
      String? cartId = await _getOrCreateCart();
      if (cartId == null) {
        return false;
      }

      if (newQuantity <= 0) {
        // Remove item from cart
        await FirebaseFirestore.instance
            .collection('cartItems')
            .doc(itemId)
            .delete();
      } else {
        // Update quantity
        await FirebaseFirestore.instance
            .collection('cartItems')
            .doc(itemId)
            .update({
              'quantity': newQuantity,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      // Update cart timestamp
      await FirebaseFirestore.instance.collection('cart').doc(cartId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating quantity: $e');
      return false;
    }
  }

  // Remove item from cart
  Future<bool> removeItem(String itemId) async {
    try {
      String? cartId = await _getOrCreateCart();
      if (cartId == null) {
        return false;
      }

      // Remove all options for this item first
      var optionsSnapshot = await FirebaseFirestore.instance
          .collection('cartItemOptions')
          .where('cartItemId', isEqualTo: itemId)
          .get();

      for (var optionDoc in optionsSnapshot.docs) {
        await optionDoc.reference.delete();
      }

      // Remove the cart item
      await FirebaseFirestore.instance
          .collection('cartItems')
          .doc(itemId)
          .delete();

      // Update cart timestamp
      await FirebaseFirestore.instance.collection('cart').doc(cartId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error removing item: $e');
      return false;
    }
  }

  // Clear cart for current user
  Future<bool> clearCart() async {
    try {
      String? cartId = await _getOrCreateCart();
      if (cartId == null) {
        return false;
      }

      // Get all cart items
      var cartItemsSnapshot = await FirebaseFirestore.instance
          .collection('cartItems')
          .where('cartId', isEqualTo: cartId)
          .get();

      // Remove all options for all items
      for (var itemDoc in cartItemsSnapshot.docs) {
        var optionsSnapshot = await FirebaseFirestore.instance
            .collection('cartItemOptions')
            .where('cartItemId', isEqualTo: itemDoc.id)
            .get();

        for (var optionDoc in optionsSnapshot.docs) {
          await optionDoc.reference.delete();
        }
      }

      // Remove all cart items
      for (var doc in cartItemsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Update cart timestamp
      await FirebaseFirestore.instance.collection('cart').doc(cartId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error clearing cart: $e');
      return false;
    }
  }

  // Get cart count for current user
  Future<int> getCartCount() async {
    try {
      String? cartId = await _getOrCreateCart();
      if (cartId == null) {
        return 0;
      }

      var cartItemsSnapshot = await FirebaseFirestore.instance
          .collection('cartItems')
          .where('cartId', isEqualTo: cartId)
          .get();

      int totalCount = 0;
      for (var doc in cartItemsSnapshot.docs) {
        totalCount += int.parse((doc.data()['quantity'] ?? 1).toString());
      }

      return totalCount;
    } catch (e) {
      print('Error getting cart count: $e');
      return 0;
    }
  }

  // Calculate cart total for current user
  Future<double> getCartTotal() async {
    try {
      String? cartId = await _getOrCreateCart();
      if (cartId == null) {
        return 0.0;
      }

      var cartItemsSnapshot = await FirebaseFirestore.instance
          .collection('cartItems')
          .where('cartId', isEqualTo: cartId)
          .get();

      double total = 0.0;
      for (var doc in cartItemsSnapshot.docs) {
        var data = doc.data();
        double itemPrice = (data['price'] ?? 0.0) * (data['quantity'] ?? 1);

        // Add options price
        var optionsSnapshot = await FirebaseFirestore.instance
            .collection('cartItemOptions')
            .where('cartItemId', isEqualTo: doc.id)
            .get();

        for (var optionDoc in optionsSnapshot.docs) {
          itemPrice += (optionDoc.data()['extraPrice'] ?? 0.0);
        }

        total += itemPrice;
      }

      return total;
    } catch (e) {
      print('Error calculating cart total: $e');
      return 0.0;
    }
  }

  // Add option to cart item
  Future<bool> addCartItemOption(
    String cartItemId,
    String optionName,
    String optionValue,
    double extraPrice,
  ) async {
    try {
      var optionData = {
        'cartItemId': cartItemId,
        'optionName': optionName,
        'optionValue': optionValue,
        'extraPrice': extraPrice,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('cartItemOptions')
          .add(optionData);

      return true;
    } catch (e) {
      print('Error adding cart item option: $e');
      return false;
    }
  }

  // Remove option from cart item
  Future<bool> removeCartItemOption(String optionId) async {
    try {
      await FirebaseFirestore.instance
          .collection('cartItemOptions')
          .doc(optionId)
          .delete();

      return true;
    } catch (e) {
      print('Error removing cart item option: $e');
      return false;
    }
  }

  // Mark cart as ordered (when order is created)
  Future<bool> markCartAsOrdered(String cartId) async {
    try {
      await FirebaseFirestore.instance.collection('cart').doc(cartId).update({
        'status': CART_STATUS_ORDERED,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error marking cart as ordered: $e');
      return false;
    }
  }

  // Get cart ID for current user
  Future<String?> getCurrentCartId() async {
    return await _getOrCreateCart();
  }
}
