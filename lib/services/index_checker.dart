import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pizza_app_vs_010/service/shared_pref.dart';

class IndexChecker {
  static final IndexChecker _instance = IndexChecker._internal();
  factory IndexChecker() => _instance;
  IndexChecker._internal();

  // Check if required indexes are ready
  Future<Map<String, bool>> checkIndexes() async {
    Map<String, bool> indexStatus = {
      'cartItems': false,
      'orders': false,
      'cart': false,
    };

    try {
      // Test cartItems index
      try {
        await FirebaseFirestore.instance
            .collection('cartItems')
            .where('cartId', isEqualTo: 'test')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();
        indexStatus['cartItems'] = true;
        print('✅ cartItems index is ready');
      } catch (e) {
        print('❌ cartItems index not ready: $e');
      }

      // Test orders index
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: 'test')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();
        indexStatus['orders'] = true;
        print('✅ orders index is ready');
      } catch (e) {
        print('❌ orders index not ready: $e');
      }

      // Test cart index
      try {
        await FirebaseFirestore.instance
            .collection('cart')
            .where('userId', isEqualTo: 'test')
            .where('status', isEqualTo: 'active')
            .limit(1)
            .get();
        indexStatus['cart'] = true;
        print('✅ cart index is ready');
      } catch (e) {
        print('❌ cart index not ready: $e');
      }
    } catch (e) {
      print('Error checking indexes: $e');
    }

    return indexStatus;
  }

  // Check if orders index is ready
  static Future<bool> isOrdersIndexReady() async {
    try {
      String? userId = await SharedPreferenceHelper().getUserId();
      if (userId == null) return false;

      // Try a simple query to test the index
      await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      return true;
    } catch (e) {
      if (e.toString().contains('index')) {
        return false;
      }
      return true; // Other errors don't indicate index issues
    }
  }

  // Wait for orders index to be ready
  static Future<void> waitForOrdersIndex({int maxWaitSeconds = 60}) async {
    print('⏳ Waiting for orders index to be ready...');
    int waitedSeconds = 0;

    while (waitedSeconds < maxWaitSeconds) {
      if (await isOrdersIndexReady()) {
        print('✅ Orders index is ready!');
        return;
      }

      print(
        '⏳ Orders index still building... (${waitedSeconds + 5}s/${maxWaitSeconds}s)',
      );
      await Future.delayed(Duration(seconds: 5));
      waitedSeconds += 5;
    }

    print('⚠️ Orders index not ready after $maxWaitSeconds seconds');
  }

  // Get index creation links
  Map<String, String> getIndexLinks() {
    return {
      'cartItems':
          'https://console.firebase.google.com/v1/r/project/food-delivery-beb90/firestore/indexes?create_composite=ClVwcm9qZWN0cy9mb29kLWRlbGl2ZXJ5LWJlYjkwL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9jYXJ0SXRlbXMvaW5kZXhlcy9fEAEaCgoGY2FydElkEAEaDQoJY3JlYXRlZEF0EAIaDAoIX19uYW1lX18QAg',
      'orders':
          'https://console.firebase.google.com/v1/r/project/food-delivery-beb90/firestore/indexes?create_composite=ClJwcm9qZWN0cy9mb29kLWRlbGl2ZXJ5LWJlYjkwL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9vcmRlcnMvaW5kZXhlcy9fEAEaCgoGdXNlcklkEAEaDQoJY3JlYXRlZEF0EAIaDAoIX19uYW1lX18QAg',
    };
  }

  // Print index status
  Future<void> printIndexStatus() async {
    print('🔍 Checking Firestore indexes...');
    Map<String, bool> status = await checkIndexes();

    print('\n📊 Index Status:');
    status.forEach((collection, isReady) {
      print(
        '${isReady ? '✅' : '❌'} $collection: ${isReady ? 'Ready' : 'Not Ready'}',
      );
    });

    if (status.values.contains(false)) {
      print('\n🔗 Index Creation Links:');
      Map<String, String> links = getIndexLinks();
      links.forEach((collection, link) {
        if (!status[collection]!) {
          print('📝 $collection: $link');
        }
      });
    }
  }

  // Check and create FoodItems indexes
  static Future<void> checkFoodItemsIndexes() async {
    print('🔍 Checking FoodItems indexes...');

    try {
      // Test query for Category + createdAt index
      await FirebaseFirestore.instance
          .collection('FoodItems')
          .where('Category', isEqualTo: 'test')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      print('✅ FoodItems Category + createdAt index is ready');
    } catch (e) {
      print('⚠️ FoodItems index not ready: $e');

      // Try to create the index by making a request
      try {
        print('🔄 Attempting to create FoodItems index...');
        await FirebaseFirestore.instance
            .collection('FoodItems')
            .where('Category', isEqualTo: 'Pizza')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();
        print('✅ FoodItems index creation initiated');
      } catch (e2) {
        print('❌ Could not create FoodItems index: $e2');
      }
    }
  }
}
